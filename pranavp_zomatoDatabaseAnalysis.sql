use pranav;
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2021-01-08 21:30:45','25km','25mins',null),
(8,2,'2021-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2021-01-11 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01  18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


A. ROLL METRICS

Q 1. how many rolls were ordered?

select count(roll_id) from customer_orders;


Q 2.How many unique customer orders were made?

select count(distinct customer_id) from customer_orders;


Q 3.How many successful orders were delivered by each driver?

select driver_id,count(order_id) from driver_order
where cancellation not in ('Cancellation','Customer Cancellation')
group by driver_id


Q 4.How many of each type roll was delivered?

select roll_id,count(roll_id) 
from customer_orders
where order_id in (select order_id from (select *,
case 
   when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as stats
from driver_order)t1
where stats='nc')
group by roll_id


Q 5.How many veg and non veg rolls were ordered by each customer?

select customer_id,roll,count(roll) cnt,roll_name
from(select c.order_id order_id,c.customer_id customer_id,c.roll_id roll,r.roll_name roll_name
from customer_orders c
join rolls r
on c.roll_id=r.roll_id)t
group by customer_id,roll,roll_name
order by roll,customer_id

OR

select t1.*,r.roll_name
from (select customer_id,roll_id,count(roll_id) cnt
from customer_orders
group by customer_id,roll_id)t1 join rolls r on t1.roll_id=r.roll_id;


Q 6.What was the maximum number of rolls delivered in a single order?

select * from
(select * ,rank() over(order by cnt desc) rnk from
(select order_id,count(order_id) cnt from 
customer_orders
where order_id in (select order_id from (select *,
case 
   when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as stats
from driver_order)t1
where stats='nc')
group by order_id)t2)t3
where rnk=1

Q 7. For each customer,how many delivered rolls had at least 1 change and how many had no change?

with temp_customer_table as 
(
select order_id,customer_id,roll_id,
case when not_include_items='' or not_include_items is NULL or not_include_items='NaN' or not_include_items='NULL' then 0 else not_include_items end as new_not_include,
case when extra_items_included='' or extra_items_included is NULL or extra_items_included='NaN' or extra_items_included='NULL' then 0 else extra_items_included end as new_extra_items,
order_date as date 
from customer_orders
),
temp_driver_order as
(
select order_id,driver_id,
case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order
)

select customer_id,change_or_not,count(customer_id) from
(select *,
case when new_not_include='0' and new_extra_items='0' then 'no_change' else 'change' end as change_or_not
from temp_customer_table 
where order_id in (select order_id from temp_driver_order where new_cancellation!='0'))t
group by customer_id,change_or_not


Q 8. How many rolls were delivered that had both exclusions and extras?

with temp_customer_table as 
(
select order_id,customer_id,roll_id,
case when not_include_items='' or not_include_items is NULL or not_include_items='NaN' or not_include_items='NULL' then 0 else not_include_items end as new_not_include,
case when extra_items_included='' or extra_items_included is NULL or extra_items_included='NaN' or extra_items_included='NULL' then 0 else extra_items_included end as new_extra_items,
order_date as date 
from customer_orders
),
temp_driver_order as
(
select order_id,driver_id,
case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order
)

select status,count(status)
from(select *,
case when new_not_include!=0 and new_extra_items!=0 then 'both_exlusive' else 'one_exc_inc' end as status
from temp_customer_table
where order_id in(select order_id from temp_driver_order where new_cancellation!=0))t
group by status

Q 9. What was the total number of rolls ordered for each hour of the day?

select order_time,count(order_id) cnt from(select *,concat(hour(order_date),'-',hour(order_date)+1) as order_time
from customer_orders)t
group by order_time
order by order_time

Q 10. What was the number of orders for each day of the week?

select days,count(distinct order_id) cnt_per_day from(select *,dayname(order_date) days 
from customer_orders)t
group by days


B. Driver and customer experience

Q 1.What was the average time in minutes it took for each driver to arrive at the fassos HQ to pickup the order?

select driver_id,round((sum(time_taken)/60)/count(driver_id)) dif from
(select * from
(select *,row_number() over(partition by order_id) rnk
from(select c.*,d.driver_id,d.pickup_time,time_to_sec(timediff(d.pickup_time,c.order_date)) time_taken
from customer_orders c join driver_order d
on c.order_id=d.order_id and d.pickup_time is not null)t)t1
where rnk=1)t2
group by driver_id

Q 2.Is there any relationship between the number of rolls and how long the order takes to prepare?

select order_id,count(roll_id) count,round(sum(time_taken)/count(roll_id)) time from
(select c.*,d.driver_id,d.pickup_time,round(time_to_sec(timediff(d.pickup_time,c.order_date))/60) time_taken
from customer_orders c join driver_order d
on c.order_id=d.order_id and d.pickup_time is not null)t
group by order_id

Q 3. What was the average distance travelled for each customer?

select customer_id,sum(distance)/count(customer_id) avg_dist from
(select * from
(select *,row_number() over(partition by order_id) rnk from
(select c.order_id,c.customer_id,cast(trim(replace(lower(d.distance),'km','')) as decimal(4,2)) distance
from customer_orders c join driver_order d 
on c.order_id=d.order_id and d.distance is not null)t)t1
where rnk=1)t2
group by customer_id


Q 4.What was the difference between the longest and shortest delivery times for all orders?

select max(duration)-min(duration) diff from
(select * from
(select *,row_number() over(partition by order_id) rnk from
(select c.*,trim(replace(lower(replace(lower(replace(lower(d.duration),'minutes','')),'mins','')),'minute','')) duration
from customer_orders c join driver_order d 
on c.order_id=d.order_id and duration is not null)t)t1
where rnk=1)t2

Q 5.What was the average speed for each driver for each delivery and do you notice any trend for these values?

select driver_id,order_id,count(roll_id) roll_cnt,cast(sum(speed)/count(driver_id) as decimal(4,2)) avg_speed_kmph from
(select c.*,d.driver_id,cast(cast(trim(replace(lower(d.distance),'km','')) as decimal(4,2))/(trim(replace(lower(replace(lower(replace(lower(d.duration),'minutes','')),'mins','')),'minute',''))/60) as decimal(4,2)) speed
from customer_orders c join driver_order d 
on c.order_id=d.order_id and duration is not null)t
group by driver_id,order_id


Q 6. What is the successful delivery percentage for each driver?

select * from driver_order

select driver_id,cast(sum(pass)/count(driver_id) as decimal(4,2))*100 percent_completed  from
(select *,
case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as pass
from driver_order)t
group by driver_id


