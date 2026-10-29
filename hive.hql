DROP TABLE IF EXISTS station_month_stats;
CREATE EXTERNAL TABLE station_month_stats (
  station_id STRING,
  month STRING,
  avg_temp DOUBLE,
  max_wind_speed DOUBLE,
  no_measurements INT,
  stormy_count INT,
  temp_sum DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '${hivevar:input_dir3}';

DROP TABLE IF EXISTS stations;
CREATE EXTERNAL TABLE stations (
  station_id STRING,
  station_name STRING,
  region STRING,
  latitude DOUBLE,
  longitude DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '${hivevar:input_dir4}'
TBLPROPERTIES ('skip.header.line.count'='1');

DROP TABLE IF EXISTS region_month_stats;
CREATE EXTERNAL TABLE region_month_stats (
  region STRING,
  month STRING,
  region_month_avg_temp DOUBLE,
  region_avg_temp DOUBLE,
  avg_temp_deviation DOUBLE,
  stations_ranking ARRAY<STRUCT<station_id:STRING, rank_in_region:INT>>)
STORED AS JSONFILE
LOCATION '${hivevar:output_dir6}';

WITH station_months AS (
  SELECT s.region,
         m.month,
         m.station_id,
         avg(m.avg_temp) OVER (PARTITION BY s.region, m.station_id) AS station_avg_temp,
         row_number() OVER (PARTITION BY s.region, m.station_id ORDER BY m.month) AS station_row,
         row_number() OVER (PARTITION BY s.region, m.month ORDER BY m.station_id) AS region_month_row,
         sum(m.temp_sum) OVER (PARTITION BY s.region, m.month)
           / sum(m.no_measurements) OVER (PARTITION BY s.region, m.month) AS region_month_avg_temp,
         sum(m.temp_sum) OVER (PARTITION BY s.region)
           / sum(m.no_measurements) OVER (PARTITION BY s.region) AS region_avg_temp
  FROM station_month_stats m
  JOIN stations s ON m.station_id = s.station_id
),
station_ranking AS (
  SELECT region,
         month,
         station_id,
         station_row,
         region_month_row,
         region_month_avg_temp,
         region_avg_temp,
         CASE WHEN station_row = 1
              THEN rank() OVER (PARTITION BY region, station_row ORDER BY station_avg_temp DESC)
         END AS rank_in_region
  FROM station_months
),
region_ranking AS (
  SELECT region,
         month,
         region_month_avg_temp,
         region_avg_temp,
         region_month_row,
         collect_list(CASE WHEN station_row = 1
                           THEN named_struct('station_id', station_id, 'rank_in_region', rank_in_region)
                      END) OVER (PARTITION BY region) AS stations_ranking
  FROM station_ranking
)
INSERT OVERWRITE TABLE region_month_stats
SELECT region,
       month,
       region_month_avg_temp,
       region_avg_temp,
       region_month_avg_temp - region_avg_temp AS avg_temp_deviation,
       stations_ranking
FROM region_ranking
WHERE region_month_row = 1;
