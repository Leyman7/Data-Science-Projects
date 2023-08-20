-- IT jobs market analysis --

--Creating directory path
CREATE DIRECTORY csv_directory AS 'C:\Users\lukas\OneDrive\Pulpit\Football model prediciton\The Bookies\SQL project';

--Giving necessery priviliges to created user in CMD 
ALTER USER C##leyman QUOTA UNLIMITED ON USERS;

--Creating table with text column format for all variables
DROP TABLE  C##leyman.IT_market;
CREATE TABLE C##leyman.IT_market
(
  Title VARCHAR2(4000),
  City VARCHAR2(4000),
  Country_code VARCHAR2(4000),
  Marker_icon VARCHAR2(4000),
  Workplace_type VARCHAR2(4000),
  Experience_level VARCHAR2(4000),
  Published_at VARCHAR2(4000),
  Remote_interview VARCHAR2(4000),
  Remote VARCHAR2(4000),
  Open_to_hire_Ukrainians VARCHAR2(4000),
  Company_size_from VARCHAR2(4000),
  Company_size_to VARCHAR2(4000),
  if_permanent VARCHAR2(4000),
  salary_from_permanent VARCHAR2(4000),
  salary_to_permanent VARCHAR2(4000),
  salary_currency_permanent VARCHAR2(4000),
  if_b2b VARCHAR2(4000),
  salary_from_b2b VARCHAR2(4000),
  salary_to_b2b VARCHAR2(4000),
  salary_currency_b2b VARCHAR2(4000),
  if_mandate VARCHAR2(4000),
  salary_from_mandate VARCHAR2(4000),
  salary_to_mandate VARCHAR2(4000),
  salary_currency_mandate VARCHAR2(4000),
  if_other VARCHAR2(4000),
  salary_from_other VARCHAR2(4000),
  salary_to_other VARCHAR2(4000),
  salary_currency_other VARCHAR2(4000),
  currency_exchange_rate VARCHAR2(4000),
  skills_name_0 VARCHAR2(4000),
  skills_value_0 VARCHAR2(4000),
  skills_name_1 VARCHAR2(4000),
  skills_value_1 VARCHAR2(4000),
  skills_name_2 VARCHAR2(4000),
  skills_value_2 VARCHAR2(4000)
);

--Checking if working correctly 
SELECT COUNT(*) FROM C##leyman.IT_MARKET;

--Verifying data types
DESC C##leyman.it_market;

-- Data cleansing

-- Dropping columns that won't be used in analysis
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN if_mandate;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN salary_from_mandate;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN salary_to_mandate;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN if_b2b;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN salary_from_b2b;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN salary_to_b2b;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN salary_currency_b2b;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN if_other;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN salary_from_other;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN salary_to_other;
ALTER TABLE C##leyman.IT_MARKET DROP COLUMN salary_currency_other;]

--I'm only interested in jobs from Poland. Creating the new table. Further work only with the new table.
DROP TABLE  C##leyman.it_market_poland;
CREATE TABLE C##leyman.it_market_poland AS
SELECT *
FROM C##leyman.it_market
WHERE country_code = 'PL';

--Selecting duplicated rows based on title and publishing date. Duplicates found 2137
SELECT COUNT(*)
FROM C##leyman.it_market_poland t1
WHERE EXISTS (SELECT 1
              FROM C##leyman.it_market_poland t2
              WHERE t1.Title = t2.Title AND t1.Published_at = t2.Published_at
                AND t1.rowid <> t2.rowid);

-- 1,160 rows deleted.                
DELETE FROM C##leyman.it_market_poland
WHERE ROWID NOT IN (
    SELECT MIN(ROWID) AS keep_rowid
    FROM C##leyman.it_market_poland
    GROUP BY Title, Published_at
);

-- checking if deleted correctly - returned zero. 
SELECT COUNT(*)
FROM C##leyman.it_market_poland t1
WHERE EXISTS (SELECT 1
              FROM C##leyman.it_market_poland t2
              WHERE t1.Title = t2.Title AND t1.Published_at = t2.Published_at
                AND t1.rowid <> t2.rowid);

--checking how many job offers without salary. Returned - 23027 - for both columns. I left rows for further analysis - non salary related. 
SELECT COUNT(*)
FROM C##leyman.it_market_poland
WHERE salary_from_permanent = 0;

SELECT COUNT(*)
FROM C##leyman.it_market_poland
WHERE salary_to_permanent = 0;

-- Checking average salary (only where it was specified) - 15073.21
SELECT ROUND(AVG((salary_from_permanent + salary_to_permanent) / 2), 2) 
FROM C##leyman.it_market_poland
WHERE salary_from_permanent != 0 AND salary_to_permanent != 0;

