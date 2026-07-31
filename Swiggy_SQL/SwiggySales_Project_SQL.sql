create database Swiggy_Database ;

-- SQL script file - in data analysis project file   
-- Swiggy database is in Program data ( data directory )

use Swiggy_Database ;
show tables ;


-- We imported the data using table import wizard by keeping order date fromat as text only  but got  only 6540 rows rest we did not get
-- and the order date is also not fetched properly 
-- So we will import using Load data local infile 

-- Creating table swiggy_data 
-- Adding extra id column as primary key so later it will be useful for joins and unique row identification

create table swiggy_data(id int auto_increment primary key ,state varchar (200) , city varchar (200) , order_date date , restaurant_name varchar(200) , location varchar(200) , category  varchar(200) ,
dish_name varchar(250) , price numeric(8,2) , rating numeric(2,1),rating_count int );
select * from swiggy_data ;

-- Setting Local infile  'ON '
show variables like "Local_infile";
set global local_infile =1;


-- Importing Data using Load data Local Infile 

load data local infile "C:\\Users\\Prathamesh\\Desktop\\My_Workspace\\Data Analysis Projects\\Swiggy_SQL_Analysis\\Swiggy_Data.csv"
into table swiggy_data
fields terminated by ','
ENCLOSED BY '"'       -- to indicate that consider values between " " as single values 
lines terminated by '\n'
ignore 1 rows
(state,
city,
@order_date,
restaurant_name,
location,
category,
dish_name,
price,
rating,
rating_count)
set order_date = str_to_date(@order_date , "%d-%m-%Y");     --  for converting the order date format 


-- the problem is rows in Mysql it is showing 197510 but in real there are 197430 so where are these extra 80 rows coming from ?
-- we solved this issue becuase we did not write enclosed  by  ' " ' in local data local infile 

select * from swiggy_data limit 5 ;
select count(*) from swiggy_data ;    -- Now it is showing 197430 which correct number of rows 

select count(order_date) from swiggy_data ;    -- 0
-- Now problem is order_date not a single value is imported 
/* we solved it using below , reimported csv 
@order_date temporarily stores the text "29-06-2025".
STR_TO_DATE() converts it into a proper MySQL DATE value (2025-06-29).
The converted value is then stored in order_date.*/

select count(order_date) from swiggy_data ;  -- 197430 , means our import is now good
select order_date from  swiggy_data  limit 5;   -- now order date is fetched properly 
select * from swiggy_data limit 5 ;      

-- Turning off Local infile 
set global local_infile = 0;
show variables like "Local_Infile";  -- OFF

-- Let us do some data walkthrough 
select count(distinct state) as total_states , count(distinct city) as total_cities ,count(distinct category ) as total_category,min(rating),max(rating) from swiggy_data ;
-- okay so 28 states , 28 cities , around 4772 categories of food , rating 0-5 is the scale this is just rough  we will deep dive later 

select count(distinct restaurant_name) from swiggy_data ;     -- 984 restaurants 

select min(order_date) , max(order_date) from swiggy_data ;
-- Data is between 01 Jan 2025 and 31 August 2025 

/*
Qualitative Columns  : State, City , Order date, Restaurant name , Location , Category , Dish name
Quantitative Columns  : Price (INR), Rating , Rating Count 
*/

-- Data Cleaning and Validation 
-- Null Values check in each column 

select 
	sum(case when state is null then 1 else 0 end) as null_state,
    sum(case when city is null then 1 else 0 end) as null_city,
    sum(case when order_date is null then 1 else 0 end) as null_order_date,
    sum(case when restaurant_name is null then 1 else 0 end) as null_restaurant ,
    sum(case when location is null then 1 else 0 end) as null_location ,
    sum(case when category is null then 1 else 0 end) as null_category ,
    sum(case when dish_name is null then 1 else 0 end) as null_dish ,
    sum(case when price is null then 1 else 0 end) as null_price ,
    sum(case when rating is null then 1 else 0 end) as null_rating ,
    sum(case when rating_count is null then 1 else 0 end) as null_rating_count
from swiggy_data ;
-- All values are filled no null values present in any of the columns ;

-- Blank values check  or empty strings 
 select * from swiggy_data
 where state ='' or city ='' or restaurant_name='' or location='' or category ='' or dish_name='' ;  
   
select ''+5 ; -- When MySQL compares a numeric column to an empty string (''), it implicitly converts the empty string to 0.

-- Duplicate Detection 
select 
state,
city,
order_date,
restaurant_name,
location,
category,
dish_name,
price,
rating,
rating_count,count(*)
from swiggy_data
group by 
state,
city,
order_date,
restaurant_name,
location,
category,
dish_name,
price,
rating,
rating_count
having count(*)>1 ;
-- We got 27 rows which were duplicate 

-- Finding the duplicate rows 
with duplicates_rn as (
select *, row_number() over (partition by state,
city,
order_date,
restaurant_name,
location,
category,
dish_name,
price,
rating,
rating_count 
) as rn
from swiggy_data )
select * from duplicates_rn where rn>1;
-- We got 27 rows which were duplicate 
-- you can see this another way to find duplicates , here alsowe can see 27 rows duplicates are there now we will delete the duplicates (rn=2) and keep the original ones where rn=1 ;

select version();   -- to check version of mysql 

select * from swiggy_data where id in (
	with duplicates_rn as (
	select *, row_number() over (partition by state,
	city,
	order_date,
	restaurant_name,
	location,
	category,
	dish_name,
	price,
	rating,
	rating_count 
) as rn
from swiggy_data )
select id from duplicates_rn where rn>1 ) ;


-- Actual Deletion 
delete from swiggy_data where id in (
	with duplicates_rn as (
	select *, row_number() over (partition by state,
	city,
	order_date,
	restaurant_name,
	location,
	category,
	dish_name,
	price,
	rating,
	rating_count 
) as rn
from swiggy_data )
select id from duplicates_rn where rn>1 ) ;
	
