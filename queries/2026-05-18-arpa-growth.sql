WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', created_at) as month,
        COUNT(DISTINCT account_id) as active_accounts,
        SUM(amount) as total_revenue
    FROM invoices
    GROUP BY 1
)
SELECT 
    month, 
    total_revenue / active_accounts as arpa,
    LAG(total_revenue / active_accounts) OVER (ORDER BY month) as prev_arpa
FROM monthly_revenue ORDER BY month;