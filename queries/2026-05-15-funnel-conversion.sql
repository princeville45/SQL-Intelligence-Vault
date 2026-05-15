WITH stages AS (
    SELECT 
        user_id, 
        MIN(CASE WHEN event = 'visit' THEN timestamp END) as visited,
        MIN(CASE WHEN event = 'signup' THEN timestamp END) as signed_up,
        MIN(CASE WHEN event = 'purchase' THEN timestamp END) as purchased
    FROM user_events
    GROUP BY 1
)
SELECT 
    COUNT(visited) as total_visits,
    COUNT(signed_up) as total_signups,
    COUNT(purchased) as total_purchases,
    COUNT(signed_up)::float / NULLIF(COUNT(visited), 0) as visit_to_signup_rate,
    COUNT(purchased)::float / NULLIF(COUNT(signed_up), 0) as signup_to_purchase_rate
FROM stages;