-- Now let us check if they are gone or not 
select * from swiggy_data where id in (
	with duplicates_rn as (
	select *, row_number() over (partition by state,
	city,
	order_date,
	restaurant_name,
	location,
	category,
	dish_name,
	price,
	rating,
	rating_count 
) as rn
from swiggy_data )
select id from duplicates_rn where rn>1) ;
-- You can see the duplicate rows are deleted as it returned nothing

select count(*) from swiggy_data ; -- also row count is now 197403 (means 27 rows are deleted)
commit ;


-- Data Validation checks 
-- Check the state ,city ,order_date if there is any :
-- 1) Leading /Trailing spaces    2) Different spellings  3) Any wrong format date for order_date 

select distinct state from swiggy_data order by state asc  ;

select distinct city from swiggy_data order by city  ;

select distinct order_date from swiggy_data order by order_Date ;


-- For category we will check if any same category is been used again 
select distinct category from swiggy_data order by category ;

-- we can see 1/2Kg Cakes and 1/2kg Cakes
-- Accompaniment (28) , Accompaniments (514) , Accompaninents (3)  three different spellings
-- 'Add On',Add ons,Add-on(6),Add-ons(1),Addons(14)
-- Al Faham,Alfaham,Alfahm  we can ignore this as we dont know are they really same or different things 
-- Ala Carte ,A La Carte  again ignore this 
-- All Time Favorites(21),All Time Favourite(7)
-- Appetizens(12),Appetizer(723),Appetizers(496),Appettizers(13)
-- Appetizers -chicken,Appetizers Chicken
-- APPTIZERS VEG(18),Appetizers Veg(7),Appetizers-vegetarian(40)
-- Basudi(2),Basundi(3)
-- Beef,'Beef '(3)
-- 'Bevarage'(1),'Beverage'(113),Beverages(2681),Bevereges(9),Beverages.(86),'Beverages '(1)
-- 'Biryani','Biryani '(10)
-- Biryani & Rice (136),Biryani and Rice(63),Biryani And Rice(10)
-- Biryani combo,Biryani Combos
-- Biryani Lunch Box(4),Biryani Lunchbox(181)
-- Biscuit,Biscuits 
-- Brack fast(16),Brakefast(5),Breackfast(3),Break Fast(10),'Breakfast'(838)
-- 'Bread'(107),'Bread '(5),Breads.(4)
-- Breads & Rice(60),Breads and Rice(98)
-- Burgers & Sandwichs(2),Burgers & Sandwiches(29)

SELECT category , count(*) as frequency
FROM swiggy_data
where category like 'A%'or category like 'B%'
group by category 
order by category asc;

-- there are lot of unique categories out there , working manually on them let us find the typos 

SELECT category , count(*) as frequency
FROM swiggy_data
where category like 'A%'
group by category 
order by category asc;

-- Z-4 , Y-6 , W-79 , V-177,U-14, T-228, S>500, R-224, Q-15, P-320,O-52 ,N-224 rows,M-376,L-76,K-152,I-167,J-49,H-148,G-158,F-213,E-94 D-212,C>500,B-365,A-142
-- Uthappam(13),Uttapam(199), Uttappam(7),Utthapam(10)
-- Quick-bites(!4), Quick Bites(317)
-- Other(8),Others(9)
-- Namekeen(6),Namkeen(761),Nan(6), 'Non Veg Main Course ', '33','Non Veg Main Course', '114',Non Veg Meals(18),'Non Veg Meals '(1),'Non Veg Staters', '14','Non Veg Starters', '83'
-- Non Vegetarian(9),Noodlesss(10)
-- Lebanese (1),Lebanese(28)
-- Janmashtami Specials(13),Janmasthmi Special(1),Jar Cake(65),Jar Cake.(92)
-- Egg(88),Egg (2)
-- We will update these categories later 

-- Now let us check the price column
select min(price) , max(price) from swiggy_data  ;
-- min price is showing 0.95 max = 8000 . Let us check min value record 
select * from swiggy_data where price=0.95; -- it is satisfactory as it tomato ketchup 
select * from swiggy_data where dish_name ='Tomato Ketchup';


-- Now let us rating column  all values should be within the range
select min(rating),max(rating) from swiggy_data ;    -- min =1.5 and max=5 , no negative records found and all valus within range 0 -5 

-- Now let us check the rating count 
select min(rating_count),max(rating_count) from swiggy_data ;
select * from swiggy_data where rating_count=999;
select * from swiggy_data where rating_count=0;  -- there are considerable records of 0 rating count so it has some business meaning to it .So let us keep it as it is 

-- Let us now update the values of the categories that we found faulty
-- Uthappam(13),Uttapam(199), Uttappam(7),Utthapam(10)
-- Quick-bites(!4), Quick Bites(317)
-- Other(8),Others(9)
-- Namekeen(6),Namkeen(761),Nan(6), 'Non Veg Main Course ', '33','Non Veg Main Course', '114',Non Veg Meals(18),'Non Veg Meals '(1),'Non Veg Staters', '14','Non Veg Starters', '83'
-- Non Vegetarian(9),Noodlesss(10)
-- Lebanese (1),Lebanese(28)
-- Janmashtami Specials(13),Janmasthmi Special(1),Jar Cake(65),Jar Cake.(92)
-- Egg(88),Egg (2)

-- Correcting inconsistent category 

select count(*) from swiggy_data where category like 'Acc%' and category like '%ts';  -- 517
select * from swiggy_data where category = "Accompaninents";
select count(*) from swiggy_data where category = "Accompaniments"; -- 514 , means those are main three needs to be updated 
update swiggy_data
set category = "Accompaniments"
where category = "Accompaninents";

select count(*) from swiggy_data where category = "Accompaniments"; -- 517 , now they are updated

select * from swiggy_data where category like 'Add%' and category like '%on'; -- 24 
select * from swiggy_data where category = "Add-on";  -- 6
update swiggy_data
set category = "Add On"
where category = "Add-on";
select * from swiggy_data where category="AddOn";   -- null , means 6 rows updated
commit ;