-- There was salary offers in different currencies like EUR or USD, I decieded to use only PLN based offers to return correct average salary value. 
UPDATE C##leyman.it_market_poland
SET salary_from_permanent = salary_from_permanent / currency_exchange_rate,
    salary_to_permanent = salary_to_permanent / currency_exchange_rate
WHERE currency_exchange_rate != 0;
--1,160 rows deleted.
--1,250 rows updated.

-- Updated average salary 18005.65
SELECT ROUND(AVG((salary_from_permanent + salary_to_permanent) / 2), 2) 
FROM C##leyman.it_market_poland
WHERE salary_from_permanent != 0 AND salary_to_permanent != 0;

-- Removing local currency job offers. 

-- Remove the currency_exchange_rate column
ALTER TABLE C##leyman.it_market_poland
DROP COLUMN currency_exchange_rate;

-- Remove the salary_currency_permanent column
ALTER TABLE C##leyman.it_market_poland
DROP COLUMN salary_currency_permanent;

-- Remove the salary_currency_mandate column
ALTER TABLE C##leyman.it_market_poland
DROP COLUMN salary_currency_mandate;

--Checking results
SELECT * FROM C##leyman.it_market_poland

-- Add the avg_salary column with the desired data type
ALTER TABLE C##leyman.it_market_poland
ADD avg_salary NUMERIC;

-- Update the avg_salary values based on the condition
UPDATE C##leyman.it_market_poland
SET avg_salary = CASE
                    WHEN salary_from_permanent = 0 THEN 0
                    ELSE (salary_from_permanent + salary_to_permanent) / 2
                 END;
                 
--Table C##LEYMAN.IT_MARKET_POLAND altered.
--35,098 rows updated.

--checking if works 
SELECT *
FROM C##leyman.it_market_poland

-- Action was done correctly so I remove not needed columns.

-- Drop the salary_from_permanent column
ALTER TABLE C##leyman.it_market_poland
DROP COLUMN salary_from_permanent;

-- Drop the salary_to_permanent column
ALTER TABLE C##leyman.it_market_poland
DROP COLUMN salary_to_permanent;

-- Checking the results again. Seems fine. 
SELECT *
FROM C##leyman.it_market_poland

--It seems there are some values that reflects salary for whole year. I assumed 80k+ as whole year value and such values will be divided for 12.
SELECT COUNT(*)
FROM C##leyman.it_market_poland
WHERE avg_salary > 80000;
-- 277 rows returned 

UPDATE C##leyman.it_market_poland
SET avg_salary = CASE
                    WHEN avg_salary > 80000 THEN avg_salary / 12
                    ELSE avg_salary
                 END;
--35,098 rows updated.  There are still 3 rows left due to some issue, but it won't be able to impact 35098 records totally.  


-- Statistics based on dataset 

--
SELECT Marker_icon, COUNT(*) AS num_jobs
FROM C##leyman.it_market_poland
GROUP BY Marker_icon
ORDER BY num_jobs DESC;

--Results returned. The most popular job is JavaScript-related, while the least popular is Scala. 
--javascript	4745
--java	3383
--testing	2679
--net	2263
--devops	2001
--support	1980
--data	1916
--admin	1881
--pm	1757
--php	1616
--python	1600
--mobile	1395
--analytics	1232
--architecture	1211
--other	1203
--c	1096
--ux	712
--security	563
--erp	555
--ruby	390
--html	310
--go	260
--game	217
--scala	133

-- Create table related to data and analytics jobs offers only
CREATE TABLE it_market_poland_data AS
SELECT *
FROM C##leyman.it_market_poland
WHERE marker_icon IN ('data', 'analytics');

--checking if correctly applied 
SELECT * FROM it_market_poland_data

-- Display stats for job market in Poland related to 'data' and 'analytics'

-- Count of jobs in each city
SELECT City, COUNT(*) AS job_count
FROM C##leyman.it_market_poland
WHERE Marker_icon IN ('data', 'analytics')
GROUP BY City
ORDER BY job_count DESC;

-- Top10 cities 
--Warszawa	1609
--Krak??w	382
--Wroc?‚aw	377
--Gda?„sk	194
--Pozna?„	180
--Katowice	84
--????d??	53
--Szczecin	28
--Warsaw	23
--Gdynia	23

