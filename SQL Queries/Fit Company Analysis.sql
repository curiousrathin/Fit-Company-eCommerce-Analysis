

-- 1.1 DATA OVERVIEW - Quick table counts
-- ======================================
SELECT 
    'customers' as table_name, 
    COUNT(*) as record_count 
FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'fact_interactions', COUNT(*) FROM fact_interactions
ORDER BY record_count DESC;

-- 1.2 BUSINESS METRICS OVERVIEW
-- =============================
SELECT 
    COUNT(DISTINCT o.session_id) as total_orders,
    COUNT(o.order_number) as total_order_items,
    ROUND(AVG(o.product_price), 2) as avg_item_price,
    ROUND(SUM(o.total_value), 2) as total_revenue,
    ROUND(AVG(o.qty_ordered), 1) as avg_quantity_per_item
FROM orders o;

-- 1.3 TOTAL SESSIONS COUNT
-- ========================
SELECT COUNT(DISTINCT session_id) as total_sessions FROM fact_interactions;

-- 1.4 OVERALL CONVERSION RATE
-- ===========================
SELECT 
    COUNT(DISTINCT session_id) as total_sessions,
    COUNT(DISTINCT CASE WHEN will_convert_to_order = 'TRUE' THEN session_id END) as converting_sessions,
    ROUND(
        COUNT(DISTINCT CASE WHEN will_convert_to_order = 'TRUE' THEN session_id END) * 100.0 / 
        COUNT(DISTINCT session_id), 2
    ) as conversion_rate_percent
FROM fact_interactions;

-- 1.5 SEASONAL TRENDS

-- SEASONAL TRENDS ANALYSIS
-- ========================
SELECT 
    EXTRACT(YEAR FROM purchase_date) as year,
    EXTRACT(MONTH FROM purchase_date) as month,
    TO_CHAR(purchase_date, 'Month') as month_name,
    
    -- Order metrics
    COUNT(DISTINCT order_number) as total_orders,
    COUNT(order_number) as total_items_sold,
    
    -- Customer metrics  
    COUNT(DISTINCT customer_id) as unique_customers,
    
    -- Revenue metrics
    ROUND(SUM(total_value), 2) as total_revenue,
    ROUND(AVG(total_value), 2) as avg_order_value,
    ROUND(SUM(total_value) / COUNT(DISTINCT customer_id), 2) as revenue_per_customer,
    
    -- Items per order
    ROUND(COUNT(order_number) * 1.0 / COUNT(DISTINCT order_number), 1) as avg_items_per_order,
    
    -- Month-over-month growth
    ROUND(
        (SUM(total_value) - LAG(SUM(total_value)) OVER (ORDER BY EXTRACT(YEAR FROM purchase_date), EXTRACT(MONTH FROM purchase_date))) * 100.0 / 
        NULLIF(LAG(SUM(total_value)) OVER (ORDER BY EXTRACT(YEAR FROM purchase_date), EXTRACT(MONTH FROM purchase_date)), 0), 
        1
    ) as mom_revenue_growth_percent

FROM orders 
WHERE purchase_date IS NOT NULL
GROUP BY 
    EXTRACT(YEAR FROM purchase_date),
    EXTRACT(MONTH FROM purchase_date),
    TO_CHAR(purchase_date, 'Month')
ORDER BY year, month;

-- =============================================================================
-- 2. PRODUCT PERFORMANCE ANALYSIS
-- =============================================================================