-- Janmashtami Specials(13),Janmasthmi Special(1),Jar Cake(65),Jar Cake.(92)
select * from swiggy_data where category like 'No%'  and category like '%les'; -- and category not in ('Namkeen','Naan Aur Rotiyan','Nashville Glazed Fried Chicken'); -- 25
select count(*) from swiggy_data where category = "Noodles";  -- 859
select * from swiggy_data where category = "Noodlesss";  -- 7
select * from swiggy_data where category = "Appetizers-vegetarian";   -- 40 
update swiggy_data
set category = "Egg"
where category = 'Egg ';
select count(*) from swiggy_data where category = "Naan";   -- 25 returned , so 25 rows updated 


-- 534 rows
commit;
select count(distinct category ) from swiggy_data ;   -- 4729 ...earlier it was 4772 categories so we updated nearly 43 unnecessary categories which were just typos 


-- Data modelling

-- creating schema - dimension and fact table
-- date table 
use swiggy_database;
create table dim_date ( date_id int auto_increment primary key ,
	full_date date ,
    year int ,
    month int,
    month_name varchar(50) ,
    Quarter int,
    day int,
    week int);

select * from swiggy_data limit 5;

-- dim_location table 
create table dim_location(location_id int auto_increment primary key , state varchar(100) , city varchar(100) , location varchar(250));

-- dim_restaurant table
create table dim_restaurant(restaurant_id int auto_increment primary key,restaurant_name varchar(300));

-- dim_category table
create table dim_category(category_id int auto_increment primary key, category varchar(300) );

-- dim_dish table 
create table dim_dish( dish_id int auto_increment primary key , dish_name varchar(350));

commit ;

-- let us now create fact table 
use swiggy_database ;
select * from swiggy_data limit 5 ;
create table fact_swiggy_orders(
	order_id int auto_increment primary key,
    
    date_id int ,
    price numeric(10,2),
    rating numeric (4,2),
    rating_count int ,
    
    location_id int,
    restaurant_id int,
    category_id int,
    dish_id int,
    
    
    foreign key(date_id) references dim_date(date_id),
    foreign key(location_id) references dim_location(location_id),
    foreign key(restaurant_id) references dim_restaurant(restaurant_id),
    foreign key(category_id) references dim_category(category_id),
    foreign key(dish_id) references dim_dish(dish_id)
);

select * from fact_swiggy_orders ;

-- Insert date into the tables 
select week(order_date) from swiggy_data limit 5 ;
insert into dim_date(full_date, year,month,month_name,Quarter,day,week)
select distinct order_date,
year(order_date),
month(order_date),
monthname(order_date),
quarter(order_date),
day(order_date),
week(order_date)
from swiggy_data 
where order_date is not null ;     -- 243 rows inserted into dim_date table 

select * from dim_date limit 5;

select distinct state , city , location  from swiggy_data ;   -- distinct checks all the column and returns the unique combinations  , 963 rows 

-- DISTINCT checks the entire row (or the entire list of selected columns), not just the first column.

-- dim_location table 
insert into dim_location(state,city,location)
select distinct state,city, location 
from swiggy_data;            -- 963 rows inserted

select * from dim_location limit 5;

-- dim_restaurant
insert into dim_restaurant(restaurant_name)
select distinct
restaurant_name 
from swiggy_data
where restaurant_name is not null ;    -- 984 rows inserted


select * from dim_restaurant limit 5;

-- dim_category table 
insert into dim_category(category)
select distinct category 
from swiggy_data 
where category is not null ;    -- 4729 rows inserted 

-- dim_dish table
insert into dim_dish(dish_name)
select distinct dish_name 
from swiggy_data 
where dish_name is not null ;

select * from swiggy_data limit 5;

-- Now we have created alll dimension table , let us create the fact table 


desc fact_swiggy_orders	;
insert into fact_swiggy_orders(
date_id,price,
rating,rating_count,
location_id,restaurant_id,
category_id,dish_id)
select 
	dd.date_id,
    s.price,
    s.rating,
    s.rating_count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dds.dish_id
from swiggy_data s

join dim_date dd 
on dd.full_date=s.order_date

join dim_location dl
on dl.state=s.state
and dl.city=s.city
and dl.location=s.location 

join dim_restaurant dr
on dr.restaurant_name = s.restaurant_name

join dim_category dc
on dc.category=s.category

join dim_dish dds
on dds.dish_name=s.dish_name

where s.id between 197404 and 197430;
-- we will insert data in batches of 25000 because mysql is losing connection 

    
select 
	count(*)
from swiggy_data s

join dim_date dd 
on dd.full_date=s.order_date

join dim_location dl
on dl.state=s.state
and dl.city=s.city
and dl.location=s.location 

join dim_restaurant dr
on dr.restaurant_name = s.restaurant_name

join dim_category dc
on dc.category=s.category

join dim_dish dds
on dds.dish_name=s.dish_name

where s.id between 197404 and 197430;   -- there 24995 , 24992 ,49992 ,24997 ,25000 , 47400,27 join rows 


select min(id) , max(id) from swiggy_data ;  -- 1 and 197430

select count(*) from swiggy_data ;     -- 197403
select count(*) from fact_swiggy_orders;   -- there are 197376 rows earlier , so 27 rows are missing  this gap is because of duplicate rows which we deleted , we checked min and mx id and inserted extra rows accordingly now we have correct count 197403


-- Now let us Join all the table 
select * from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id 
limit 5;

-- KPI development 
use swiggy_database;

select * from fact_swiggy_orders limit 5;

-- Possible KPI
-- Total Orders , Total Orders per month and which month gave max and min and why 
-- Total revenue generated , per month .highest and lowest month revenue 
-- Avg Rating 
-- Avg rating count
-- Revenue per state 
-- Revenue / Order per category 
-- Avg Dish Price 


-- Total Orders
select count(order_id) as Total_Orders from fact_swiggy_orders ;  -- 197403 orders placed 

