CREATE DATABASE SMOOTHIES;
--DROP DATABASE SMOOTHIES;

--
CREATE TABLE SMOOTHIES.PUBLIC.FRUIT_OPTIONS (
    FRUIT_ID NUMBER,
    FRUIT_NAME VARCHAR(25)
);

DESCRIBE TABLE SMOOTHIES.PUBLIC.FRUIT_OPTIONS;

create file format smoothies.public.two_headerrow_pct_delim
  type = CSV,
  skip_header = 2,
  field_delimiter = '%',
  trim_space = TRUE
;

LIST @SMOOTHIES.PUBLIC.MY_UPLOADED_FILES;
select $1, $2 
from @SMOOTHIES.PUBLIC.MY_UPLOADED_FILES/fruits_available_for_smoothies.txt
(file_format => smoothies.public.two_headerrow_pct_delim);

COPY INTO smoothies.public.fruit_options
FROM @smoothies.public.my_uploaded_files
FILES = ('fruits_available_for_smoothies.txt')
FILE_FORMAT = (FORMAT_NAME = smoothies.public.two_headerrow_pct_delim)
ON_ERROR = ABORT_STATEMENT
VALIDATION_MODE = RETURN_ERRORS
PURGE = TRUE;

COPY INTO SMOOTHIES.PUBLIC.FRUIT_OPTIONS 
FROM ( 
    SELECT $2 FRUIT_ID, $1 FRUIT_NAME FROM @SMOOTHIES.PUBLIC.MY_UPLOADED_FILES/fruits_available_for_smoothies.txt
)
FILE_FORMAT = (FORMAT_NAME = smoothies.public.two_headerrow_pct_delim)
ON_ERROR = ABORT_STATEMENT
PURGE = TRUE;

-- Remember that you MUST USE ACCOUNTADMIN and UTIL_DB.PUBLIC as your context anytime you run DORA checks!!
-- DO NOT EDIT ANYTHING BELOW THIS LINE
select grader(step, (actual = expected), actual, expected, description) as graded_results from
(
  SELECT
    'DORA_IS_WORKING' as step,
    (select 223) as actual,
    223 as expected,
    'Dora is working!' as description
);

-- Set your worksheet drop lists
-- DO NOT EDIT ANYTHING BELOW THIS LINE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from (
  SELECT 'DABW001' as step
 ,( select count(*)
    from SMOOTHIES.PUBLIC.FRUIT_OPTIONS) as actual
 , 25 as expected
 ,'Fruit Options table looks good' as description
);

CREATE TABLE SMOOTHIES.PUBLIC.ORDERS (
    INGREDIENTS VARCHAR(200)
);

TRUNCATE TABLE SMOOTHIES.PUBLIC.ORDERS;

insert into smoothies.public.orders(ingredients) values ('Apples Blueberries Cantaloupe Figs Kiwi ');

-- Set your worksheet drop lists
-- DO NOT EDIT ANYTHING BELOW THIS LINE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from (
SELECT 'DABW002' as step
 ,(select IFF(count(*)>=5,5,0)
    from (select ingredients from smoothies.public.orders
    group by ingredients)
 ) as actual
 ,  5 as expected
 ,'At least 5 different orders entered' as description
);

-- Set your worksheet drop lists  
-- DO NOT EDIT ANYTHING BELOW THIS LINE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from (
  SELECT 'DABW003' as step
 ,(select ascii(fruit_name) from smoothies.public.fruit_options
where fruit_name ilike 'z%') as actual
 , 90 as expected
 ,'A mystery check for the inquisitive' as description
);

ALTER TABLE SMOOTHIES.PUBLIC.ORDERS ADD COLUMN NAME_ON_ORDER VARCHAR(100);

select * from smoothies.public.orders;

ALTER TABLE SMOOTHIES.PUBLIC.ORDERS 
DROP COLUMN ORDER_FILLED;

-- 2. La creamos de nuevo con el DEFAULT correcto desde el inicio
ALTER TABLE SMOOTHIES.PUBLIC.ORDERS 
ADD COLUMN ORDER_FILLED BOOLEAN DEFAULT FALSE;

update smoothies.public.orders
set order_filled = true
where name_on_order is null;

-- Set your worksheet drop lists
-- DO NOT EDIT ANYTHING BELOW THIS LINE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from (
  SELECT 'DABW004' as step
 ,(select count(*) from smoothies.information_schema.columns
    where table_schema = 'PUBLIC' 
    and table_name = 'ORDERS'
    and column_name = 'ORDER_FILLED'
    and column_default = 'FALSE'
    and data_type = 'BOOLEAN') as actual
 , 1 as expected
 ,'Order Filled is Boolean' as description
);

TRUNCATE TABLE SMOOTHIES.PUBLIC.ORDERS;

alter table SMOOTHIES.PUBLIC.ORDERS 
add column order_uid integer
default smoothies.public.order_seq.nextval  --sets the value of the column to sequence
constraint order_uid unique enforced;

ALTER TABLE SMOOTHIES.PUBLIC.ORDERS 
ADD COLUMN ORDER_UID NUMBER DEFAULT 0; -- Usa una constante como 0 o NULL


