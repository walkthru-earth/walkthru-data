# Walkthru Data

Open data pipeline infrastructure for discovering, installing, and querying public datasets. Each "tap" extracts data from public sources (APIs, satellites, surveys) and publishes versioned snapshots to S3 with DuckLake catalogs.

## Quick Start

```bash
# Install CLI
pip install walkthru-data

# Search for datasets
walkthru search "real estate"

# Install a tap
walkthru install re01

# Query data
walkthru query re01 "SELECT * FROM data WHERE year = 2025 LIMIT 10"

# Time travel
walkthru query re01@20251101 "SELECT COUNT(*) FROM data"
```

## Available Taps

| ID | Name | Category | Update | Records |
|----|------|----------|--------|---------|
| [re01](taps/re01/) | Nawy Real Estate Data | Real Estate | Monthly | ~1,200 |
| [dm01](taps/dm01/) | World Population Data | Demographics | Monthly | ~250 |

## Architecture

```
walkthru-data/
├── taps/              # Dataset definitions
│   └── re01/          # Short ID: Real Estate #01
│       ├── tap.yaml   # Manifest
│       ├── extract.sql # DuckDB extraction script
│       └── catalog.db  # DuckLake version history
│
├── registry/          # Central discovery
│   ├── registry.db    # Searchable catalog
│   └── taps.json      # Index
│
├── cli/               # CLI tool
│   └── walkthru_data/
│
└── .github/workflows/ # Automated extraction
```

## S3 Storage (Simple & Isolated)

Each tap has its own S3 directory:

```
s3://walkthru-earth/
├── dm01/                                    # World Population (isolated)
│   ├── catalog.ducklake                     # SQLite catalog
│   └── main/countries/*.parquet             # Data files (DuckLake managed)
│
├── re01/                                    # Nawy Real Estate (isolated)
│   ├── catalog.ducklake                     # SQLite catalog
│   └── main/compounds/*.parquet             # Data files (DuckLake managed)
│
└── _registry/                               # Central discovery
    └── taps.json                            # Tap metadata
```

**Simple Design:**
- ✅ **Isolated**: Each tap = one S3 folder
- ✅ **No Cross-Access**: Taps can't touch other taps' data
- ✅ **Homebrew Model**: Contribute taps like homebrew formulae
- ✅ **Cloud-Native**: Hard-to-access data → easy S3 access

## Tap ID System

Format: `{category}{number}`

**Categories**:
- `re` - Real estate
- `cl` - Climate
- `dm` - Demographics
- `st` - Satellite
- `tr` - Transit
- `en` - Environment
- `if` - Infrastructure

**Examples**: `re01`, `cl01`, `dm01`, `st01`

## Contributing a Tap

```bash
# 1. Create tap structure
./scripts/create-tap.sh re02 "My Real Estate Data"

# 2. Edit manifest
cd taps/re02
vim tap.yaml

# 3. Write extraction
vim extract.sql

# 4. Test locally
walkthru tap test re02

# 5. Submit PR
git add taps/re02/
git commit -m "Add re02: My Real Estate Data"
git push origin add-re02
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Features

✅ **Short IDs**: `re01` vs `real-estate-nawy-data`
✅ **Version history**: DuckLake catalogs track all snapshots
✅ **Time travel**: Query any historical snapshot
✅ **Auto-generated workflows**: From tap.yaml manifest
✅ **CLI tool**: Install and query datasets
✅ **Searchable registry**: Find datasets quickly
✅ **Hive partitioning**: Efficient queries
✅ **Open formats**: Parquet, GeoParquet

## Technology

- **Table Format**: DuckLake (SQL-based lakehouse)
- **Query Engine**: DuckDB
- **Storage**: S3-compatible object storage
- **Compression**: Parquet with ZSTD
- **Catalogs**: SQLite per-tap + central PostgreSQL (optional)
- **CI/CD**: GitHub Actions + Hetzner Cloud runners

## Infrastructure

- **Runners**: Self-hosted on Hetzner Cloud (~98% cheaper than GitHub)
- **Storage**: S3-compatible (Hetzner Object Storage)
- **Cost**: ~$73/month for 100 datasets, 1TB storage
- **Setup**: See [SECRETS.md](SECRETS.md) for required GitHub secrets configuration

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [Tap Manifest Format](docs/TAP_MANIFEST.md)
- [CLI Reference](docs/CLI.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Roadmap](ROADMAP.md)

## License

MIT - Data subject to original sources' terms

## Credits

Built by [Walkthru Earth](https://walkthru.earth)

Powered by:
- [DuckDB](https://duckdb.org/) - Analytics engine
- [DuckLake](https://ducklake.select/) - Lakehouse format
- [Hetzner Cloud](https://www.hetzner.com/cloud) - Infrastructure
