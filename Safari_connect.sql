CREATE SCHEMA IF NOT EXISTS safari_connect;

SET search_path TO safari_connect;

-- Staging table: ALL columns TEXT - accepts dirty data without failing
CREATE TABLE IF NOT EXISTS bookings_staging (
    booking_id       TEXT,
    passenger_name    TEXT, 
    passenger_phone  TEXT,
    passenger_gender TEXT, 
    passenger_city    TEXT, 
    route_code       TEXT,
    route_from       TEXT, 
    route_to          TEXT, 
    vehicle_plate    TEXT,
    vehicle_type     TEXT, 
    driver_name       TEXT, 
    driver_rating    TEXT,
    departure_date   TEXT, 
    departure_time    TEXT, 
    seat_class       TEXT,
    seats_booked     TEXT, 
    fare_per_seat     TEXT, 
    total_fare       TEXT,
    payment_method   TEXT, 
    booking_status    TEXT, 
    trip_rating      TEXT
);

select * from safari_connect.bookings_staging bs;

-- Verify Import
select count(*) from safari_connect.bookings_staging bs;

select * from safari_connect.bookings_staging bs limit 10;


-- Identify Name Casing Problems
select distinct passenger_name from safari_connect.bookings_staging bs order by passenger_name limit 30;

-- Clean 1 - passenger_name casing + whitespace

select booking_id, passenger_name FROM bookings_staging
where passenger_name != INITCAP(TRIM(passenger_name));

update bookings_staging
set passenger_name = INITCAP(TRIM(passenger_name))
where passenger_name != INITCAP(TRIM(passenger_name));

select booking_id, passenger_name FROM bookings_staging
where passenger_name = INITCAP(TRIM(passenger_name));

-- Clean 2. Gender variants - should be only Male/Female

select distinct passenger_gender, COUNT(*) FROM bookings_staging GROUP BY passenger_gender;

select passenger_gender,
case
	when upper(trim(passenger_gender)) in ('FEMALE', 'F') then 'Female'
	when upper(trim(passenger_gender)) in ('MALE', 'M') then 'Male'
end
from safari_connect.bookings_staging bs;

--Update the passenger_gender column
update safari_connect.bookings_staging bs
set passenger_gender = case
	when upper(trim(passenger_gender)) in ('FEMALE', 'F') then 'Female'
	when upper(trim(passenger_gender)) in ('MALE', 'M') then 'Male'
	else passenger_gender
end;

-- Check disctint gender again after update
select distinct passenger_gender, COUNT(*) FROM bookings_staging GROUP BY passenger_gender;

-- Clean 3. Phone format problems
Select booking_id, passenger_phone FROM safari_connect.bookings_staging;
where passenger_phone LIKE '+254%' OR passenger_phone LIKE '%-%';

--Identifying the dashes
select booking_id, passenger_phone,
REGEXP_REPLACE(passenger_phone,'[^0-9]','','g')
FROM safari_connect.bookings_staging
WHERE passenger_phone LIKE '%-%';

-- Removing the dashes
update bookings_staging
set passenger_phone = REGEXP_REPLACE(passenger_phone,'[^0-9]','','g')
where passenger_phone LIKE '%-%';

select booking_id, passenger_name, 
SUBSTRING(REGEXP_REPLACE(passenger_phone,'[^0-9]','','g'),4) as phone
from safari_connect.bookings_staging bs


select distinct bs.passenger_name, bs.passenger_phone, bs.booking_id 
from safari_connect.bookings_staging bs 
order by bs.booking_id ;



/*select booking_id, passenger_phone,  '0' || SUBSTRING(REGEXP_REPLACE(passenger_phone,'[^0-9]','','g'),4) as phn
from safari_connect.booking_staging bs 
WHERE passenger_phone LIKE '254%';
*/


update  safari_connect.bookings_staging 
set passenger_phone = '734333444'
where booking_id = 'BK0093';


