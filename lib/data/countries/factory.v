module countries

// --- Embed the data file content at compile time ---
// The path is relative to the location of this `factory.v` file.

// get_all_countries parses the country data embedded in the executable.
// It returns a list of Country structs.
pub fn get_all_countries() ![]Country {
	mut countries_list := []Country{}

	embedded_country_data := $embed_file('data/countryInfo.txt', .zlib).to_string()

	// --- Parse the embedded string ---
	// Use strings.split to split the text into lines
	lines := embedded_country_data.split_into_lines()
	mut found_header := false

	for line in lines {
		// --- Skip empty lines and comments ---
		trimmed_line := line.trim_space()
		if trimmed_line == '' || trimmed_line.starts_with('#') {
			continue
		}

		// --- Identify and skip the header ---
		// Check if this line looks like the header (contains key identifiers)
		if !found_header && trimmed_line.contains('ISO') && trimmed_line.contains('Country')
			&& trimmed_line.contains('CurrencyCode') {
			found_header = true
			continue // Skip the header line itself
		}

		// println("Processing line:${countries_list.len} ${line} ")

		// --- Process data lines ---
		// Use strings.split to split the line by tab character
		fields := line.split_by_space()

		// --- Create Country struct instance ---
		// Map fields by index based on the header structure.
		// Handle potential out-of-bounds or missing data gracefully using `or {}`.
		// The last field might sometimes be empty or missing in the data, handle it
		iso_field := fields[0] or { '' }
		iso3_field := fields[1] or { '' }
		iso_numeric_field := fields[2] or { '' }
		fips_field := fields[3] or { '' }
		country_name_field := fields[4] or { '' }
		capital_field := fields[5] or { '' }
		area_sqkm_field := fields[6] or { '' }
		population_field := fields[7] or { '' }
		continent_field := fields[8] or { '' }
		tld_field := fields[9] or { '' }
		currency_code_field := fields[10] or { '' }
		currency_name_field := fields[11] or { '' }
		phone_field := fields[12] or { '' }
		postal_format_field := fields[13] or { '' }
		postal_regex_field := fields[14] or { '' }
		languages_field := fields[15] or { '' }
		geonameid_field := fields[16] or { '' }
		neighbours_field := fields[17] or { '' }
		equiv_fips_code_field := fields[18] or { '' }

		country := Country{
			iso:             iso_field.trim_space()
			iso3:            iso3_field.trim_space()
			iso_numeric:     iso_numeric_field.trim_space()
			fips:            fips_field.trim_space()
			country_name:    country_name_field.trim_space()
			capital:         capital_field.trim_space()
			area_sqkm:       area_sqkm_field.trim_space()
			population:      population_field.trim_space()
			continent:       continent_field.trim_space()
			tld:             tld_field.trim_space()
			currency_code:   currency_code_field.trim_space()
			currency_name:   currency_name_field.trim_space()
			phone:           phone_field.trim_space()
			postal_format:   postal_format_field.trim_space()
			postal_regex:    postal_regex_field.trim_space()
			languages:       languages_field.trim_space()
			geonameid:       geonameid_field.trim_space()
			neighbours:      neighbours_field.trim_space()
			equiv_fips_code: equiv_fips_code_field.trim_space()
		}

		// --- Append to list ---
		countries_list << country
	}

	return countries_list
}

// Optional: Helper function to find a country by ISO code
pub fn find_country_by_iso(iso_code string) !Country {
	countries := get_all_countries()!
	for country in countries {
		if country.iso == iso_code {
			return country
		}
	}
	return error('Country with ISO code "${iso_code}" not found')
}