create or replace table smoothies.public.orders (
       order_uid integer default smoothies.public.order_seq.nextval,
       order_filled boolean default false,
       name_on_order varchar(100),
       ingredients varchar(200),
       constraint order_uid unique (order_uid),
       order_ts timestamp_ltz default current_timestamp()
);

select * from smoothies.public.orders;

-- Set your worksheet drop lists
-- DO NOT EDIT ANYTHING BELOW THIS LINE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from (
 SELECT 'DABW005' as step
 ,(select IFF(count(*)>=2, 2, 0) as num_sis_apps
    from (
        select count(*) as tally
        from snowflake.account_usage.query_history
        where query_text like 'execute streamlit%'
        group by query_text)
 ) as actual
 , 2 as expected
 ,'There seem to be 2 SiS Apps' as description
);

CREATE FUNCTION SUM_MYSTERY_BAG_VARS (VAR1 NUMBER, VAR2 NUMBER, VAR3 NUMBER)
    RETURNS NUMBER AS 'SELECT VAR1+VAR2+VAR3';

SELECT SUM_MYSTERY_BAG_VARS(12,36,204);

-- Set your worksheet drop lists
-- Set these local variables according to the instructions
set this = -10.5;
set that = 2;
set the_other = 1000;

-- DO NOT EDIT ANYTHING BELOW THIS LINE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from (
  SELECT 'DABW006' as step
 ,( select util_db.public.sum_mystery_bag_vars($this,$that,$the_other)) as actual
 , 991.5 as expected
 ,'Mystery Bag Function Output' as description
);

CREATE OR REPLACE FUNCTION UTIL_DB.PUBLIC.NEUTRALIZE_WHINING (phrase TEXT)
RETURNS TEXT
AS
$$
    INITCAP(phrase)
$$;

-- Set your worksheet drop lists
-- DO NOT EDIT ANYTHING BELOW THIS LINE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from (
 SELECT 'DABW007' as step
 ,( select hash(neutralize_whining('bUt mOm i wAsHeD tHe dIsHes yEsTeRdAy'))) as actual
 , -4759027801154767056 as expected
 ,'WHINGE UDF Works' as description
);


ALTER TABLE SMOOTHIES.PUBLIC.FRUIT_OPTIONS 
ADD COLUMN SEARCH_ON VARCHAR(50);

UPDATE SMOOTHIES.PUBLIC.FRUIT_OPTIONS
SET SEARCH_ON = FRUIT_NAME
WHERE SEARCH_ON IS NULL;

-- Actualización para Jack Fruit
UPDATE SMOOTHIES.PUBLIC.FRUIT_OPTIONS
SET SEARCH_ON = 'Jackfruit'
WHERE FRUIT_NAME = 'Jack Fruit';

-- Actualizaciones estándar (Apples, Blueberries, Raspberries, Strawberries)
-- Nota: Generalmente se usan en singular para las APIs
UPDATE SMOOTHIES.PUBLIC.FRUIT_OPTIONS
SET SEARCH_ON = 'Apple' WHERE FRUIT_NAME = 'Apples';

UPDATE SMOOTHIES.PUBLIC.FRUIT_OPTIONS
SET SEARCH_ON = 'Blueberry' WHERE FRUIT_NAME = 'Blueberries';

UPDATE SMOOTHIES.PUBLIC.FRUIT_OPTIONS
SET SEARCH_ON = 'Raspberry' WHERE FRUIT_NAME = 'Raspberries';

UPDATE SMOOTHIES.PUBLIC.FRUIT_OPTIONS
SET SEARCH_ON = 'Strawberry' WHERE FRUIT_NAME = 'Strawberries';

-- Set your worksheet drop lists
-- DO NOT EDIT ANYTHING BELOW THIS LINE
select GRADER(step, (actual = expected), actual, expected, description) as graded_results from (
   SELECT 'DABW008' as step
   ,( select sum(hash_ing) from
      (select hash(ingredients) as hash_ing
         from smoothies.public.orders
         where order_ts is not null
         and name_on_order is not null
         and (name_on_order = 'Kevin' and order_filled = FALSE and hash_ing = 7976616299844859825)
         or (name_on_order ='Divya' and order_filled = TRUE and hash_ing = -6112358379204300652)
         or (name_on_order ='Xi' and order_filled = TRUE and hash_ing = 1016924841131818535))
      ) as actual
   , 2881182761772377708 as expected
   ,'Followed challenge lab directions' as description
);

select *, length(name_on_order) from smoothies.public.orders;

UPDATE smoothies.public.orders
SET ingredients = 'Apples Lime Ximenia '
WHERE name_on_order = 'Kevin' AND order_uid = 11;

UPDATE smoothies.public.orders
SET ingredients = 'Dragon Fruit Guava Figs Blueberries '
WHERE name_on_order = 'Divya' AND order_uid = 13;

UPDATE smoothies.public.orders
SET ingredients = 'Vanilla Fruit Nectarine '
WHERE name_on_order = 'Xi' AND order_uid = 15;

TRUNCATE TABLE smoothies.public.orders;