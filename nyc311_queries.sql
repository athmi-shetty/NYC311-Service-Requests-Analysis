
-- 1.CREATE DATABASE AND TABLE
CREATE DATABASE nyc_311;

USE nyc_311;

CREATE TABLE `service_request` (
`Unique Key` INT,
`Created Date` VARCHAR(50),
`Closed Date` VARCHAR(50),
`Agency` VARCHAR(100),
`Agency Name` VARCHAR(255),
`Complaint Type` VARCHAR(255),
`Descriptor` VARCHAR(255),
`Location Type` VARCHAR(255),
`Incident Zip` VARCHAR(20),
`Incident Address` VARCHAR(255),
`Street Name` VARCHAR(255),
`City`  VARCHAR(100),
`Status`  VARCHAR(50),
`Borough` VARCHAR(100),
`Latitude` DECIMAL(10,7) NULL,
`Longitude` DECIMAL(10,7) NULL
);

SHOW TABLES;


-- 2.LOAD DATA USING LOAD DATA INFILE
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/311_Service_Requests_from_2010_to_Present.csv'
INTO TABLE `service_request`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    `Unique Key`,
    `Created Date`,
    `Closed Date`,
    `Agency`,
    `Agency Name`,
    `Complaint Type`,
    `Descriptor`,
    `Location Type`,
    `Incident Zip`,
    `Incident Address`,
    `Street Name`,
    `City`,
    `Status`,
    `Borough`,
    @lat,
    @lon
)
SET
    `Latitude` = NULLIF(@lat, ''),
    `Longitude` = NULLIF(@lon, '');
    

-- CHECK TOTAL ROWS
SELECT COUNT(*) FROM service_request;



-- PREVIEW FIRST 10 ROWS
SELECT * FROM service_request LIMIT 10;



-- CHECK COLUMN EXISTS
DESCRIBE service_request;



-- 3.DATA CLEANING

-- CHECK MISSING AND NULL VALUES
SELECT
SUM(CASE WHEN `Unique Key` IS NULL THEN 1 ELSE 0 END) AS missing_unique_key,
SUM(CASE WHEN `Created Date` IS NULL THEN 1 ELSE 0 END) AS missing_created_date,
SUM(CASE WHEN `Closed Date` IS NULL THEN 1 ELSE 0 END) AS missing_closed_date,
SUM(CASE WHEN `Agency` IS NULL THEN 1 ELSE 0 END) AS missing_agency,
SUM(CASE WHEN `Agency name` IS NULL THEN 1 ELSE 0 END) AS missing_agency_name,
SUM(CASE WHEN `Complaint Type` IS NULL THEN 1 ELSE 0 END) AS missing_complaint_type,
SUM(CASE WHEN `Descriptor` IS NULL THEN 1 ELSE 0 END )AS missing_descriptor,
SUM(CASE WHEN `Location Type` IS NULL THEN 1 ELSE 0 END )AS missing_location_type,
SUM(CASE WHEN `Incident Zip` IS NULL THEN 1 ELSE 0 END )AS missing_incident_zip,
SUM(CASE WHEN `Incident Address` IS NULL THEN 1 ELSE 0 END )AS missing_incident_address,
SUM(CASE WHEN `Street Name` IS NULL THEN 1 ELSE 0 END) AS missing_street_name,
SUM(CASE WHEN `city` IS NULL THEN 1 ELSE 0 END )AS missing_city,
SUM(CASE WHEN `status` IS NULL THEN 1 ELSE 0 END) AS missing_status,
SUM(CASE WHEN `borough` IS NULL THEN 1 ELSE 0 END) AS missing_borough,
SUM(CASE WHEN `Latitude` IS NULL THEN 1 ELSE 0 END) AS missing_latitude,
SUM(CASE WHEN `Longitude` IS NULL THEN 1 ELSE 0 END) AS missing_longitude
FROM service_request;

