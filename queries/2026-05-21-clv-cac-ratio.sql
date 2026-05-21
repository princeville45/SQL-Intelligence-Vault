WITH customer_revenue AS (
    SELECT customer_id, SUM(amount) as ltv
    FROM invoices GROUP BY 1
),
marketing_spend AS (
    SELECT DATE_TRUNC('month', created_at) as month, SUM(spend) as total_cac
    FROM ad_spend GROUP BY 1
)
SELECT 
    m.month,
    AVG(r.ltv) as avg_clv,
    m.total_cac / COUNT(DISTINCT r.customer_id) as cac,
    AVG(r.ltv) / (m.total_cac / NULLIF(COUNT(DISTINCT r.customer_id), 0)) as clv_cac_ratio
FROM marketing_spend m
JOIN customers c ON DATE_TRUNC('month', c.signup_date) = m.month
JOIN customer_revenue r ON c.id = r.customer_id
GROUP BY 1 ORDER BY 1 DESC;