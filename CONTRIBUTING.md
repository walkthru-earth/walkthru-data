# Contributing to Walkthru Data

Thank you for contributing! This guide will help you add a new tap (dataset).

## Quick Start

```bash
# 1. Fork and clone
git clone https://github.com/walkthru-earth/walkthru-data
cd walkthru-data

# 2. Create a new tap
./scripts/create-tap.sh <tap-id> "<Tap Name>"
# Example: ./scripts/create-tap.sh cl01 "ND-GAIN Climate Index"

# 3. Edit tap manifest
cd taps/<tap-id>
vim tap.yaml

# 4. Write extraction script
vim extract.sql

# 5. Test locally
../../scripts/test-tap.sh <tap-id>

# 6. Submit PR
git checkout -b add-<tap-id>
git add taps/<tap-id>/
git commit -m "Add <tap-id>: <Tap Name>"
git push origin add-<tap-id>
```

## Tap ID Guidelines

### Format
`{category}{number}`

### Categories
- `re` - Real estate
- `cl` - Climate
- `dm` - Demographics
- `st` - Satellite
- `tr` - Transit
- `en` - Environment
- `if` - Infrastructure

### Numbering
- Sequential within category
- Check `registry/taps.json` for next available number
- Example: `re01`, `re02`, `cl01`, `dm01`

## Tap Manifest (tap.yaml)

Required fields:

```yaml
tap:
  id: <tap-id>
  namespace: walkthru  # or 'community' for external contributors
  full_id: walkthru/<tap-id>

meta:
  name: "<Human Readable Name>"
  description: "<Short description>"
  category: <category>
  tags: [tag1, tag2, tag3]
  license: <license>
  homepage: <url>

source:
  type: api | file | satellite
  url: <source-url>

output:
  format: ducklake
  storage: s3
  bucket: walkthru-earth
  path: <tap-id>
  partitions: [country, year, month]

schedule:
  frequency: monthly | weekly | daily
  day: 1
  time: "02:00"
  timezone: UTC

extract:
  script: extract.sql
  engine: duckdb
  version: "1.4.2"
  extensions: [httpfs, spatial, json]

maintainers:
  - github: <your-github-username>
    email: <your-email>
```

See [taps/re01/tap.yaml](taps/re01/tap.yaml) for complete example.

## Extraction Script (extract.sql)

### Template

```sql
-- Install extensions
INSTALL httpfs; LOAD httpfs;
INSTALL json; LOAD json;

-- S3 Configuration
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
    '<tap-id>' AS tap_id,
    CURRENT_TIMESTAMP AS extracted_at,
    YEAR(CURRENT_TIMESTAMP) AS year,
    MONTH(CURRENT_TIMESTAMP) AS month,
    '<ISO3>' AS country;  -- if applicable

-- Extract data
CREATE OR REPLACE TABLE data_raw AS
SELECT * FROM read_json_auto('<source-url>');

-- Transform to typed schema
CREATE OR REPLACE TABLE data_final AS
SELECT
    (SELECT extracted_at FROM _config) AS extracted_at,
    -- your columns here
FROM data_raw;

-- Export to S3 with Hive partitioning
COPY data_final
TO 's3://walkthru-earth/<tap-id>'
(
    FORMAT 'PARQUET',
    PARTITION_BY (country, year, month),
    COMPRESSION 'ZSTD',
    ROW_GROUP_SIZE 100000
);

-- Save locally for testing
COPY data_final TO 'data/<tap-id>_latest.parquet'
(FORMAT 'PARQUET', COMPRESSION 'ZSTD');

-- Summary
SELECT
    'Export Complete' AS status,
    (SELECT tap_id FROM _config) AS tap_id,
    COUNT(*) AS total_records,
    's3://walkthru-earth/<tap-id>/' AS s3_location,
    (SELECT extracted_at FROM _config) AS extracted_at
FROM data_final;
```

See [taps/re01/extract.sql](taps/re01/extract.sql) for complete example.

## Testing Locally

```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Run extraction
cd taps/<tap-id>
duckdb -c ".read extract.sql"

# Verify output
duckdb -c "SELECT COUNT(*) FROM 'data/<tap-id>_latest.parquet'"
```

## PR Checklist

Before submitting your PR, ensure:

- [ ] `tap.yaml` is valid (run `./scripts/validate-tap.sh <tap-id>`)
- [ ] `extract.sql` runs without errors locally
- [ ] Output file `data/<tap-id>_latest.parquet` is created
- [ ] Record count matches expectations
- [ ] S3 path follows convention: `s3://walkthru-earth/<tap-id>/`
- [ ] README.md created in tap directory
- [ ] Schema documented in README.md
- [ ] Maintainer info is correct
- [ ] No secrets committed (check .gitignore)

## Automated Checks

On PR submission, CI will:

1. Validate `tap.yaml` schema
2. Check SQL syntax
3. Ensure unique tap ID
4. Verify S3 path convention
5. Check for secrets
6. Run extraction (dry-run)

## After Merge

Once your PR is merged:

1. Workflow file `.github/workflows/tap-<tap-id>.yml` is auto-generated
2. Tap is added to `registry/taps.json`
3. First extraction runs automatically
4. Data is published to S3
5. Tap appears in CLI (`walkthru search`)

## Questions?

- Open an issue
- Join our Discord
- Email: contrib@walkthru.earth

## Code of Conduct

Be respectful and collaborative. We're building open data infrastructure together!
