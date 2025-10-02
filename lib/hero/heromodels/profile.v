module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import json

@[heap]
pub struct Profile {
	db.Base
pub mut:
	user_id  u32 // a user can have more than one profile
	summary  string
	headline string
	location string
	industry string
	// urls to profile pictures
	picture_url          string
	background_image_url string
	// contact info
	email   string
	phone   string
	website string
	// experience
	experience []Experience
	education  []Education
	skills     []string
	languages  []string
}

pub struct Experience {
pub:
	title       string
	company     string
	location    string
	start_date  u64
	end_date    u64
	current     bool
	description string
}

pub struct Education {
pub:
	school         string
	degree         string
	field_of_study string
	start_date     u64
	end_date       u64
	description    string
}

pub struct DBProfile {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Profile) type_name() string {
	return 'profile'
}

// return example rpc call and result for each methodname
pub fn (self Profile) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a profile. Returns the ID of the profile.'
		}
		'update' {
			return 'Update an existing profile. Returns the updated profile object.'
		}
		'get' {
			return 'Retrieve a profile by ID. Returns the profile object.'
		}
		'delete' {
			return 'Delete a profile by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a profile exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all profiles. Returns an array of profile objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self Profile) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"profile": {"name": "John Doe", "summary": "Software Engineer", "headline": "Building the future", "location": "San Francisco", "industry": "IT", "picture_url": "http://example.com/pic.jpg", "background_image_url": "http://example.com/bg.jpg", "email": "john.doe@example.com", "phone": "123456789", "website": "example.com", "experience": [{"title": "Software Engineer", "company": "Example Inc.", "location": "SF", "start_date": 1609459200, "end_date": 0, "current": true, "description": "Worked on stuff."}], "education": [{"school": "Example University", "degree": "BS", "field_of_study": "CS", "start_date": 1483228800, "end_date": 1609459200, "description": "Learned stuff."}], "skills": ["Vlang", "Go"], "languages": ["English"]}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "John Doe", "summary": "Software Engineer", "headline": "Building the future", "location": "San Francisco", "industry": "IT", "picture_url": "http://example.com/pic.jpg", "background_image_url": "http://example.com/bg.jpg", "email": "john.doe@example.com", "phone": "123456789", "website": "example.com", "experience": [{"title": "Software Engineer", "company": "Example Inc.", "location": "SF", "start_date": 1609459200, "end_date": 0, "current": true, "description": "Worked on stuff."}], "education": [{"school": "Example University", "degree": "BS", "field_of_study": "CS", "start_date": 1483228800, "end_date": 1609459200, "description": "Learned stuff."}], "skills": ["Vlang", "Go"], "languages": ["English"]}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "John Doe", "summary": "Software Engineer", "headline": "Building the future", "location": "San Francisco", "industry": "IT", "picture_url": "http://example.com/pic.jpg", "background_image_url": "http://example.com/bg.jpg", "email": "john.doe@example.com", "phone": "123456789", "website": "example.com", "experience": [{"title": "Software Engineer", "company": "Example Inc.", "location": "SF", "start_date": 1609459200, "end_date": 0, "current": true, "description": "Worked on stuff."}], "education": [{"school": "Example University", "degree": "BS", "field_of_study": "CS", "start_date": 1483228800, "end_date": 1609459200, "description": "Learned stuff."}], "skills": ["Vlang", "Go"], "languages": ["English"]}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Profile) dump(mut e encoder.Encoder) ! {
	e.add_u32(self.user_id)
	e.add_string(self.summary)
	e.add_string(self.headline)
	e.add_string(self.location)
	e.add_string(self.industry)
	e.add_string(self.picture_url)
	e.add_string(self.background_image_url)
	e.add_string(self.email)
	e.add_string(self.phone)
	e.add_string(self.website)
	e.add_string(json.encode_pretty(self.experience))
	e.add_string(json.encode_pretty(self.education))
	e.add_list_string(self.skills)
	e.add_list_string(self.languages)
}

