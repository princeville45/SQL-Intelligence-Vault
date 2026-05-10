-- Revenue Analytics Portfolio
-- Author: Irem Victor Chinonso (Prince Victor)

-- 1. Total Revenue by Product, Region, and Month
-- Business Question: What are our core revenue drivers across different markets over time?
SELECT 
    DATE_TRUNC('month', sale_date) AS sales_month,
    region,
    product_name,
    SUM(amount) AS total_revenue,
    COUNT(order_id) AS order_count
FROM sales
GROUP BY 1, 2, 3
ORDER BY 1 DESC, 4 DESC;

-- 2. Month-over-Month (MoM) Revenue Growth
-- Business Question: Are we growing? What is the percentage change in revenue compared to last month?
WITH monthly_rev AS (
    SELECT 
        DATE_TRUNC('month', sale_date) AS sales_month,
        SUM(amount) AS revenue
    FROM sales
    GROUP BY 1
)
SELECT 
    sales_month,
    revenue,
    LAG(revenue) OVER (ORDER BY sales_month) AS prev_month_revenue,
    (revenue - LAG(revenue) OVER (ORDER BY sales_month)) / NULLIF(LAG(revenue) OVER (ORDER BY sales_month), 0) * 100 AS mom_growth_pct
FROM monthly_rev;

-- 3. Running Total Revenue (Cumulative)
-- Business Question: What is our total revenue trajectory for the year?
SELECT 
    sale_date,
    amount,
    SUM(amount) OVER (ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM sales;

-- 4. Top 5 Customers by Lifetime Value (LTV)
-- Business Question: Who are our most valuable advocates?
SELECT 
    customer_id,
    customer_name,
    SUM(amount) AS lifetime_value,
    RANK() OVER (ORDER BY SUM(amount) DESC) AS customer_rank
FROM sales
JOIN customers USING (customer_id)
GROUP BY 1, 2
QUALIFY customer_rank <= 5;

-- 5. Cohort Retention: Month 1 to Month 2
-- Business Question: Of the customers we acquired in a specific month, how many returned the following month?
WITH first_purchase AS (
    SELECT customer_id, MIN(DATE_TRUNC('month', sale_date)) AS cohort_month
    FROM sales
    GROUP BY 1
),
retention AS (
    SELECT 
        s.customer_id,
        fp.cohort_month,
        DATE_TRUNC('month', s.sale_date) AS activity_month
    FROM sales s
    JOIN first_purchase fp ON s.customer_id = fp.customer_id
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN activity_month = cohort_month + INTERVAL '1 month' THEN customer_id END) AS month_1_retention
FROM retention
GROUP BY 1;

-- 6. Sales Funnel Conversion Rates
-- Business Question: Where are we losing potential customers in the acquisition process?
WITH funnel AS (
    SELECT '1_Visit' AS stage, COUNT(DISTINCT visitor_id) AS users FROM web_logs
    UNION ALL
    SELECT '2_Add_to_Cart', COUNT(DISTINCT visitor_id) FROM cart_events
    UNION ALL
    SELECT '3_Checkout', COUNT(DISTINCT visitor_id) FROM checkout_events
    UNION ALL
    SELECT '4_Purchase', COUNT(DISTINCT visitor_id) FROM sales
)
SELECT 
    stage,
    users,
    LAG(users) OVER (ORDER BY stage) AS prev_stage_users,
    users::float / NULLIF(LAG(users) OVER (ORDER BY stage), 0) AS conversion_rate
FROM funnel;

-- 7. Flagging Underperforming Regions
-- Business Question: Which regions are failing to meet the \$10,000 monthly revenue threshold?
SELECT 
    region,
    SUM(amount) AS monthly_revenue
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY region
HAVING SUM(amount) < 10000;

-- 8. Churn Detection (90-Day Inactivity)
-- Business Question: Which customers have stopped buying from us in the last 3 months?
SELECT 
    customer_id,
    MAX(sale_date) AS last_purchase_date
FROM sales
GROUP BY 1
HAVING MAX(sale_date) < CURRENT_DATE - INTERVAL '90 days';
