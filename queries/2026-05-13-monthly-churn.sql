WITH monthly_active AS (
    SELECT user_id, DATE_TRUNC('month', activity_date) as month
    FROM user_activity GROUP BY 1, 2
), churn_calc AS (
    SELECT a.month, COUNT(DISTINCT a.user_id) as total_users,
           COUNT(DISTINCT CASE WHEN b.user_id IS NULL THEN a.user_id END) as churned_users
    FROM monthly_active a
    LEFT JOIN monthly_active b ON a.user_id = b.user_id AND b.month = a.month + INTERVAL '1 month'
    GROUP BY 1
) SELECT month, total_users, churned_users, (churned_users::float / total_users) * 100 as churn_rate FROM churn_calc;