SELECT 
    DATE_TRUNC('month', payment_date) as month,
    SUM(CASE WHEN status = 'active' THEN amount ELSE 0 END) as mrr,
    SUM(CASE WHEN status = 'new' THEN amount ELSE 0 END) as new_revenue,
    SUM(CASE WHEN status = 'churn' THEN amount ELSE 0 END) as churn_loss,
    (SUM(CASE WHEN status = 'churn' THEN amount ELSE 0 END) / NULLIF(SUM(amount), 0)) * -100 as churn_rate_pct
FROM revenue_stream
GROUP BY 1 ORDER BY 1 DESC;