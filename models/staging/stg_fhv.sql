{{
    config(
        materialized='table'
    )
}}

-- Select relevant data from the FHV table, filtering out rows where dispatching_base_num is NULL
SELECT
    dispatching_base_num,
    pickup_datetime,
    dropOff_datetime,
    PUlocationID,
    DOlocationID,
    SR_Flag,
    Affiliated_base_number
 from {{ source('staging','fhv') }}
WHERE dispatching_base_num IS NOT NULL