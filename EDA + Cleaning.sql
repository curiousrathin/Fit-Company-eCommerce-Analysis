-- ==============
-- EDA QUERIES
-- ==============

-- 1. COUNT RECORDS IN EACH TABLE
-- ==============================
-- Check how many rows in each table
SELECT 'customers' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL  
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'fact_interactions', COUNT(*) FROM fact_interactions;

-- 2. CHECK FOR MISSING VALUES
-- ===========================
-- Count missing values in important fields
SELECT COUNT(*) as missing_customer_ids FROM customers WHERE customer_id IS NULL;
SELECT COUNT(*) as missing_cities FROM customers WHERE city IS NULL;
SELECT COUNT(*) as missing_provinces FROM customers WHERE province IS NULL;

SELECT COUNT(*) as missing_product_names FROM products WHERE product_name IS NULL;
SELECT COUNT(*) as missing_brands FROM products WHERE brand IS NULL;
SELECT COUNT(*) as missing_categories FROM products WHERE product_category IS NULL;

-- 3. LOOK FOR DUPLICATE RECORDS
-- =============================
-- Find duplicate customer IDs
SELECT customer_id, COUNT(*) as duplicate_count
FROM customers 
GROUP BY customer_id 
HAVING COUNT(*) > 1;

-- Find duplicate product IDs
SELECT product_id, COUNT(*) as duplicate_count
FROM products 
GROUP BY product_id 
HAVING COUNT(*) > 1;

-- 4. CHECK FOR BAD DATA VALUES
-- ============================
-- Find negative or zero prices
SELECT COUNT(*) as bad_prices FROM products WHERE product_price <= 0;

-- Find negative or zero order quantities  
SELECT COUNT(*) as bad_quantities FROM orders WHERE qty_ordered <= 0;

-- Find negative order values
SELECT COUNT(*) as negative_orders FROM orders WHERE total_value <= 0;

-- 5. EXAMINE BOOLEAN TEXT VALUES
-- ==============================
-- See what values are in boolean fields
SELECT DISTINCT email_subscriber FROM customers;
SELECT DISTINCT add_to_cart FROM fact_interactions;
SELECT DISTINCT bounce FROM fact_interactions;
SELECT DISTINCT will_be_purchased FROM fact_interactions;

-- 6. LOOK AT PRODUCT NAMES
-- ========================
-- See all unique product names and count them
SELECT product_name, COUNT(*) as frequency
FROM products 
GROUP BY product_name 
ORDER BY frequency DESC;

-- Check for extra spaces in product names
SELECT product_name 
FROM products 
WHERE product_name LIKE ' %' OR product_name LIKE '% ';

-- 7. EXAMINE BRAND NAMES
-- ======================
-- See all unique brands
SELECT brand, COUNT(*) as frequency
FROM products 
WHERE brand IS NOT NULL
GROUP BY brand 
ORDER BY frequency DESC;

-- Look for brands with different cases
SELECT DISTINCT brand FROM products WHERE brand IS NOT NULL ORDER BY brand;

-- 8. CHECK PRODUCT CATEGORIES
-- ===========================
-- See all categories
SELECT product_category, COUNT(*) as frequency
FROM products 
WHERE product_category IS NOT NULL
GROUP BY product_category 
ORDER BY frequency DESC;

-- 9. EXAMINE CITY NAMES  
-- =====================
-- See all cities
SELECT city, COUNT(*) as frequency
FROM customers 
WHERE city IS NOT NULL
GROUP BY city 
ORDER BY frequency DESC;

-- Look for cities that might be the same but spelled different
SELECT DISTINCT city FROM customers WHERE city IS NOT NULL ORDER BY city;

-- 10. CHECK PROVINCE VALUES
-- =========================
-- See all provinces
SELECT province, COUNT(*) as frequency
FROM customers 
WHERE province IS NOT NULL
GROUP BY province 
ORDER BY frequency DESC;

-- =========
-- CLEANING
-- =========

-- CLEAN PRODUCT NAMES
-- ===================
-- Remove extra spaces from product names
UPDATE products 
SET product_name = TRIM(product_name) 
WHERE product_name IS NOT NULL;

-- Make product names proper case
UPDATE products 
SET product_name = INITCAP(LOWER(product_name))
WHERE product_name IS NOT NULL;

-- CLEAN BRAND NAMES
-- =================
-- Remove extra spaces from brands
UPDATE products 
SET brand = TRIM(brand) 
WHERE brand IS NOT NULL;

-- Make brands proper case  
UPDATE products 
SET brand = INITCAP(LOWER(brand))
WHERE brand IS NOT NULL;

-- Fix specific brand name problems we found
UPDATE products SET brand = 'Optimum Nutrition' WHERE brand = 'Opt Nutrition';
UPDATE products SET brand = 'Optimum Nutrition' WHERE brand = 'Optimumnutrition';

-- CLEAN CATEGORIES
-- ================
-- Remove extra spaces from categories
UPDATE products 
SET product_category = TRIM(product_category) 
WHERE product_category IS NOT NULL;

-- Make categories proper case
UPDATE products 
SET product_category = INITCAP(LOWER(product_category))
WHERE product_category IS NOT NULL;

-- Fix category name problems
UPDATE products SET product_category = 'Protein Powders' WHERE product_category = 'Protein Powder';
UPDATE products SET product_category = 'Pre-Workout' WHERE product_category = 'Pre Workout';

-- CLEAN CITY NAMES
-- ================
-- Remove extra spaces from cities
UPDATE customers 
SET city = TRIM(city) 
WHERE city IS NOT NULL;

-- Make cities proper case
UPDATE customers 
SET city = INITCAP(LOWER(city))
WHERE city IS NOT NULL;

-- Fix common city name problems
UPDATE customers SET city = 'Toronto' WHERE city IN ('Torronto', 'T.O.', 'Tor');
UPDATE customers SET city = 'Vancouver' WHERE city IN ('Vancuver', 'Van');

-- CLEAN PROVINCES
-- ===============
-- Make provinces uppercase
UPDATE customers 
SET province = UPPER(TRIM(province))
WHERE province IS NOT NULL;

-- Change full province names to abbreviations
UPDATE customers SET province = 'ON' WHERE province = 'ONTARIO';
UPDATE customers SET province = 'BC' WHERE province = 'BRITISH COLUMBIA';
UPDATE customers SET province = 'AB' WHERE province = 'ALBERTA';
UPDATE customers SET province = 'QC' WHERE province = 'QUEBEC';

