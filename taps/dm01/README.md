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

SELECT * FROM 's3://walkthru-earth/dm01/**/*.parquet' LIMIT 10;
```

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