-- 2.1 TOP PRODUCTS WITH PARETO ANALYSIS (ROLLING TOTAL)
-- =====================================================
SELECT 
    p.product_name,
    p.product_category,
    p.brand,
    p.product_price,
    COUNT(o.order_number) as times_ordered,
    ROUND(SUM(o.total_value), 2) as total_revenue,
    ROUND(
        SUM(o.total_value) * 100.0 / 
        (SELECT SUM(total_value) FROM orders WHERE total_value IS NOT NULL), 
        2
    ) as revenue_percentage,
    ROUND(
        SUM(SUM(o.total_value)) OVER (ORDER BY SUM(o.total_value) DESC ROWS UNBOUNDED PRECEDING) * 100.0 /
        (SELECT SUM(total_value) FROM orders WHERE total_value IS NOT NULL),
        2
    ) as cumulative_percentage
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name, p.product_category, p.brand, p.product_price
ORDER BY total_revenue DESC NULLS LAST
LIMIT 15;

-- 2.2 CATEGORY PERFORMANCE BREAKDOWN
-- ==================================
SELECT 
    p.product_category,
    COUNT(DISTINCT p.product_id) as total_products,
    COUNT(o.order_number) as total_orders,
    ROUND(SUM(o.total_value), 2) as total_revenue,
    ROUND(
        SUM(o.total_value) * 100.0 / 
        (SELECT SUM(total_value) FROM orders WHERE total_value IS NOT NULL), 
        2
    ) as revenue_percentage
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_category
ORDER BY total_revenue DESC NULLS LAST;

-- 2.3 CATEGORY PERFORMANCE WITH PRICING
-- =====================================
SELECT 
    product_category,
    COUNT(DISTINCT o.session_id) as orders,
    COUNT(o.order_number) as total_items_sold,
    ROUND(SUM(o.total_value), 2) as category_revenue,
    ROUND(AVG(o.product_price), 2) as avg_price
FROM orders o
GROUP BY product_category
ORDER BY category_revenue DESC;

-- 2.4 PAGE VIEWS vs CONVERSIONS BY CATEGORY
-- =========================================
SELECT 
    p.product_category,
    COUNT(*) as total_page_views,
    COUNT(*) FILTER (WHERE fi.will_be_purchased = 'TRUE') as conversions,
    COUNT(DISTINCT fi.session_id) as unique_sessions,
    COUNT(DISTINCT p.product_id) as products_in_category,
    
    -- Conversion rate
    ROUND(
        COUNT(*) FILTER (WHERE fi.will_be_purchased = 'TRUE') * 100.0 / 
        NULLIF(COUNT(*), 0), 
        2
    ) as conversion_rate_percent,
    
    -- Sessions that converted
    ROUND(
        COUNT(DISTINCT CASE WHEN fi.will_be_purchased = 'TRUE' THEN fi.session_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT fi.session_id), 0), 
        2
    ) as session_conversion_rate,
    
    -- Page views per conversion
    ROUND(
        COUNT(*) * 1.0 / 
        NULLIF(COUNT(*) FILTER (WHERE fi.will_be_purchased = 'TRUE'), 0), 
        1
    ) as page_views_per_conversion

FROM fact_interactions fi
JOIN products p ON fi.product_id = p.product_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category
ORDER BY total_page_views DESC;

-- =============================================================================
-- 3. CONVERSION FUNNEL ANALYSIS
-- =============================================================================

-- 3.1 OVERALL CART vs PURCHASE FUNNEL SUMMARY
-- ============================================
SELECT 
    'Overall Summary' as analysis_type,
    
    -- Total product page views
    (SELECT COUNT(*) FROM fact_interactions WHERE page_type = 'product') as total_product_page_views,
    
    -- Total cart additions
    (SELECT COUNT(*) FROM fact_interactions WHERE add_to_cart = 'TRUE') as total_cart_additions,
    
    -- Total actual purchases
    (SELECT COUNT(*) FROM orders) as total_purchases,
    
    -- Overall conversion rate
    ROUND(
        (SELECT COUNT(*) FROM orders) * 100.0 / 
        NULLIF((SELECT COUNT(*) FROM fact_interactions WHERE add_to_cart = 'TRUE'), 0), 
        2
    ) as overall_cart_conversion_rate,
    
    -- Cart abandonment
    (SELECT COUNT(*) FROM fact_interactions WHERE add_to_cart = 'TRUE') - 
    (SELECT COUNT(*) FROM orders) as total_abandoned_carts;

