-- Advanced SQL Analytics Patterns
-- Author: Irem Victor Chinonso (Prince Victor)

-- 1. CTE Chaining for Complex Pipeline Analysis
-- Business Question: Clean data, aggregate it, then filter based on aggregates in one readable flow.
WITH raw_data AS (
    SELECT * FROM transactions WHERE status = 'COMPLETED'
),
customer_metrics AS (
    SELECT 
        customer_id,
        COUNT(*) AS total_tx,
        SUM(amount) AS total_spent
    FROM raw_data
    GROUP BY 1
),
high_value_customers AS (
    SELECT * FROM customer_metrics WHERE total_spent > 5000
)
SELECT * FROM high_value_customers;

-- 2. Window Function Variety (Rankings & Distributions)
SELECT 
    product_name,
    category,
    price,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) AS unique_rank,
    RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rank_with_gaps,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS dense_rank_no_gaps,
    NTILE(4) OVER (ORDER BY price) AS price_quartile
FROM products;

-- 3. PIVOT Simulation (Rows to Columns)
-- Business Question: View sales by region as columns for a side-by-side comparison.
SELECT 
    DATE_TRUNC('month', sale_date) AS sales_month,
    SUM(CASE WHEN region = 'North' THEN amount ELSE 0 END) AS north_revenue,
    SUM(CASE WHEN region = 'South' THEN amount ELSE 0 END) AS south_revenue,
    SUM(CASE WHEN region = 'East' THEN amount ELSE 0 END) AS east_revenue,
    SUM(CASE WHEN region = 'West' THEN amount ELSE 0 END) AS west_revenue
FROM sales
GROUP BY 1;

-- 4. Recursive CTE for Hierarchical Data (Org Chart)
WITH RECURSIVE org_hierarchy AS (
    -- Anchor member
    SELECT employee_id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive member
    SELECT e.employee_id, e.name, e.manager_id, oh.level + 1
    FROM employees e
    JOIN org_hierarchy oh ON e.manager_id = oh.employee_id
)
SELECT * FROM org_hierarchy;

-- 5. JSON Extraction Pattern (PostgreSQL syntax)
-- Business Question: Extracting specific values from semi-structured data fields.
SELECT 
    event_id,
    event_data->>'user_agent' AS browser,
    event_data->'metadata'->>'ip_address' AS ip
FROM raw_events;

-- 6. Dynamic Date Filtering Patterns
-- Business Question: Compare current month to previous month without hardcoding dates.
SELECT *
FROM revenue
WHERE revenue_date >= DATE_TRUNC('month', CURRENT_DATE) -- Current Month
   OR (revenue_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') 
       AND revenue_date < DATE_TRUNC('month', CURRENT_DATE)); -- Previous Month

-- 7. Self-Join for Period-over-Period Comparison
-- Business Question: Compare each day's performance to the same day last week.
SELECT 
    t1.sale_date,
    t1.revenue AS current_rev,
    t2.revenue AS last_week_rev,
    t1.revenue - t2.revenue AS difference
FROM daily_revenue t1
JOIN daily_revenue t2 ON t1.sale_date = t2.sale_date + INTERVAL '7 days';