update safari_connect.bookings_staging bs 
set passenger_phone = '790123456'
where booking_id = 'BK0049';

update safari_connect.bookings_staging bs 
set passenger_phone = '790123456'
where booking_id = 'BK0269';

select * from safari_connect.bookings_staging bs 
where passenger_name = 'Karen Adhiambo';

update safari_connect.bookings_staging bs 
set passenger_phone = '778901234'
where booking_id in ('BK0247','BK0027');

update safari_connect.bookings_staging bs 
set passenger_phone = '756789012'
where booking_id in ('BK0225','BK0005');

update safari_connect.bookings_staging bs 
set passenger_phone = '790999000'
where booking_id in ('BK0159');

update safari_connect.bookings_staging bs 
set passenger_phone = '778777888'
where booking_id in ('BK0137');



update safari_connect.bookings_staging bs
set passenger_phone = case booking_id
when 'BK0203' then '734567890'
when 'BK0181' then '712345678'
when 'BK0182' then '723456789'
when 'BK0204' then '0745678901'
when 'BK0006' then '0767890123'
when 'BK0226' then '0767890123'
when 'BK0028' then '0789012345'
when 'BK0248' then '0789012345'
when 'BK0270' then '701234567'
when 'BK0050' then '0701234567'
when 'BK0051' then '712111222'
when 'BK0052' then '0723222333'
when 'BK0094' then '745444555'
when 'BK0115' then '756555666'
when 'BK0116' then '0767666777'
when 'BK0138' then '789888999'
when 'BK0160' then '0701000111'
else passenger_phone
end;


update safari_connect.bookings_staging bs
set passenger_phone = case booking_id
when 'BK9004' then '0745678901'
when 'BK0072' then '0723222333'
when 'BK0071' then '712111222'
else passenger_phone
end;

update safari_connect.bookings_staging bs 
SET passenger_phone = '0' || passenger_phone
where length(passenger_phone) = 9 and passenger_phone like '7%';

select * from safari_connect.bookings_staging;

-- Clean 4... seat_class variants
select distinct seat_class, COUNT(*) FROM bookings_staging GROUP BY seat_class;

select seat_class,
case 
	when upper(trim(seat_class)) in ('ECONOMY', 'ECONOMY CLASS', 'ECO') then 'Economy'
	WHEN UPPER(TRIM(seat_class)) IN ('BUSINESS','BUS','BUSINESS CLASS') THEN 'Business'
    ELSE seat_class
end
from safari_connect.bookings_staging bs;

UPDATE bookings_staging
SET seat_class = CASE
    WHEN UPPER(TRIM(seat_class)) IN ('ECONOMY','ECO','ECONOMY CLASS') THEN 'Economy'
    WHEN UPPER(TRIM(seat_class)) IN ('BUSINESS','BUS','BUSINESS CLASS') THEN 'Business'
    ELSE seat_class
END;

-- Clean 5 ... Payment method variants
select distinct payment_method from safari_connect.bookings_staging bs;

select payment_method,
case 
	when upper(trim(payment_method)) in ('MPESA', 'M-PESA') then 'M-Pesa'
	when upper(trim(payment_method)) in ('CASH') then 'Cash'
	when upper(trim(payment_method)) in ('CARD') then 'Card'
	else payment_method
end
from safari_connect.bookings_staging bs;

--- updating the table
update safari_connect.bookings_staging bs 
set payment_method = 
case
	when upper(trim(payment_method)) in ('MPESA', 'M-PESA') then 'M-Pesa'
	when upper(trim(payment_method)) in ('CASH') then 'Cash'
	when upper(trim(payment_method)) in ('CARD') then 'Card'
	else payment_method
end;

-- Clean 6 Booking status
-- Select booking_status variants

select distinct bs.booking_status  from safari_connect.bookings_staging bs;

