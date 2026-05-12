-- ============================================================
-- RevOps Analytics SQL Suite
-- Author: Irem Victor Chinonso | Statistical Business Architect
-- Date: 2026-05-12
-- Repo: SQL-Intelligence-Vault
-- ============================================================
-- Purpose: Production-grade SQL patterns for revenue operations
-- reporting — MRR tracking, ARR cohorts, expansion revenue,
-- and churn attribution.
-- ============================================================


-- SCHEMA

CREATE TABLE IF NOT EXISTS subscriptions (
    sub_id          TEXT PRIMARY KEY,
    customer_id     TEXT,
    plan_name       TEXT,
    mrr_ngn         REAL,
    start_date      TEXT,
    end_date        TEXT,
    status          TEXT,    -- active, churned, expanded, contracted
    region          TEXT
);

CREATE TABLE IF NOT EXISTS mrr_events (
    event_id        TEXT PRIMARY KEY,
    customer_id     TEXT,
    event_type      TEXT,    -- new_business, expansion, contraction, churn, reactivation
    event_date      TEXT,
    mrr_change_ngn  REAL
);


-- ============================================================
-- QUERY 1: Monthly MRR Waterfall (New + Expansion - Contraction - Churn)
-- ============================================================
SELECT
    strftime('%Y-%m', event_date)               AS month,
    SUM(CASE WHEN event_type = 'new_business'   THEN mrr_change_ngn ELSE 0 END) AS new_mrr,
    SUM(CASE WHEN event_type = 'expansion'      THEN mrr_change_ngn ELSE 0 END) AS expansion_mrr,
    SUM(CASE WHEN event_type = 'contraction'    THEN mrr_change_ngn ELSE 0 END) AS contraction_mrr,
    SUM(CASE WHEN event_type = 'churn'          THEN mrr_change_ngn ELSE 0 END) AS churned_mrr,
    SUM(CASE WHEN event_type = 'reactivation'   THEN mrr_change_ngn ELSE 0 END) AS reactivation_mrr,
    SUM(mrr_change_ngn)                                                           AS net_mrr_change
FROM mrr_events
GROUP BY strftime('%Y-%m', event_date)
ORDER BY month;


-- ============================================================
-- QUERY 2: ARR by Region (Annualized from MRR)
-- ============================================================
SELECT
    region,
    COUNT(DISTINCT customer_id)         AS active_customers,
    ROUND(SUM(mrr_ngn), 2)              AS total_mrr_ngn,
    ROUND(SUM(mrr_ngn) * 12, 2)         AS arr_ngn,
    ROUND(AVG(mrr_ngn), 2)              AS avg_mrr_per_customer
FROM subscriptions
WHERE status = 'active'
GROUP BY region
ORDER BY arr_ngn DESC;


-- ============================================================
-- QUERY 3: Expansion Revenue — Customers Who Upgraded
-- ============================================================
SELECT
    customer_id,
    COUNT(*)                            AS expansion_events,
    ROUND(SUM(mrr_change_ngn), 2)       AS total_expansion_ngn,
    MIN(event_date)                     AS first_expansion,
    MAX(event_date)                     AS last_expansion
FROM mrr_events
WHERE event_type = 'expansion'
GROUP BY customer_id
HAVING total_expansion_ngn > 0
ORDER BY total_expansion_ngn DESC
LIMIT 20;


-- ============================================================
-- QUERY 4: Churn Attribution by Plan
-- ============================================================
SELECT
    s.plan_name,
    COUNT(DISTINCT s.customer_id)                       AS churned_customers,
    ROUND(SUM(ABS(m.mrr_change_ngn)), 2)                AS revenue_lost_ngn,
    ROUND(AVG(
        julianday(s.end_date) - julianday(s.start_date)
    ), 1)                                               AS avg_tenure_days
FROM subscriptions s
JOIN mrr_events m
    ON s.customer_id = m.customer_id
    AND m.event_type = 'churn'
WHERE s.status = 'churned'
GROUP BY s.plan_name
ORDER BY revenue_lost_ngn DESC;


-- ============================================================
-- QUERY 5: Net Revenue Retention (NRR) by Cohort Month
-- ============================================================
WITH cohort_base AS (
    SELECT
        strftime('%Y-%m', start_date)   AS cohort_month,
        customer_id,
        mrr_ngn                         AS base_mrr
    FROM subscriptions
    WHERE status != 'churned'
),
cohort_current AS (
    SELECT
        strftime('%Y-%m', s.start_date) AS cohort_month,
        SUM(s.mrr_ngn)                  AS current_mrr,
        SUM(cb.base_mrr)                AS starting_mrr
    FROM subscriptions s
    JOIN cohort_base cb ON s.customer_id = cb.customer_id
    GROUP BY strftime('%Y-%m', s.start_date)
)
SELECT
    cohort_month,
    ROUND(starting_mrr, 2)                              AS starting_mrr_ngn,
    ROUND(current_mrr, 2)                               AS current_mrr_ngn,
    ROUND(current_mrr / NULLIF(starting_mrr, 0) * 100, 2) AS nrr_pct
FROM cohort_current
ORDER BY cohort_month;


-- ============================================================
-- QUERY 6: Top 10 Highest-Value Active Accounts
-- ============================================================
SELECT
    customer_id,
    plan_name,
    region,
    ROUND(mrr_ngn, 2)           AS mrr_ngn,
    ROUND(mrr_ngn * 12, 2)      AS arr_ngn,
    start_date
FROM subscriptions
WHERE status = 'active'
ORDER BY mrr_ngn DESC
LIMIT 10;
