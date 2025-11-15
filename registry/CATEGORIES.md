# Tap Category Registry

**Complete list of official tap categories and their ID prefixes.**

## Category Reference

| Prefix | Category | Description | Examples |
|--------|----------|-------------|----------|
| `re` | **Real Estate** | Property listings, developments, land use, housing markets | re01 (Nawy Egypt), re02 (Zillow US) |
| `cl` | **Climate** | Climate data, weather, vulnerability indices, emissions | cl01 (ND-GAIN), cl02 (INFORM Risk) |
| `dm` | **Demographics** | Population, age/sex distributions, migration, census | dm01 (WorldPop), dm02 (UN Population) |
| `st` | **Satellite** | Remote sensing, imagery, nightlights, land cover | st01 (VIIRS Nightlights), st02 (Sentinel-2) |
| `tr` | **Transit** | Public transportation, routes, schedules, ridership | tr01 (Transitland), tr02 (GTFS Feeds) |
| `en` | **Environment** | Air quality, noise, pollution, water quality | en01 (OpenAQ), en02 (EEA Noise) |
| `if` | **Infrastructure** | Buildings, roads, utilities, POIs, networks | if01 (MS Buildings), if02 (OSM Roads) |
| `ec` | **Economy** | GDP, trade, business, employment, prices | ec01 (World Bank), ec02 (OECD Stats) |
| `hl` | **Health** | Disease, healthcare, mortality, nutrition | hl01 (WHO Data), hl02 (IHME GBD) |
| `ed` | **Education** | Schools, literacy, enrollment, testing | ed01 (UNESCO), ed02 (World Bank Ed) |
| `sc` | **Social** | Events, conflict, news, social media | sc01 (GDELT), sc02 (ACLED Conflict) |
| `ag` | **Agriculture** | Crops, yields, farming, food security | ag01 (FAO), ag02 (Crop Monitors) |
| `en` | **Energy** | Power generation, consumption, grids | eg01 (IEA), eg02 (Energy Atlas) |
| `wa` | **Water** | Rivers, reservoirs, consumption, quality | wa01 (USGS), wa02 (FAO Aquastat) |

## Detailed Descriptions

### re - Real Estate
**What belongs here:**
- Residential and commercial property listings
- Real estate developments and compounds
- Housing prices and market data
- Land parcels and zoning
- Rental markets

**What doesn't:**
- Building footprints (use `if` Infrastructure)
- Land cover/use from satellites (use `st` Satellite)

### cl - Climate
**What belongs here:**
- Climate vulnerability and risk indices
- Climate projections and scenarios
- Historical climate data
- Carbon emissions and sequestration
- Climate adaptation/mitigation

**What doesn't:**
- Weather forecasts (real-time, not historical)
- Satellite imagery (use `st` Satellite)

### dm - Demographics
**What belongs here:**
- Population counts and distributions
- Age, sex, ethnicity breakdowns
- Migration patterns
- Census data
- Urbanization rates

**What doesn't:**
- Health outcomes (use `hl` Health)
- Education statistics (use `ed` Education)

### st - Satellite
**What belongs here:**
- Optical imagery (Landsat, Sentinel, etc.)
- Radar imagery (SAR)
- Nighttime lights
- Land cover classifications
- Vegetation indices (NDVI, EVI)
- Elevation models (DEM)

**What doesn't:**
- Derived infrastructure (use `if` Infrastructure)
- Weather observations (use `cl` Climate)

### tr - Transit
**What belongs here:**
- Public transportation routes and schedules
- GTFS feeds
- Transit ridership
- Transportation networks
- Mobility patterns

**What doesn't:**
- Road networks (use `if` Infrastructure)
- Traffic data (use `if` Infrastructure)

### en - Environment
**What belongs here:**
- Air quality (PM2.5, NO2, O3, etc.)
- Noise pollution
- Water pollution
- Soil contamination
- Environmental monitoring

**What doesn't:**
- Climate data (use `cl` Climate)
- Land cover (use `st` Satellite)

### if - Infrastructure
**What belongs here:**
- Building footprints
- Road networks
- Utilities (water, power, telecom)
- Points of interest (POIs)
- Bridges, tunnels
- Cell towers

**What doesn't:**
- Real estate listings (use `re` Real Estate)
- Transit routes (use `tr` Transit)

### ec - Economy
**What belongs here:**
- GDP and economic indicators
- Trade flows
- Business registries
- Employment statistics
- Inflation and prices
- Financial markets

**What doesn't:**
- Real estate markets (use `re` Real Estate)
- Energy markets (use `eg` Energy)

### hl - Health
**What belongs here:**
- Disease surveillance
- Healthcare facilities
- Mortality and morbidity
- Nutrition data
- Health outcomes

**What doesn't:**
- Demographics (use `dm` Demographics)
- Environmental health factors (use `en` Environment)

### ed - Education
**What belongs here:**
- School locations and enrollment
- Literacy rates
- Test scores
- Educational attainment
- University rankings

**What doesn't:**
- Demographics (use `dm` Demographics)

### sc - Social
**What belongs here:**
- Conflict and events (GDELT, ACLED)
- Protests and demonstrations
- News archives
- Social media datasets
- Crime statistics

**What doesn't:**
- Demographics (use `dm` Demographics)
- Health (use `hl` Health)

### ag - Agriculture
**What belongs here:**
- Crop production and yields
- Farming practices
- Food security
- Agricultural prices
- Irrigation

**What doesn't:**
- Land cover (use `st` Satellite)
- Water use (use `wa` Water)

### eg - Energy
**What belongs here:**
- Power generation capacity
- Energy consumption
- Electricity grids
- Renewable energy
- Energy access

**What doesn't:**
- Carbon emissions (use `cl` Climate)

### wa - Water
**What belongs here:**
- River flows and levels
- Reservoirs and dams
- Water consumption
- Water quality
- Groundwater

**What doesn't:**
- Water pollution (use `en` Environment)
- Irrigation (use `ag` Agriculture)

## How to Choose

**Step 1**: What is the *primary* purpose of the data?
- If it's about **property markets** → `re` Real Estate
- If it's about **climate risk** → `cl` Climate
- If it's from a **satellite** → `st` Satellite

**Step 2**: Check detailed descriptions above

**Step 3**: If still unclear, ask in your PR or issue

## Requesting New Categories

To request a new category:

1. Open an issue titled "New Category: {name}"
2. Provide:
   - Proposed 2-letter prefix
   - Description
   - 3+ example datasets
   - Why existing categories don't fit
3. Maintainers will review and approve

## Multi-Category Data

If a dataset fits multiple categories:
- Choose the **primary** category
- Mention other relevant categories in `tags`

Example: Building heights
- Primary: `if` (Infrastructure)
- Tags: `[buildings, 3d, urban, satellite-derived]`

## Reserved Prefixes

These prefixes are reserved for future use:

- `mt` - Meteorology (real-time weather)
- `oc` - Ocean (marine data)
- `sp` - Space (non-Earth satellite data)
- `bi` - Biodiversity
- `cu` - Culture (heritage, tourism)
- `le` - Legal (laws, regulations)
- `go` - Government (admin boundaries, services)

## Deprecated

None yet.

## Version

Category Registry v1.0.0 (2025-11-15)
