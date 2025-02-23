{{
    config(
        materialized='table'
    )
}}

WITH fhv_tripdata AS (
    -- Select relevant columns from FHV data, ensuring dispatching_base_num is not NULL
    SELECT
        dispatching_base_num,
        pickup_datetime,
        dropOff_datetime,
        PUlocationID,
        DOlocationID,
        SR_Flag,
        Affiliated_base_number
    FROM {{ ref('stg_fhv') }}
    WHERE dispatching_base_num IS NOT NULL
),
dim_zones AS (
    -- Select valid zones from the dim_zones table (only those with boroughs not equal to 'Unknown')
    SELECT * 
    FROM {{ ref('dim_zones') }}
    WHERE borough != 'Unknown'
)
-- Final selection joining FHV data with zone information for both pickup and drop-off locations
SELECT 
    fhv_tripdata.dispatching_base_num,
    fhv_tripdata.pickup_datetime,
    fhv_tripdata.dropOff_datetime,
    EXTRACT(YEAR FROM fhv_tripdata.pickup_datetime) AS year,  -- New year dimension
    EXTRACT(MONTH FROM fhv_tripdata.pickup_datetime) AS month,  -- New month dimension
    fhv_tripdata.PUlocationID,
    pickup_zone.borough AS pickup_borough,
    pickup_zone.zone AS pickup_zone,
    fhv_tripdata.DOlocationID,
    dropoff_zone.borough AS dropoff_borough,
    dropoff_zone.zone AS dropoff_zone,
    fhv_tripdata.SR_Flag,
    fhv_tripdata.Affiliated_base_number
FROM fhv_tripdata
-- Join pickup zone data
INNER JOIN dim_zones AS pickup_zone
    ON fhv_tripdata.PUlocationID = pickup_zone.locationid
-- Join drop-off zone data
INNER JOIN dim_zones AS dropoff_zone
    ON fhv_tripdata.DOlocationID = dropoff_zone.locationid