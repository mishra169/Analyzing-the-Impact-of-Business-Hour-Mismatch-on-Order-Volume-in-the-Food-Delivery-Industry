WITH grubhub_data AS (
  SELECT
    store_id AS grubhub_slug,
    JSON_EXTRACT(json_data, '$.availability_by_catalog.STANDARD_DELIVERY.schedule_rules') AS schedule_rules
  FROM
    `arboreal-vision-339901.take_home_v2.virtual_kitchen_ubereats_hours LIMIT 1000;`
),

tab_grubhub AS (
  SELECT
    grubhub_slug,
    day_of_week.value AS day_of_week,
    JSON_EXTRACT_SCALAR(rule, '$.from') AS open_time,
    JSON_EXTRACT_SCALAR(rule, '$.to') AS close_time
  FROM
    grubhub_data,
    UNNEST(JSON_EXTRACT_ARRAY(schedule_rules)) AS rule,
    UNNEST(JSON_EXTRACT_ARRAY(rule, '$.days_of_week')) AS day_of_week
),
ubereats_data AS (
  SELECT
    store_id AS ubereats_slug,
    JSON_EXTRACT(json_data, '$.menus[0].sections[0].regularHours[0].daysBitArray') AS days_bit_array,
    JSON_EXTRACT_SCALAR(json_data, '$.menus[0].sections[0].regularHours[0].startTime') AS start_time,
    JSON_EXTRACT_SCALAR(json_data, '$.menus[0].sections[0].regularHours[0].endTime') AS end_time
  FROM
    `arboreal-vision-339901.take_home_v2.virtual_kitchen_grubhub_hours LIMIT 1000;`
),
tab_ubereats AS (
  SELECT
    ubereats_slug,
    CASE
      WHEN days_bit_array[OFFSET(0)] THEN 'SUNDAY'
      WHEN days_bit_array[OFFSET(1)] THEN 'MONDAY'
      WHEN days_bit_array[OFFSET(2)] THEN 'TUESDAY'
      WHEN days_bit_array[OFFSET(3)] THEN 'WEDNESDAY'
      WHEN days_bit_array[OFFSET(4)] THEN 'THURSDAY'
      WHEN days_bit_array[OFFSET(5)] THEN 'FRIDAY'
      WHEN days_bit_array[OFFSET(6)] THEN 'SATURDAY'
    END AS day_of_week,
    start_time AS open_time,
    end_time AS close_time
  FROM
    ubereats_data,
    UNNEST([true, true, true, true, true, true, true]) AS days_bit_array
),
business_hours AS (
  SELECT
    g.grubhub_slug,
    u.ubereats_slug,
    g.day_of_week,
    TIME(TIMESTAMP(g.open_time)) AS grubhub_open_time,
    TIME(TIMESTAMP(g.close_time)) AS grubhub_close_time,
    TIME(TIMESTAMP(u.open_time)) AS ubereats_open_time,
    TIME(TIMESTAMP(u.close_time)) AS ubereats_close_time
  FROM
    tab_grubhub g
  JOIN
    tab_ubereats u
  ON
    g.grubhub_slug = u.ubereats_slug AND g.day_of_week = u.day_of_week
),
mismatch AS (
  SELECT
    grubhub_slug,
    ubereats_slug,
    day_of_week,
    grubhub_open_time,
    grubhub_close_time,
    ubereats_open_time,
    ubereats_close_time,
    TIMESTAMP_DIFF(grubhub_open_time, ubereats_open_time, MINUTE) AS open_time_diff_minutes,
    TIMESTAMP_DIFF(grubhub_close_time, ubereats_close_time, MINUTE) AS close_time_diff_minutes,
    ABS(TIMESTAMP_DIFF(grubhub_open_time, ubereats_open_time, MINUTE)) +
    ABS(TIMESTAMP_DIFF(grubhub_close_time, ubereats_close_time, MINUTE)) AS total_mismatch_minutes,
    CASE
      WHEN ABS(TIMESTAMP_DIFF(grubhub_open_time, ubereats_open_time, MINUTE)) <= 5 AND
           ABS(TIMESTAMP_DIFF(grubhub_close_time, ubereats_close_time, MINUTE)) <= 5 THEN 'In Range'
      ELSE CONCAT('Out of Range with ', 
                  ABS(TIMESTAMP_DIFF(grubhub_open_time, ubereats_open_time, MINUTE)), 
                  ' mins difference between GH and UE')
    END AS is_out_range
  FROM
    business_hours
)
SELECT
  grubhub_slug,
  day_of_week,
  FORMAT("%T - %T", grubhub_open_time, grubhub_close_time) AS `Virtual Restaurant Business Hours`,
  ubereats_slug,
  FORMAT("%T - %T", ubereats_open_time, ubereats_close_time) AS `Uber Eats Business Hours`,
  is_out_range
FROM
  mismatch
ORDER BY
  grubhub_slug, 
  day_of_week;