-- Total Revenue Generated
select sum(price) as total_revenue from fact_swiggy_orders;
select price  from fact_swiggy_orders limit 5 ;
select concat(format(sum(price)/1000000,2) , ' Million INR') as Total_Revenue  from fact_swiggy_orders;
-- This query calculates the total revenue, converts it into millions, formats it to two decimal places, 
-- and displays it with the label "Million INR" for better readability.


-- Avg Dish Price
select dish_id,price from fact_swiggy_orders limit 5;
select count(distinct dish_id) from fact_swiggy_orders ;   -- 56582 unique dishes 
select concat(format(avg(price),2),' INR') as avg_dish_price  from fact_swiggy_orders ;    -- 268.50 INR AOV 

-- Avg rating 
use swiggy_database;
select format(avg(rating),2) as avg_rating  from fact_swiggy_orders ;    -- 4.34 is the avg rating  

-- Deep Dive Analysis 
select * from fact_swiggy_orders limit 5;
-- orders each month 
-- orders each quarter (Jan , feb, march -Q1 and arpil ,may,june -Q2 )
-- order trend per week 
-- total revenue  per month , quarter wise revenue , 
-- highest price dish and its order count and lowest price dish and its order count
-- highest rating and lowest rating , avg rating per month 
-- can we find which state is performing best and which state has low orders  
-- find restaurant with low rating and low order count  and also high rating but low order 
-- find restaruant with high rating and high order count  and also low rating and high order
-- category buckets form(becoz there are lot of unique categories so we nee to form buckets)  and understand which kind of food category is ordered most and which kind of category bucket gives more revenue 
-- dish - high rating dish and low rating dish with their rating counts .



select * from dim_date limit 5 ;
select min(week), max(week) from dim_date ;   -- 0,35 

-- Date Based Analysis 
-- Monthly order trends and Monthly Revenue trend 
select 
d.year,
d.month,
d.month_name,
count(f.order_id) as Total_Orders_Monthly ,
concat(format((sum(f.price)/1000000),2),' Million INR') as Total_Revenue_Monthly 
from fact_swiggy_orders f
join dim_date d
on f.date_id=d.date_id 
group by d.year,
d.month,
d.month_name 
order by Total_Orders_Monthly desc; 

-- Jan , August , May had  highest number of orders ,and same pattern is observed for total_revenue generated 
-- Feb , March , June had lowest orders and same pattern is observed for total_revenue generated


-- Quarterly Order trends 
select 
d.year,
d.quarter,
count(f.order_id) as Total_Orders_Quarterly ,
concat(format((sum(f.price)/1000000),2),' Million INR') as Total_Revenue_Quarterly
from fact_swiggy_orders f
join dim_date d
on f.date_id=d.date_id 
group by d.year,
d.quarter 
order by Total_Orders_Quarterly desc; 

-- Q2 - had highest orders means April , May , June - 74155..same pattern observed for total revenue generated 
-- Q3- had lowest orders means July , August but they were just 2 months -50163...same pattern observed for total revenue generated 

-- Orders by Day of Week 

select dayname(d.full_date) as dayname,
count(f.order_id) as total_orders_week
from fact_swiggy_orders f
join dim_date d 
on f.date_id =d.date_id  
group by dayofweek(d.full_date),dayname(d.full_date) 
order by total_orders_week desc  ;  -- why dayofweek because there it clear gives numbers as 1,2,3,4 where as group by dayname alone means confusion because sundays repeat , saturdays  repeat

-- Location based Analysis 

-- Top 10 cities by order volume

select * from dim_location limit 5;
select 
l.city,
count(f.order_id) as total_orders_city
from fact_swiggy_orders f
join dim_location l
on f.location_id = l.location_id
group by l.city
order by total_orders_city desc
limit 10;


-- Bottom 10 cities by order volume 
select 
l.city,
count(f.order_id) as total_orders_city
from fact_swiggy_orders f
join dim_location l
on f.location_id = l.location_id
group by l.city
order by total_orders_city asc
limit 10;

-- Top 10 cities by total_revenue 

select 
l.city,
concat(format(sum(f.price)/1000000,2),' Million INR') as total_revenue_city
from fact_swiggy_orders f
join dim_location l
on f.location_id = l.location_id
group by l.city
order by total_revenue_city desc
limit 10;

-- Bottom 10 cities by total revenue 

select 
l.city,
concat(format(sum(f.price)/1000000,2),' Million INR') as total_revenue_city
from fact_swiggy_orders f
join dim_location l
on f.location_id = l.location_id
group by l.city
order by total_revenue_city asc
limit 10;

-- Revenue Contribution by states
select
l.state,
concat(format(sum(f.price)/1000000,2),' Million INR') as total_revenue_state
from fact_swiggy_orders f
join dim_location l 
on f.location_id = l.location_id 
group by l.state
order by total_revenue_state desc;
-- we can see it is same as pattern shown by cities because from each state there is only one city 

-- Food Performance
-- Top 10 restaurants by order

select * from dim_restaurant limit 5;
select
r.restaurant_id,
r.restaurant_name,
count(f.order_id) as total_orders_resto
from fact_swiggy_orders f
join dim_restaurant r 
on f.restaurant_id = r.restaurant_id 
group by r.restaurant_id,
r.restaurant_name
order by total_orders_resto desc
limit 20 ;
-- McDonalds , KFC , Burger King are top restaurants as per order volume 

-- Top 10 restaruants by revenue 
select
r.restaurant_id,
r.restaurant_name,
concat(format(sum(f.price)/1000000,2),' Million INR') as total_revenue_resto
from fact_swiggy_orders f
join dim_restaurant r 
on f.restaurant_id = r.restaurant_id 
group by r.restaurant_id,
r.restaurant_name
order by total_revenue_resto desc
limit 10 ;


