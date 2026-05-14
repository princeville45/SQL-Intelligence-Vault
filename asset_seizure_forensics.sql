-- SQL Intelligence Vault: Asset Seizure Forensics
-- Vibe: Authoritative | Logic: Detecting Hidden Assets

/*
This query identifies accounts with high transaction volume but low reported balances,
suggesting potential revenue leakage or hidden asset maneuvers.
The 'Financial Pivot Law' requires total transparency of capital.
*/

WITH TransactionAggregates AS (
    SELECT 
        account_id,
        SUM(amount) AS total_inflow,
        COUNT(transaction_id) AS tx_count,
        AVG(amount) AS avg_tx_value
    FROM transactions
    WHERE status = 'COMPLETED' AND type = 'CREDIT'
    GROUP BY account_id
),
RiskScoring AS (
    SELECT 
        a.account_id,
        a.reported_balance,
        ta.total_inflow,
        (ta.total_inflow / NULLIF(a.reported_balance, 0)) AS inflow_to_balance_ratio
    FROM accounts a
    JOIN TransactionAggregates ta ON a.account_id = ta.account_id
)
SELECT 
    account_id,
    reported_balance,
    total_inflow,
    inflow_to_balance_ratio,
    CASE 
        WHEN inflow_to_balance_ratio > 10 THEN 'IMMEDIATE SEIZURE REVIEW'
        WHEN inflow_to_balance_ratio > 5 THEN 'HIGH CONVICTION ANOMALY'
        ELSE 'STANDARD OPERATIONAL'
    END AS forensic_status
FROM RiskScoring
ORDER BY inflow_to_balance_ratio DESC;
