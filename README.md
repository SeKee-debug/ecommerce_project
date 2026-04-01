# End-to-End E-commerce Analytics: Orders, Logistics, and Customer Experience

## Project Overview
This project analyzes the Olist Brazilian e-commerce dataset to evaluate platform performance, customer experience, logistics efficiency, category health, seller quality, and customer value concentration. The goal was to translate multi-table transactional data into actionable business insights and operational recommendations.

## Business Questions
1. How is the platform performing overall in terms of orders, delivery success, GMV, and AOV?
2. Which states contribute the most orders and GMV, and which regions show weaker customer experience?
3. Which product categories act as core revenue drivers, and which show signs of risk?
4. How strongly is delivery timeliness associated with customer ratings?
5. Which sellers perform well, and which sellers require closer monitoring?
6. Does the platform have a stable base of high-value customers?

## Dataset
Source tables used:
- `olist_orders`
- `olist_order_items`
- `olist_order_reviews`
- `olist_products`
- `olist_customers`
- `olist_sellers`
- `product_category_name_translation`

## Data Preparation
Python was used to clean and enrich the raw data:
- Converted delivery-related timestamps to datetime
- Added `order_month`, `order_year`, `delivery_days`, `estimated_delivery_days`, `is_delivered`, and `is_late`
- Added `item_total_value` and `freight_ratio`
- Added `review_group`
- Merged product category names with English translations

## Tools
- **Python**: pandas, numpy, matplotlib
- **SQL / PostgreSQL**: multi-table joins, KPI aggregation, business analysis
- **Dashboard packaging**: generated static dashboard visuals for portfolio presentation

## Key Results
### 1) Platform Performance
- Total orders: **99,441**
- Delivered orders: **96,478**
- Delivery rate: **97.02%**
- Total GMV: **R$ 15.84M**
- AOV: **R$ 160.58**

### 2) Regional Insights
- **SP** is the dominant market by both orders and GMV.
- **RJ** is a high-volume state but shows slower delivery and lower customer ratings than SP.
- Several lower-volume states show much longer delivery times, indicating logistics friction in remote regions.

### 3) Category Insights
- **Health & Beauty** and **Watches & Gifts** are among the strongest categories by GMV.
- Several home-related categories generate scale but face weaker review scores and higher freight burden.
- Freight ratio is a useful signal for identifying categories with margin or experience pressure.

### 4) Logistics and Ratings
- Late orders average **2.57** stars versus **4.21** for on-time orders.
- Negative review rate jumps from **11.38%** for on-time orders to **54.02%** for late orders.
- Orders taking **over 21 days** show a sharp ratings drop to **3.01**, suggesting a service threshold.

### 5) Seller Segmentation
- Ordinary / potential sellers: **2,486** (**80.32%**)
- High-risk sellers: **562** (**18.16%**)
- Top-tier sellers: **47** (**1.52%**)

### 6) Customer Value
- Unique customers: **93,358**
- Repeat customers: **2,801**
- Repeat purchase rate: **3.00%**
- Average customer value: **R$ 141.62**
- Top 5% customer value threshold: **R$ 419.81**

## Business Recommendations
- Prioritize logistics optimization in high-volume but weaker-experience states such as RJ.
- Use category-level freight burden and review signals to identify categories requiring fulfillment or quality improvements.
- Reduce the share of high-risk sellers through monitoring and governance, as they contribute relatively little GMV but likely generate experience drag.
- Design targeted retention actions for high-spend one-time buyers to improve repeat purchase behavior.


## Repository Structure
```text
project/
├── data/
├── sql/
├── notebooks/
├── outputs/
│   ├── dashboard_overview.png
│   ├── dashboard_product_customer.png
│   └── dashboard_ops_sellers.png
├── README.md
└── resume_bullets.md
```

## Portfolio Value
This project demonstrates:
- end-to-end data cleaning and feature engineering
- SQL-based business analysis across multiple relational tables
- KPI design and operational storytelling
- dashboard packaging for portfolio and interview use
