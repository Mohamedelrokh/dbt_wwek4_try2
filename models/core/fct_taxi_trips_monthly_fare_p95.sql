{{
    config(
        materialized='table'
    )
}}

WITH filtered_trips AS (
    -- Filter out invalid entries
    SELECT 
        pickup_datetime,
        fare_amount,
        trip_distance,
        service_type,
        payment_type_description
    FROM {{ ref('fact_trips') }}
    WHERE 
        fare_amount > 0 
        AND trip_distance > 0
        AND UPPER(payment_type_description) IN ('CASH', 'CREDIT CARD')
), 

monthly_fare AS (
    -- Extract year and month
    SELECT 
        EXTRACT(YEAR FROM pickup_datetime) AS year,
        EXTRACT(MONTH FROM pickup_datetime) AS month,
        service_type,
        fare_amount
    FROM filtered_trips
), 

cte AS (
    -- Calculate percentiles for fare_amount
    SELECT 
        year,
        month,
        service_type,
        APPROX_QUANTILES(fare_amount, 100)[OFFSET(97)] AS p97,
        APPROX_QUANTILES(fare_amount, 100)[OFFSET(95)] AS p95,
        APPROX_QUANTILES(fare_amount, 100)[OFFSET(90)] AS p90
    FROM monthly_fare
    GROUP BY year, month, service_type
    ORDER BY service_type, year, month
)

SELECT * 
FROM cte 
WHERE year = 2020 AND month = 4