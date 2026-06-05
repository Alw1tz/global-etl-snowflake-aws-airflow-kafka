select current_user();

alter user ALW1TZ set default_role = 'SYSADMIN';
alter user ALW1TZ set default_warehouse = 'COMPUTE_WH';
alter user ALW1TZ set default_namespace = 'UTIL_DB.PUBLIC';

use role accountadmin;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from
(SELECT 
 'DORA_IS_WORKING' as step
 ,(select 123 ) as actual
 ,123 as expected
 ,'Dora is working!' as description
); 

--
CREATE DATABASE AGS_GAME_AUDIENCE;
DROP SCHEMA PUBLIC;
CREATE SCHEMA RAW;

CREATE TABLE GAME_LOGS (
    RAW_LOG VARIANT
);

list @uni_kishore/kickoff;

CREATE OR REPLACE FILE FORMAT AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS
  TYPE = JSON
  strip_outer_array = true;

SELECT * FROM @uni_kishore/kickoff
(FILE_FORMAT => AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

COPY INTO AGS_GAME_AUDIENCE.RAW.GAME_LOGS
FROM @uni_kishore/kickoff
FILE_FORMAT = (FORMAT_NAME=AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

SELECT 
$1:agent::varchar agent,
$1:user_event::varchar user_event,
$1:datetime_iso8601::timestamp datetime_iso8601,
$1:user_login::varchar user_login,
$1 raw_log
FROM @uni_kishore/kickoff
(FILE_FORMAT => AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

CREATE VIEW AGS_GAME_AUDIENCE.RAW.LOGS AS 
SELECT 
$1:agent::varchar agent,
$1:user_event::varchar user_event,
$1:datetime_iso8601::timestamp datetime_iso8601,
$1:user_login::varchar user_login,
$1 raw_log
FROM @uni_kishore/kickoff
(FILE_FORMAT => AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

SELECT * FROM AGS_GAME_AUDIENCE.RAW.LOGS;

--
-- DO NOT EDIT THIS CODE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from
(
 SELECT
 'DNGW01' as step
  ,(
      select count(*)  
      from ags_game_audience.raw.logs
      where is_timestamp_ntz(to_variant(datetime_iso8601))= TRUE 
   ) as actual
, 250 as expected
, 'Project DB and Log File Set Up Correctly' as description
); 

SELECT CURRENT_TIMESTAMP();

----
--what time zone is your account(and/or session) currently set to? Is it -0700?
select current_timestamp();

--worksheets are sometimes called sessions -- we'll be changing the worksheet time zone
alter session set timezone = 'UTC';
select current_timestamp();

--how did the time differ after changing the time zone for the worksheet?
alter session set timezone = 'America/Mexico_City';
select current_timestamp();

alter session set timezone = 'Pacific/Funafuti';
select current_timestamp();

alter session set timezone = 'Pacific/Funafuti';
select current_timestamp();

alter session set timezone = 'Asia/Shanghai';
select current_timestamp();

--show the account parameter called timezone
show parameters like 'timezone';

SELECT 
raw_log, 
raw_log:agent::text,
raw_log:ip_address::text
FROM AGS_GAME_AUDIENCE.RAW.GAME_LOGS;

select $1 from @uni_kishore/updated_feed
(FILE_FORMAT => AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

COPY INTO AGS_GAME_AUDIENCE.RAW.GAME_LOGS
FROM @uni_kishore/updated_feed
FILE_FORMAT = (FORMAT_NAME=AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

SELECT * FROM AGS_GAME_AUDIENCE.RAW.GAME_LOGS;

SELECT * FROM LOGS;

--
SELECT 
    raw_log:ip_address::varchar as ip_address,
    raw_log:user_event::varchar as user_event,
    raw_log:user_login::varchar as user_login,
    raw_log
FROM AGS_GAME_AUDIENCE.RAW.GAME_LOGS
WHERE raw_log:ip_address IS NOT NULL;

SELECT 
    raw_log:agent::varchar as agent,
    raw_log:user_event::varchar as user_event,
    raw_log
FROM AGS_GAME_AUDIENCE.RAW.GAME_LOGS
WHERE raw_log:agent IS NOT NULL;

--
CREATE OR REPLACE VIEW AGS_GAME_AUDIENCE.RAW.LOGS AS 
SELECT 
    --raw_log:agent::varchar as agent,
    raw_log:ip_address::varchar as ip_address, -- New field added!
    raw_log:user_event::varchar as user_event,
    raw_log:datetime_iso8601::timestamp as datetime_iso8601,
    raw_log:user_login::varchar as user_login,
    raw_log
FROM AGS_GAME_AUDIENCE.RAW.GAME_LOGS
WHERE raw_log:ip_address::varchar IS NOT NULL;

--looking for empty AGENT column
select * 
from ags_game_audience.raw.LOGS
where agent is null;

--looking for non-empty IP_ADDRESS column
select 
RAW_LOG:ip_address::text as IP_ADDRESS
,*
from ags_game_audience.raw.LOGS
where RAW_LOG:ip_address::text is not null;

SELECT * FROM LOGS;

SELECT 
    RAW_LOG:user_login::varchar as user_login,
    RAW_LOG:datetime_iso8601::timestamp as login_time,
    RAW_LOG
FROM AGS_GAME_AUDIENCE.RAW.GAME_LOGS
WHERE RAW_LOG:datetime_iso8601::timestamp >= '2022-10-16 01:00:00'
  AND RAW_LOG:datetime_iso8601::timestamp <= '2022-10-16 02:00:00';

SELECT * FROM GAME_LOGS
WHERE RAW_LOG ILIKE '%kishore%';

select GRADER(step, (actual = expected), actual, expected, description) as graded_results from
(
SELECT
   'DNGW02' as step
   ,( select sum(tally) from(
        select (count(*) * -1) as tally
        from ags_game_audience.raw.logs 
        union all
        select count(*) as tally
        from ags_game_audience.raw.game_logs)     
     ) as actual
   ,250 as expected
   ,'View is filtered' as description
); 

--
SELECT 
parse_ip(ip_address,'inet') enhanced_ip,
parse_ip(ip_address,'inet'):ipv4 ipv4,
ip_address, 
*
FROM AGS_GAME_AUDIENCE.RAW.LOGS
where ipv4 = 1680412832;

--

create schema ags_game_audience.ENHANCED;

--Look up Kishore and Prajina's Time Zone in the IPInfo share using his headset's IP Address with the PARSE_IP function.
select start_ip, end_ip, start_ip_int, end_ip_int, city, region, country, timezone
from IPINFO_GEOLOC.demo.location
where parse_ip('100.41.16.160', 'inet'):ipv4 --Kishore's Headset's IP Address
BETWEEN start_ip_int AND end_ip_int;

--Join the log and location tables to add time zone to each row using the PARSE_IP function.
select logs.*
       , loc.city
       , loc.region
       , loc.country
       , loc.timezone
from AGS_GAME_AUDIENCE.RAW.LOGS logs
join IPINFO_GEOLOC.demo.location loc
where parse_ip(logs.ip_address, 'inet'):ipv4 
BETWEEN start_ip_int AND end_ip_int;

--Use two functions supplied by IPShare to help with an efficient IP Lookup Process!
SELECT logs.ip_address
, logs.user_login
, logs.user_event
, logs.datetime_iso8601
, city
, region
, country
, timezone 
, convert_timezone('UTC', timezone, datetime_iso8601) GAME_EVENT_LTZ
, dayname(GAME_EVENT_LTZ)
from AGS_GAME_AUDIENCE.RAW.LOGS logs
JOIN IPINFO_GEOLOC.demo.location loc 
ON IPINFO_GEOLOC.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
AND IPINFO_GEOLOC.public.TO_INT(logs.ip_address) 
BETWEEN start_ip_int AND end_ip_int;

-- Your role should be SYSADMIN
-- Your database menu should be set to AGS_GAME_AUDIENCE
-- The schema should be set to RAW

--a Look Up table to convert from hour number to "time of day name"
create table ags_game_audience.raw.time_of_day_lu
(  hour number
   ,tod_name varchar(25)
);

--insert statement to add all 24 rows to the table
insert into ags_game_audience.raw.time_of_day_lu
values
(6,'Early morning'),
(7,'Early morning'),
(8,'Early morning'),
(9,'Mid-morning'),
(10,'Mid-morning'),
(11,'Late morning'),
(12,'Late morning'),
(13,'Early afternoon'),
(14,'Early afternoon'),
(15,'Mid-afternoon'),
(16,'Mid-afternoon'),
(17,'Late afternoon'),
(18,'Late afternoon'),
(19,'Early evening'),
(20,'Early evening'),
(21,'Late evening'),
(22,'Late evening'),
(23,'Late evening'),
(0,'Late at night'),
(1,'Late at night'),
(2,'Late at night'),
(3,'Toward morning'),
(4,'Toward morning'),
(5,'Toward morning');

--Check your table to see if you loaded it properly
select tod_name, listagg(hour,',') 
from time_of_day_lu
group by tod_name;

--
SELECT logs.ip_address
, logs.user_login gamer_name
, logs.user_event game_event_name
, logs.datetime_iso8601 game_event_utc
, city
, region
, country
, timezone gamer_ltz_name 
, convert_timezone('UTC', loc.timezone, logs.datetime_iso8601) game_event_ltz
, dayname(GAME_EVENT_LTZ) dow_name
, dt.tod_name
from AGS_GAME_AUDIENCE.RAW.LOGS logs
JOIN IPINFO_GEOLOC.demo.location loc 
ON IPINFO_GEOLOC.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
AND IPINFO_GEOLOC.public.TO_INT(logs.ip_address) 
BETWEEN start_ip_int AND end_ip_int
JOIN ags_game_audience.raw.time_of_day_lu dt
ON HOUR(GAME_EVENT_LTZ) = dt.hour;

create table ags_game_audience.enhanced.logs_enhanced as(
    SELECT logs.ip_address
    , logs.user_login gamer_name
    , logs.user_event game_event_name
    , logs.datetime_iso8601 game_event_utc
    , city
    , region
    , country
    , timezone gamer_ltz_name 
    , convert_timezone('UTC', loc.timezone, logs.datetime_iso8601) game_event_ltz
    , dayname(GAME_EVENT_LTZ) dow_name
    , dt.tod_name
    from AGS_GAME_AUDIENCE.RAW.LOGS logs
    JOIN IPINFO_GEOLOC.demo.location loc 
    ON IPINFO_GEOLOC.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
    AND IPINFO_GEOLOC.public.TO_INT(logs.ip_address) 
    BETWEEN start_ip_int AND end_ip_int
    JOIN ags_game_audience.raw.time_of_day_lu dt
    ON HOUR(GAME_EVENT_LTZ) = dt.hour
);

select * from ags_game_audience.enhanced.logs_enhanced;

select GRADER(step, (actual = expected), actual, expected, description) as graded_results from
(
  SELECT
   'DNGW03' as step
   ,( select count(*) 
      from ags_game_audience.enhanced.logs_enhanced
      where dow_name = 'Sat'
      and tod_name = 'Early evening'   
      and gamer_name like '%prajina'
     ) as actual
   ,2 as expected
   ,'Playing the game on a Saturday evening' as description
); 

--
--first we dump all the rows out of the table
truncate table ags_game_audience.enhanced.LOGS_ENHANCED;

--then we put them all back in
INSERT INTO ags_game_audience.enhanced.LOGS_ENHANCED (
SELECT logs.ip_address 
, logs.user_login as GAMER_NAME
, logs.user_event as GAME_EVENT_NAME
, logs.datetime_iso8601 as GAME_EVENT_UTC
, city
, region
, country
, timezone as GAMER_LTZ_NAME
, CONVERT_TIMEZONE( 'UTC',timezone,logs.datetime_iso8601) as game_event_ltz
, DAYNAME(game_event_ltz) as DOW_NAME
, TOD_NAME
from ags_game_audience.raw.LOGS logs
JOIN ipinfo_geoloc.demo.location loc 
ON ipinfo_geoloc.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
AND ipinfo_geoloc.public.TO_INT(logs.ip_address) 
BETWEEN start_ip_int AND end_ip_int
JOIN ags_game_audience.raw.TIME_OF_DAY_LU tod
ON HOUR(game_event_ltz) = tod.hour);

--Hey! We should do this every 5 minutes from now until the next millennium - Y3K!!!
--Alexa, play Yeah by Usher!

--clone the table to save this version as a backup (BU stands for Back Up)
create or replace table ags_game_audience.enhanced.LOGS_ENHANCED_BU
clone ags_game_audience.enhanced.LOGS_ENHANCED;

--ZERO-COPY
select * from ags_game_audience.enhanced.LOGS_ENHANCED_BU 
except 
select * from ags_game_audience.enhanced.LOGS_ENHANCED;

--MERGE
MERGE INTO ENHANCED.LOGS_ENHANCED e
USING RAW.LOGS r
ON r.user_login = e.GAMER_NAME
AND r.datetime_iso8601 = e.game_event_utc
AND r.user_event = e.game_event_name
WHEN MATCHED THEN
UPDATE SET IP_ADDRESS = 'Hey I updated matching rows!';


MERGE INTO ENHANCED.LOGS_ENHANCED e
USING (
    SELECT logs.ip_address 
        , logs.user_login as GAMER_NAME
        , logs.user_event as GAME_EVENT_NAME
        , logs.datetime_iso8601 as GAME_EVENT_UTC
        , city
        , region
        , country
        , timezone as GAMER_LTZ_NAME
        , CONVERT_TIMEZONE( 'UTC',timezone,logs.datetime_iso8601) as game_event_ltz
        , DAYNAME(game_event_ltz) as DOW_NAME
        , TOD_NAME
        from ags_game_audience.raw.LOGS logs
        JOIN ipinfo_geoloc.demo.location loc 
        ON ipinfo_geoloc.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
        AND ipinfo_geoloc.public.TO_INT(logs.ip_address) 
        BETWEEN start_ip_int AND end_ip_int
        JOIN ags_game_audience.raw.TIME_OF_DAY_LU tod
        ON HOUR(game_event_ltz) = tod.hour
) r --we'll put our fancy select here
ON r.GAMER_NAME = e.GAMER_NAME
and r.game_event_utc = e.game_event_utc
and r.game_event_name = e.game_event_name
WHEN NOT MATCHED THEN
insert (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME) --list of columns
values (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME) --list of columns (but we can mark as coming from the r select)
;

--
 
EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

SELECT * FROM AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

truncate table AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

--TESTING
--Testing cycle for MERGE. Use these commands to make sure the Merge works as expected

--Write down the number of records in your table 
select * from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

--Run the Merge a few times. No new rows should be added at this time 
EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

--Check to see if your row count changed 
select * from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

--Insert a test record into your Raw Table 
--You can change the user_event field each time to create "new" records 
--editing the ip_address or datetime_iso8601 can complicate things more than they need to 
--editing the user_login will make it harder to remove the fake records after you finish testing 
INSERT INTO ags_game_audience.raw.game_logs 
select PARSE_JSON('{"datetime_iso8601":"2025-01-01 00:00:00.000", "ip_address":"196.197.196.255", "user_event":"fake event", "user_login":"fake user"}');

--After inserting a new row, run the Merge again 
EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

--Check to see if any rows were added 
select * from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

--When you are confident your merge is working, you can delete the raw records 
delete from ags_game_audience.raw.game_logs where raw_log like '%fake user%';

--You should also delete the fake rows from the enhanced table
delete from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED
where gamer_name = 'fake user';

--Row count should be back to what it was in the beginning
select * from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED; 


----
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from
(
SELECT
'DNGW04' as step
 ,( select count(*)/iff (count(*) = 0, 1, count(*))
  from table(ags_game_audience.information_schema.task_history
              (task_name=>'LOAD_LOGS_ENHANCED'))) as actual
 ,1 as expected
 ,'Task exists and has been run at least once' as description 
 ); 

create or replace table AGS_GAME_AUDIENCE.RAW.PL_GAME_LOGS
clone AGS_GAME_AUDIENCE.RAW.GAME_LOGS;

--truncate table AGS_GAME_AUDIENCE.RAW.PL_GAME_LOGS;

COPY INTO AGS_GAME_AUDIENCE.RAW.PL_GAME_LOGS
FROM @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
FILE_FORMAT = (FORMAT_NAME = AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

EXECUTE TASK AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES;

CREATE VIEW AGS_GAME_AUDIENCE.RAW.PL_LOGS AS 
SELECT 
$1:agent::varchar agent,
$1:user_event::varchar user_event,
$1:datetime_iso8601::timestamp datetime_iso8601,
$1:user_login::varchar user_login,
$1 raw_log
FROM @uni_kishore/kickoff
(FILE_FORMAT => AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

SELECT * FROM PL_LOGS;

CREATE OR REPLACE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED
	WAREHOUSE='COMPUTE_WH'
	SCHEDULE='5 MINUTE'
AS
MERGE INTO AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED e
USING (
    SELECT logs.ip_address 
        , logs.user_login as GAMER_NAME
        , logs.user_event as GAME_EVENT_NAME
        , logs.datetime_iso8601 as GAME_EVENT_UTC
        , city
        , region
        , country
        , timezone as GAMER_LTZ_NAME
        , CONVERT_TIMEZONE( 'UTC',timezone,logs.datetime_iso8601) as game_event_ltz
        , DAYNAME(game_event_ltz) as DOW_NAME
        , TOD_NAME
        from ags_game_audience.raw.LOGS logs
        JOIN ipinfo_geoloc.demo.location loc 
        ON ipinfo_geoloc.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
        AND ipinfo_geoloc.public.TO_INT(logs.ip_address) 
        BETWEEN start_ip_int AND end_ip_int
        JOIN ags_game_audience.raw.TIME_OF_DAY_LU tod
        ON HOUR(game_event_ltz) = tod.hour
) r 
ON r.GAMER_NAME = e.GAMER_NAME
   AND r.game_event_utc = e.game_event_utc
   AND r.game_event_name = e.game_event_name
WHEN NOT MATCHED THEN
INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
VALUES (r.IP_ADDRESS, r.GAMER_NAME, r.GAME_EVENT_NAME, r.GAME_EVENT_UTC, r.CITY, r.REGION, r.COUNTRY, r.GAMER_LTZ_NAME, r.GAME_EVENT_LTZ, r.DOW_NAME, r.TOD_NAME);

EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

SELECT * FROM AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED 
ORDER BY GAME_EVENT_UTC DESC;

--
-- Clean out the old data
TRUNCATE TABLE AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

-- Confirm it's empty
SELECT COUNT(*) FROM AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

-- Start the ingestion task (Step 2)
ALTER TASK AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES RESUME;

-- Start the transformation/merge task (Step 4)
ALTER TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED RESUME;

-- Check the last hour of task history
SELECT *
  FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
  WHERE SCHEMA_NAME = 'RAW'
  ORDER BY QUERY_START_TIME DESC;

  --
DESCRIBE VIEW AGS_GAME_AUDIENCE.RAW.PL_LOGS;

-- Start the ingestion task (Step 2)
EXECUTE TASK AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES;

-- Start the transformation/merge task (Step 4)
EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

--
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE SYSADMIN;
USE ROLE SYSADMIN;

CREATE OR REPLACE TASK AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES
	USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
	SCHEDULE = '5 MINUTE'
AS
COPY INTO AGS_GAME_AUDIENCE.RAW.PL_GAME_LOGS
FROM @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
FILE_FORMAT = (FORMAT_NAME = AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

CREATE OR REPLACE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED
	USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
	AFTER AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES
AS
MERGE INTO AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED e
USING (
    SELECT logs.ip_address 
        , logs.user_login as GAMER_NAME
        , logs.user_event as GAME_EVENT_NAME
        , logs.datetime_iso8601 as GAME_EVENT_UTC
        , city
        , region
        , country
        , timezone as GAMER_LTZ_NAME
        , CONVERT_TIMEZONE( 'UTC',timezone,logs.datetime_iso8601) as game_event_ltz
        , DAYNAME(game_event_ltz) as DOW_NAME
        , TOD_NAME
        from ags_game_audience.raw.LOGS logs
        JOIN ipinfo_geoloc.demo.location loc 
        ON ipinfo_geoloc.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
        AND ipinfo_geoloc.public.TO_INT(logs.ip_address) 
        BETWEEN start_ip_int AND end_ip_int
        JOIN ags_game_audience.raw.TIME_OF_DAY_LU tod
        ON HOUR(game_event_ltz) = tod.hour
) r 
ON r.GAMER_NAME = e.GAMER_NAME
   AND r.game_event_utc = e.game_event_utc
   AND r.game_event_name = e.game_event_name
WHEN NOT MATCHED THEN
INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
VALUES (r.IP_ADDRESS, r.GAMER_NAME, r.GAME_EVENT_NAME, r.GAME_EVENT_UTC, r.CITY, r.REGION, r.COUNTRY, r.GAMER_LTZ_NAME, r.GAME_EVENT_LTZ, r.DOW_NAME, r.TOD_NAME);

-- 1. Resume the child first
ALTER TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED RESUME;

-- 2. Resume the root (the trigger) last
ALTER TASK AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES RESUME;

---
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from
(
SELECT
'DNGW05' as step
 ,(
   select max(tally) from (
       select CASE WHEN SCHEDULED_FROM = 'SCHEDULE' 
                         and STATE= 'SUCCEEDED' 
              THEN 1 ELSE 0 END as tally 
   from table(ags_game_audience.information_schema.task_history (task_name=>'GET_NEW_FILES')))
  ) as actual
 ,1 as expected
 ,'Task succeeds from schedule' as description
 ); 

 ---+++++++++++++++++++++++++++++

USE ROLE SYSADMIN;
USE DATABASE AGS_GAME_AUDIENCE;
USE SCHEMA RAW;

CREATE OR REPLACE TABLE AGS_GAME_AUDIENCE.RAW.ED_PIPELINE_LOGS (
    LOG_FILE_NAME VARCHAR(100),
    LOG_FILE_ROW_ID NUMBER,
    LOAD_LTZ TIMESTAMP_LTZ,
    DATETIME_ISO8601 TIMESTAMP_NTZ,
    USER_EVENT VARCHAR(25),
    USER_LOGIN VARCHAR(100),
    IP_ADDRESS VARCHAR(100)
);

SELECT 
    METADATA$FILENAME as log_file_name 
  , METADATA$FILE_ROW_NUMBER as log_file_row_id 
  , current_timestamp(0) as load_ltz 
  , get($1,'datetime_iso8601')::timestamp_ntz as DATETIME_ISO8601
  , get($1,'user_event')::text as USER_EVENT
  , get($1,'user_login')::text as USER_LOGIN
  , get($1,'ip_address')::text as IP_ADDRESS    
FROM @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
(file_format => 'AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS')
LIMIT 10;

--truncate the table rows that were input during the CTAS, if you used a CTAS and didn't recreate it with shorter VARCHAR fields
truncate table ED_PIPELINE_LOGS;

--reload the table using your COPY INTO
COPY INTO ED_PIPELINE_LOGS
FROM (
    SELECT 
    METADATA$FILENAME as log_file_name 
  , METADATA$FILE_ROW_NUMBER as log_file_row_id 
  , current_timestamp(0) as load_ltz 
  , get($1,'datetime_iso8601')::timestamp_ntz as DATETIME_ISO8601
  , get($1,'user_event')::text as USER_EVENT
  , get($1,'user_login')::text as USER_LOGIN
  , get($1,'ip_address')::text as IP_ADDRESS    
  FROM @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
)
file_format = (format_name = ff_json_logs);

----
CREATE OR REPLACE PIPE PIPE_GET_NEW_FILES
auto_ingest=true
aws_sns_topic='arn:aws:sns:us-west-2:321463406630:dngw_topic'
AS 
COPY INTO ED_PIPELINE_LOGS
FROM (
    SELECT 
    METADATA$FILENAME as log_file_name 
  , METADATA$FILE_ROW_NUMBER as log_file_row_id 
  , current_timestamp(0) as load_ltz 
  , get($1,'datetime_iso8601')::timestamp_ntz as DATETIME_ISO8601
  , get($1,'user_event')::text as USER_EVENT
  , get($1,'user_login')::text as USER_LOGIN
  , get($1,'ip_address')::text as IP_ADDRESS    
  FROM @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
)
file_format = (format_name = ff_json_logs);

--
-- First, ensure the task is suspended so we can modify it
ALTER TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED SUSPEND;

CREATE OR REPLACE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '5 MINUTE' -- Changed from AFTER back to SCHEDULE
AS
MERGE INTO AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED e
USING (
    SELECT 
          ed.IP_ADDRESS 
        , ed.USER_LOGIN as GAMER_NAME
        , ed.USER_EVENT as GAME_EVENT_NAME
        , ed.DATETIME_ISO8601 as GAME_EVENT_UTC
        , city
        , region
        , country
        , timezone as GAMER_LTZ_NAME
        , CONVERT_TIMEZONE('UTC', loc.timezone, ed.DATETIME_ISO8601) as game_event_ltz
        , DAYNAME(game_event_ltz) as DOW_NAME
        , tod.TOD_NAME
    FROM AGS_GAME_AUDIENCE.RAW.ED_PIPELINE_LOGS ed -- UPDATED SOURCE
    JOIN IPINFO_GEOLOC.demo.location loc 
      ON IPINFO_GEOLOC.public.TO_JOIN_KEY(ed.IP_ADDRESS) = loc.join_key
      AND IPINFO_GEOLOC.public.TO_INT(ed.IP_ADDRESS) BETWEEN loc.start_ip_int AND loc.end_ip_int
    JOIN AGS_GAME_AUDIENCE.RAW.TIME_OF_DAY_LU tod
      ON HOUR(CONVERT_TIMEZONE('UTC', loc.timezone, ed.DATETIME_ISO8601)) = tod.hour
) r 
ON r.GAMER_NAME = e.GAMER_NAME
   AND r.game_event_utc = e.game_event_utc
   AND r.game_event_name = e.game_event_name
WHEN NOT MATCHED THEN
INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
VALUES (r.IP_ADDRESS, r.GAMER_NAME, r.GAME_EVENT_NAME, r.GAME_EVENT_UTC, r.CITY, r.REGION, r.COUNTRY, r.GAMER_LTZ_NAME, r.GAME_EVENT_LTZ, r.DOW_NAME, r.TOD_NAME);

ALTER TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED RESUME;

SELECT SYSTEM$PIPE_STATUS('AGS_GAME_AUDIENCE.RAW.PIPE_GET_NEW_FILES');
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME=>'LOAD_LOGS_ENHANCED'))
ORDER BY SCHEDULED_TIME DESC;

select parse_json(SYSTEM$PIPE_STATUS( 'ags_game_audience.raw.PIPE_GET_NEW_FILES' ));

---------------++++++++++++++++
USE ROLE SYSADMIN;

--create a stream that will keep track of changes to the table
create or replace stream ags_game_audience.raw.ed_cdc_stream 
on table AGS_GAME_AUDIENCE.RAW.ED_PIPELINE_LOGS;

--look at the stream you created
show streams;

--check to see if any changes are pending (expect FALSE the first time you run it)
--after the Snowpipe loads a new file, expect to see TRUE
select system$stream_has_data('ed_cdc_stream');

-------------------
--query the stream
select * 
from ags_game_audience.raw.ed_cdc_stream; 

--check to see if any changes are pending
select system$stream_has_data('ed_cdc_stream');

--if your stream remains empty for more than 10 minutes, make sure your PIPE is running
select SYSTEM$PIPE_STATUS('PIPE_GET_NEW_FILES');

--if you need to pause or unpause your pipe
--alter pipe PIPE_GET_NEW_FILES set pipe_execution_paused = true;
--alter pipe PIPE_GET_NEW_FILES set pipe_execution_paused = false;

SELECT * FROM AGS_GAME_AUDIENCE.RAW.ED_CDC_STREAM; --0 
SELECT count(*) FROM AGS_GAME_AUDIENCE.RAW.ED_PIPELINE_LOGS; --580

----
--Create a new task that uses the MERGE you just tested
create or replace task AGS_GAME_AUDIENCE.RAW.CDC_LOAD_LOGS_ENHANCED
	USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE='XSMALL'
	SCHEDULE = '5 minutes'
WHEN   
    system$stream_has_data('ed_cdc_stream')
	as 
MERGE INTO AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED e
USING (
        SELECT cdc.ip_address 
        , cdc.user_login as GAMER_NAME
        , cdc.user_event as GAME_EVENT_NAME
        , cdc.datetime_iso8601 as GAME_EVENT_UTC
        , city
        , region
        , country
        , timezone as GAMER_LTZ_TIME
        , CONVERT_TIMEZONE( 'UTC',timezone,cdc.datetime_iso8601) as game_event_ltz
        , DAYNAME(game_event_ltz) as DOW_NAME
        , TOD_NAME
        from ags_game_audience.raw.ed_cdc_stream cdc
        JOIN ipinfo_geoloc.demo.location loc 
        ON ipinfo_geoloc.public.TO_JOIN_KEY(cdc.ip_address) = loc.join_key
        AND ipinfo_geoloc.public.TO_INT(cdc.ip_address) 
        BETWEEN start_ip_int AND end_ip_int
        JOIN AGS_GAME_AUDIENCE.RAW.TIME_OF_DAY_LU tod
        ON HOUR(game_event_ltz) = tod.hour
      ) r
ON r.GAMER_NAME = e.GAMER_NAME
AND r.GAME_EVENT_UTC = e.GAME_EVENT_UTC
AND r.GAME_EVENT_NAME = e.GAME_EVENT_NAME 
WHEN NOT MATCHED THEN 
INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME
        , GAME_EVENT_UTC, CITY, REGION
        , COUNTRY, GAMER_LTZ_TIME, GAME_EVENT_LTZ
        , DOW_NAME, TOD_NAME)
        VALUES
        (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME
        , GAME_EVENT_UTC, CITY, REGION
        , COUNTRY, GAMER_LTZ_TIME, GAME_EVENT_LTZ
        , DOW_NAME, TOD_NAME);
        
--Resume the task so it is running
alter task AGS_GAME_AUDIENCE.RAW.CDC_LOAD_LOGS_ENHANCED resume;

select GRADER(step, (actual = expected), actual, expected, description) as graded_results from
(
SELECT
'DNGW06' as step
 ,(
   select CASE WHEN pipe_status:executionState::text = 'RUNNING' THEN 1 ELSE 0 END 
   from(
   select parse_json(SYSTEM$PIPE_STATUS( 'ags_game_audience.raw.PIPE_GET_NEW_FILES' )) as pipe_status)
  ) as actual
 ,1 as expected
 ,'Pipe exists and is RUNNING' as description
 ); 


 ---tracking 
 SELECT * FROM table(information_schema.copy_history(table_name=>'AGS_GAME_AUDIENCE.RAW.ED_PIPELINE_LOGS', start_time=> dateadd(hours, -1, current_timestamp())));

 -- Ejecuta esto para mover lo que ya cargó el Snowpipe a la tabla final
MERGE INTO AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED e
USING (
    SELECT 
          ed.IP_ADDRESS 
        , ed.USER_LOGIN as GAMER_NAME
        , ed.USER_EVENT as GAME_EVENT_NAME
        , ed.DATETIME_ISO8601 as GAME_EVENT_UTC
        , loc.city, loc.region, loc.country, loc.timezone as GAMER_LTZ_NAME
        , CONVERT_TIMEZONE('UTC', loc.timezone, ed.DATETIME_ISO8601) as game_event_ltz
        , DAYNAME(game_event_ltz) as DOW_NAME
        , tod.TOD_NAME
    FROM AGS_GAME_AUDIENCE.RAW.ED_PIPELINE_LOGS ed 
    JOIN IPINFO_GEOLOC.demo.location loc 
      ON IPINFO_GEOLOC.public.TO_JOIN_KEY(ed.IP_ADDRESS) = loc.join_key
      AND IPINFO_GEOLOC.public.TO_INT(ed.IP_ADDRESS) BETWEEN loc.start_ip_int AND loc.end_ip_int
    JOIN AGS_GAME_AUDIENCE.RAW.TIME_OF_DAY_LU tod
      ON HOUR(CONVERT_TIMEZONE('UTC', loc.timezone, ed.DATETIME_ISO8601)) = tod.hour
) r 
ON r.GAMER_NAME = e.GAMER_NAME
   AND r.game_event_utc = e.game_event_utc
   AND r.game_event_name = e.game_event_name
WHEN NOT MATCHED THEN
INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
VALUES (r.IP_ADDRESS, r.GAMER_NAME, r.game_event_name, r.game_event_utc, r.city, r.region, r.country, r.gamer_ltz_name, r.game_event_ltz, r.dow_name, r.tod_name);

SELECT count(*) FROM AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

---
ALTER TASK AGS_GAME_AUDIENCE.RAW.CDC_LOAD_LOGS_ENHANCED SUSPEND;

CREATE SCHEMA IF NOT EXISTS AGS_GAME_AUDIENCE.CURATED;

USE ROLE SYSADMIN;
USE SCHEMA AGS_GAME_AUDIENCE.CURATED;

CREATE OR REPLACE TABLE AGS_GAME_AUDIENCE.CURATED.USER_PROFILE_EDITION AS
SELECT
    GAMER_NAME,
    CITY,
    COUNTRY,
    GAME_EVENT_UTC,
    -- Esta función numera los eventos de cada gamer del más viejo al más nuevo
    ROW_NUMBER() OVER (
        PARTITION BY GAMER_NAME 
        ORDER BY GAME_EVENT_UTC ASC
    ) as EVENT_SEQUENCE_NUMBER
FROM AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

-- Verifica el resultado
SELECT * FROM USER_PROFILE_EDITION ORDER BY GAMER_NAME, EVENT_SEQUENCE_NUMBER;


--You can run this code in a WORKSHEET

--the ListAgg function can put both login and logout into a single column in a single row
-- if we don't have a logout, just one timestamp will appear
select GAMER_NAME
      , listagg(GAME_EVENT_LTZ,' / ') as login_and_logout
from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED 
group by gamer_name;

-- Ejecuta este bloque tal cual (sin comentarios extras adentro)
select case when game_session_length < 10 then '< 10 mins'
            when game_session_length < 20 then '10 to 19 mins'
            when game_session_length < 30 then '20 to 29 mins'
            when game_session_length < 40 then '30 to 39 mins'
            else '> 40 mins' 
            end as session_length
            ,tod_name
from (
select GAMER_NAME
       , tod_name
       ,game_event_ltz as login 
       ,lead(game_event_ltz) 
                OVER (
                    partition by GAMER_NAME 
                    order by GAME_EVENT_LTZ
                ) as logout
       ,coalesce(datediff('mi', login, logout),0) as game_session_length
from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED)
where logout is not null;

-- Dora busca este texto: case when game_session_length < 10
SELECT 'case when game_session_length < 10';

SELECT query_text, start_time
FROM table(information_schema.query_history())
WHERE query_text LIKE '%case when game_session_length < 10%'
ORDER BY start_time DESC;


select GRADER(step, (actual = expected), actual, expected, description) as graded_results from
(
SELECT
'DNGW07' as step
 ,( select count(*)/count(*) from snowflake.account_usage.query_history
    where query_text like '%case when game_session_length < 10%'
  ) as actual
 ,1 as expected
 ,'Curated Data Lesson completed' as description
 );

 select * from snowflake.account_usage.query_history
 where query_text <> ''
 order by start_time desc
 limit 10;