fn (mut self DBProfile) load(mut o Profile, mut e encoder.Decoder) ! {
	o.user_id = e.get_u32()!
	o.summary = e.get_string()!
	o.headline = e.get_string()!
	o.location = e.get_string()!
	o.industry = e.get_string()!
	o.picture_url = e.get_string()!
	o.background_image_url = e.get_string()!
	o.email = e.get_string()!
	o.phone = e.get_string()!
	o.website = e.get_string()!
	o.experience = json.decode([]Experience, e.get_string()!)!
	o.education = json.decode([]Education, e.get_string()!)!
	o.skills = e.get_list_string()!
	o.languages = e.get_list_string()!
}

@[params]
pub struct ProfileArg {
pub mut:
	id                   u32 // Required for update, ignored for set
	name                 string
	description          string
	user_id              u32 // a user can have more than one profile
	summary              string
	headline             string
	location             string
	industry             string
	picture_url          string
	background_image_url string
	email                string
	phone                string
	website              string
	experience           []Experience
	education            []Education
	skills               []string
	languages            []string
	securitypolicy       u32
	tags                 []string
	messages             []db.MessageArg
}

// get new profile, not from the DB
pub fn (mut self DBProfile) new(args ProfileArg) !Profile {
	mut o := Profile{
		user_id:              args.user_id
		summary:              args.summary
		headline:             args.headline
		location:             args.location
		industry:             args.industry
		picture_url:          args.picture_url
		background_image_url: args.background_image_url
		email:                args.email
		phone:                args.phone
		website:              args.website
		experience:           args.experience
		education:            args.education
		skills:               args.skills
		languages:            args.languages
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBProfile) set(o Profile) !Profile {
	// Use db set function which returns the object with assigned ID
	return self.db.set[Profile](o)!
}

// update existing profile
pub fn (mut self DBProfile) update(args ProfileArg) !Profile {
	// Create new object with all the updated data
	mut updated := self.new(args)!
	// Set the ID to update existing record
	updated.id = args.id
	// Use set method which will replace the existing record
	return self.set(updated)!
}

pub fn (mut self DBProfile) delete(id u32) !bool {
	// Check if the item exists before trying to delete
	if !self.db.exists[Profile](id)! {
		return false
	}
	self.db.delete[Profile](id)!
	return true
}

pub fn (mut self DBProfile) exist(id u32) !bool {
	return self.db.exists[Profile](id)!
}

pub fn (mut self DBProfile) get(id u32) !Profile {
	mut o, data := self.db.get_data[Profile](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBProfile) list() ![]Profile {
	r := self.db.list[Profile]()!.map(self.get(it)!)
	println(r)
	return r
}

pub fn profile_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	mut converter := ResponseConverter{
		db: f.profile.db
	}

	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.profile.get(id)!
			// Use generic converter for consistent string timestamps and tags
			response_json := converter.convert_model_to_response(res)!
			return new_response(rpcid, response_json)
		}
		'set' {
			args := db.decode_generic[ProfileArg](params)!
			mut o := f.profile.new(args)!
			o = f.profile.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'update' {
			args := db.decode_generic[ProfileArg](params)!
			if args.id == 0 {
				return new_error(rpcid, code: 400, message: 'ID is required for update operation')
			}
			o := f.profile.update(args)!
			// Return updated object with string conversion
			response_json := converter.convert_model_to_response(o)!
			return new_response(rpcid, response_json)
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.profile.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'Profile with ID ${id} not found'
				)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.profile.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			res := f.profile.list()!
			// Use generic converter for consistent string timestamps and tags
			response_json := converter.convert_list_to_response(res)!
			return new_response(rpcid, response_json)
		}
		else {
			println('Method not found on profile: ${method}')
			$dbg;
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on profile'
			)
		}
	}
}
