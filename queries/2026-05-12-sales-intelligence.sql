-- ============================================================
-- SQL Sales Intelligence: Revenue Funnel & Conversion Analysis
-- Author: Irem Victor Chinonso | Statistical Business Architect
-- Date: 2026-05-12
-- Repo: SQL-Intelligence-Vault
-- ============================================================
-- Purpose: Analyze sales pipeline stages, conversion rates,
-- average deal sizes, and revenue leakage by stage.
-- ============================================================


-- SCHEMA SETUP (SQLite/PostgreSQL compatible)

CREATE TABLE IF NOT EXISTS sales_pipeline (
    deal_id       TEXT PRIMARY KEY,
    rep_name      TEXT,
    region        TEXT,
    stage         TEXT,         -- Prospecting, Qualified, Proposal, Negotiation, Closed Won, Closed Lost
    deal_value    REAL,
    currency      TEXT DEFAULT 'NGN',
    created_date  TEXT,
    closed_date   TEXT,
    days_in_stage INTEGER
);


-- ============================================================
-- QUERY 1: Stage-Level Funnel Volume & Total Value
-- ============================================================
SELECT
    stage,
    COUNT(deal_id)                          AS total_deals,
    ROUND(SUM(deal_value), 2)               AS total_value_ngn,
    ROUND(AVG(deal_value), 2)               AS avg_deal_size_ngn,
    ROUND(AVG(days_in_stage), 1)            AS avg_days_in_stage
FROM sales_pipeline
GROUP BY stage
ORDER BY
    CASE stage
        WHEN 'Prospecting'  THEN 1
        WHEN 'Qualified'    THEN 2
        WHEN 'Proposal'     THEN 3
        WHEN 'Negotiation'  THEN 4
        WHEN 'Closed Won'   THEN 5
        WHEN 'Closed Lost'  THEN 6
        ELSE 7
    END;


-- ============================================================
-- QUERY 2: Conversion Rate Between Stages
-- ============================================================
WITH stage_counts AS (
    SELECT
        stage,
        COUNT(deal_id) AS deal_count
    FROM sales_pipeline
    GROUP BY stage
),
ordered AS (
    SELECT
        stage,
        deal_count,
        LAG(deal_count) OVER (
            ORDER BY
                CASE stage
                    WHEN 'Prospecting'  THEN 1
                    WHEN 'Qualified'    THEN 2
                    WHEN 'Proposal'     THEN 3
                    WHEN 'Negotiation'  THEN 4
                    WHEN 'Closed Won'   THEN 5
                    ELSE 6
                END
        ) AS prev_stage_count
    FROM stage_counts
)
SELECT
    stage,
    deal_count,
    prev_stage_count,
    ROUND(
        CAST(deal_count AS REAL) / NULLIF(prev_stage_count, 0) * 100,
        2
    ) AS conversion_rate_pct
FROM ordered
WHERE prev_stage_count IS NOT NULL;


-- ============================================================
-- QUERY 3: Rep Performance — Win Rate & Revenue Contribution
-- ============================================================
SELECT
    rep_name,
    COUNT(deal_id)                                          AS total_deals,
    SUM(CASE WHEN stage = 'Closed Won'  THEN 1 ELSE 0 END) AS won,
    SUM(CASE WHEN stage = 'Closed Lost' THEN 1 ELSE 0 END) AS lost,
    ROUND(
        SUM(CASE WHEN stage = 'Closed Won' THEN 1.0 ELSE 0 END)
        / COUNT(deal_id) * 100, 2
    )                                                       AS win_rate_pct,
    ROUND(
        SUM(CASE WHEN stage = 'Closed Won' THEN deal_value ELSE 0 END), 2
    )                                                       AS revenue_won_ngn
FROM sales_pipeline
GROUP BY rep_name
ORDER BY win_rate_pct DESC;


-- ============================================================
-- QUERY 4: Revenue Leakage — Lost Deals by Stage
-- ============================================================
SELECT
    stage,
    COUNT(deal_id)                  AS lost_deals,
    ROUND(SUM(deal_value), 2)       AS revenue_lost_ngn,
    ROUND(AVG(deal_value), 2)       AS avg_lost_deal_ngn
FROM sales_pipeline
WHERE stage = 'Closed Lost'
GROUP BY stage;


-- ============================================================
-- QUERY 5: Regional Revenue Distribution
-- ============================================================
SELECT
    region,
    COUNT(deal_id)                                              AS total_deals,
    ROUND(SUM(deal_value), 2)                                   AS total_revenue_ngn,
    ROUND(AVG(deal_value), 2)                                   AS avg_deal_ngn,
    SUM(CASE WHEN stage = 'Closed Won' THEN 1 ELSE 0 END)       AS closed_won,
    ROUND(
        SUM(CASE WHEN stage = 'Closed Won' THEN deal_value ELSE 0 END), 2
    )                                                           AS won_revenue_ngn
FROM sales_pipeline
GROUP BY region
ORDER BY total_revenue_ngn DESC;


-- ============================================================
-- QUERY 6: Deals Stalled Longest in Stage (Top 10)
-- ============================================================
SELECT
    deal_id,
    rep_name,
    stage,
    deal_value,
    days_in_stage
FROM sales_pipeline
WHERE stage NOT IN ('Closed Won', 'Closed Lost')
ORDER BY days_in_stage DESC
LIMIT 10;
