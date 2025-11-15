# dm01: World Population Data

TODO: Short description

## Quick Info

- **ID**: dm01
- **Category**: demographics
- **Update**: TODO
- **Records**: TODO
- **Geography**: TODO
- **Source**: [TODO](TODO)

## Installation

```bash
walkthru install dm01
```

## Query

```bash
# Latest data
walkthru query dm01 "SELECT * FROM data LIMIT 10"
```

## Direct S3 Access (Simple & Efficient)

Attach the S3 catalog directly and query:

```sql
-- Configure S3 access (Hetzner Object Storage)
CREATE OR REPLACE SECRET s3_secret (
    TYPE S3,
    PROVIDER credential_chain,
    ENDPOINT 'fsn1.your-objectstorage.com',
    URL_STYLE 'vhost',
    USE_SSL true,
    REGION 'us-east-1'
);

-- Attach tap's DuckLake catalog from S3 (read-only)
ATTACH 'ducklake:sqlite:s3://walkthru-earth/dm01/catalog.ducklake' AS dm01 (READ_ONLY);

-- Query tables directly
SELECT * FROM dm01.countries LIMIT 10;

-- Filter and aggregate
SELECT region, COUNT(*) as country_count, SUM(population) as total_pop
FROM dm01.countries
GROUP BY region
ORDER BY total_pop DESC;
```

**Benefits:**
- ✅ **Simple**: One command to attach, then query like any database
- ✅ **Efficient**: DuckLake handles data layout and statistics
- ✅ **Versioned**: Snapshots and time travel built-in
- ✅ **Isolated**: Each tap is completely isolated in its own S3 folder

## Schema

| Column | Type | Description |
|--------|------|-------------|
| TODO | TODO | TODO |

## Files

- `tap.yaml` - Manifest
- `extract.sql` - DuckDB extraction script
- `catalog.db` - DuckLake catalog

## Maintainers

- [@TODO](https://github.com/TODO)

## License

TODO