-- Updating Booking_status variants
update safari_connect.bookings_staging bs 
set booking_status = 
case
	when upper(trim(booking_status)) in ('CANCELLED') then 'Cancelled'
	when upper(trim(booking_status)) in ('COMPLETED') then 'Completed'
	when upper(trim(booking_status)) in ('NO SHOW') then 'No Show'
	else booking_status
end;

-- Clean 7 ...Fares stored as text (total_fares and fare_per_seat)
Select booking_id, total_fare, fare_per_seat FROM bookings_staging
WHERE total_fare LIKE 'KES%' OR fare_per_seat LIKE 'KES%'; 

update bookings_staging
set total_fare = REGEXP_REPLACE(total_fare,'[^0-9.]','','g')
where total_fare SIMILAR TO '%[^0-9.]%';

UPDATE bookings_staging
SET fare_per_seat = REGEXP_REPLACE(fare_per_seat,'[^0-9.]','','g')
WHERE fare_per_seat SIMILAR TO '%[^0-9.]%';


-- see trip_rating
select distinct bs.trip_rating  from safari_connect.bookings_staging bs; 

-- select invalid trip ratings
select bs.trip_rating  
from safari_connect.bookings_staging bs
where bs.trip_rating not in ('1', '2', '3', '4', '5', ''); 


update safari_connect.bookings_staging bs 
set trip_rating = ''
where bs.trip_rating not in ('1', '2', '3', '4', '5'); 


-- Passenger city
select passenger_city, bs.booking_id, bs.passenger_name  
from safari_connect.bookings_staging bs;

-- Cleaning passenger_city
--checking all the rows in the city column that are not written in proper case
select booking_id, passenger_name, passenger_city
from safari_connect.bookings_staging bs
where bs.passenger_city = initcap(TRIM(passenger_city)); 

--rewritting every value in the passenger_city column to the correct format
update safari_connect.bookings_staging bs
set passenger_city = initcap(TRIM(passenger_city))
where bs.passenger_city != initcap(TRIM(passenger_city));


--checking for blank values in Passenger_city column
select booking_id, passenger_name, passenger_city
from safari_connect.bookings_staging bs
where passenger_city = ''; 
 
 
update safari_connect.bookings_staging bs
set passenger_city = case passenger_name
when 'Brian Otieno' then 'Mombasa'
when 'Nathan Kipchoge' then 'Eldoret'
when 'David Kamau' then 'Nairobi'
when 'Felix Hassan' then 'Nairobi'
when 'Henry Korir' then 'Nairobi'
when 'Patrick Ngugi' then 'Nyeri'
when 'James Gitonga' then 'Nairobi'
when 'Liam Mutua' then 'Machakos'
when 'Samuel Odhiambo' then 'Kisumu'
when 'Victor Abdi' then 'Mombasa'
else passenger_city
end;


--Clean seats_booked
select distinct seats_booked
from safari_connect.bookings_staging bs;

SELECT booking_id, seats_booked FROM bookings_staging
WHERE NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9-]','','g'),'')::INTEGER < 1; --Invalid id = 'BK9002'

update bookings_staging bs 
set seats_booked = ''
WHERE NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9-]','','g'),'')::INTEGER < 1;

-- Clean Vehicle types
select distinct bs.vehicle_type  from safari_connect.bookings_staging bs 

select vehicle_type, 
case 
	when UPPER(trim(vehicle_type)) in ('BUS') then 'Bus'
	when upper(trim(vehicle_type)) in ('MATATU') then 'Matatu'
	when upper(trim(vehicle_type)) in ('MINIBUS') then 'Minibus'
	else bs.vehicle_type
end as type
from safari_connect.bookings_staging bs;
 
--update
update safari_connect.bookings_staging bs
set vehicle_type =
case
	when UPPER(trim(vehicle_type)) in ('BUS') then 'Bus'
	when upper(trim(vehicle_type)) in ('MATATU') then 'Matatu'
	when upper(trim(vehicle_type)) in ('MINIBUS') then 'Minibus'
	else bs.vehicle_type
end;