-- CHECK  BOROUGH
SELECT DISTINCT `Borough`, COUNT(*) AS Total
FROM `service_request`
GROUP BY `Borough`
ORDER BY Total DESC;

-- FIX BOROUGH - UNSPECIFIED TO NULL
SET SQL_SAFE_UPDATES = 0;
UPDATE `service_request`
SET `Borough` = NULL
WHERE `Borough` = 'Unspecified';
SET SQL_SAFE_UPDATES = 1;



-- CHECK STATUS
SELECT DISTINCT `Status` ,COUNT(*) AS Total
FROM `service_request`
GROUP BY  `Status`
ORDER BY Total DESC;

-- FIX STATUS - DRAFT TO NULL
SET SQL_SAFE_UPDATES=0;
UPDATE `service_request`
SET `Status`=NULL
WHERE `Status`='Draft';
SET SQL_SAFE_UPDATES=1;



-- CHECK COMPLAINT TYPE
SELECT DISTINCT `Complaint Type`, COUNT(*) as total
FROM `service_request`
GROUP BY `Complaint Type`
ORDER BY total DESC;



-- CHECK AGENCY
SELECT DISTINCT `Agency`, COUNT(*) as total
FROM `service_request`
GROUP BY `Agency`
ORDER BY total DESC;


-- CHECK LOCATION TYPE
SELECT DISTINCT `Location Type`, COUNT(*) as total
FROM `service_request`
GROUP BY `Location Type`
ORDER BY total DESC;


-- FIX LOCATION TYPE - EMPTY STRING TO NULL
SET SQL_SAFE_UPDATES=0;
UPDATE `service_request`
SET `Location Type`=NULL
WHERE `Location Type`='';
SET SQL_SAFE_UPDATES=1;



-- CHECK CITY
SELECT DISTINCT `City`, COUNT(*) as total
FROM `service_request`
GROUP BY `City`
ORDER BY total DESC;

-- FIX CITY - EMPTY STRING TO NULL
SET SQL_SAFE_UPDATES=0;
UPDATE `service_request`
SET `City`=NULL
WHERE city='';
SET SQL_SAFE_UPDATES=1;



-- CHECK DESCRIPTOR
SELECT DISTINCT `Descriptor`, COUNT(*) as total
FROM `service_request`
GROUP BY `Descriptor`
ORDER BY total DESC;



-- 4.DATE CONVERSION

ALTER TABLE `service_request`
ADD COLUMN `Created_dt` DATETIME NULL,
ADD COLUMN `Closed_dt` DATETIME NULL;

-- Converting VARCHAR to DATETIME
SET SQL_SAFE_UPDATES=0;
-- Step 1: Converting slash format rows
UPDATE `service_request`
SET `created_dt` = STR_TO_DATE(`Created Date`, '%m/%d/%Y %h:%i:%s %p')
WHERE `Created Date` LIKE '%/%';

-- Step 2: Converting dash format rows
UPDATE `service_request`
SET `created_dt` = STR_TO_DATE(`Created Date`, '%m-%d-%Y %H:%i')
WHERE `Created Date` NOT LIKE '%/%';
SET SQL_SAFE_UPDATES=1;

-- Step 1: Convert slash format rows in Closed Date
SET SQL_SAFE_UPDATES=0;
UPDATE `service_request`
SET `closed_dt` = STR_TO_DATE(`Closed Date`, '%m/%d/%Y %h:%i:%s %p')
WHERE `Closed Date` LIKE '%/%';

-- Step 2: Convert dash format rows in Closed Date
UPDATE `service_request`
SET `closed_dt` = STR_TO_DATE(`Closed Date`, '%m-%d-%Y %H:%i')
WHERE `Closed Date` NOT LIKE '%/%'
AND `Closed Date` !=''
AND `Closed Date` IS NOT NULL;
SET SQL_SAFE_UPDATES=1;


-- CHECK CONVERTED DATES
SELECT 
    `Created Date`,
    `created_dt`,
    `Closed Date`,
    `closed_dt`
