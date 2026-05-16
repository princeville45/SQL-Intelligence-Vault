WITH first_purchase AS (
    SELECT user_id, MIN(DATE_TRUNC('month', created_at)) as cohort_month
    FROM orders GROUP BY 1
),
retention AS (
    SELECT 
        f.cohort_month, 
        DATE_TRUNC('month', o.created_at) as activity_month,
        COUNT(DISTINCT o.user_id) as active_users
    FROM first_purchase f
    JOIN orders o ON f.user_id = o.user_id
    GROUP BY 1, 2
)
SELECT cohort_month, activity_month, active_users FROM retention ORDER BY 1, 2;