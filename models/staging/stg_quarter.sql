WITH quarters AS (
    SELECT  *
     
    FROM {{ source('week4', 'quarter') }}
    order by ryear_quarter
 
)

SELECT 
 *
FROM quarters

