SELECT 
    c.segment,
    c.tier,
    COUNT(DISTINCT i.customer_id) as active_customers,
    SUM(i.amount) as total_revenue,
    SUM(i.amount) / NULLIF(COUNT(DISTINCT i.customer_id), 0) as arpu
FROM invoices i
JOIN customers c ON i.customer_id = c.id
WHERE i.status = 'paid'
GROUP BY 1, 2
ORDER BY arpu DESC;