-- Bottom 10 restaurants by order 
select
r.restaurant_id,
r.restaurant_name,
count(f.order_id) as total_orders_resto
from fact_swiggy_orders f
join dim_restaurant r 
on f.restaurant_id = r.restaurant_id 
group by r.restaurant_id,
r.restaurant_name
order by total_orders_resto asc
limit 10 ;


-- Bottom 10 restaurants by total revenue 

select
r.restaurant_id,
r.restaurant_name,
sum(f.price) as total_revenue_resto
from fact_swiggy_orders f
join dim_restaurant r 
on f.restaurant_id = r.restaurant_id 
group by r.restaurant_id,
r.restaurant_name
order by total_revenue_resto asc
limit 10 ;

-- Top 10 categories by order

select * from dim_category limit 5;
use swiggy_database ;
select 
c.category,
count(f.order_id) as total_orders_cat
from fact_swiggy_orders f
join dim_category c
on f.category_id = c.category_id
group by c.category 
order by total_orders_cat desc 
limit 10 ;

-- Recommended , Desserts , Main COurse , Beverages,Burgers, Sweets are most commonly ordered 

select 
c.category,
concat(format(sum(f.price)/1000000,2),' Million INR') as total_revenue_cat
from fact_swiggy_orders f
join dim_category c
on f.category_id = c.category_id
group by c.category 
order by total_revenue_cat desc 
limit 10 ;

-- we can promote burger combos from top restaurants like Mcdonalds and Burger king as they are most ordered and generating high revenue
-- Recomended , Main course , Burgers, Burgers Combo , Sweets , Deserts are giving high total revenue 

-- Most Ordered Dishes

select * from dim_dish limit 5;

select
d.dish_name,
count(f.order_id) as total_order_dish
from fact_swiggy_orders f 
join dim_dish d 
on f.dish_id=d.dish_id
group by d.dish_name
order by total_order_dish desc
limit 10 ;

-- We need to find from which restos these top dishes are been ordered that is an opportunity to create more profit as demand for these dishes is high .

-- Cuisine performance → Orders + Avg Rating

select * from dim_category limit 5 ;
-- we need to check how many orders for category and how is their avg rating

select
c.category,
count(f.order_id) as total_orders_cat,
avg(f.rating) as avg_rating_cat
from fact_swiggy_orders f 
join dim_category c
on f.category_id =c.category_id 
group by category
having avg_rating_cat >4.5 
order by total_orders_cat desc ;

-- we can see  cusines of highly ordered catgeory  recommended , desserts,main course , beverages , burgers are having rating between  4-4.5 
-- we can see categories like Namkeen , Classic & Nuts Ice Creams,500 ml Ice creams,Chocolate Ice Creams,100 ml Ice creams,Stick Kulfi are having high ratings but they are ordered in less amount 
-- we can improve their order count 

--  Customer Spending Insights 

select * from fact_swiggy_orders limit 5 ;
select max(price), min(price) from fact_swiggy_orders ;    -- 8000 , 0.95
select 
case 
	when price < 100 then 'Under 100'
    when price between 100 and 199  then '100-199'
    when price between 200 and 299  then '200-299' 
    when price between 300 and 499  then '300-499'
    else '500+'
end as price_range,
count(order_id) as total_orders
from fact_swiggy_orders
group by
case 
	when price < 100 then 'Under 100'
    when price between 100 and 199  then '100-199'
    when price between 200 and 299  then '200-299' 
    when price between 300 and 499  then '300-499'
    else '500+'
end
order by total_orders desc ;

-- we can see order are mostly coming form price bucket between 100-500 price bucket .
-- Comparitively few orders are seen in 'under 100' , '500 + category'

--  Rating Count distribution 

select
rating,
count(rating) as total_rating_count 
from fact_swiggy_orders 
group by rating 
order by rating desc ;

-- we can see 5.00 rating has good count  but these dishes have low orders and low people who gave rating  so how can we increase their order count or can organize event to promote them identify their true potential 
select
rating,
count(rating) as total_rating_count 
from fact_swiggy_orders 
group by rating 
order by total_rating_count desc ;

-- 4.40 is the rating which has received the highest rating count , nearly 43.3 % of total orders 

with rating_cte as 
	(select
    rating,
    count(rating) as total_rating_count 
    from fact_swiggy_orders
	where rating <3  
	group by rating 
	order by rating desc )
select sum(total_rating_count) from rating_cte ;

-- we just have 3438 ratings below 3 out of 1,97,403  orders .Means only 1.7 % of total orders 



-- Business Insights 

-- Checking orders from feb month 

select * from fact_swiggy_orders limit 5 ;
with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select count(*) from join_cte1 where month=6 and dayofweek(full_date) in (1,4,5,6) and week in (25,26) and dish_name in (
'Choco Lava Cake',
'Veg Fried Rice',
'Paneer Butter Masala',
'Jeera Rice',
'French Fries',
'Chicken Sausage',
'Butter Naan',
'Margherita Pizza',
'Chicken Fried Rice',
'Green Salad'
)
;   -- so there are 23,292 which is not very low it is just 2101 orders less to maximum order value 

-- feb , Desserts order -350 ,Main Course -326, BURGERS-297 , Beverages-331,Burger Combos ( 3 Pc Meals )-158 ,  city -6698 , restaruant name - 5450 ,category - 4191 , dish -150 , category -5265,resto -8288 , weekends -14,786 , 11995 ,11297
-- jan ,Desserts order -404 ,Main Course -388, BURGERS-325 , Beverages-371,Burger Combos ( 3 Pc Meals ) -165 , city - 6647,restaruant name - 5889 , category - 4556, dish -162, category -5682 ,resto-8978, weekends = 13872  ,14703,10690
-- march,Desserts order -404 ,Main Course -388, BURGERS-325 , Beverages-371,Burger Combos ( 3 Pc Meals ) -165 , city - 6647,restaruant name - 5889 , category - 4556, dish -162, category -5682 ,resto-8978, weekends = 13872  ,11683,12717

