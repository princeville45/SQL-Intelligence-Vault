WITH cohort_base AS (
    SELECT user_id, DATE_TRUNC('month', created_at) AS cohort_month
    FROM users
),
revenue_events AS (
    SELECT user_id, amount, DATE_TRUNC('month', created_at) AS event_month
    FROM transactions
)
SELECT 
    c.cohort_month, 
    r.event_month, 
    COUNT(DISTINCT c.user_id) AS cohort_size,
    SUM(r.amount) AS total_revenue,
    SUM(r.amount) / COUNT(DISTINCT c.user_id) AS ltv_per_user
FROM cohort_base c
JOIN revenue_events r ON c.user_id = r.user_id
GROUP BY 1, 2
ORDER BY 1, 2;