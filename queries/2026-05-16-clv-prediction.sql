WITH user_value AS (
    SELECT user_id, SUM(amount) as total_spent, COUNT(*) as frequency
    FROM orders GROUP BY 1
),
clv_prediction AS (
    SELECT 
        user_id, 
        total_spent / frequency as avg_order_value,
        (total_spent / frequency) * (frequency * 1.2) as predicted_clv_12m
    FROM user_value
)
SELECT * FROM clv_prediction WHERE predicted_clv_12m > 1000;