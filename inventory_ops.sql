-- Inventory & Operations Intelligence
-- Author: Irem Victor Chinonso (Prince Victor)

-- 1. Current Stock Levels with Restock Flag
-- Business Question: What items do we need to order right now to avoid stockouts?
SELECT 
    product_id,
    product_name,
    current_stock,
    reorder_threshold,
    CASE 
        WHEN current_stock <= reorder_threshold THEN 'CRITICAL: RESTOCK NOW'
        WHEN current_stock <= reorder_threshold * 1.2 THEN 'WARNING: LOW STOCK'
        ELSE 'OK'
    END AS stock_status
FROM inventory;

-- 2. Stock Velocity (Average Daily Units Sold)
-- Business Question: How fast is each product moving? (Crucial for lead time planning)
SELECT 
    product_id,
    SUM(quantity) / 30.0 AS avg_daily_velocity
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 1;

-- 3. Dead Stock Detection
-- Business Question: Which products are taking up shelf space without generating sales?
SELECT 
    i.product_id,
    i.product_name,
    i.current_stock
FROM inventory i
LEFT JOIN sales s ON i.product_id = s.product_id AND s.sale_date >= CURRENT_DATE - INTERVAL '30 days'
WHERE s.product_id IS NULL AND i.current_stock > 0;

-- 4. Supplier Performance Metrics
-- Business Question: Which suppliers are reliable and which are delaying our operations?
SELECT 
    supplier_id,
    AVG(delivery_date - order_date) AS avg_lead_time_days,
    COUNT(CASE WHEN delivery_date <= promised_date THEN 1 END)::float / COUNT(*) AS on_time_delivery_rate
FROM purchase_orders
GROUP BY 1;

-- 5. FIFO Inventory Valuation (First-In, First-Out)
-- Business Question: What is the current value of our inventory based on the oldest stock prices?
WITH stock_batches AS (
    SELECT 
        product_id,
        batch_id,
        unit_cost,
        quantity_received,
        SUM(quantity_received) OVER (PARTITION BY product_id ORDER BY received_date) AS running_total_received
    FROM supplier_deliveries
),
current_inv AS (
    SELECT product_id, current_stock FROM inventory
)
SELECT 
    sb.product_id,
    SUM(sb.unit_cost * CASE 
        WHEN sb.running_total_received <= ci.current_stock THEN sb.quantity_received
        WHEN sb.running_total_received - sb.quantity_received < ci.current_stock THEN ci.current_stock - (sb.running_total_received - sb.quantity_received)
        ELSE 0 
    END) AS fifo_valuation
FROM stock_batches sb
JOIN current_inv ci ON sb.product_id = ci.product_id
GROUP BY 1;

-- 6. Weekly Stock Movement Report
-- Business Question: How did stock levels fluctuate this week?
SELECT 
    DATE_TRUNC('week', movement_date) AS movement_week,
    product_id,
    SUM(CASE WHEN movement_type = 'IN' THEN quantity ELSE 0 END) AS total_in,
    SUM(CASE WHEN movement_type = 'OUT' THEN quantity ELSE 0 END) AS total_out,
    SUM(CASE WHEN movement_type = 'IN' THEN quantity ELSE -quantity END) AS net_movement
FROM stock_ledger
GROUP BY 1, 2;