-- Count of jobs by experience level
SELECT Experience_level, COUNT(*) AS job_count
FROM C##leyman.it_market_poland
WHERE Marker_icon IN ('data', 'analytics')
GROUP BY Experience_level
ORDER BY job_count DESC;
--Experience level results:
-- mid	1805
-- senior	968
-- junior	375

-- Count of jobs by workplace type
SELECT Workplace_type, COUNT(*) AS job_count
FROM C##leyman.it_market_poland
WHERE Marker_icon IN ('data', 'analytics')
GROUP BY Workplace_type
ORDER BY job_count DESC;
-- Job working type results 
--remote	1779
--partly_remote	1251
--office	118

-- Show the most valuable skills from skill_name_0 column
SELECT skills_name_0, AVG(avg_salary) AS avg_salary_temp
FROM C##leyman.it_market_poland
GROUP BY skills_name_0
ORDER BY avg_salary_temp DESC;

--Top results

--Analysis	70034
--Robohelp	42522
--SAP AM	39000
--OO patterns	37750
--Architect or Developer experience	35750
--cyber security	35000
--Cloud Platforms	34000
--Golang/Rust	33750
--Source System Analysis	32500
--Log Monitoring	32000
--Azzure DevOps	32000
--C#/.NET project build/release experience	31500
--Lucerne	30500
--churn prediction	30500
--SAFE Agile Certification	30000
--Migrations	30000
--Adobe AEM/Sitecore XP	30000
--Leading engineering team	30000
--MES integration	30000
--Cloud Architectures	30000
--Banking domain expertise	29500
--CPE architecture	29000
--End-to-end Architecture	29000
--Contenerization	28500
--Oracle Applications R12	28500

-- Show the most valuable skills for all 3 skills columns. Also display the frequency of those skills in the dataset.
WITH skills_cte AS (
    SELECT avg_salary, skills_name_0 AS Skill FROM C##leyman.it_market_poland
    UNION ALL
    SELECT avg_salary, skills_name_1 AS Skill FROM C##leyman.it_market_poland
    UNION ALL
    SELECT avg_salary, skills_name_2 AS Skill FROM C##leyman.it_market_poland
)
SELECT Skill, AVG(avg_salary) AS avg_salary_temp, COUNT(*) AS skill_count
FROM skills_cte
GROUP BY Skill
ORDER BY avg_salary_temp DESC;

--Top results 

--RabbitMq (potentially will be migrated to Azure ServiceBus)	57780
--Tech Stack: Azure as a cloud provider	57780
--Robohelp	42522
--C++ OO design development	41500
--Leading a Software Engineering team	41500
--SAP AM	39000
--SAP JVA	39000
--Network programing	38500
--OO patterns	37750
--Architect or Developer experience	35750
--PyData	35166.6666666666666666666666666666666667
--Software	35017
--cyber security	35000
--Golang/Rust	33750
--Golang / Rust	33750
--Windows Systems	33750
--Cloud Experience	33000
--Automation Platform	32500
--virtualised server operating systems	32500
--Data Profiling	32500
--Source System Analysis	32500

--Average salary by job title:
SELECT Title, AVG(avg_salary) AS avg_salary_temp
FROM C##leyman.it_market_poland
GROUP BY Title
ORDER BY avg_salary_temp DESC;

--Top20 results 

--Mid/Senior Sitecore Developers	155839
--Development Manager	104294.5
--Manual Testing Engineerâ€“QualityAssurance	78377
--Junior Technical Product Owner	77637
--Data Migration Specialist 	75568
--C++ Group Interview	75000
--Middle Business Analyst	74514
--Senior Project  Manager	74301
--Technical Writer (part-time as optional)	73044
--Quality Engineer 	72869
--Middle Full Stack Developer	72291
--Live Casino Studio Project Manager	71790
--Middle .NET Full-Stack Engineer	71727
--Middle AQA Engineer (.NET)	71727
--Middle QA Automation Engineer (Python)	70802
--Mid Database Administrator	70170
--Senior Full Stack Developer -Growth Team	70170
--Unity Mobile Games Developer (F/M)	70170
--Junior Requirements Engineer	70034
--Magento 2 Front-end developer	68428

--Top 10 most popular job titles:
SELECT Title, COUNT(*) AS job_count
FROM C##leyman.it_market_poland
GROUP BY Title
ORDER BY job_count DESC
FETCH FIRST 10 ROWS ONLY;
--Results:
--Java Developer	510
--DevOps Engineer	423
--Frontend Developer	324
--PHP Developer	253
--.NET Developer	237
--Senior Java Developer	230
--Python Developer	203
--Scrum Master	195
--QA Engineer	176
--Android Developer	172

