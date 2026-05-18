SELECT 
    region,
    state,
    COUNT(DISTINCT order_id) as total_orders,
    SUM(total_amount) as total_revenue,
    SUM(total_amount) / COUNT(DISTINCT order_id) as avg_ticket
FROM orders
WHERE country = 'Nigeria'
GROUP BY 1, 2
HAVING total_revenue > 1000000
ORDER BY total_revenue DESC;