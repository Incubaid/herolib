# Countries Data Module

This module provides access to country information data, including ISO codes, country names, continents, currencies, and more. It parses country data from a built-in dataset and makes it available through a simple API.

## Purpose

The countries module allows you to:
- Load all country data from an embedded dataset
- Search for specific countries by ISO code
- Filter countries by continent or other attributes
- Access detailed information about countries including names, codes, currencies, and more

## Data Source

The country data is sourced from GeoNames (http://www.geonames.org), containing information about countries including:
- ISO country codes (2-letter, 3-letter, and numeric)
- Country names and capitals
- Continent information
- Currency codes and names
- Phone country codes
- Postal code formats and regex patterns
- Languages spoken
- Neighboring countries
- FIPS codes and equivalent FIPS codes

## Example Usage

```v
import freeflowuniverse.herolib.data.countries

// Get all countries
mut all_countries := countries.get_all_countries()!

println('Total countries loaded: ${all_countries.len}')

// Find a specific country by ISO code
japan := countries.find_country_by_iso('JP')!
println('Found Japan: ${japan.str()}')

// Filter countries by continent
mut eu_countries := []countries.Country{}
for country in all_countries {
    if country.continent == 'EU' {
        eu_countries << country
    }
}
println('Found ${eu_countries.len} European countries.')
```

## Country Structure

Each country entry contains the following fields:

- `iso`: ISO 2-letter country code (e.g., "BE" for Belgium)
- `iso3`: ISO 3-letter country code (e.g., "BEL" for Belgium)
- `iso_numeric`: ISO numeric country code (e.g., "056" for Belgium)
- `fips`: FIPS country code
- `country_name`: Full country name
- `capital`: Country capital city
- `area_sqkm`: Area in square kilometers
- `population`: Population count
- `continent`: Continent code (e.g., "EU" for Europe, "NA" for North America)
- `tld`: Top-level domain (e.g., ".be" for Belgium)
- `currency_code`: Currency code (e.g., "EUR" for Euro)
- `currency_name`: Full currency name
- `phone`: Phone country code
- `postal_format`: Postal code format
- `postal_regex`: Postal code validation regex
- `languages`: Languages spoken in the country
- `geonameid`: GeoNames ID
- `neighbours`: Neighboring countries (ISO codes separated by commas)
- `equiv_fips_code`: Equivalent FIPS code

## Available Functions

- `get_all_countries()`: Returns a list of all countries in the dataset
- `find_country_by_iso(iso_code string)`: Finds and returns a country by its 2-letter ISO code