-- select disctint driver_name
select distinct driver_name from safari_connect.bookings_staging bs;

update safari_connect.bookings_staging
set driver_name = initcap(trim(driver_name))
where driver_name != initcap(trim(driver_name));

-- Cleaning date formats
select departure_date  from safari_connect.bookings_staging bs;


--identifies dates where the second part is greater than 12

UPDATE safari_connect.bookings_staging bs
SET departure_date = TO_DATE(departure_date, 'MM/DD/YYYY')::TEXT
WHERE departure_date LIKE '%/%'
  AND LENGTH(departure_date) = 10
  AND SPLIT_PART(departure_date, '/', 2)::INTEGER > 12;

UPDATE safari_connect.bookings_staging bs
SET departure_date = TO_DATE(departure_date, 'MM/DD/YYYY')::TEXT
WHERE departure_date LIKE '%/%'
  AND LENGTH(departure_date) = 9
  AND SPLIT_PART(departure_date, '/', 2)::INTEGER > 12;

--identifies dates where the second part is greater than 12 & length 10

UPDATE safari_connect.bookings_staging bs
SET departure_date = TO_DATE(departure_date, 'DD/MM/YYYY')::TEXT
WHERE departure_date LIKE '%/%'
  AND LENGTH(departure_date) = 10
  AND SPLIT_PART(departure_date, '/', 1)::INTEGER > 12;

--identifies dates where the second part is greater than 12 & length 9

UPDATE safari_connect.bookings_staging bs
SET departure_date = TO_DATE(departure_date, 'DD/MM/YYYY')::TEXT
WHERE departure_date LIKE '%/%'
  AND LENGTH(departure_date) = 9
  AND SPLIT_PART(departure_date, '/', 1)::INTEGER > 12;


-- identifies dates where length 9
UPDATE safari_connect.bookings_staging bs
SET departure_date = TO_DATE(departure_date, 'MM/DD/YYYY')::TEXT
WHERE departure_date LIKE '%/%'
  AND LENGTH(departure_date) = 9;


-- identifies dates where length 8
UPDATE safari_connect.bookings_staging bs 
SET departure_date = TO_DATE(departure_date,'DD-MM-YY')::TEXT
WHERE departure_date LIKE '%-%' AND LENGTH(departure_date) = 8;

UPDATE safari_connect.bookings_staging bs
SET departure_date = TO_DATE(departure_date, 'MM/DD/YYYY')::TEXT
WHERE departure_date LIKE '%/%'
  AND LENGTH(departure_date) = 8;

UPDATE safari_connect.bookings_staging bs
SET departure_date = TO_DATE(departure_date, 'MM/DD/YYYY')::TEXT
WHERE departure_date LIKE '%/%'
  AND LENGTH(departure_date) = 10;

--check dates with slashes
SELECT booking_id, departure_date
FROM safari_connect.bookings_staging
WHERE departure_date LIKE '%/%';

-- check dates seperated by hyphen
SELECT booking_id, departure_date
FROM safari_connect.bookings_staging
WHERE departure_date LIKE '%-%';


-- find dates whose length is not 10 characters
SELECT booking_id, departure_date
FROM safari_connect.bookings_staging
WHERE departure_date LIKE '%-%'
  AND LENGTH(departure_date) <> 10;

-- Remove duplicates
select booking_id, count(*) as count
from safari_connect.bookings_staging bs 
group by bs.booking_id
having count(*) >1
order by booking_id;

SELECT ctid, booking_id
FROM safari_connect.bookings_staging
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    from safari_connect.bookings_staging
    GROUP BY booking_id
)
ORDER BY booking_id, ctid;


-- Remove exact duplicates (keep first ctid)
DELETE FROM safari_connect.bookings_staging 
WHERE ctid NOT IN 
    (SELECT MIN(ctid) FROM safari_connect.bookings_staging GROUP BY booking_id);


delete from safari_connect.bookings_staging 





select * from safari_connect.bookings_staging bs;




