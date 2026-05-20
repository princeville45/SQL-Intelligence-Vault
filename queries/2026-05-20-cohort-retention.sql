WITH monthly_active_users AS (
    SELECT account_id, DATE_TRUNC('month', activity_date) AS active_month
    FROM user_activity
    GROUP BY 1, 2
),
cohort_signup AS (
    SELECT account_id, MIN(DATE_TRUNC('month', activity_date)) AS cohort_month
    FROM user_activity
    GROUP BY 1
)
SELECT 
    c.cohort_month,
    m.active_month,
    COUNT(DISTINCT m.account_id) AS active_users
FROM cohort_signup c
JOIN monthly_active_users m ON c.account_id = m.account_id
GROUP BY 1, 2 ORDER BY 1, 2;