select week from dim_date where month=6; 
-- 22, 23 ,24 ,25 ,26 
-- so we can conclude that due to less number of weeks / days in feb 2025 (28 days) the number of orders were less . 


-- difference between june and jan orders - 25393 -24383 = around 1010 orders less
-- June weeekend order= 13896  (week 22,23,24 -9719  ---- week 25,26 - 4177)
-- Jan weeekend order in week 0,1,2 = 8965 , Jan weeekend order in week 3,4 = 6615  ..total =15580 
-- Due to low weekend orders in week 25,26 
-- we need to check why order were less in week 8,9,10 ?
-- June  order in bengaluru , Mumbai , Hyderabad = 5024 (in week 25,26 -850)
-- Jan  order in bengaluru , Mumbai , Hyderabad = 5303 (B-2612,M-1398,H-1293)    (in week 3,4 -1398)
-- we can clearly see order count reduced in Bengaluru in march month 
-- Jan order in top restaurant - 7084   (in week 3,4 -1772) 
-- June order in top restaurant - 6684   (in week 25,26 -1125)
-- June order in top categories - 5371   (in week 25,26 -906)
-- Jan order in top categories - 5682    (in week 3,4 -1484)
-- So we can conclude that in june , due to less weekend orders in week 25, 26 the order count was less
-- In jan month , most ordered dishes order count (week 3,4 - 73)
-- In june month , most ordered dishes order count (week 25,26 - 55)

-- Why Gangtok , Kohima , Aizawl has low order count and Low revenue 
with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select restaurant_name, count(*) from join_cte1 where city = 'Aizawl'
group by restaurant_name
order by count(*) desc;


-- Aizawl - Order count  - 3088 ,Revenue - 0.58 Million , Avg rating - 4.34 (But rating count of people rating is very low so we cannot soleley depend on this avg rating )
-- Aizawl - Overal monthly order trend is stable there is not much difference seen 
-- Aizawl - Overal weekdays  order trend is stable o , there is not much difference seen . Only tuesday has slightly lower order count comapred to others 
-- Aizawl - there are 18 distinct locations in Aizawl  ( this may be the reason as locations are less the order count value is less )
-- I checked the distinct locations for top cities are very high like 75,37,41 distinct locations 
-- Bengaluru - Ang(price ) - 271.82
-- Aizawl- Ang(price ) - 266.81 , so prices are also almost same 
-- Aizawl- distinct restaurants are 35
-- Bengaluru- distinct restaurants are 87
-- Mumbai- distinct restaurants are 71, so distinct restaurants count is very less in Gangtok 
-- Aizawl -- top 5 restos - KFC,Domino's Pizza,Pizza Hut,Roti Tarka,Chopstyx
-- Aizawl -- top 5 categories  - Recommended,Main Course,ROLLS,Noodles,Rice 
-- Aizawl -- top 5 dishes are - Chicken biryani,French Fries,Chicken Sausage,Chicken Fried Rice,Veg Fried Rice

-- so we can conclude Kohima has low order count because it has less number of distinct locations only 11 , less number of distinct restaruants 29 
-- We need to partner with more resots in Gangtok to increses order count , here top 5 restaurants are Domino's Pizza,KFC,Tibet Kitchen,Crescent International Hotel,Royal Veg. Hotel
-- And top 5 categories are Recommended,Fried Rice,Soup,Mains,Beverages. So we can partner with restaurants having these categories .

-- Lucknow has 5th order volume but has 2nd highest revenue ? 
with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select sum(price)/count(*)  as revenue_per_order from join_cte1 where city = 'Mumbai';


use swiggy_database ;

-- Lucknow has 10,192 orders , 5th hoghest 
-- Lucknow has 3.12 million INR  , 2nd highest 
-- Lucknow has avg dish price - 305.86 
-- Mumbai has avg dish price - 287.006,
-- Hyderabad has avg dish price - 293.11
-- Bengaluru has avg dish price - 271.82 , means bengaluru revenue is due to its highest number of orders
-- Bengaluru has avg rating-4.3 , avg rating count -28
-- Lucknow has avg rating-4.37 , avg rating count -28.2
-- Mumbai has avg rating-4.34 , avg rating count -21.25
-- Hyderabad has avg rating-4.2 , avg rating count -28.5
-- Lucknow  top 4 restaruants - McDonalds (1177,0.27 M ), KFC (932, 0.28 M),Burger King (797 ,0.22 M), Pizza Hut(529, 0.18 M) 
-- Mumbai  top 4 restaruants - McDonalds (1426,0.35 M ), Aromas Cafe and Bistro (676, 0.26 M),Shiv sagar veg restaruant (584 ,0.16 M), Veg Sizzles (525, 0.15 M) 
-- Hyderabad  top 4 restaruants - Bikanervala (772,0.21 M ), KFC (635, 0.20 M),LunchBox - Meals and Thalis (611 ,0.14 M),Veg Meals by Lunchbox  (527, 0.14M) 
-- So may be in lucknow most orders are from high revenue generating restaurants that may be the reason why lucknow is generating revenue .
-- Top categories  in Hyderabad - Recommended(1647,0.56 M),Desserts (318,0.05M),Namkeen(148,0.03 M),Beverages (145,0.01 M),Sweets(104,0.03 M)
-- Top categories  in Lucknow - Recommended(1537,0.53 M),Beverages(262,0.03 M),Burgers(204,0.05 M),Exclusive Deals(193,0.04 M),Desserts(175,0.02 M)
-- Also lucknow has orders from top categories having high revenue like recommended , burgers ,sweets ,deserts ...but other city also have this is not the single factor affecting lucknow revenue , it tis the top restaruants that affecting the revenue 


-- Why Jaipur beign 4th highest in orders is giving revenue 10 th highest ?
with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select restaurant_name,count(*) from join_cte1 where city ='Jaipur'
group by restaurant_name
order by count(*) desc
limit 10;
use swiggy_database;

