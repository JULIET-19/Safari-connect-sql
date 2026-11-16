CREATE OR REPLACE VIEW v_clean_trips AS
SELECT *,
    TO_CHAR(departure_date, 'YYYY-MM')    AS travel_month,
    TO_CHAR(departure_date, 'Month YYYY') AS month_label,
    TO_CHAR(departure_date, 'Day')        AS day_name,
    EXTRACT(MONTH FROM departure_date)    AS month_num,
    EXTRACT(DOW FROM departure_date)      AS day_of_week,
    (fare_per_seat * seats_booked)           AS calculated_fare,
    CASE
        WHEN trip_rating BETWEEN 4 AND 5 THEN 'Satisfied'
        WHEN trip_rating = 3 THEN 'Neutral'
        WHEN trip_rating BETWEEN 1 AND 2 THEN 'Unsatisfied'
        ELSE 'No Rating'
    END AS satisfaction
FROM bookings
WHERE booking_status = 'Completed';

-- Test
SELECT * FROM v_clean_trips LIMIT 10;


/* Question - 1 : Route Analysis Which routes earn the most? 
Which are most popular? Which is most efficient per seat sold?

Specific route codes with KES figures - A clear top route and a clear underperformer.
*/

-- first step - Create Route name for the Distinct Route codes
-- Calculate Total_Revenue
CREATE OR REPLACE VIEW v_route_analysis AS
with route_name as(
     select distinct route_code, route_from || ' - ' || route_to as name
     from v_clean_trips
),
total_revenue_per_route as(
     select route_code, 
     count(route_code) as popular,
     sum(seats_booked) as total_seats,
     sum(total_fare) as total_revenue
     from v_clean_trips
     group by route_code
)
select tr.route_code,rn.name, tr.popular, tr.total_seats, tr.total_revenue,
rank() over (order by total_revenue desc) as Most_earning_route,
rank() over (order by total_seats, total_revenue desc) as Most_efficient
from total_revenue_per_route tr
inner join route_name rn
on rn.route_code = tr.route_code;



/*Question 2
 * Driver Performance Who are the best drivers? 
 * Does driver rating affect passenger satisfaction? : No passenger satisfaction does not affect driver ratings	 
 *Named drivers with revenue and rating figures. 
 *A promotion recommendation with data behind it.
 *(Kelvin Omondi  with an average rating of 4.5(in 3rd postion) and still 
 *second best revenue_generator with a total revenue of 30,855)
-- */
CREATE OR REPLACE VIEW v_driver_perfomance AS
with driver_performance as(
	select driver_name, 
	avg(driver_rating)as driver_rating,
	round(avg(
	case
		when satisfaction = 'No Rating' then null
		when satisfaction = 'Satisfied' then 3
		when satisfaction = 'Unsatisfied' then 1
		when satisfaction = 'Neutral' then 2
		end ),1)
	as avg_passenger_satisfaction,
	sum(total_fare) as revenue_generated
	from v_clean_trips
	group by driver_name
)
select 
	driver_name, 
	revenue_generated,
	rank() over (order by  revenue_generated desc) as Top_Revenue_earner,
	driver_rating,
	avg_passenger_satisfaction,
	rank() over (order by driver_rating desc, revenue_generated) as Top_Rated
from driver_performance 
order by Top_Rated;

select * from v_driver_perfomance



/* Question 3
 Revenue Trends How is revenue changing month by month? 
 What are our best and worst months?	Month-over-month change with % growth. 
 A trend direction - growing or declining?
 * */

select total_fare, calculated_fare
from v_clean_trips;

CREATE OR REPLACE VIEW v_revenue_trends as
with total_revenue as (
select
     month_label,
     sum(total_fare) as monthly_revenue
from v_clean_trips
group by month_label
order by to_date(month_label, 'Month YYYY')
),
revenue_trend as(
	select 
	month_label,
	monthly_revenue,
	lag( monthly_revenue,1) over (order by TO_DATE(month_label, 'Month YYYY')) as previous_month_revenue
from total_revenue
)
select
month_label,
monthly_revenue,
previous_month_revenue,
round(100 *(monthly_revenue - previous_month_revenue)/previous_month_revenue,1) as percentage_growth
from revenue_trend 
order by TO_DATE(month_label, 'Month YYYY');

