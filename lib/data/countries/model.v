module countries

// Country represents a country entry from countryInfo.txt
pub struct Country {
pub:
	iso             string // ISO
	iso3            string // ISO3
	iso_numeric     string // ISO-Numeric
	fips            string // fips
	country_name    string // Country
	capital         string // Capital
	area_sqkm       string // Area(in sq km) (Keeping as string for potential parsing issues, convert later if needed)
	population      string // Population (Keeping as string for potential parsing issues, convert later if needed)
	continent       string // Continent
	tld             string // tld
	currency_code   string // CurrencyCode
	currency_name   string // CurrencyName
	phone           string // Phone
	postal_format   string // Postal Code Format
	postal_regex    string // Postal Code Regex
	languages       string // Languages
	geonameid       string // geonameid (Keeping as string for potential parsing issues, convert later if needed)
	neighbours      string // neighbours
	equiv_fips_code string // EquivalentFipsCode
}

// Optional: Add a method for better printing/debugging
pub fn (c Country) str() string {
	return 'Country{iso: "${c.iso}", country_name: "${c.country_name}", continent: "${c.continent}", currency_code: "${c.currency_code}"}'
}