-- Jaipur --  Count if Order s- 10285
-- Jaipur - revenue -2.50 Million  Inr
-- Jaipur - avg  dish price is 243.34
-- Mumbai has avg dish price - 287.006,
-- Hyderabad has avg dish price - 293.11
-- Delhi has avg dish price -277.61 ,Ahmedabad has avg dish price - 276.71
-- So there is strong possibilty that due to low revenue per order the revenue generated is less from Jaipur
-- Jaipur top restaurants from which order is placed - McDonald's (671),Burger Farmm (631),Burger King,Tan-Sukh By Kanha,KFC
-- Jaipur -- Burger Farm restaurant avg price is 200.826,Mcdonalds restaurant avg price is 225.57,Burger King restaurant avg price is 268.67
-- Jaipur -- Tan-Sukh By Kanha restaurant avg price is 265.79,KFC restaurant avg price is 299.07 
-- We can see top restaruants generating revenue the Burger Farm and Tan-Sukh By Kanha despite of high order count are at 5th psotition and 6th position 
-- So there is possibilty that due to order count from restaurants like Tan-Sukh By Kanha,Burger Farm is high but their revenue per order  is low  ,so overall the revenue of Jaipur is being generated low
-- We can promote these restaurants to generate more order count from them  by providing them operational support .
-- Jaipur top categories -Recommended,Main Course,Desserts,BURGERS,Breads ..so categories is the not problem because theses are high revenue generating categories .

-- Evalutating the top 10 restaurants 

-- Find top categories in Mcdonalds
with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select category,count(*),concat(format(sum(price)/1000000,2),' INR miliion') as total_revenue,format(avg(price),2) as avg_price from join_cte1 where restaurant_name ="McDonald's"
group by category 
order by total_revenue desc
limit 10 ;



use swiggy_database ;

-- McDonalds top categories order count  - McSaver Combos (2 Pc Meals),Burger Combos ( 3 Pc Meals ),Coffee & Beverages (Hot and Cold),Protein Plus and Burgers with Millet Bun,Burgers & Wraps 
-- Mcdonalds top categroies revenue wise - Burger Combos ( 3 Pc Meals ),McSaver Combos (2 Pc Meals),Group Sharing Combos,Protein Plus and Burgers with Millet Bun,Double Patty Burgers & Meals
-- Mcdonalds categories with high revenue and high avg price and good order count - Burger Combos ( 3 Pc Meals ),McSaver Combos (2 Pc Meals),Group Sharing Combos,Protein Plus and Burgers with Millet Bun,Double Patty Burgers & Meals
-- So Group Sharing Combos has high avg dish price and roder count is also in top 5 so we can consider for bundling and promotions or bulk orders 
-- We can focus on Burger Combos ( 3 Pc Meals ) as it is having high order count and high revenue generation , recommending some other good revenue genrating categories like Coffee & Beverages (Hot and Cold) will increase average order value thus improving revenue 
-- McSaver Combos (2 Pc Meals) is also another good performing category in McDonald's.
-- For health conscious or diet conscious crowd  - Protein Plus and Burgers with Millet Bun promoting this category will be beneficial 


-- KFC 
with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select category,count(*),concat(format(sum(price)/1000000,2),' INR miliion') as total_revenue,format(avg(price),2) as avg_price from join_cte1 where restaurant_name ="KFC"
group by category 
order by total_revenue desc
limit 10 ;

-- KFC top categories order count-BURGERS, Recommended,DESSERTS & BEVERAGES,ROLLS,SIDES AND DIPS
-- KFC top categroies revenue wise- BURGERS,Recommended,LATE NIGHT SPECIALS (STARTING AT 199),ROLLS
-- KFC categories with high revenue and high avg price and good order count - Recommended,LATE NIGHT SPECIALS (STARTING AT 199),EPIC VALUE MEALS FOR 1-2 (UP TO 22% OFF)
-- KFC - Burgers have good demand .Maintain the strong performance of Burgers  by ensuring consistent availability and using it as a benchmark to understand the pricing and promotional strategies that drive customer demand
-- Also one interesting thing is observed here the demand for rolls is high and its avg price is low , we can bundle it with burgers or other food catgeories like LATE NIGHT SPECIALS (STARTING AT 199) so average order valueincrease .
-- KFC- high evenue generation is from LATE NIGHT SPECIALS (STARTING AT 199), Rolls & EPIC VALUE MEALS FOR 1-2 (UP TO 22% OFF) we can promote these categories 
-- Also desserts and beverages are having high demand and  low revenue per order so we can promote it as add ons with the order  or can include them in premium order meals .
-- Maximum revenue contribution is from Recommended , Burgers , Rolls , LATE NIGHT SPECIALS (STARTING AT 199)

-- Pizza Hut 

with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select category,count(*),concat(format(sum(price)/1000000,2),' INR miliion') as total_revenue,format(avg(price),2) as avg_price from join_cte1 where restaurant_name ="Pizza Hut"
group by category 
order by count(*) desc
limit 10 ;

-- Pizza Hut top categories order count-Recommended,Veg Pizza,Non Veg Pizza,Appetizer,Flash Sale Pizzas,Garlic Bread
-- An appetizer is a small portion of food or drink served before a main course ( Starter )
-- Pizza Hut top categories revenue wise - Recommended,Thin n Crispy Pizzas,Flash Sale Pizzas,Non Veg Pizza,Veg Pizza
-- Pizza Hut top avg_price categroies - Thin n Crispy Pizzas,One Plus One Medium @649,Flash Sale Pizzas
-- Most revenue of Pizza hut is from - Recommended,Veg Pizza,Non Veg Pizza,Flash Sale Pizzas
-- Appetizer are having good order count but have low avg price , so we might bundle it Veg Pizza,Non Veg Pizza,Flash Sale Pizzas as combo offer for increasing average order value 
-- Flash sale pizzas are having order count-418 and revenue_per_order = 679 ..we can think like buy 2 flash sale pizzas and get one veg or non veg pizza free as they are having low average price but higher demand in public .Although effect on revenue , profit must be checked before this 
-- Thin n Crispy Pizzas are having good order count but not that high but it has high avg_price so we can use it as customer retention product. we can gice coupons to customer on every order of Thin n Crispy Pizzas and after 3 consistent orders they can get appetizer or Garlic Bread free .
-- As garlic bread and appetizer have high demand and low avg_price 