-- 3.2 DETAILED CART vs PURCHASE CONVERSION ANALYSIS
-- =================================================
SELECT 
    COUNT(*) FILTER (WHERE add_to_cart = 'TRUE') as products_added_to_cart,
    COUNT(*) FILTER (WHERE will_be_purchased = 'TRUE') as products_purchased,
    COUNT(*) FILTER (WHERE add_to_cart = 'TRUE' AND will_be_purchased = 'TRUE') as cart_items_purchased,
    COUNT(*) FILTER (WHERE add_to_cart = 'TRUE' AND will_be_purchased = 'FALSE') as cart_items_abandoned,
    
    -- Conversion rates
    ROUND(
        COUNT(*) FILTER (WHERE will_be_purchased = 'TRUE') * 100.0 / 
        NULLIF(COUNT(*) FILTER (WHERE add_to_cart = 'TRUE'), 0), 
        2
    ) as cart_to_purchase_conversion_rate,
    
    -- Abandonment rate
    ROUND(
        COUNT(*) FILTER (WHERE add_to_cart = 'TRUE' AND will_be_purchased = 'FALSE') * 100.0 / 
        NULLIF(COUNT(*) FILTER (WHERE add_to_cart = 'TRUE'), 0), 
        2
    ) as cart_abandonment_rate
FROM fact_interactions;

-- 3.3 PRODUCT-LEVEL CART vs PURCHASE PERFORMANCE
-- ==============================================
SELECT 
    product_name,
    product_id,
    COUNT(*) FILTER (WHERE add_to_cart = 'TRUE') as times_added_to_cart,
    COUNT(*) FILTER (WHERE will_be_purchased = 'TRUE') as times_purchased,
    ROUND(
        COUNT(*) FILTER (WHERE will_be_purchased = 'TRUE') * 100.0 / 
        NULLIF(COUNT(*) FILTER (WHERE add_to_cart = 'TRUE'), 0), 
        2
    ) as conversion_rate
FROM fact_interactions
WHERE product_id IS NOT NULL
GROUP BY product_id, product_name
HAVING COUNT(*) FILTER (WHERE add_to_cart = 'TRUE') > 0
ORDER BY times_added_to_cart DESC
LIMIT 50;

-- 3.4 BOUNCE RATE ANALYSIS
-- ========================
SELECT 
    COUNT(DISTINCT session_id) as total_sessions,
    COUNT(DISTINCT CASE WHEN bounce = 'TRUE' THEN session_id END) as bounced_sessions,
    ROUND(
        COUNT(DISTINCT CASE WHEN bounce = 'TRUE' THEN session_id END) * 100.0 / 
        COUNT(DISTINCT session_id), 2
    ) as bounce_rate_percent
FROM fact_interactions;

-- =============================================================================
-- 4. TRAFFIC & CUSTOMER ANALYSIS
-- =============================================================================

-- 4.1 TRAFFIC SOURCE PERFORMANCE
-- ==============================
SELECT 
    traffic_source,
    COUNT(DISTINCT session_id) as total_sessions,
    COUNT(DISTINCT CASE WHEN will_convert_to_order = 'TRUE' THEN session_id END) as conversions,
    ROUND(
        COUNT(DISTINCT CASE WHEN will_convert_to_order = 'TRUE' THEN session_id END) * 100.0 / 
        COUNT(DISTINCT session_id), 2
    ) as conversion_rate_percent
FROM fact_interactions
GROUP BY traffic_source
ORDER BY conversions DESC;

