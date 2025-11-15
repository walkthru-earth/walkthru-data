#!/bin/bash
# Create a new tap scaffold
#
# Usage: ./scripts/create-tap.sh <tap-id> "<Tap Name>"
# Example: ./scripts/create-tap.sh cl01 "ND-GAIN Climate Index"

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <tap-id> \"<Tap Name>\""
    echo "Example: $0 cl01 \"ND-GAIN Climate Index\""
    exit 1
fi

TAP_ID=$1
TAP_NAME=$2

# Extract category from tap-id (first 2 letters)
CATEGORY_PREFIX="${TAP_ID:0:2}"

# Map prefix to category name
case "$CATEGORY_PREFIX" in
    re) CATEGORY="real-estate" ;;
    cl) CATEGORY="climate" ;;
    dm) CATEGORY="demographics" ;;
    st) CATEGORY="satellite" ;;
    tr) CATEGORY="transit" ;;
    en) CATEGORY="environment" ;;
    if) CATEGORY="infrastructure" ;;
    ec) CATEGORY="economy" ;;
    hl) CATEGORY="health" ;;
    ed) CATEGORY="education" ;;
    sc) CATEGORY="social" ;;
    ag) CATEGORY="agriculture" ;;
    eg) CATEGORY="energy" ;;
    wa) CATEGORY="water" ;;
    *)
        echo "Error: Unknown category prefix '$CATEGORY_PREFIX'"
        echo "See registry/CATEGORIES.md for valid categories"
        exit 1
        ;;
esac

# Check if tap already exists
if [ -d "taps/$TAP_ID" ]; then
    echo "Error: Tap 'taps/$TAP_ID' already exists"
    exit 1
fi

echo "Creating tap: $TAP_ID ($TAP_NAME)"
echo "Category: $CATEGORY"

# Create tap directory
mkdir -p "taps/$TAP_ID"

# Create tap.yaml
cat > "taps/$TAP_ID/tap.yaml" <<EOF
# Tap Manifest
# Format: https://walkthru-data.readthedocs.io/tap-manifest/

tap:
  id: $TAP_ID
  namespace: walkthru
  full_id: walkthru/$TAP_ID

meta:
  name: "$TAP_NAME"
  description: "TODO: Add description"
  category: $CATEGORY
  tags:
    - TODO
  license: TODO
  homepage: TODO
  source_url: TODO

source:
  type: api  # or: file, satellite
  method: http_get
  auth: none
  rate_limit: null
  coverage:
    region: TODO
    bbox:
      min_lat: 0.0
      max_lat: 0.0
      min_lon: 0.0
      max_lon: 0.0

output:
  format: ducklake
  storage: s3
  bucket: walkthru-earth
  path: $TAP_ID
  partitions:
    - country
    - year
    - month
  compression: zstd
  row_group_size: 100000

schedule:
  frequency: monthly  # monthly, weekly, daily
  day: 1
  time: "02:00"
  timezone: UTC
  enabled: true

extract:
  script: extract.sql
  engine: duckdb
  version: "1.4.2"
  extensions:
    - httpfs
    - http_client
    - json
    - spatial
  timeout_minutes: 30

runner:
  provider: hetzner
  server_type: cax11  # 2 vCPU, 4GB RAM, 40GB SSD (ARM Ampere Altra)
  architecture: arm  # arm (Ampere Altra) or x86
  image: ubuntu-24.04
  location: nbg1  # nbg1 (Nuremberg), fsn1 (Falkenstein), hel1 (Helsinki)

catalog:
  type: sqlite
  location: catalog.db
  sync_to_s3: true
  central_registry: true
  retention_snapshots: 12

schema:
  version: "1.0.0"
  fields:
    - name: extracted_at
      type: TIMESTAMP
      description: Extraction timestamp
    - name: id
      type: INTEGER
      description: TODO
      primary_key: true

maintainers:
  - github: TODO
    email: TODO

metrics:
  expected_records: 0
  expected_file_size_mb: 0
  freshness_hours: 720

