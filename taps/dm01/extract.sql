-- ============================================================================
-- Tap: dm01 (World Population Data)
-- Source: REST Countries API
-- Output: s3://walkthru-earth/dm01/
-- ============================================================================

-- Install extensions
INSTALL httpfs; LOAD httpfs;
INSTALL http_client FROM community; LOAD http_client;
INSTALL json; LOAD json;

-- ============================================================================
-- S3 Configuration
-- ============================================================================

CREATE OR REPLACE SECRET s3_secret (
    TYPE S3,
    PROVIDER credential_chain,
    CHAIN 'env;config',
    ENDPOINT 'walkthru-earth.fsn1.your-objectstorage.com',
    URL_STYLE 'path',
    USE_SSL true
);

-- Configuration
CREATE OR REPLACE TABLE _config AS
SELECT
    'walkthru-earth' AS bucket_name,
    'dm01' AS tap_id,
    CURRENT_TIMESTAMP AS extracted_at,
    YEAR(CURRENT_TIMESTAMP) AS year,
    MONTH(CURRENT_TIMESTAMP) AS month;

-- ============================================================================
-- Extract Data from REST Countries API
-- ============================================================================

-- Fetch all countries from REST Countries API
CREATE OR REPLACE TABLE _raw_countries AS
SELECT * FROM read_json_auto('https://restcountries.com/v3.1/all?fields=cca3,name,population,area,region,subregion,capital,latlng');

-- ============================================================================
-- Transform to Typed Schema
-- ============================================================================

CREATE OR REPLACE TABLE countries_final AS
SELECT
    (SELECT extracted_at FROM _config) AS extracted_at,
    (SELECT year FROM _config) AS year,
    (SELECT month FROM _config) AS month,
    cca3 AS country_code,  -- ISO 3166-1 alpha-3
    COALESCE(name.common, 'Unknown') AS country_name,
    COALESCE(name.official, 'Unknown') AS official_name,
    COALESCE(population, 0) AS population,
    COALESCE(area, 0.0) AS area_km2,
    COALESCE(region, 'Unknown') AS region,
    COALESCE(subregion, 'Unknown') AS subregion,
    COALESCE(capital[1], 'Unknown') AS capital,
    COALESCE(TRY_CAST(latlng[1] AS DOUBLE), 0.0) AS latitude,
    COALESCE(TRY_CAST(latlng[2] AS DOUBLE), 0.0) AS longitude
FROM _raw_countries
WHERE cca3 IS NOT NULL
ORDER BY population DESC;

-- ============================================================================
-- Export to S3 with Hive Partitioning
-- ============================================================================

-- Export partitioned data
-- Path: s3://walkthru-earth/dm01/year=YYYY/month=MM/*.parquet
COPY (
    SELECT
        country_code,
        country_name,
        official_name,
        population,
        area_km2,
        region,
        subregion,
        capital,
        latitude,
        longitude,
        extracted_at,
        year,
        month
    FROM countries_final
) TO 's3://walkthru-earth/dm01'
(
    FORMAT 'PARQUET',
    PARTITION_BY (year, month),
    COMPRESSION 'ZSTD',
    ROW_GROUP_SIZE 100000
);

-- ============================================================================
-- Export Local Copy for Verification
-- ============================================================================

COPY countries_final TO 'data/dm01_latest.parquet' (FORMAT 'PARQUET', COMPRESSION 'ZSTD');

-- ============================================================================
-- Summary
-- ============================================================================

SELECT
    'Export Complete' AS status,
    (SELECT tap_id FROM _config) AS tap_id,
    COUNT(*) AS total_records,
    's3://walkthru-earth/dm01/' AS s3_location,
    (SELECT extracted_at FROM _config) AS extracted_at
FROM countries_final;
