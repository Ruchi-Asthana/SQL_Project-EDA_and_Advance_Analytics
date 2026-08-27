# SQL | Exploratory Data Analysis (EDA) | Advance Analytics
## Project Overview
This project analyses customers, products and sales data in two stages: 
First, we perform an EDA which is the initial investigation phase of the data where we explore the database, dimensions, measures and perform 
some basic analyses like ranking and magnitude analysis. Then, in the second stage, we dive into a deeper, more insights-driven analysis comprising 
Cumulative Analysis, Change-over-time trends, Performance Analysis, Part-to-whole (Proportional) Analysis and Data Segmentation. 
Finally we build a customer and a product report in the form of two SQL Views, highlighting our findings.
## EDA
Step 1: Database Exploration
* Exploring the meta data or structure of the database.
* Exploring all columns in the database for metadata information.


Step 2: Dimensions Exploration (Identifying the unique values or categories in each dimension)
* Exploring all countries our customers come from.
* Exploring all product categories (the major divisions).
* Exploring product subcategories.
* We have 4 product categories, 36 subcategories and 295 unique products.
* Low Cardinality Dimensions (dimensions with fewer unique values): Country, Gender, Category, ...
* High Cardinality Dimensions (Dimensions with large number of unique values): customer, product, address, ...


Step 3: Date Exploration


