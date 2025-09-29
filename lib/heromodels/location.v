module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Address represents a physical address
@[heap]
pub struct Address {
pub mut:
	street      string
	city        string
	state       string // Optional state/province
	postal_code string
	country     string
	company     string // Optional company name
}

// Location represents a location entity that can contain multiple addresses
@[heap]
pub struct Location {
	db.Base
pub mut:
	addresses    []Address // Multiple addresses (home, work, etc.)
	coordinates  Coordinates // GPS coordinates
	timezone     string
	is_verified  bool
	location_type LocationType
}

// Coordinates represents GPS coordinates
@[heap]
pub struct Coordinates {
pub mut:
	latitude  f64
	longitude f64
	altitude  f64 // Optional altitude in meters
}

// LocationType represents different types of locations
pub enum LocationType {
	home
	work
	business
	delivery
	billing
	shipping
	other
}

pub struct DBLocation {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Location) type_name() string {
	return 'location'
}

// return example rpc call and result for each methodname
pub fn (self Location) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a location. Returns the ID of the location.'
		}
		'get' {
			return 'Retrieve a location by ID. Returns the location object.'
		}
		'delete' {
			return 'Delete a location by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a location exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all locations. Returns an array of location objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self Location) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"location": {"name": "Home Address", "description": "Primary residence", "addresses": [{"street": "123 Main St", "city": "Anytown", "state": "CA", "postal_code": "12345", "country": "USA", "company": ""}], "coordinates": {"latitude": 37.7749, "longitude": -122.4194, "altitude": 0}, "timezone": "America/Los_Angeles", "is_verified": true, "location_type": "home"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "Home Address", "description": "Primary residence", "addresses": [{"street": "123 Main St", "city": "Anytown", "state": "CA", "postal_code": "12345", "country": "USA", "company": ""}], "coordinates": {"latitude": 37.7749, "longitude": -122.4194, "altitude": 0}, "timezone": "America/Los_Angeles", "is_verified": true, "location_type": "home"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "Home Address", "description": "Primary residence", "addresses": [{"street": "123 Main St", "city": "Anytown", "state": "CA", "postal_code": "12345", "country": "USA", "company": ""}], "coordinates": {"latitude": 37.7749, "longitude": -122.4194, "altitude": 0}, "timezone": "America/Los_Angeles", "is_verified": true, "location_type": "home"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Address) dump(mut e encoder.Encoder) ! {
	e.add_string(self.street)
	e.add_string(self.city)
	e.add_string(self.state)
	e.add_string(self.postal_code)
	e.add_string(self.country)
	e.add_string(self.company)
}

fn (mut self Address) load(mut e encoder.Decoder) ! {
	self.street = e.get_string()!
	self.city = e.get_string()!
	self.state = e.get_string()!
	self.postal_code = e.get_string()!
	self.country = e.get_string()!
	self.company = e.get_string()!
}

pub fn (self Coordinates) dump(mut e encoder.Encoder) ! {
	e.add_f64(self.latitude)
	e.add_f64(self.longitude)
	e.add_f64(self.altitude)
}

fn (mut self Coordinates) load(mut e encoder.Decoder) ! {
	self.latitude = e.get_f64()!
	self.longitude = e.get_f64()!
	self.altitude = e.get_f64()!
}

pub fn (self Location) dump(mut e encoder.Encoder) ! {
	// Encode addresses
	e.add_u32(u32(self.addresses.len))
	for addr in self.addresses {
		addr.dump(mut e)!
	}
	
	// Encode coordinates
	self.coordinates.dump(mut e)!
	
	// Encode other fields
	e.add_string(self.timezone)
	e.add_bool(self.is_verified)
	e.add_u8(u8(self.location_type))
}

fn (mut self DBLocation) load(mut o Location, mut e encoder.Decoder) ! {
	// Decode addresses
	addr_count := e.get_u32()!
	o.addresses = []Address{cap: int(addr_count)}
	for _ in 0..addr_count {
		mut addr := Address{}
		addr.load(mut e)!
		o.addresses << addr
	}
	
	// Decode coordinates
	o.coordinates.load(mut e)!
	
	// Decode other fields
	o.timezone = e.get_string()!
	o.is_verified = e.get_bool()!
	o.location_type = LocationType(e.get_u8()!)
}

@[params]
pub struct LocationArg {
pub mut:
	name          string
	description   string
	addresses     []Address
	coordinates   Coordinates
	timezone      string
	is_verified   bool
	location_type LocationType
}

@[params]
pub struct AddressArg {
pub mut:
	street      string
	city        string
	state       string
	postal_code string
	country     string
	company     string
}

@[params]
pub struct CoordinatesArg {
pub mut:
	latitude  f64
	longitude f64
	altitude  f64
}

// Helper function to create a new address
pub fn new_address(args AddressArg) Address {
	return Address{
		street:      args.street
		city:        args.city
		state:       args.state
		postal_code: args.postal_code
		country:     args.country
		company:     args.company
	}
}

// Helper function to create new coordinates
pub fn new_coordinates(args CoordinatesArg) Coordinates {
	return Coordinates{
		latitude:  args.latitude
		longitude: args.longitude
		altitude:  args.altitude
	}
}

// get new location, not from the DB
pub fn (mut self DBLocation) new(args LocationArg) !Location {
	mut o := Location{
		addresses:     args.addresses
		coordinates:   args.coordinates
		timezone:      args.timezone
		is_verified:   args.is_verified
		location_type: args.location_type
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBLocation) set(o Location) !Location {
	// Use db set function which returns the object with assigned ID
	return self.db.set[Location](o)!
}

pub fn (mut self DBLocation) delete(id u32) ! {
	self.db.delete[Location](id)!
}

pub fn (mut self DBLocation) exist(id u32) !bool {
	return self.db.exists[Location](id)!
}

pub fn (mut self DBLocation) get(id u32) !Location {
	mut o, data := self.db.get_data[Location](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBLocation) list() ![]Location {
	return self.db.list[Location]()!.map(self.get(it)!)
}

// Helper method to add an address to a location
pub fn (mut self Location) add_address(address Address) {
	self.addresses << address
}

// Helper method to get the primary address (first address)
pub fn (self Location) primary_address() ?Address {
	if self.addresses.len > 0 {
		return self.addresses[0]
	}
	return none
}

// Helper method to format coordinates as string
pub fn (self Coordinates) to_string() string {
	return '${self.latitude}, ${self.longitude}'
}

// Helper method to check if coordinates are set
pub fn (self Coordinates) is_valid() bool {
	return self.latitude != 0.0 || self.longitude != 0.0
}