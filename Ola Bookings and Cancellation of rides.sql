CREATE DATABASE OLA;
USE OLA;

SET SQL_SAFE_UPDATES = 0;

CREATE TABLE Ride_Booking_Cancellation (
    Date DATE,
    Time TIME,
    Booking_ID VARCHAR(50),
    Booking_Status VARCHAR(50),
    Customer_ID VARCHAR(50),
    Vehicle_Type VARCHAR(50),
    Pickup_Location VARCHAR(255),
    Drop_Location VARCHAR(255),
    V_TAT Varchar(30), 	-- SHOULD BE INT
    C_TAT Varchar(30),  -- SHOULD BE INT
    Canceled_Rides_by_Customer varchar(200),
    Canceled_Rides_by_Driver varchar(200),
    Incomplete_Rides varchar(10),
    Incomplete_Rides_Reason VARCHAR(255),
    Booking_Value INT,
    Payment_Method VARCHAR(50),
    Ride_Distance DECIMAL(10,2),
    Driver_Ratings VARCHAR(10),  -- SHOULD BE FLOAT, ALSO REMOVED 'S' FROM NAME
    Customer_Rating VARCHAR(10), -- SHOULD BE FLOAT
    Vehicle_Images VARCHAR(255)
);

drop table ride_booking_cancellation;

LOAD DATA INFILE 'C:/Users/prashant/OneDrive/Desktop/Projects/Ola & Uber Ride Booking & Cancellation Data/Booking_s.csv'
INTO TABLE Ride_Booking_Cancellation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

UPDATE RIDE_BOOKING_CANCELLATION 
SET V_TAT = 0
WHERE V_TAT = 'NULL';

UPDATE RIDE_BOOKING_CANCELLATION 
SET C_TAT = 0
WHERE C_TAT = 'NULL';

-- CHANGING COLUMN NATURE FROM VARCHAR TO INT
ALTER TABLE Ride_Booking_Cancellation
MODIFY COLUMN V_TAT INT;

ALTER TABLE Ride_Booking_Cancellation
MODIFY COLUMN C_TAT INT;

UPDATE RIDE_BOOKING_CANCELLATION 
SET Driver_Ratings = 0
WHERE Driver_Ratings = 'NULL';

ALTER TABLE Ride_Booking_Cancellation
MODIFY COLUMN Driver_Ratings Float;

UPDATE RIDE_BOOKING_CANCELLATION 
SET Customer_Rating = 0
WHERE Customer_Rating = 'NULL';

ALTER TABLE Ride_Booking_Cancellation
MODIFY COLUMN Customer_Rating FLOAT;

ALTER TABLE Ride_Booking_Cancellation
CHANGE COLUMN Driver_Ratings Driver_Rating VARCHAR(50);

ALTER TABLE ride_booking_cancellation
ADD COLUMN Ride_status varchar(50);

UPDATE ride_booking_cancellation
SET Ride_Status = 'Cancelled'
where Booking_Status <> 'Success';    

UPDATE ride_booking_cancellation
SET Ride_Status = 'Success'
where Ride_Status is null;


-- DROPPED COLUMN BECAUSE ITS UNNECESSARY
ALTER TABLE Ride_Booking_Cancellation
DROP COLUMN Vehicle_Images;

SELECT * FROM RIDE_BOOKING_CANCELLATION; 

-- Revenue by Vehicle Type (Success Rides Only)
Select 
	vehicle_type, 
	Count(vehicle_type) as vehicle_majority, 
    sum(Booking_value) as Ride_Amount 
    from ride_booking_cancellation
	Where Booking_status = 'Success'
	GROUP BY Vehicle_type
    ORDER BY Vehicle_majority desc;

-- Loss in every vehicle category where ride is not success due to some reasons
Select 
	vehicle_type, 
    count(vehicle_type) as vehicle_majority , 
    sum(Booking_value) as Ride_Amount 
    from ride_booking_cancellation
Where Booking_status <> 'Success'
GROUP BY Vehicle_type
ORDER BY Ride_Amount desc;

-- Main Reasons of Cancelled Ride from customer's side
Select 
	Canceled_Rides_by_Customer, 
	Sum(Booking_Value) as Cancelled_booking_amount  
	from ride_booking_cancellation
	GROUP BY Canceled_Rides_by_Customer
	ORDER BY Cancelled_booking_amount desc;

SELECT DISTINCT Booking_ID FROM RIDE_BOOKING_CANCELLATION
limit 95000;

-- Total number of completed and canceled rides.
SELECT 
    booking_status,
    COUNT(*) AS total_rides,
    ROUND( (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ride_booking_cancellation)), 2 ) AS percentage_of_total_rides
FROM ride_booking_cancellation
GROUP BY booking_status
ORDER BY total_rides DESC;


-- Top 3 most frequently used pickup locations.
SELECT pickup_location, count(*) as total_pickup from ride_booking_cancellation
GROUP BY pickup_location 
ORDER BY total_pickup DESC
limit 3;