-- 4.2 CUSTOMER TYPE ANALYSIS (REGISTERED vs GUEST)
-- =================================================
SELECT 
    customer_type,
    COUNT(DISTINCT session_id) as sessions,
    COUNT(DISTINCT CASE WHEN will_convert_to_order = 'TRUE' THEN session_id END) as conversions,
    ROUND(
        COUNT(DISTINCT CASE WHEN will_convert_to_order = 'TRUE' THEN session_id END) * 100.0 / 
        COUNT(DISTINCT session_id), 2
    ) as conversion_rate_percent
FROM fact_interactions
GROUP BY customer_type
ORDER BY conversion_rate_percent DESC;

-- 4.3 TOP CUSTOMERS BY VALUE
-- ==========================
SELECT 
    customer_id,
    total_invoiced,
    total_products_ordered,
    city,
    province
FROM customers 
WHERE total_invoiced IS NOT NULL
ORDER BY total_invoiced DESC 
LIMIT 10;

-- =============================================================================
-- 5. GROWTH OPPORTUNITIES
-- =============================================================================

-- 5.1 CROSS-SELL OPPORTUNITY ANALYSIS
-- ====================================
SELECT 
    o1.product_name as product_1,
    o2.product_name as product_2,
    COUNT(*) as times_bought_together
FROM orders o1
JOIN orders o2 ON o1.session_id = o2.session_id 
    AND o1.product_id < o2.product_id  -- Avoid duplicates
GROUP BY o1.product_name, o2.product_name
HAVING COUNT(*) > 1  -- Only show combinations that happened more than once
ORDER BY times_bought_together DESC
LIMIT 10;

-- 5.2 GEOGRAPHIC PERFORMANCE (PROVINCE ANALYSIS)
-- ==============================================
SELECT 
    c.province,
    COUNT(DISTINCT c.customer_id) as total_customers,
    COUNT(DISTINCT o.session_id) as total_orders,
    ROUND(SUM(o.total_value), 2) as total_revenue,
    ROUND(AVG(c.total_invoiced), 2) as avg_customer_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.province
ORDER BY total_revenue DESC NULLS LAST;

-- =============================================================================
-- DIAGNOSTIC QUERIES (FOR DATA VALIDATION)
-- =============================================================================

-- Check add_to_cart values
SELECT 
    add_to_cart,
    COUNT(*) as count_add_to_cart
FROM fact_interactions 
WHERE add_to_cart IS NOT NULL
GROUP BY add_to_cart
ORDER BY count_add_to_cart DESC;

-- Check will_be_purchased values
SELECT 
    will_be_purchased,
    COUNT(*) as count_will_be_purchased
FROM fact_interactions 
WHERE will_be_purchased IS NOT NULL
GROUP BY will_be_purchased
ORDER BY count_will_be_purchased DESC;

-- SIMPLIFIED FUNNEL FOR POWER BI
-- ==============================
SELECT 
    'Product Page Views' as step,
    1 as order_num,
    (SELECT COUNT(*) FROM fact_interactions WHERE page_type = 'product') as value,
    100.0 as percentage,
    NULL as conversion_rate
    
UNION ALL

SELECT 
    'Added to Cart' as step,
    2 as order_num,
    (SELECT COUNT(*) FROM fact_interactions WHERE add_to_cart = 'TRUE') as value,
    ROUND(
        (SELECT COUNT(*) FROM fact_interactions WHERE add_to_cart = 'TRUE') * 100.0 / 
        (SELECT COUNT(*) FROM fact_interactions WHERE page_type = 'product'), 
        1
    ) as percentage,
    14.5 as conversion_rate  -- Your calculated rate
    
UNION ALL

SELECT 
    'Completed Purchase' as step,
    3 as order_num,
    (SELECT COUNT(*) FROM orders) as value,
    ROUND(
        (SELECT COUNT(*) FROM orders) * 100.0 / 
        (SELECT COUNT(*) FROM fact_interactions WHERE page_type = 'product'), 
        1
    ) as percentage,
    20.5 as conversion_rate  -- Cart to purchase rate

ORDER BY order_num;