created: "$(date +%Y-%m-%d)"
updated: "$(date +%Y-%m-%d)"
version: "1.0.0"
EOF

# Create extract.sql template
cat > "taps/$TAP_ID/extract.sql" <<'EOF'
-- ============================================================================
-- Tap: TODO (TODO)
-- Source: TODO
-- Output: s3://walkthru-earth/TODO/
-- ============================================================================

-- Install extensions
INSTALL httpfs; LOAD httpfs;
INSTALL http_client FROM community; LOAD http_client;
INSTALL json; LOAD json;
INSTALL spatial; LOAD spatial;

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
    'TODO' AS tap_id,
    CURRENT_TIMESTAMP AS extracted_at,
    YEAR(CURRENT_TIMESTAMP) AS year,
    MONTH(CURRENT_TIMESTAMP) AS month,
    'TODO' AS country;  -- ISO 3166-1 alpha-3

-- ============================================================================
-- Extract Data
-- ============================================================================

-- TODO: Implement extraction logic

-- ============================================================================
-- Transform to Typed Schema
-- ============================================================================

-- TODO: Transform to final schema

-- ============================================================================
-- Export to S3 with Hive Partitioning
-- ============================================================================

-- TODO: Implement export

-- ============================================================================
-- Summary
-- ============================================================================

SELECT
    'Export Complete' AS status,
    (SELECT tap_id FROM _config) AS tap_id,
    0 AS total_records,
    's3://walkthru-earth/TODO/' AS s3_location,
    (SELECT extracted_at FROM _config) AS extracted_at;
EOF

# Replace TODO placeholders with tap info
sed -i '' "s/TODO (TODO)/$TAP_ID ($TAP_NAME)/g" "taps/$TAP_ID/extract.sql"
sed -i '' "s/'TODO' AS tap_id/'$TAP_ID' AS tap_id/g" "taps/$TAP_ID/extract.sql"
sed -i '' "s|s3://walkthru-earth/TODO/|s3://walkthru-earth/$TAP_ID/|g" "taps/$TAP_ID/extract.sql"

# Create README template
cat > "taps/$TAP_ID/README.md" <<EOF
# $TAP_ID: $TAP_NAME

TODO: Short description

## Quick Info

- **ID**: $TAP_ID
- **Category**: $CATEGORY
- **Update**: TODO
- **Records**: TODO
- **Geography**: TODO
- **Source**: [TODO](TODO)

## Installation

\`\`\`bash
walkthru install $TAP_ID
\`\`\`

## Query

\`\`\`bash
# Latest data
walkthru query $TAP_ID "SELECT * FROM data LIMIT 10"
\`\`\`

## Direct S3 Access

\`\`\`sql
-- DuckDB
CREATE OR REPLACE SECRET s3_secret (
    TYPE S3,
    PROVIDER credential_chain,
    CHAIN 'env',
    ENDPOINT 'walkthru-earth.fsn1.your-objectstorage.com',
    URL_STYLE 'path',
    USE_SSL true
);

SELECT * FROM 's3://walkthru-earth/$TAP_ID/**/*.parquet' LIMIT 10;
\`\`\`

## Schema

| Column | Type | Description |
|--------|------|-------------|
| TODO | TODO | TODO |

## Files

- \`tap.yaml\` - Manifest
- \`extract.sql\` - DuckDB extraction script
- \`catalog.db\` - DuckLake catalog

## Maintainers

- [@TODO](https://github.com/TODO)

## License

TODO
EOF

echo ""
echo "✅ Tap scaffold created: taps/$TAP_ID/"
echo ""
echo "Next steps:"
echo "  1. cd taps/$TAP_ID"
echo "  2. Edit tap.yaml (fill in TODOs)"
echo "  3. Edit extract.sql (implement extraction)"
echo "  4. Edit README.md (document schema)"
echo "  5. Test: ../../scripts/test-tap.sh $TAP_ID"
echo "  6. Submit PR"
echo ""
echo "See CONTRIBUTING.md for details."