-- Average booking value across all rides.
SELECT 
    ROUND(AVG(booking_value), 2) AS Average_booking_value
FROM ride_booking_cancellation;

-- Top 3 most commonly used payment method.
SELECT payment_method, count(payment_method) as mostly_used_payment_method 
from ride_booking_cancellation
Where Booking_status = 'Success'
GROUP BY payment_method
order by mostly_used_payment_method desc
limit 3;

-- Average driver rating vs average customer rating.
Select 
	Round(Avg(Driver_Rating),2) as Driver_Peformance, 
	Round(AVG(Customer_rating),2) AS customer_Behaviour 
	from ride_booking_cancellation;

-- Average rating per vehicle type
Select Vehicle_Type, 
	Round(Avg(Driver_Rating),2) as avg_driver_rating,
	Round(AVG(Customer_rating),2) as avg_customer_rating  
	from ride_booking_cancellation
	GROUP BY Vehicle_Type
    ORDER BY avg_customer_rating desc;
    
-- Find the hour of the day with the highest number of cancellations.
SELECT
		Hour(Time) as Cancel_hour,
        count(*) as total_cancellation
	from ride_booking_cancellation
    where Ride_status = 'Cancelled'
    GROUP BY Hour(Time)
    ORDER BY total_cancellation desc
    LIMIT 1;

-- Identify the vehicle type with the highest average booking value.
SELECT 
	Vehicle_type, 
    Round(Avg(Booking_value),2) as avg_booking_value
    from ride_booking_cancellation
    GROUP BY vehicle_type
    ORDER BY avg_booking_value desc
    limit 1;


-- Which pickup location generates the highest total revenue?
Select 
	Pickup_Location,
    sum(Booking_value) as Total_Revenue
    from ride_booking_cancellation
    GROUP BY Pickup_Location
    ORDER BY Total_Revenue desc
    Limit 1;
    
## -- Compare weekday vs weekend ride counts.
SELECT
    CASE 
        WHEN DAYOFWEEK(Date) IN (1,7) THEN 'Weekend'   -- Sunday=1, Saturday=7
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS total_rides
FROM ride_booking_cancellation
GROUP BY day_type;

-- Identify customers who have canceled more than 2 rides.
SELECT 
	Customer_id,
    Count(*) as Cancel_count
    from ride_booking_cancellation
where Ride_status = 'Cancelled'
GROUP BY Customer_id
Having count(*)>2;

## -- Determine cancellation hotspots by combining pickup location + hour.
SELECT 
    pickup_location,
    HOUR(Time) AS cancel_hour,
    COUNT(*) AS total_cancellations
FROM ride_booking_cancellation
WHERE Ride_status = 'Cancelled'
GROUP BY pickup_location, HOUR(Time)
ORDER BY total_cancellations DESC;

## -- Analyze whether long-distance rides have a higher cancellation rate than short-distance rides.
SELECT 
    CASE
        WHEN ride_distance < 5 THEN 'Short (<5 km)'
        WHEN ride_distance BETWEEN 5 AND 15 THEN 'Medium (5–15 km)'
        ELSE 'Long (>15 km)'
    END AS distance_category,
    
    COUNT(*) AS total_rides,
    
    SUM(CASE WHEN ride_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_rides,
    
    ROUND(
        SUM(CASE WHEN ride_status = 'Cancelled' THEN 1 ELSE 0 END) 
        * 100.0 / COUNT(*), 
        2
    ) AS cancellation_rate_percentage
    
FROM ride_booking_cancellation
GROUP BY distance_category
ORDER BY cancellation_rate_percentage DESC;

## -- Identify the top 5 routes (pickup → drop) that generate the most revenue.
SELECT 
    CONCAT(pickup_location, ' → ', drop_location) AS route,
    SUM(booking_value) AS total_revenue,
    COUNT(*) AS total_rides
FROM ride_booking_cancellation
GROUP BY pickup_location, drop_location
ORDER BY total_revenue DESC
LIMIT 5;

## -- Check if low driver ratings correlate with more cancellations.
SELECT
    CASE
        WHEN driver_rating < 3 THEN 'Low (0–3)'
        WHEN driver_rating BETWEEN 3 AND 4 THEN 'Medium (3–4)'
        ELSE 'High (4–5)'
    END AS rating_category,

    COUNT(*) AS total_rides,

    SUM(CASE WHEN ride_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_rides,

    ROUND(
        SUM(CASE WHEN ride_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate_percentage
FROM ride_booking_cancellation
GROUP BY rating_category
ORDER BY cancellation_rate_percentage DESC;

## -- Identify operational inefficiency: which vehicle type has the worst V_TAT and C_TAT performance?
SELECT
    vehicle_type,
    ROUND(AVG(V_TAT), 2) AS avg_v_tat,
    ROUND(AVG(C_TAT), 2) AS avg_c_tat
FROM ride_booking_cancellation
GROUP BY vehicle_type
ORDER BY avg_v_tat DESC, avg_c_tat DESC;

SELECT * from ride_booking_cancellation;