FROM `service_request`
LIMIT 10;





-- 5.ANALYSIS QUERIES
-- BOROUGH COMPLAINT COUNT
SELECT Borough,COUNT(`Complaint Type`) AS Total_Complaint
FROM service_request
GROUP BY Borough
ORDER BY Total_Complaint DESC;

-- TOP 5 COMPLAINT TYPES
SELECT `Complaint Type`,COUNT(*) AS common_complaint 
FROM service_request
GROUP BY `Complaint Type` 
ORDER BY common_complaint desc
LIMIT 5;

-- AVG RESOLUTION TIME PER BOROUGH
SELECT `Borough`, AVG(TIMESTAMPDIFF(HOUR,created_dt ,closed_dt)) AS avg_hours
FROM service_request
WHERE Agency="NYPD"
GROUP BY `Borough`
ORDER BY avg_hours ASC;
  
 
 -- COMPLAINTS BY DAY OF WEEK
SELECT DAYNAME(created_dt) AS days,
count(`Complaint Type`)AS Total_complaint
FROM service_request
GROUP BY days
ORDER BY Total_complaint DESC;


-- MONTHLY COMPLAINT TREND
SELECT DATE_FORMAT(created_dt, '%Y-%m') AS months,
COUNT(`Complaint Type`) AS Total_complaint
FROM service_request
GROUP BY months
ORDER BY months ASC ;


-- TOP COMPLAINT PER BOROUGH (Window Function) 
SELECT `Borough`, `Complaint Type`, Total_Complaint
FROM
(
SELECT Borough,`Complaint Type`,
COUNT(`Complaint Type`) AS Total_Complaint,
RANK() OVER (PARTITION BY `Borough` ORDER BY COUNT(`Complaint Type`) DESC) AS rnk
FROM service_request
WHERE Borough IS NOT NULL
GROUP BY Borough,`Complaint Type`
)AS ranked
WHERE rnk=1;


-- BOROUGH ABOVE AVERAGE COMPLAINTS(CTES)
WITH borough_total AS(
SELECT `Borough`,COUNT(`Complaint Type`) AS Total_complaint
FROM service_request
WHERE `Borough` IS NOT NULL
GROUP BY Borough
),
city_average AS(
SELECT AVG(Total_complaint) AS avg_complaint
FROM borough_total
)

SELECT `Borough`,Total_complaint,ROUND(avg_complaint,0)AS avg_complaint
FROM borough_total,city_average
WHERE Total_complaint>avg_complaint
ORDER BY Total_complaint DESC;

-- BOROUGHS SLOWER THAN AVERAGE RESOLUTIONS (CTE)
WITH avg_resolution AS(
SELECT `Borough`, AVG(TIMESTAMPDIFF(HOUR,created_dt ,closed_dt)) AS avg_resolution
FROM service_request
WHERE `Borough` IS NOT NULL
    AND `closed_dt` IS NOT NULL
GROUP BY `Borough`

),
agnecy_avg AS(
SELECT  AVG(avg_resolution) AS avg_hours
 FROM avg_resolution 
 )
 SELECT `Borough`,avg_resolution,ROUND(avg_hours,0) AS avg_hours
 FROM avg_resolution,agnecy_avg
 WHERE avg_resolution>avg_hours;
 
 USE nyc_311;

SELECT 
    `Borough`,
    `Complaint Type`,
    `Status`,
    `City`,
    `Descriptor`,
    `Latitude`,
    `Longitude`,
    `created_dt`,
    `closed_dt`,
    TIMESTAMPDIFF(HOUR, `created_dt`, `closed_dt`) AS resolution_hours,
    DAYNAME(`created_dt`) AS day_of_week,
    DATE_FORMAT(`created_dt`, '%Y-%m') AS month_year
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/nyc311_export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
FROM service_request
WHERE `created_dt` IS NOT NULL;
 

