# Swiggy Sales Performance Analysis (Jan–Aug 2025)
#### Identifying Business Growth Opportunities Through SQL & Power BI




### 📌 Project Overview

This project analyzes Swiggy's food delivery order data from January to August 2025 to understand business performance, customer ordering behavior, restaurant performance, category demand, and customer satisfaction.

Using SQL for data cleaning, transformation, dimensional modeling, and business analysis, followed by Power BI for interactive dashboard development, the project identifies key business trends and provides data-driven recommendations to support revenue growth, marketing strategies, and operational decision-making.

The project follows a complete end-to-end analytics workflow—from raw transactional data to stakeholder-ready insights through dashboards, presentations, and business reporting.


###  🎯 Business Problem

Food delivery platforms generate large volumes of transactional data every day, making it essential to convert this information into actionable business insights. Understanding how customer demand varies across cities, restaurants, categories, and time periods can help identify opportunities to improve revenue, restaurant partnerships opportunities , and enhance customer experience.

This project analyzes Swiggy's order data to answer key business questions related to demand trends, city performance, restaurant performance, category contribution, and customer ratings, ultimately supporting data-driven business decision-making.

###  🎯 Project Objectives

The primary objectives of this project were to:\
•	Analyze Swiggy's overall business performance using key performance indicators (KPIs) such as total orders, revenue, average dish price, and customer ratings.\
•	Identify demand patterns across different months and weekdays to understand customer ordering behavior.\
•	Evaluate the performance of cities, restaurants, and food categories to identify high-performing and underperforming areas.\
•	Investigate variations in revenue and order volume to uncover potential business opportunities and operational insights.\
•	Assess customer satisfaction using rating analysis to identify regions and restaurants delivering a strong customer experience.\
•	Develop an interactive Power BI dashboard and stakeholder presentation to communicate insights effectively and support data-driven decision-making.

###   📊 Dataset Overview

The analysis is based on Swiggy food delivery transaction data covering an 8-month period (January–August 2025). Each record represents a single customer order and contains information about the order date, restaurant,location, food category, dish, pricing, and customer rating.

| Attribute |	Details |
| -- | -- |
| Time Period | January 2025 – August 2025 |
| Total Records |	197,403 Orders |
| Data Grain |	One record represents one customer order |
| Source |	Swiggy_Dataset |
| Key Fields |	Order Date, State, City, Restaurant Name, Food Category, Dish Name, Price, Rating, Rating Count |

###    📌 Tech Stack

The project was completed using the following tools and technologies:

| Tool / Technology | Purpose |
| -- | -- |
| Microsoft Excel | Source dataset and initial data inspection |
| MySQL | Data cleaning, transformation, star schema creation, and business analysis using SQL |
| Power BI | Interactive dashboard development and data visualization |
| Microsoft PowerPoint | Stakeholder presentation and data storytelling |
| Microsoft Word | Business report documentation |
| GitHub | Portfolio showcase |

###    🔄 Project Workflow

The project follows an end-to-end data analytics workflow, starting from raw transactional data and progressing through data preparation, business analysis, visualization, and stakeholder communication.


Workflow Image 

###   ⭐ Data Model

To support efficient analysis and dashboard development, the raw transactional dataset was transformed into a Star Schema consisting of one fact table and multiple dimension tables.

Data Model Overview

  •	Fact Table\
            &emsp; 1) fact_swiggy_orders – Stores transactional order-level data and acts as the central table for analysis.

        
   •	Dimension Tables\
            &emsp; 1) dim_date\
            &emsp; 2) dim_location\
            &emsp; 3) dim_restaurant\
            &emsp; 4) dim_category\
            &emsp; 5) dim_dish

 Screenshot of star schema

###   📊 Dashboard Preview

An interactive Power BI dashboard was developed to present key business insights through visualizations and enable exploratory analysis across demand trends, city performance, restaurant performance, category analysis, and customer experience.

### Dashboard Overview












