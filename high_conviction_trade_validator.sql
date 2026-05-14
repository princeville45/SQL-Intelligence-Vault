-- SQL Intelligence Vault: High Conviction Trade Validator
-- Vibe: Financial-Noir | Logic: Intelligence Validation

/*
Identifies trades that deviate significantly from moving averages
during high-volatility events. These are the 'High Conviction' moves.
*/

WITH MarketBaseline AS (
    SELECT 
        symbol,
        AVG(price) OVER(PARTITION BY symbol ORDER BY trade_time ROWS BETWEEN 100 PRECEDING AND CURRENT ROW) AS moving_avg,
        STDDEV(price) OVER(PARTITION BY symbol ORDER BY trade_time ROWS BETWEEN 100 PRECEDING AND CURRENT ROW) AS volatility
    FROM market_trades
),
AnomalousTrades AS (
    SELECT 
        t.trade_id,
        t.symbol,
        t.price,
        mb.moving_avg,
        ABS(t.price - mb.moving_avg) / NULLIF(mb.volatility, 0) AS z_score
    FROM market_trades t
    JOIN MarketBaseline mb ON t.symbol = mb.symbol
)
SELECT 
    trade_id,
    symbol,
    price,
    z_score,
    CASE 
        WHEN z_score > 3 THEN 'BLACK SWAN EVENT'
        WHEN z_score > 2 THEN 'HIGH CONVICTION MOVE'
        ELSE 'MARKET NOISE'
    END AS trade_logic
FROM AnomalousTrades
WHERE z_score > 1.5
ORDER BY z_score DESC;
