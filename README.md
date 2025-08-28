# FitCompany eCommerce Analytics Project

## Project Overview

**The goal of this project is to evaluate the first year of operations, providing strategic guidance on product investment, and how to modernize their eCommerce efforts to meet their revenue goal and improve customer journey.**

Much like many other companies in the eCommerce space, the health and fitness supplement brand **Fit Company** wanted to assess their first year of operations and identify areas for improvement. The company enjoyed a strong first year but has ambitious goals to grow substantially in the next. The company is heavily investing in products and realize their systems and digital customer experience need to level up as well.

This analysis centers on two critical business questions:

1. **Which products should FitCompany prioritize for investment in the upcoming year?**
2. **How can they improve traffic and, ultimately, Conversion Rate Optimization (CRO)?**

## Dataset Structure

The project utilizes a relational database with four main tables:
- **customers**: Customer demographics and purchase history
- **products**: Product catalog with pricing and inventory data  
- **orders**: Transactional data with purchase details
- **fact_interactions**: Website interaction tracking data

<img width="958" height="850" alt="image" src="https://github.com/user-attachments/assets/cd73df9e-0a92-41c5-bf17-c43a11231e14" />

## Key Findings

### Product Portfolio Performance
- **Extreme revenue concentration presents significant risk**: The top 10 products generate 87.67% of total revenue, indicating a severe departure from the typical 80/20 distribution
- **Category-level concentration mirrors product-level findings**: Protein Powders and Pre-Workout categories alone drive approximately 80% of revenue despite representing only 2 of 13 active categories

  <img width="491" height="629" alt="image" src="https://github.com/user-attachments/assets/914000a1-624a-4cda-ac89-a81383115932" />

### Conversion Funnel Efficiency
- **Overall session conversion rate of 3.12%** (4,593 converting sessions from 147K total sessions)
- **Multi-stage funnel reveals optimization opportunities**: 341K product page views → 23.5K cart additions (14.5%) → 4.8K purchases (20.5% cart conversion)
- **Uniform conversion rates across categories (1.1% - 1.9%)** indicate that increased visibility for long-tail products would directly translate to revenue increases

### Traffic Source Attribution
- **Email dominates traffic**: 50%+ of total traffic with 3.45% conversion rate
- **User segmentation opportunity**: Registered users (43% traffic, 5.53% conversion) vs guests (57% traffic, 1.3% conversion)
- **Seasonal optimization potential**: Monthly AOV ranges from $47.82 (February) to $79.45 (December), showing 58% seasonal variance

## Strategic Recommendations

### Primary Recommendation: AI Recommendation System
**Revenue Impact**: 75K additional long-tail product views could generate **$47.25K additional revenue** (1,050 conversions × $45 average product price)

**Key Benefits**:
- Addresses product discovery problem for 313 underperforming products
- Industry benchmarks show 5-30% revenue improvements
- Implementation costs: $1,200-6,000 annually for plugin-based solutions

### Supporting Initiatives
1. **Data-Driven Product Catalog Expansion**: Focus on deepening successful categories rather than expanding breadth
2. **Engaging Pop-Ups**: Target 14.85% bounce rate with exit-intent campaigns
3. **Email & Social Media Priority**: Leverage highest-converting traffic sources
4. **Subscription Model**: Capitalize on repeat purchase behavior in top categories

## Technical Implementation

### Tools & Technologies
- **Data Generation**: Python (faker, numpy, pandas)
- **Data Processing**: SQL (PostgreSQL)
- **Analysis**: SQL queries, Excel EDA
- **Visualization**: Power BI Dashboard


## Key SQL Queries

### Product Performance with Pareto Analysis
```sql
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
```
<img width="886" height="314" alt="image" src="https://github.com/user-attachments/assets/b6b47e73-c8d6-45e6-8295-49d7400bdf21" />


### Conversion Funnel Analysis
```sql
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
```

<img width="409" height="89" alt="image" src="https://github.com/user-attachments/assets/23cd7f9c-025c-4781-aa10-073fe3602a0b" />

## Dashboard & Visualizations

The Power BI dashboard features:
- **Revenue concentration visualization** showing the 87/10 Pareto problem
- **Conversion funnel** with stage-by-stage drop-off analysis
- **Traffic source performance** with conversion rate comparisons
- **Seasonal trends** revealing optimization opportunities
- **Customer segmentation** insights for targeted strategies

### Dashboard Sample

<img width="1551" height="868" alt="image" src="https://github.com/user-attachments/assets/9cab594d-c1e6-4646-9c69-69b6d2efe0e7" />

## Business Impact

This analysis reveals that FitCompany has a **customer discovery problem, not a product problem**. With 313 products generating only 12% of revenue and uniform conversion rates across categories, the primary opportunity lies in helping customers find relevant products through AI-powered recommendations.

**Projected Impact**: Implementation of recommended strategies could generate $47K+ in additional annual revenue while reducing business risk from extreme revenue concentration.



**License**: MIT
