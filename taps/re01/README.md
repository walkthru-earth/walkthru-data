# re01: Nawy Real Estate Data

Real estate compounds and developments across Egypt from Nawy.

## Quick Info

- **ID**: re01
- **Category**: Real Estate
- **Update**: Monthly (1st of month at 02:00 UTC)
- **Records**: ~1,200 compounds
- **Geography**: Egypt (country=EGY)
- **Source**: [Nawy API](https://nawy.com)

## Installation

```bash
walkthru install re01
```

## Query

```bash
# Latest data
walkthru query re01 "SELECT * FROM data WHERE year = 2025 LIMIT 10"

# Specific area
walkthru query re01 "
SELECT area_name, developer_name, COUNT(*) as compounds
FROM data
WHERE country = 'EGY'
GROUP BY area_name, developer_name
ORDER BY compounds DESC
"

# Time travel (query historical snapshot)
walkthru query re01@20251101 "SELECT COUNT(*) FROM data"
```

## Direct S3 Access

```sql
-- DuckDB
CREATE OR REPLACE SECRET s3_secret (
    TYPE S3,
    PROVIDER credential_chain,
    CHAIN 'env',
    ENDPOINT 'walkthru-earth.fsn1.your-objectstorage.com',
    URL_STYLE 'path',
    USE_SSL true
);

-- Query latest month
SELECT area_name, COUNT(*) as count
FROM 's3://walkthru-earth/re01/**/*.parquet'
WHERE country = 'EGY'
    AND year = 2025
    AND month = 11
GROUP BY area_name
ORDER BY count DESC;
```

## Schema

| Column | Type | Description |
|--------|------|-------------|
| extracted_at | TIMESTAMP | Extraction timestamp |
| year | INTEGER | Partition: Year |
| month | INTEGER | Partition: Month |
| country | VARCHAR | Partition: ISO3 code (EGY) |
| id | INTEGER | Compound ID (primary key) |
| name | VARCHAR | Compound name (English) |
| name_ar | VARCHAR | Compound name (Arabic) |
| latitude | DOUBLE | Latitude |
| longitude | DOUBLE | Longitude |
| geometry | GEOMETRY | Polygon/Point (in geo version) |
| area_name | VARCHAR | Development area |
| developer_name | VARCHAR | Developer company |
| min_price | DOUBLE | Minimum price |
| max_price | DOUBLE | Maximum price |
| currency | VARCHAR | Currency code |
| status | VARCHAR | Development status |

## S3 Layout

```
s3://walkthru-earth/re01/
├── catalog.db                    # DuckLake version history
├── country=EGY/
│   └── year=2025/
│       ├── month=10/
│       │   └── data-*.parquet
│       ├── month=11/
│       │   └── data-*.parquet
│       └── month=12/
│           └── data-*.parquet
└── _snapshots/
    ├── 20251001T020000Z/
    ├── 20251101T020000Z/
    └── 20251201T020000Z/
```

## Version History

```bash
# List all snapshots
walkthru snapshots re01

# Compare versions
walkthru diff re01@20251001 re01@20251101
```

## Files

- `tap.yaml` - Manifest
- `extract.sql` - DuckDB extraction script
- `catalog.db` - DuckLake catalog (synced to S3)

## Maintainers

- [@yharby](https://github.com/yharby)

## License

Data subject to [Nawy](https://nawy.com) terms of service.
