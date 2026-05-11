WITH fp AS (
    SELECT user_id, DATE_TRUNC('week', MIN(created_at)) AS cw
    FROM orders GROUP BY 1
),
wa AS (
    SELECT o.user_id, fp.cw, EXTRACT(EPOCH FROM (DATE_TRUNC('week', o.created_at) - fp.cw)) / 604800 AS wn
    FROM orders o JOIN fp ON o.user_id = fp.user_id
),
cs AS (
    SELECT cw, COUNT(DISTINCT user_id) AS tu
    FROM fp GROUP BY 1
),
ret AS (
    SELECT cw, wn, COUNT(DISTINCT user_id) AS au
    FROM wa GROUP BY 1, 2
)
SELECT r.cw, cs.tu, r.wn, r.au, ROUND(r.au::numeric / cs.tu * 100, 2) AS rr
FROM ret r JOIN cs ON r.cw = cs.cw
WHERE r.wn IN (0, 1, 2, 4, 8)
ORDER BY r.cw DESC, r.wn;
