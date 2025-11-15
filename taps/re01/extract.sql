-- ============================================================================
-- Tap: re01 (Nawy Real Estate Data)
-- Source: https://listing-api.nawy.com/v1/maps
-- Output: s3://walkthru-earth/re01/country=EGY/year=YYYY/month=MM/
-- ============================================================================

-- Install extensions
INSTALL httpfs; LOAD httpfs;
INSTALL http_client FROM community; LOAD http_client;
INSTALL json; LOAD json;
INSTALL spatial; LOAD spatial;

-- ============================================================================
-- S3 Configuration (Modern CREATE SECRET)
-- ============================================================================

-- Create secret from environment variables
-- Expects: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
CREATE OR REPLACE SECRET s3_secret (
    TYPE S3,
    PROVIDER credential_chain,
    ENDPOINT 'fsn1.your-objectstorage.com',
    URL_STYLE 'vhost',
    USE_SSL true,
    REGION 'us-east-1'
);

-- Configuration
CREATE OR REPLACE TABLE _config AS
SELECT
    'walkthru-earth' AS bucket_name,
    're01' AS tap_id,
    CURRENT_TIMESTAMP AS extracted_at,
    YEAR(CURRENT_TIMESTAMP) AS year,
    MONTH(CURRENT_TIMESTAMP) AS month,
    'EGY' AS country;

-- ============================================================================
-- Extract Data from Nawy API
-- ============================================================================

-- Step 1: Get all development areas in Egypt
CREATE OR REPLACE TABLE areas_data AS
WITH api_response AS (
    SELECT http_get(
        'https://listing-api.nawy.com/v1/maps/areas',
        headers => MAP {
            'Accept': 'application/json',
            'client-id': 'vT2CXdmtgU',
            'platform': 'web'
        },
        params => MAP {
            'topLeft[lat]': '31.5',
            'topLeft[long]': '25.0',
            'bottomRight[lat]': '22.0',
            'bottomRight[long]': '36.0'
        }
    ) AS res
)
SELECT
    value->>'id' AS area_id,
    value->>'name' AS area_name,
    ST_YMax(ST_GeomFromGeoJSON(value->'geometry')) AS max_lat,
    ST_XMin(ST_GeomFromGeoJSON(value->'geometry')) AS min_lon,
    ST_YMin(ST_GeomFromGeoJSON(value->'geometry')) AS min_lat,
    ST_XMax(ST_GeomFromGeoJSON(value->'geometry')) AS max_lon
FROM api_response, json_each((res->>'body')::JSON)
WHERE (res->>'status')::INT = 200;

-- Step 2: Create 0.03° tiles for each area to avoid API limits
CREATE OR REPLACE TABLE tiles AS
SELECT
    area_name,
    (min_lon + col_idx * 0.03) AS tl_long,
    (max_lat - row_idx * 0.03) AS tl_lat,
    LEAST(min_lon + (col_idx + 1) * 0.03, max_lon) AS br_long,
    GREATEST(max_lat - (row_idx + 1) * 0.03, min_lat) AS br_lat
FROM areas_data
CROSS JOIN generate_series(0, CAST(CEIL((max_lon - min_lon) / 0.03) AS INT) - 1) AS col_series(col_idx)
CROSS JOIN generate_series(0, CAST(CEIL((max_lat - min_lat) / 0.03) AS INT) - 1) AS row_series(row_idx);

-- Step 3: Query compounds for each tile
CREATE OR REPLACE TABLE api_responses AS
SELECT
    area_name,
    http_get(
        'https://listing-api.nawy.com/v1/maps/compounds',
        headers => MAP {
            'Accept': 'application/json',
            'client-id': 'vT2CXdmtgU',
            'platform': 'web'
        },
        params => MAP {
            'topLeft[lat]': tl_lat::VARCHAR,
            'topLeft[long]': tl_long::VARCHAR,
            'bottomRight[lat]': br_lat::VARCHAR,
            'bottomRight[long]': br_long::VARCHAR
        }
    ) AS res
FROM tiles;

-- Step 4: Parse JSON and deduplicate
CREATE OR REPLACE TABLE compounds_raw AS
WITH parsed AS (
    SELECT
        area_name,
        value AS json_data,
        ROW_NUMBER() OVER (PARTITION BY (value->>'id')::INT ORDER BY area_name) as rn
    FROM api_responses,
         json_each((res->>'body')::JSON)
    WHERE (res->>'status')::INT = 200
)
SELECT area_name, json_data
FROM parsed
WHERE rn = 1;

-- ============================================================================
-- Transform to Typed Schema
-- ============================================================================

CREATE OR REPLACE TABLE compounds_final AS
SELECT
    (SELECT extracted_at FROM _config) AS extracted_at,
    (SELECT year FROM _config) AS year,
    (SELECT month FROM _config) AS month,
    (SELECT country FROM _config) AS country,
    (json_data->>'id')::INT AS id,
    json_data->>'name' AS name,
    json_data->>'nameAr' AS name_ar,
    (json_data->>'lat')::DOUBLE AS latitude,
    (json_data->>'long')::DOUBLE AS longitude,
    CASE
        WHEN json_data->>'geometry' IS NOT NULL
        THEN ST_GeomFromGeoJSON(json_data->'geometry')
        ELSE ST_Point((json_data->>'long')::DOUBLE, (json_data->>'lat')::DOUBLE)
    END AS geometry,
    area_name,
    json_data->'developer'->>'name' AS developer_name,
    (json_data->'min_price'->>'value')::DOUBLE AS min_price,
    (json_data->'max_price'->>'value')::DOUBLE AS max_price,
    json_data->'currency'->>'code' AS currency,
    json_data->>'status' AS status
FROM compounds_raw;

-- ============================================================================
-- Export to S3 with Hive Partitioning
-- ============================================================================

-- Export Standard Parquet (without geometry)
-- Path: s3://walkthru-earth/re01/country=EGY/year=YYYY/month=MM/*.parquet
COPY (
    SELECT * EXCLUDE (geometry)
    FROM compounds_final
) TO 's3://walkthru-earth/re01'
(
    FORMAT 'PARQUET',
    PARTITION_BY (country, year, month),
    COMPRESSION 'ZSTD',
    ROW_GROUP_SIZE 100000
);

-- Export GeoParquet (with geometry)
-- Path: s3://walkthru-earth/re01-geo/country=EGY/year=YYYY/month=MM/*.parquet
COPY compounds_final
TO 's3://walkthru-earth/re01-geo'
(
    FORMAT 'PARQUET',
    PARTITION_BY (country, year, month),
    COMPRESSION 'ZSTD'
);

-- Also save locally for testing
COPY compounds_final TO 'data/re01_latest.parquet'
(FORMAT 'PARQUET', COMPRESSION 'ZSTD');

-- ============================================================================
-- Summary
-- ============================================================================

SELECT
    'Export Complete' AS status,
    (SELECT tap_id FROM _config) AS tap_id,
    COUNT(*) AS total_records,
    's3://walkthru-earth/re01/country=' || (SELECT country FROM _config) ||
        '/year=' || (SELECT year FROM _config) ||
        '/month=' || LPAD((SELECT month FROM _config)::VARCHAR, 2, '0') || '/' AS s3_location,
    (SELECT extracted_at FROM _config) AS extracted_at
FROM compounds_final;
