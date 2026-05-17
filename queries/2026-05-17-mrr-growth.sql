SELECT 
    DATE_TRUNC('month', payment_date) as month,
    SUM(CASE WHEN transaction_type = 'new' THEN amount ELSE 0 END) as new_mrr,
    SUM(CASE WHEN transaction_type = 'expansion' THEN amount ELSE 0 END) as expansion_mrr,
    SUM(CASE WHEN transaction_type = 'churn' THEN -amount ELSE 0 END) as churn_mrr,
    SUM(amount) OVER (ORDER BY DATE_TRUNC('month', payment_date)) as total_mrr
FROM transactions
GROUP BY 1 ORDER BY 1;