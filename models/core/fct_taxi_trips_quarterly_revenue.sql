{{
    config(
        materialized='table'
    )
}}

WITH quarterly_revenue AS (
    -- Calculate total revenue per quarter and service type
    SELECT 
        ryear_quarter,
        service_type,
        SUM(total_amount) AS revenue
    FROM {{ ref('fact_trips') }}
    GROUP BY 1, 2
),

quarterly_revenue_with_previous AS (
    -- Use LAG to calculate previous quarter's revenue
    SELECT 
        ryear_quarter AS quarter,
        revenue,
        service_type,
        LAG(revenue) OVER (PARTITION BY service_type ORDER BY ryear_quarter) AS previous_revenue
    FROM quarterly_revenue
),

quarterly_revenue_final AS (
    -- Calculate percentage change and return 0% if no previous quarter exists
    SELECT 
        quarter,
        revenue,
        service_type,
        previous_revenue,
        CASE 
            WHEN previous_revenue IS NULL THEN 0
            ELSE (revenue - previous_revenue) / previous_revenue * 100
        END AS revenue_percentage_change
    FROM quarterly_revenue_with_previous
)

-- Final select to get the desired output with quarter, revenue, percentage change, and service type
SELECT 
    quarter,
    revenue,
    previous_revenue ,
    revenue_percentage_change,
    service_type
FROM quarterly_revenue_final
ORDER BY service_type, quarter