SELECT
    stage,
    COUNT(DISTINCT deal_id) as deal_count,
    COUNT(DISTINCT deal_id) * 100.0 / SUM(COUNT(DISTINCT deal_id)) OVER () as pct_of_total,
    LAG(COUNT(DISTINCT deal_id)) OVER (ORDER BY stage_order) as prev_stage_count,
    CAST(COUNT(DISTINCT deal_id) AS FLOAT) / NULLIF(LAG(COUNT(DISTINCT deal_id)) OVER (ORDER BY stage_order), 0) as stage_conversion
FROM sales_funnel
GROUP BY 1, stage_order
ORDER BY stage_order;