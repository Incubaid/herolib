module location

// Address represents a physical address
pub struct Address {
pub mut:
	street      string  // Street address
	city        string  // City name
	state       ?string // State/province (optional)
	postal_code string  // Postal/ZIP code
	country     string  // Country name or code
	company     ?string // Company name (optional)
}

// new creates a new Address with default values
pub fn Address.new() Address {
	return Address{
		street: ''
		city: ''
		state: none
		postal_code: ''
		country: ''
		company: none
	}
}

// street sets the street address (builder pattern)
pub fn (mut a Address) street(street string) Address {
	a.street = street
	return a
}

// city sets the city (builder pattern)
pub fn (mut a Address) city(city string) Address {
	a.city = city
	return a
}

// state sets the state/province (builder pattern)
pub fn (mut a Address) state(state ?string) Address {
	a.state = state
	return a
}

// postal_code sets the postal code (builder pattern)
pub fn (mut a Address) postal_code(postal_code string) Address {
	a.postal_code = postal_code
	return a
}

// country sets the country (builder pattern)
pub fn (mut a Address) country(country string) Address {
	a.country = country
	return a
}

// company sets the company name (builder pattern)
pub fn (mut a Address) company(company ?string) Address {
	a.company = company
	return a
}

// is_complete checks if all required fields are filled
pub fn (a Address) is_complete() bool {
	return a.street.len > 0 && a.city.len > 0 && a.postal_code.len > 0 && a.country.len > 0
}

// has_state checks if the address has a state/province
pub fn (a Address) has_state() bool {
	return a.state != none
}

// has_company checks if the address has a company
pub fn (a Address) has_company() bool {
	return a.company != none
}

// format_single_line returns the address formatted as a single line
pub fn (a Address) format_single_line() string {
	mut parts := []string{}
	
	if company := a.company {
		if company.len > 0 {
			parts << company
		}
	}
	
	if a.street.len > 0 {
		parts << a.street
	}
	
	if a.city.len > 0 {
		parts << a.city
	}
	
	if state := a.state {
		if state.len > 0 {
			parts << state
		}
	}
	
	if a.postal_code.len > 0 {
		parts << a.postal_code
	}
	
	if a.country.len > 0 {
		parts << a.country
	}
	
	return parts.join(', ')
}

// format_multiline returns the address formatted as multiple lines
pub fn (a Address) format_multiline() string {
	mut lines := []string{}
	
	if company := a.company {
		if company.len > 0 {
			lines << company
		}
	}
	
	if a.street.len > 0 {
		lines << a.street
	}
	
	mut city_line := ''
	if a.city.len > 0 {
		city_line = a.city
	}
	
	if state := a.state {
		if state.len > 0 {
			if city_line.len > 0 {
				city_line += ', ${state}'
			} else {
				city_line = state
			}
		}
	}
	
	if a.postal_code.len > 0 {
		if city_line.len > 0 {
			city_line += ' ${a.postal_code}'
		} else {
			city_line = a.postal_code
		}
	}
	
	if city_line.len > 0 {
		lines << city_line
	}
	
	if a.country.len > 0 {
		lines << a.country
	}
	
	return lines.join('\n')
}

// get_state_string returns the state as a string (empty if none)
pub fn (a Address) get_state_string() string {
	return a.state or { '' }
}

// get_company_string returns the company as a string (empty if none)
pub fn (a Address) get_company_string() string {
	return a.company or { '' }
}

// equals compares two addresses for equality
pub fn (a Address) equals(other Address) bool {
	return a.street == other.street &&
		   a.city == other.city &&
		   a.state == other.state &&
		   a.postal_code == other.postal_code &&
		   a.country == other.country &&
		   a.company == other.company
}

// is_empty checks if the address is completely empty
pub fn (a Address) is_empty() bool {
	return a.street.len == 0 && 
		   a.city.len == 0 && 
		   a.postal_code.len == 0 && 
		   a.country.len == 0 &&
		   a.state == none &&
		   a.company == none
}

// validate performs basic validation on the address
pub fn (a Address) validate() !bool {
	if a.is_empty() {
		return error('Address cannot be empty')
	}
	
	if a.street.len == 0 {
		return error('Street address is required')
	}
	
	if a.city.len == 0 {
		return error('City is required')
	}
	
	if a.postal_code.len == 0 {
		return error('Postal code is required')
	}
	
	if a.country.len == 0 {
		return error('Country is required')
	}
	
	return true
}