-- Investigate why Anand Sweets and Biggie Burger are not getting that much demand or revenue because their categories are highly ordered but why they are performing low 

with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select * from join_cte1 where city ='Bhubaneswar' and dish_name = 'Cool Bliss';
-- group by dish_name
-- order by count(*) desc;

-- Anand Sweets & Savouries (1) , Biggies Burger (3)
-- Anand Sweets & Savouries is in Bengaluru - Snack category purchased 133 rs -- Dish name - Butter Murukku-200gm
-- Biggies Burger is in Bhubaneswar - Summer Deal Of The Month category purchased 219 rs
-- In Bengaluru  major sweets category supplier is Kanti Sweets
-- In Bengaluru  snacks category has only 1 order which is of Anand Sweets & Savouries
-- In Bengaluru major snacks category supplier is Kanti Sweets,Sri Vinayaka Hot Chips, although there are only 8 restaurants providing snacks category 
-- After checking top dushes in snack category we observed that the range of demand varoes from 1-4 order count per dish it means thee is no specific dish which is explodingly having high demand in snack category 
-- Variety is the key in snack item as even though orders are less dishes ordered are showing variety
-- So Anand Sweets & Savouries can provide unique snack options  which might increase their order demand  .
-- As we do not have data of menu of Anand Sweets & Savouries we cannot directly suggest which snack dish will have high sales or high order count 

-- Biggies Burger dishes ordered - Naughty Nutella Browine Shake,Peachy Lagoon,Cool Bliss
-- In Bhubaneswar , starters have high demand ...burgers and beverages are having considerable count of orders 
-- But beverages are having low revenue as their avg_price is low . Starters and Burgers are having good revenue .
-- There are already many big players in burger categories in  Bhubaneswar like - McDonald's,KFC,Domino's Pizza
-- Whereas in starter category there is comparitvely less variance seen in order count of the different restaruants 
-- For category Summer Deal Of The Month there is only one resto which is Biggies Burger
-- So biggie burgers can provide options including starters or starters combined with Summer Deal Of The Month category
-- Also the orders in Biggies Burger were placed during most of the summer season , so do be competetive after summer they can aslo introduce some other beverages as they high demand and high revenue  
-- As we do not have data of menu of Biggies Burger we cannot directly suggest which starter dish or beverage  will have high sales or high order count .
-- Biggies Burger have unique drinks like Cool Bliss so better visibilty of this can increase the order count .

with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select restaurant_name ,count(*)  from join_cte1 where category="Main Course"
group by restaurant_name
order by count(*) desc
limit 10;
use swiggy_database;

-- Q. Investigate from which restaurant are the top categroies been order and see if they are in top 10 list of restaurants.
-- Restos where main course category is ordered highest - BOX8 - Desi Meals,Radha Krishna,Tan-Sukh By Kanha,Priya Restaurant
-- Restos where Desserts category is ordered highest - The Good Bowl,Burger King,McDonald's,Faasos - Wraps, Rolls & Shawarma
-- Restos where Beverages category is ordered highest - McDonald's,Domino's Pizza,LunchBox - Meals and Thalis,The Good Bowl
-- Restos where BURGERS category is ordered highest - KFC,McDonald's,Pizza Crust
-- One observation  here is although the main course categroy has high order volume and high revenue the restaruants providing the main course are not in the list of top 10 restaruants by order and top 10 restaurants by revenue 
-- Which shows main course is highly order from different restaruants and location due to this diversification restaurants providing main course category are not in top list 
-- Also top restaurants are earning good revenue and are at top because they have top selling categories like Dessert category alongwith Burgers, Beverages category 

with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select state,count(*)  from join_cte1 where category="Namkeen"
group by state
order by count(*) desc
limit 10;

-- Rating Count Disitribution 
use swiggy_database;
select
rating,
count(rating) as total_rating_count 
from fact_swiggy_orders 
group by rating 
order by rating desc ;


with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select dish_name,category, count(*)  from join_cte1  where state = 'Gujarat' and restaurant_name ='Jayhind Sweets' and rating=5 
group by dish_name,category
order by count(*) desc
limit 10;


-- Gujarat(684) is having high 5 star rating after Karnataka (985) and Maharashtra (709), but Gujarat is not in top 10  states with high order 
-- We can observe the restaurants with 5* rating are also in the list of top10 restaruants by order 
-- Sample test on Gujarat  state 
-- In Gujarat - McDonalds (111) ,Jayhind Sweets (108), KFC (63) have highest 5  star rating '
-- Jayhind Sweets- Out of 552 , 108 are 5 star rating orders approx 19.5 % 
-- Jayhind Sweets - top order categories- Namkeen, Dryfruit Sweets,Recommended
-- Jayhind Sweets - Namkeen, Dryfruit Sweets are very highly order also they are rated 5 star 
-- We can promote or position Namkeen , Dryfruit sweet of Jayhind Sweets in Gujarat state to incresea its order count as we have evidence that they are highly ordered and also highly rated (5 star) so it can help improve sales 

use swiggy_database ;
show tables ;
select * from dim_category limit 10 ;

with join_cte1 as 
(select price, rating, rating_count,full_date,year,month,month_name,quarter, day,week,state,city, location, restaurant_name,
category,dish_name
from fact_swiggy_orders f
join dim_date  d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id 
join dim_restaurant r on f.restaurant_id=r.restaurant_id  
join dim_category c on  f.category_id =c.category_id
join dim_dish dd on f.dish_id=dd.dish_id
order by order_id )
select restaurant_name, count(*)  from join_cte1 where state = 'Gujarat' and rating =5
group by restaurant_name
order by count(*) desc
limit 10;


