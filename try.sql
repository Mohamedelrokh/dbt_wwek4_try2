SELECT * FROM {{ source('home_work3', 'external_yellow_tripdata') }}
LIMIT 1000;