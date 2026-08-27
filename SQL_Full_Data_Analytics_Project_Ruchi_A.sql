-- ***** SQL DATA ANALYTICS PORTFOLIO PROJECT *****
/*
********************************************************
*/
-- ***** PART 1 - EXPLORATORY DATA ANALYSIS (EDA) *****
/*
Data Import from csv files.
*/
use gold;
select database();
show tables;
select * from gold.dim_customers;
select * from gold.dim_products;
select * from gold.fact_sales;
-- Disabling date validation constraints for the current connection session.
SET session sql_mode = '';
-- Executing datatype conversion to DATETIME directly.
ALTER TABLE fact_sales MODIFY COLUMN order_date DATETIME;
ALTER TABLE fact_sales MODIFY COLUMN shipping_date DATETIME;
ALTER TABLE fact_sales MODIFY COLUMN due_date DATETIME;
ALTER Table dim_customers MODIFY COLUMN birthdate DATETIME;
ALTER Table dim_customers MODIFY COLUMN create_date DATETIME;
/*
**************************************************
*/
-- STEP 1 DATABASE EXPLORATION
-- 1.1 Exploring the meta data or structure of the database:
select * from information_schema.tables where table_schema = 'gold';
-- 1.2 Exploring all columns in the database for metadata information:
select * from information_schema.columns where table_name = 'dim_customers';
select * from information_schema.columns where table_name = 'dim_products';
select * from information_schema.columns where table_name = 'fact_sales';
/*
*********************************************************
*/
-- STEP 2 DIMENSIONS EXPLORATION
-- Identifying the unique values or categories in each dimension.
-- 2.1 Exploring all countries our customers come from:
select distinct country from dim_customers;
-- We have business coming from customers present in 6 countries.
-- 2.2 Exploring all product categories (the major divisions):
select distinct category from dim_products;
-- 2.3 Exploring product subcategories:
select distinct category, subcategory from dim_products order by 1,2;
-- 2.4 Exploring the whole hierarchy of products:
select distinct category, subcategory, product_name from dim_products order by 1,2,3;
-- We have 4 product categories, 36 subcategories and 295 unique products.
-- Low Cardinality Dimensions (dimensions with fewer unique values): Country, Gender, Category, ...
-- High Cardinality Dimensions (Dimensions with large number of unique values): customer, product, address, ...
/*
****************************************************************************
*/
-- STEP 3 DATE EXPLORATION
/* 3.1 Identifying the earliest and the latest order dates (boundaries of the dates in the dataset) 
and scope of the data (timespan of our business):
*/
select date(min(order_date)) as first_order_date, date(max(order_date)) as last_order_date, 
timestampdiff(Year, min(order_date), max(order_date)) as order_range_year from fact_sales where order_date <> 0000-00-00;
-- We have 3 years of sales data in the business.
-- 3.2 Finding the youngest and the oldest customers:
SELECT customer_id, first_name, last_name, date(birthdate) as oldest_birthdate,
timestampdiff(Year, birthdate, current_date()) as oldest_age
from gold.dim_customers
where birthdate <> 0000-00-00
order by birthdate ASC limit 1;
SELECT customer_id, first_name, last_name, date(birthdate) as youngest_birthdate,
timestampdiff(Year, birthdate, current_date()) as youngest_age
from gold.dim_customers
where birthdate <> 0000-00-00
order by birthdate desc limit 1;
/*
****************************************************************************
*/
-- STEP 4 MEASURES EXPLORATION
-- Calculating the key metrics of the business:
-- 4.1 Find the total sales.
SELECT SUM(sales_amount) as total_sales FROM gold.fact_sales;
-- 4.2 How many items are sold?
SELECT SUM(quantity) as total_items_sold FROM gold.fact_sales;
-- 4.3 Find the average selling price.
SELECT ROUND(AVG(price),0) as average_price FROM gold.fact_sales;
-- 4.4 Find the total number of orders.
SELECT COUNT(order_number) as total_orders FROM gold.fact_sales;
SELECT COUNT(DISTINCT order_number) as total_orders FROM gold.fact_sales;
-- We have duplicate order_number values because the customer ordered multiple products within the same order.
-- One order_number comprises all the products or items the customer ordered.
select * from gold.fact_sales;
-- 4.5 Find the total number of products.
select count(product_key) as total_products from gold.dim_products;
-- select count(distinct product_key) as total_products from gold.dim_products;
-- select count(product_name) as total_products from gold.dim_products;
-- 4.6 Find the total number of customers.
select count(customer_key) as total_customers from gold.dim_customers;
-- 4.7 Find the total number of customers that have placed an order.
select count(distinct customer_key) as total_customers from gold.fact_sales;
-- 4.8 Generate a report that shows all key metrics of the business.
SELECT 'Total Sales' as  measure_name, SUM(sales_amount) as measure_value FROM gold.fact_sales
union all
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
union all
SELECT 'Average Price', ROUND(AVG(price),0) FROM gold.fact_sales
union all
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
union all
select 'Total Products', count(product_key) from gold.dim_products
union all
select 'Total Customers', count(customer_key) from gold.dim_customers
union all
select 'Customers who placed Orders', count(distinct customer_key) from gold.fact_sales;
/*
****************************************************************************
*/
-- STEP 5 MAGNITUDE ANALYSIS
-- Comparing the measure values across different categories and dimensions.
-- Helps us in understanding the importance of different categories.
-- 5.1 Find total customers by countries.
SELECT country, COUNT(customer_key) as total_customers FROM gold.dim_customers group by country order by total_customers desc;
-- 5.2 Find total customers by gender.
SELECT gender, COUNT(customer_key) as total_customers FROM gold.dim_customers group by gender order by total_customers desc;
-- 5.3 Find total products by category.
SELECT category, COUNT(product_key) as total_products FROM gold.dim_products GROUP BY category ORDER BY total_products DESC;
-- 5.4 What is the average costs in each category?
SELECT category, ROUND(AVG(cost),0) as avg_costs FROM gold.dim_products GROUP BY category ORDER BY avg_costs DESC;
-- 5.5 What is the total revenue generated for each category?
SELECT p.category, SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON
p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
-- We can see that our business is making the most money from selling 'bikes'.
-- 5.6 Find total revenue generated by each customer.
SELECT
c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON
c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;
-- This gives us key insights into who our top spenders or most loyal customers are.
-- 5.7 What is the distribution of sold items across countries?
SELECT
c.country, SUM(f.quantity) total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON
c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;
/*
********************************************************
*/
-- STEP 6 RANKING ANALYSIS
/* Ordering the values of a dimension by a measure in order to identify:
the top N performers | the bottom N performers
*/
-- 6.1 Which 5 products generate the highest revenue?
SELECT p.product_name, SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON
p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;
-- 6.2 What are the 5 worst performing products in terms of sales?
SELECT p.product_name, SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON
p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue
LIMIT 5;
-- 6.3 What are the top 5 best subcategories in our business?
SELECT p.subcategory, SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON
p.product_key = f.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC
LIMIT 5;
-- 6.4 What are the 5 worst performing subcategories in our business?
SELECT p.subcategory, SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON
p.product_key = f.product_key
GROUP BY p.subcategory
ORDER BY total_revenue
LIMIT 5;
-- Window Functions:
-- 6.5 Product Ranking: Top 5 ranking products in terms of sold items
SELECT * FROM (
SELECT p.product_name, SUM(f.quantity) as total_sold_items,
row_number() over (order by SUM(f.quantity) desc) as product_rank
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON
p.product_key = f.product_key
GROUP BY p.product_name ) t
where t.product_rank <=5;
-- 6.6 Product Ranking: Top 5 ranking products in terms of total revenue generated.
SELECT * FROM (
SELECT p.product_name, SUM(f.sales_amount) as total_revenue,
row_number() over (order by SUM(f.sales_amount) desc) as product_rank
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON
p.product_key = f.product_key
GROUP BY p.product_name ) t
where t.product_rank <=5;
-- 6.7 Rank the Top 10 customers who have generated the highest revenue.
SELECT * FROM
( SELECT
c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount) total_revenue,
row_number() over( order by SUM(f.sales_amount) desc) as customer_rank
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON
c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name ) t
where t.customer_rank <= 10;
-- 6.8 Find the 3 customers with the fewest orders placed.
SELECT
c.customer_key, c.first_name, c.last_name, COUNT(distinct f.order_number) total_orders_placed
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON
c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_orders_placed, customer_key
limit 3;
/*
**************************************************
*/
-- ***** PART 2 - ADVANCED DATA ANALYTICS *****
/*
**************************************************
*/
-- STEP 7 CHANGES OVER TIME ANALYSIS
-- Technique to analyse how a measure evolves over time.
-- Helps track trends and identify seasonality in the data.
-- 7.1 Analyse Performance over time.
-- Total sales generated everyday (the granularity of our data is day).
SELECT date(order_date) as OrderDate, SUM(sales_amount) as TotalSales
FROM gold.fact_sales
WHERE  date(order_date) <> 0000-00-00
GROUP BY OrderDate
ORDER BY OrderDate;
-- Total sales generated every year.
SELECT YEAR(date(order_date)) as order_year, SUM(sales_amount) as total_sales
FROM gold.fact_sales
WHERE  date(order_date) <> 0000-00-00
GROUP BY order_year
ORDER BY order_year;
-- Total sales, customers and quantity sold over the years.
SELECT YEAR(date(order_date)) as order_year, SUM(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
FROM gold.fact_sales
WHERE  date(order_date) <> 0000-00-00
GROUP BY order_year
ORDER BY order_year;
-- 7.2 Analysing seasonality of our sales data (performance by month regardless of the years).
-- Changes over months gives detailed insights to discover seasonality in the data.
-- to understand which months in any sales year are high / low performing.
SELECT MONTH(date(order_date)) as order_month, SUM(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity_sold
FROM gold.fact_sales
WHERE  date(order_date) <> 0000-00-00
GROUP BY order_month
ORDER BY order_month;
-- The best performing month is December owing to the holiday season.
-- February is the worst performing month.
-- 7.3 Changes over months year-wise.
SELECT 
Year(date(order_date)) as order_year, 
Month(date(order_date)) as order_month,
SUM(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity_sold
FROM gold.fact_sales
WHERE  date(order_date) <> 0000-00-00
GROUP BY order_year, order_month
ORDER BY order_year, order_month;
/*
********************************************************
*/
-- STEP 8 CUMULATIVE ANALYSIS
-- Aggregating the data progressively over time. Helps to understand whether our business is growing or declining.
-- 8.1 Calculate the total sales per month and the running total of sales over time.
select
order_year,
order_month,
total_sales,
sum(total_sales) over (partition by order_year order by order_month) as running_total_sales
from
(select 
date_format(date(order_date),"%Y") as order_year,
date_format(date(order_date),"%m") as order_month, 
sum(sales_amount) as total_sales 
from gold.fact_sales 
WHERE date(order_date) <> 0000-00-00
group by order_year, order_month) t;
-- running total over years:
select
order_year,
total_sales,
sum(total_sales) over (order by order_year) as running_total_sales
from
(select 
date_format(date(order_date),"%Y") as order_year, 
sum(sales_amount) as total_sales 
from gold.fact_sales 
WHERE date(order_date) <> 0000-00-00
group by order_year) t;
-- 8.2 Calculating moving average of price over time
select
order_year,
total_sales,
sum(total_sales) over (order by order_year) as running_total_sales, 
avg_price, 
round(
avg(avg_price) over (order by order_year)
) as moving_average_price
from
(select 
date_format(date(order_date),"%Y") as order_year, 
sum(sales_amount) as total_sales, 
round(avg(price)) as avg_price 
from gold.fact_sales 
WHERE date(order_date) <> 0000-00-00
group by order_year) t;
/*
********************************************************
*/
-- STEP 9 PERFORMANCE ANALYSIS
/* Analyze the yearly performance of products by comparing each product's sales to both 
its average sales performance and the previous year's sales.
*/
with yearly_product_sales as 
(select 
YEAR(date(f.order_date)) as order_year, 
p.product_name, 
sum(f.sales_amount) as current_sales
from 
gold.fact_sales f 
left join 
gold.dim_products p 
ON f.product_key = p.product_key 
where date(f.order_date) <> 0000-00-00
group by order_year, p.product_name 
) 
select 
product_name, 
order_year, 
current_sales, 
round(avg(current_sales) over(partition by product_name)) as avg_sales, 
-- average sales value of the product through all years 
current_sales - round(avg(current_sales) over(partition by product_name)) as diff_avg, 
case when current_sales - round(avg(current_sales) over(partition by product_name)) >0 
then 'Above Average' 
when current_sales - round(avg(current_sales) over(partition by product_name)) <0 
then 'Below Average' 
else 'Avg' 
end avg_change_flag, 
-- year over year analysis
LAG(current_sales) over (partition by product_name order by order_year) as previous_year_sales, 
current_sales - LAG(current_sales) over (partition by product_name order by order_year) as yoy_sales_diff, 
case when current_sales - LAG(current_sales) over (partition by product_name order by order_year) >0 
then 'Sales Increasing' 
when current_sales - LAG(current_sales) over (partition by product_name order by order_year) <0 
then 'Sales Decreasing' 
else 'No change' 
end yoy_change_flag 
from 
yearly_product_sales 
order by product_name, order_year;
/*
********************************************************
*/
-- STEP 10 PART-TO-WHOLE (PROPORTIONAL) ANALYSIS
-- Which categories contribute the most to the overall sales?
with category_sales as (
select
category, 
sum(sales_amount) as total_sales  
from gold.fact_sales f 
left join
gold.dim_products p 
on f.product_key = p.product_key 
group by category) 
select 
category, 
total_sales, 
sum(total_sales) over() as overall_sales, 
concat(round((total_sales / sum(total_sales) over()) * 100, 2), '%') as percent_of_total 
from category_sales 
order by total_sales desc;
/*
********************************************************
*/
-- STEP 11 DATA SEGMENTATION
-- 11.1 Segment products into cost ranges and count how many products fall into each segment.
with product_segments as (
select 
product_key, product_name, cost, 
case when cost <100 then 'Below 100' 
	 when cost between 100  and 500 then '100-500' 
     when cost between 500 and 1000 then '500-1000' 
     else 'Above 1000'
end cost_range
from 
gold.dim_products p 
) 
select 
cost_range, 
count(product_key) as total_products 
from product_segments 
group by cost_range 
order by total_products desc;
/*
11.2 Group customers into three segments based on their spending behaviour:
	- VIP: At least 12 months of history and spending more than 5000 euros.
    - Regular: At least 12 months of history but spending 5000 euros or less.
    - New: Lifespan less than 12 months
And find the total number of customers by each group.
*/
with customer_spending as
(
select 
c.customer_key, 
SUM(f.sales_amount) as total_spending,  
MIN(date(f.order_date)) as first_order, 
MAX(date(f.order_date)) as last_order, 
timestampdiff(Month, min(order_date), max(order_date)) as lifespan  
from gold.fact_sales f 
left join gold.dim_customers c 
on f.customer_key = c.customer_key 
where f.order_date <> 0000-00-00 
-- omitting all rows where order_date is null
group by c.customer_key 
order by lifespan
)
select 
customer_segment, 
count(customer_key) as total_customers
from (
select
customer_key, 
total_spending, 
lifespan, 
case when lifespan >= 12 and total_spending > 5000 then 'VIP' 
	 when lifespan >= 12 and total_spending <= 5000 then 'Regular'
	 else 'New'
end customer_segment 
from customer_spending ) t 
group by customer_segment 
order by total_customers desc;
/*
********************************************************
*/
-- STEP 12 REPORTING
/*
============================================================================================================
Customer Report
============================================================================================================
Purpose:
Create an SQL VIEW to provide customer insights.
This report consolidates key customer metrics and behaviours:
Highlights:
	1. Gathers essential fields such as names, ages, transactions details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
		- total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last order)
        - average order value (AOV)
        - average monthly spend
===========================================================================================================
*/
-- The report is created as a VIEW in the database.
CREATE VIEW gold.report_customers AS 
with base_query as (
/*
Base Query: Retrieves core columns from tables. 
*/
select 
f.order_number, 
f.product_key, 
date(f.order_date) as order_date, 
f.sales_amount, 
f.quantity, 
c.customer_key, 
c.customer_number, 
concat(c.first_name, ' ', c.last_name) as customer_name, 
timestampdiff(Year, c.birthdate, current_date) as customer_age 
from 
gold.fact_sales f 
left join gold.dim_customers c 
on c.customer_key = f.customer_key 
where order_date <> 0000-00-00 
), 
customer_aggregations as (
/*
Customer Aggregations: Summarizes key metrics at the customer level.
*/
select 
customer_key, customer_number, customer_name, customer_age, 
count(distinct order_number) as total_orders, 
sum(sales_amount) as total_sales, 
sum(quantity) as total_quantity, 
count(distinct product_key) as total_products, 
MAX(order_date) as last_order_date, 
timestampdiff(Month, min(order_date), max(order_date)) as lifespan 
from 
base_query 
group by 
customer_key, customer_number, customer_name, customer_age 
) 
/*
Final Query: Combines all customer results into one output.
*/
select 
customer_key, customer_number, customer_name, customer_age, 
case when customer_age < 20 then 'Under 20' 
	 when customer_age between 20 and 29 then '20-29' 
 	 when customer_age between 30 and 39 then '30-39' 
	 when customer_age between 40 and 49 then '40-49' 
     else '50 and above'
end as age_group, 
lifespan,  
case when lifespan >= 12 and total_sales > 5000 then 'VIP' 
	 when lifespan >= 12 and total_sales <= 5000 then 'Regular'
	 else 'New'
end customer_segment, 
last_order_date, 
timestampdiff(Month, last_order_date, current_date) as recency, 
total_orders, total_sales, total_quantity, total_products, 
-- Computing Average Order Value (AOV)
case when total_orders = 0 then 0 
	 else round(total_sales / total_orders) 
end avg_order_value, 
-- Computing Average Monthly Spend
case when lifespan = 0 then 0 
	 else round(total_sales / lifespan)
end avg_monthly_spend 
from customer_aggregations;
SELECT * FROM gold.report_customers;
/* Users of this view can easily understand / query the data and generate insights, 
BI dashboards, etc. based on the customer information in this view. 
*/
-- example:
select 
customer_segment, count(customer_number) as total_customers, 
sum(total_sales) as total_sales 
from gold.report_customers 
group by customer_segment;
/*
********************************************************
*/
/*
============================================================================================================
Product Report
============================================================================================================
Purpose:
Create an SQL VIEW to provide product insights.
This report consolidates key product metrics and behaviours:
Highlights:
	1. Gathers essential fields such as product name, category, sub-category and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range and Low-Performers.
    3. Aggregates product-level metrics:
		- total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
===========================================================================================================
*/
-- The report is created as a VIEW in the database.
CREATE VIEW gold.report_products AS 
with base_query as (
/*
Base Query: Retrieves core columns from fact_sales and dim_products. 
*/
select 
f.order_number, date(f.order_date) as order_date, 
f.customer_key, f.sales_amount, f.quantity, 
p.product_key, p.product_name, p.category, 
p.subcategory, p.cost 
from gold.fact_sales f 
left join gold.dim_products p on 
f.product_key = p.product_key 
where order_date <> 0000-00-00 -- only consider valid sales dates 
), 
product_aggregations as ( 
/*
Product Aggregations: Summarizes key metrics at the product level.
*/
select product_key, product_name, category, subcategory, cost, 
MAX(order_date) as last_sale_date, 
timestampdiff(Month, min(order_date), max(order_date)) as lifespan, 
count(distinct order_number) as total_orders, 
count(distinct customer_key) as total_customers, 
sum(sales_amount) as total_sales, 
sum(quantity) as total_quantity, 
round(avg(cast(sales_amount as float) / nullif(quantity,0)),1) as avg_selling_price 
from base_query 
group by product_key, product_name, category, subcategory, cost 
) 
/*
Final Query: Combines all product results into one output.
*/
select 
product_key, product_name, category, subcategory, cost, 
last_sale_date, 
timestampdiff(Month, last_sale_date, current_date) as recency_in_months, 
case 
	when total_sales > 50000 then 'High-Performer' 
    when total_sales >= 10000 then 'Mid-Range' 
    else 'Low-Performer'
end as product_segment, 
lifespan, total_orders, total_sales, total_quantity, total_customers, 
avg_selling_price, 
-- Average Order Revenue (AOR) 
case 
	when total_orders = 0 then 0
    else round(total_sales / total_orders) 
end as avg_order_revenue, 
-- Average Monthly Revenue 
case 
	when lifespan = 0 then total_sales 
    else round(total_sales / lifespan) 
end as avg_monthly_revenue 
from product_aggregations;
SELECT * FROM gold.report_products;
/*
********************************************************
*/
/*
*********** END OF PROJECT ***********
*/





