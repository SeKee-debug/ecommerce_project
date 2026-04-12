#E-commerce Analytics: Operations, Logistics, and Customer Experience

## Project Overview
This project analyzes the **Olist Brazilian e-commerce dataset** to evaluate platform performance from multiple business angles, including order volume, GMV, logistics reliability, regional performance, product category health, seller quality, and customer retention.

The project combines **Python-based data cleaning and feature engineering** with **SQL business analysis** to turn raw transactional data into practical operational insights. The goal was not only to compute KPIs, but also to explain what those metrics mean for platform growth, customer experience, and operational risk.

---

## Business Questions
This project answers six core business questions:

1. How is the platform performing overall in terms of orders, delivery success, GMV, and AOV?
2. Which states contribute the most orders and GMV, and which regions show weaker customer experience?
3. Which product categories act as core revenue drivers, and which show signs of margin or service risk?
4. How strongly is delivery timeliness associated with customer ratings?
5. Which sellers perform well, and which sellers require closer monitoring?
6. Does the platform have a stable base of repeat or high-value customers?

---

## Dataset
The analysis uses multiple relational tables from the Olist dataset, including:

- `olist_orders`
- `olist_order_items`
- `olist_order_reviews`
- `olist_products`
- `olist_customers`
- `olist_sellers`
- `product_category_name_translation`

---

## Data Preparation
Before analysis, the raw data was cleaned and enriched in Python.

Key preparation steps included:

- converting delivery-related timestamp columns to datetime format
- creating `order_month` and `order_year` for trend analysis
- engineering logistics fields such as `delivery_days`, `estimated_delivery_days`, `is_delivered`, and `is_late`
- creating revenue-related fields such as `item_total_value` and `freight_ratio`
- grouping review scores into simplified categories for interpretation
- merging product category names with English translations for clearer analysis output

The main preprocessing workflow is documented in:

- `cleaned_orders.ipynb`

---

## Tools
- **Python**: pandas, numpy, matplotlib
- **SQL / PostgreSQL**: joins, CTEs, KPI aggregation, segmentation, business analysis
- **Jupyter Notebook**: data cleaning and feature engineering
- **tableau**: creating dashboards
---

## Repository Structure

```text
ecommerce_project/
├── data/                     # raw Olist source data
├── cleaned_data/             # cleaned and transformed datasets used for analysis
├── sql/                      # SQL scripts for the 6 business questions
├── cleaned_orders.ipynb      # notebook for cleaning and feature creation
└── README.md                 # project overview, findings, and recommendations
```

---

## SQL Analysis Highlights
A major part of the project was solving business questions with SQL. I used **CTEs, joins, aggregation, conditional logic, and segmentation rules** to move from raw tables to decision-oriented outputs.

### Example 1: Platform KPI Summary

```sql
WITH order_summary AS (
    SELECT 
        o.order_id,
        o.order_status,
        SUM(i.item_total_value) AS order_gmv
    FROM olist_orders o
    LEFT JOIN olist_order_items i ON o.order_id = i.order_id
    GROUP BY o.order_id, o.order_status
)

SELECT 
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    ROUND(
        SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(order_id) * 100, 2
    ) || '%' AS delivery_rate,
    ROUND(SUM(order_gmv)::NUMERIC, 2) AS total_gmv,
    ROUND(AVG(order_gmv)::NUMERIC, 2) AS aov
FROM order_summary;
```

### Example 2: Regional Experience Analysis

```sql
SELECT 
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(i.item_total_value)::NUMERIC, 2) AS total_gmv,
    ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
    ROUND(
        AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)))::NUMERIC, 2
    ) AS avg_delivery_days,
    ROUND(
        SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(DISTINCT o.order_id) * 100, 2
    ) || '%' AS late_delivery_rate
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_items i ON o.order_id = i.order_id
LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_orders DESC;
```

### Example 3: Delivery Delay vs Customer Ratings

```sql
SELECT 
    CASE WHEN is_late = TRUE THEN 'Late' ELSE 'On-time' END AS delivery_status,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
    ROUND(
        SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END)::NUMERIC 
        / COUNT(o.order_id) * 100, 2
    ) || '%' AS negative_review_rate
FROM olist_orders o
JOIN olist_order_reviews r ON o.order_id = r.order_id
GROUP BY delivery_status;
```

---

## Key Findings

### 1. Platform Performance
The platform processed **99,441 orders**, of which **96,478 were delivered**, resulting in a **97.02% delivery rate**. Total GMV reached **R$15.84M**, with an average order value of **R$160.58**. These results suggest strong transaction scale and generally reliable fulfillment.

### 2. Monthly Trend
The business showed rapid growth through 2017, with a major peak in **November 2017**, when monthly orders reached **8,665** and monthly GMV reached about **R$1.18M**. By 2018, monthly order volume appeared more stable, mostly in the **7,000–8,000** range.

### 3. Regional Insights
**São Paulo (SP)** was the dominant market, contributing the largest share of both orders and GMV, while also maintaining relatively strong customer experience metrics. In contrast, **Rio de Janeiro (RJ)** was also high-volume but had longer average delivery times and lower review scores, suggesting logistics pressure in an otherwise valuable market.

### 4. Category Insights
**Health & Beauty** and **Watches & Gifts** stood out as strong revenue-driving categories. At the same time, several home-related categories generated scale but showed weaker ratings and higher freight burden, indicating possible cost or fulfillment friction.

### 5. Logistics and Ratings
Delivery timeliness had one of the strongest relationships with customer satisfaction. **Late orders averaged 2.57 stars**, compared with **4.21 stars for on-time orders**. The negative review rate rose sharply from **11.38%** for on-time orders to **54.02%** for late orders. Orders taking more than **21 days** also showed a major ratings drop, suggesting a service threshold where customer patience breaks down.

### 6. Seller Segmentation
Seller performance was highly uneven. Most sellers fell into the ordinary / potential segment, while a smaller group showed clear operational risk due to weak ratings or high late-delivery rates. Only a very small share of sellers qualified as top-tier sellers under the combined criteria of scale, ratings, and delivery reliability.

### 7. Customer Retention
The platform had **93,358 unique customers**, but only **2,801 repeat customers**, producing a repeat purchase rate of just **3.00%**. Average customer value was **R$141.62**, and the top 5% customer value threshold was **R$419.81**. This suggests that the platform was capable of attracting high-spend buyers, but struggled to convert them into repeat customers.

---

## Business Recommendations
Based on the analysis, several practical actions stand out:

- prioritize logistics optimization in high-volume but weaker-experience markets such as RJ
- reduce delays on long-tail routes, especially those likely to exceed 21 days
- monitor high-risk sellers more closely, since they contribute relatively little GMV but may disproportionately damage customer experience
- use freight burden and review signals to identify categories that need fulfillment or quality improvements
- target high-spend one-time buyers with retention campaigns, since customer value concentration exists but loyalty remains weak

---

## Portfolio Value
This project demonstrates:

- end-to-end data cleaning and feature engineering
- SQL-based business analysis across multiple relational tables
- KPI design and business storytelling
- segmentation of sellers, customers, and categories
- translating analysis into actionable recommendations

---