select * from v_revenue_trends; --shows how revenue is changing month by month

-- OR 

CREATE OR REPLACE VIEW v_revenue_trend as
WITH monthly AS (
    SELECT 
        TO_CHAR(departure_date, 'YYYY-MM') AS month,
        COUNT(*) AS bookings,
        SUM(total_fare) AS revenue
    FROM v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT 
    month,
    bookings,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    revenue - LAG(revenue) OVER (ORDER BY month) AS change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 1) AS change_pct
FROM monthly;
select * from v_revenue_trend

/*Question 4
 * Passenger Insights Where do passengers come from? 
 * What seat class do they prefer? Are they satisfied?	
 * Top cities with numbers. Satisfaction breakdown. 
 * Gender and class split.
 * */

CREATE OR REPLACE VIEW v_passenger_insights AS
with top_customer_cities as (
	select 
		passenger_city, 
		vct.passenger_gender, 
		seat_class as preffered_class,
		vct.satisfaction,
		count(distinct passenger_name) as no_of_customers
	from v_clean_trips vct 
	group by passenger_gender, passenger_city , seat_class, satisfaction 
) 
select 
        passenger_city, 
        sum(no_of_customers) over(partition by passenger_city) as total_city_customers,
		passenger_gender, 
		preffered_class,
		satisfaction,
		no_of_customers
from top_customer_cities
order by total_city_customers desc,  passenger_city;


/* Question 5
 * 5	Cancellations What is the cancellation rate per route? 
 * How much revenue did cancellations cost us?	
 * A KES figure for lost revenue. 
 * The worst route for cancellations. A policy recommendation.
 * */

CREATE OR REPLACE VIEW v_cancellation_analysis AS
with cancellation_route_revenue as(
     select
	     route_code, 
	     count (distinct b.booking_id) as cancelled_bookings,
	     sum(b.total_fare) as lost_revenue_ksh 
     from safari_connect.bookings b 
     where booking_status = 'Cancelled'
     group by route_code
),
route_total_bookings as (
     select route_code,
     count(distinct booking_id) as total_city_bookings
     from v_clean_trips vct 
     group by route_code 
),
route_name as(
     select distinct route_code, route_from || ' - ' || route_to as name
     from v_clean_trips
)
select 
	cr.route_code, 
	rn.name,
	cr.lost_revenue_ksh,
	cr.cancelled_bookings, 
	rt.total_city_bookings,
	round(100* (cr.cancelled_bookings::numeric / rt.total_city_bookings), 0)as percentage_cancellation_rate
from cancellation_route_revenue cr
inner join route_total_bookings rt
on cr.route_code = rt.route_code 
inner join route_name rn
on rt.route_code = rn.route_code
order by percentage_cancellation_rate desc;


/*
 * Operational Patterns What are our busiest days and times? 
 * When should we add more vehicles? -- Wednesday 7:30 -9am
 * Specific days and times with booking and revenue numbers. 
 * A clear peak period.(Wednesday 7:30 -9am)
 * */

CREATE OR REPLACE VIEW v_operational_patterns AS
with busiest_time as (
select 
     day_name, 
     vct.departure_time,
     count(vct.booking_id) as time_bookings,
     sum(total_fare) as time_revenue
from v_clean_trips vct 
group by day_name, departure_time 
)
select 
	day_name,
	departure_time,
	time_bookings,
	row_number() over (partition by day_name order by time_bookings desc) as booking_time_rank,
	time_revenue,
	row_number() over ( partition by day_name order by time_revenue desc) as revenue_rank,
	SUM(time_bookings) over(partition by day_name) as total_of_that_day_bookings,
	SUM(time_revenue ) over(partition by day_name) as total_of_that_day_revenue
from busiest_time
order by total_of_that_day_bookings desc, booking_time_rank;



select * FROM v_clean_trips;
select * from safari_connect.bookings b;
