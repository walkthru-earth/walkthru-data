-- ============================================================================
-- Tap: dm01 (World Population Data)
-- Source: REST Countries API
-- Output: s3://walkthru-earth/dm01/
-- Catalog: SQLite-based DuckLake catalog
-- ============================================================================

-- Install extensions
INSTALL httpfs; LOAD httpfs;
INSTALL http_client FROM community; LOAD http_client;
INSTALL json; LOAD json;
INSTALL sqlite; LOAD sqlite;

-- ============================================================================
-- S3 Configuration
-- ============================================================================

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
-- DuckLake Setup (Simple & Isolated)
-- ============================================================================

-- Install DuckLake extension
INSTALL ducklake;
LOAD ducklake;

-- Attach DuckLake - Simple isolated structure
-- Catalog: s3://walkthru-earth/dm01/catalog.ducklake
-- Data:    s3://walkthru-earth/dm01/ (Hive partitions)
ATTACH 'ducklake:sqlite:data/dm01.ducklake' AS dm01_lake (
    DATA_PATH 's3://walkthru-earth/dm01/'
);

-- Create table in DuckLake (automatically versioned and snapshotted)
CREATE OR REPLACE TABLE dm01_lake.countries AS
SELECT * FROM countries_final;

-- Detach to ensure all writes are flushed
DETACH dm01_lake;

-- ============================================================================
-- Catalog Metadata (for S3 sync via workflow)
-- ============================================================================

-- Create metadata file for the catalog
-- The SQLite catalog file will be uploaded to S3 by the workflow
COPY (
    SELECT
        'dm01' AS tap_id,
        'World Population Data' AS tap_name,
        's3://walkthru-earth/dm01/' AS s3_base_path,
        's3://walkthru-earth/dm01/catalog.ducklake' AS catalog_s3_path,
        's3://walkthru-earth/dm01/data/' AS data_s3_path,
        (SELECT COUNT(*) FROM countries_final) AS total_records,
        CURRENT_TIMESTAMP AS last_updated,
        'Catalog stored locally at data/dm01.ducklake' AS note
) TO 'data/catalog_metadata.parquet';

-- ============================================================================
-- Summary
-- ============================================================================

-- Attach catalog again to read summary
ATTACH 'ducklake:sqlite:data/dm01.ducklake' AS dm01_lake (READ_ONLY);

SELECT
    'Export Complete' AS status,
    'dm01' AS dataset_id,
    'World Population Data' AS dataset_name,
    's3://walkthru-earth/dm01/' AS s3_location,
    (SELECT COUNT(*) FROM dm01_lake.countries) AS total_records,
    CURRENT_TIMESTAMP AS extracted_at
FROM (SELECT 1) AS dummy;
