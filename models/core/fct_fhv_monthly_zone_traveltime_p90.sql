{{
    config(
        materialized='table'
    )
}}

WITH trip_data AS (
    -- Calculate trip duration in seconds
    SELECT 
        fhv.dispatching_base_num,
        fhv.pickup_datetime,
        fhv.dropOff_datetime,
        fhv.PUlocationID,
        fhv.pickup_zone,
        fhv.DOlocationID,
        fhv.dropoff_zone,
        TIMESTAMP_DIFF(fhv.dropoff_datetime, fhv.pickup_datetime, SECOND) AS trip_duration,
        EXTRACT(YEAR FROM fhv.pickup_datetime) AS year,
        EXTRACT(MONTH FROM fhv.pickup_datetime) AS month
    FROM {{ ref('dim_fhv_trips') }} AS fhv
    WHERE fhv.pickup_datetime IS NOT NULL
      AND fhv.dropoff_datetime IS NOT NULL
), 

p90 AS (
    SELECT
        pickup_zone,
        PUlocationID,
        dropoff_zone,
        DOlocationID,
        year,
        month,
        APPROX_QUANTILES(trip_duration, 100)[OFFSET(90)] AS p90_trip_duration
    FROM trip_data
    GROUP BY  
        year,
        month,
        pickup_zone,
        PUlocationID,
        dropoff_zone,
        DOlocationID
),

ranked_trips AS (
    SELECT
        pickup_zone,
        PUlocationID,
        dropoff_zone,
        DOlocationID,
        year,
        month,
        p90_trip_duration,
        ROW_NUMBER() OVER (PARTITION BY pickup_zone ,year,month ORDER BY p90_trip_duration DESC) AS trip_rank
    FROM p90
)

SELECT
    pickup_zone,
    PUlocationID,
    dropoff_zone,
    DOlocationID,
    year,
    month,
    p90_trip_duration
FROM ranked_trips
WHERE trip_rank <= 2
  AND UPPER(pickup_zone) IN ('NEWARK AIRPORT', 'SOHO', 'YORKVILLE EAST') 
  AND year = 2019 
  AND month = 11
ORDER BY pickup_zone, p90_trip_duration DESC