--Average salary by experience level:
SELECT Experience_level, ROUND(AVG(avg_salary), 2) AS avg_salary_temp
FROM C##leyman.it_market_poland
GROUP BY Experience_level
ORDER BY avg_salary_temp DESC;
--Results:

--senior	7119.68
--mid	4662.59
--junior	2498.7

--Average salary by workplace type:
SELECT Workplace_type, ROUND(AVG(avg_salary), 2) AS avg_salary_temp
FROM C##leyman.it_market_poland
GROUP BY Workplace_type
ORDER BY avg_salary_temp DESC;
--Results:

--remote	5539.22
--partly_remote	4679.09
--office	2896.91

--Count of remote and non-remote job listings:
SELECT CASE
           WHEN Remote = 'Yes' THEN 'Remote'
           ELSE 'Non-Remote'
       END AS Work_Type,
       COUNT(*) AS job_count
FROM C##leyman.it_market_poland
GROUP BY Remote
ORDER BY job_count DESC;
--Results:

--Non-Remote	22327
--Non-Remote	12771

SELECT City, AVG(avg_salary) AS avg_salary_temp
FROM C##leyman.it_market_poland
GROUP BY City
ORDER BY avg_salary_temp DESC;
--Best two results:

--Krak??w 	20750
--warsaw	19000

-- Looking for problematic rows due to error.
SELECT *
FROM C##leyman.it_market_poland
WHERE NOT REGEXP_LIKE(Company_size_from, '^[0-9]+$')
   OR NOT REGEXP_LIKE(Company_size_to, '^[0-9]+$');
   
SELECT *
FROM C##leyman.it_market_poland
WHERE Company_size_from IS NULL OR TRIM(Company_size_from) = ''
   OR Company_size_to IS NULL OR TRIM(Company_size_to) = '';
   
-- Finding 277 problematic rows, and will exclude it from statistic
SELECT Company_size_range, COUNT(*) AS job_count
FROM (
  SELECT
    CASE
      WHEN REGEXP_LIKE(Company_size_from, '^[0-9]+$') AND REGEXP_LIKE(Company_size_to, '^[0-9]+$')
        THEN Company_size_from || '-' || Company_size_to
    END AS Company_size_range
  FROM C##leyman.it_market_poland
  WHERE NOT REGEXP_LIKE(Company_size_from, '^[0-9]+$')
     OR NOT REGEXP_LIKE(Company_size_to, '^[0-9]+$')
) filtered_data
GROUP BY Company_size_range
ORDER BY job_count DESC;

WITH filtered_data AS (
  SELECT
    CASE
      WHEN REGEXP_LIKE(Company_size_from, '^[0-9]+$') AND REGEXP_LIKE(Company_size_to, '^[0-9]+$')
        THEN Company_size_from || '-' || Company_size_to
    END AS Company_size_range
  FROM C##leyman.it_market_poland
  WHERE NOT REGEXP_LIKE(Company_size_from, '^[0-9]+$')
     OR NOT REGEXP_LIKE(Company_size_to, '^[0-9]+$')
)
SELECT Company_size_range, COUNT(*) AS job_count
FROM filtered_data
GROUP BY Company_size_range
ORDER BY job_count DESC;

-- Job offers grouped by company size
SELECT
  CASE
    WHEN Company_size_from <= 30 THEN '0-30'
    WHEN Company_size_from <= 50 THEN '31-50'
    WHEN Company_size_from <= 100 THEN '51-100'
    WHEN Company_size_from <= 200 THEN '101-200'
    WHEN Company_size_from <= 300 THEN '201-300'
    WHEN Company_size_from <= 500 THEN '301-500'
    ELSE '501-1000'
  END AS Company_size_range,
  COUNT(*) AS job_count
FROM C##leyman.it_market_poland
WHERE REGEXP_LIKE(Company_size_from, '^[0-9]+$')
  AND REGEXP_LIKE(Company_size_to, '^[0-9]+$')
GROUP BY
  CASE
    WHEN Company_size_from <= 30 THEN '0-30'
    WHEN Company_size_from <= 50 THEN '31-50'
    WHEN Company_size_from <= 100 THEN '51-100'
    WHEN Company_size_from <= 200 THEN '101-200'
    WHEN Company_size_from <= 300 THEN '201-300'
    WHEN Company_size_from <= 500 THEN '301-500'
    ELSE '501-1000'
  END
ORDER BY
  MIN(Company_size_from); -- Order by the lower bound of the range
-- Results:

--0-30	5601
--51-100	5246
--501-1000	10605
--101-200	4128
--201-300	2675
--301-500	2938
--31-50	3569















































