-- Define the schema for the model (if needed)
{{ config(
    materialized='table', 
    schema='nytaxi'  
) }}


SELECT
    *
FROM
    {{ source('home_work3', 'external_yellow_tripdata') }}  -- Reference the existing table
LIMIT 1000  -- You can adjust the query to suit your needs
