module heromodels

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db
import incubaid.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import incubaid.herolib.hero.user { UserRef }
import json

// Basic enums for clarity

// Core PRD type, this is the root object
@[heap]
pub struct ProductRequirementsDoc {
	db.Base
pub mut:
	product_name string
	version      string
	overview     string
	vision       string
	goals        []Goal
	use_cases    []UseCase
	requirements []Requirement
	constraints  []Constraint
}

pub struct DBPrd {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub enum PRDPriority {
	low
	medium
	high
	critical
}

pub enum RequirementType {
	functional
	non_functional
	performance
	reliability
}

// A reusable acceptance criterion type
pub struct AcceptanceCriterion {
pub:
	id          string
	description string
	condition   string // testable condition
}

// A generic requirement type (functional or NFR)
pub struct Requirement {
pub:
	id           string
	category     string // to group requirements
	title        string
	rtype        RequirementType
	description  string
	priority     PRDPriority
	criteria     []AcceptanceCriterion
	dependencies []string // list of requirement IDs this one depends on
}

// A use case type
pub struct UseCase {
pub:
	id      string
	title   string
	actor   string
	goal    string
	steps   []string
	success string
	failure string
}

pub enum GoalType {
	product
	business
	operational
}

pub struct Goal {
pub:
	id          string
	title       string
	description string
	gtype       GoalType
}

pub enum ConstraintType {
	technica
	business
	operational
	scale
	compliance
	design
}

pub struct Constraint {
pub:
	id          string
	title       string
	description string
	ctype       ConstraintType
}

pub fn (self ProductRequirementsDoc) type_name() string {
	return 'prd'
}

pub fn (self ProductRequirementsDoc) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a product requirements document. Returns the ID of the PRD.'
		}
		'get' {
			return 'Retrieve a PRD by ID. Returns the complete PRD object.'
		}
		'delete' {
			return 'Delete a PRD by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a PRD exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all PRDs. Returns an array of PRD objects.'
		}
		else {
			return 'Generic method for PRD operations.'
		}
	}
}

pub fn (self ProductRequirementsDoc) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"product_name": "Test Product", "version": "v1.0", "overview": "A test product", "vision": "To test the system", "goals": [], "use_cases": [], "requirements": [], "constraints": []}', '1'
		}
		'get' {
			return '{"id": 1}', '{"product_name": "Test Product", "version": "v1.0", "overview": "A test product", "vision": "To test the system", "goals": [], "use_cases": [], "requirements": [], "constraints": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"product_name": "Test Product", "version": "v1.0"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self ProductRequirementsDoc) dump(mut e encoder.Encoder) ! {
	e.add_string(self.product_name)
	e.add_string(self.version)
	e.add_string(self.overview)
	e.add_string(self.vision)

	// Encode goals array
	e.add_u16(u16(self.goals.len))
	for goal in self.goals {
		e.add_string(goal.id)
		e.add_string(goal.title)
		e.add_string(goal.description)
		e.add_u8(u8(goal.gtype))
	}

	// Encode use_cases array
	e.add_u16(u16(self.use_cases.len))
	for uc in self.use_cases {
		e.add_string(uc.id)
		e.add_string(uc.title)
		e.add_string(uc.actor)
		e.add_string(uc.goal)
		e.add_list_string(uc.steps)
		e.add_string(uc.success)
		e.add_string(uc.failure)
	}

	// Encode requirements array
	e.add_u16(u16(self.requirements.len))
	for req in self.requirements {
		e.add_string(req.id)
		e.add_string(req.category)
		e.add_string(req.title)
		e.add_u8(u8(req.rtype))
		e.add_string(req.description)
		e.add_u8(u8(req.priority))

		// Encode acceptance criteria
		e.add_u16(u16(req.criteria.len))
		for criterion in req.criteria {
			e.add_string(criterion.id)
			e.add_string(criterion.description)
			e.add_string(criterion.condition)
		}

		// Encode dependencies
		e.add_list_string(req.dependencies)
	}

	// Encode constraints array
	e.add_u16(u16(self.constraints.len))
	for constraint in self.constraints {
		e.add_string(constraint.id)
		e.add_string(constraint.title)
		e.add_string(constraint.description)
		e.add_u8(u8(constraint.ctype))
	}
}

pub fn (mut self DBPrd) load(mut o ProductRequirementsDoc, mut e encoder.Decoder) ! {
	o.product_name = e.get_string()!
	o.version = e.get_string()!
	o.overview = e.get_string()!
	o.vision = e.get_string()!

	// Decode goals
	goals_len := e.get_u16()!
	mut goals := []Goal{}
	for _ in 0 .. goals_len {
		goals << Goal{
			id:          e.get_string()!
			title:       e.get_string()!
			description: e.get_string()!
			gtype:       unsafe { GoalType(e.get_u8()!) }
		}
	}
	o.goals = goals

	// Decode use_cases
	use_cases_len := e.get_u16()!
	mut use_cases := []UseCase{}
	for _ in 0 .. use_cases_len {
		use_cases << UseCase{
			id:      e.get_string()!
			title:   e.get_string()!
			actor:   e.get_string()!
			goal:    e.get_string()!
			steps:   e.get_list_string()!
			success: e.get_string()!
			failure: e.get_string()!
		}
	}
	o.use_cases = use_cases

	// Decode requirements
	requirements_len := e.get_u16()!
	mut requirements := []Requirement{}
	for _ in 0 .. requirements_len {
		req_id := e.get_string()!
		req_category := e.get_string()!
		req_title := e.get_string()!
		req_rtype := unsafe { RequirementType(e.get_u8()!) }
		req_description := e.get_string()!
		req_priority := unsafe { PRDPriority(e.get_u8()!) }

		// Decode criteria
		criteria_len := e.get_u16()!
		mut criteria := []AcceptanceCriterion{}
		for _ in 0 .. criteria_len {
			criteria << AcceptanceCriterion{
				id:          e.get_string()!
				description: e.get_string()!
				condition:   e.get_string()!
			}
		}

		// Decode dependencies
		dependencies := e.get_list_string()!

		requirements << Requirement{
			id:           req_id
			category:     req_category
			title:        req_title
			rtype:        req_rtype
			description:  req_description
			priority:     req_priority
			criteria:     criteria
			dependencies: dependencies
		}
	}
	o.requirements = requirements

	// Decode constraints
	constraints_len := e.get_u16()!
	mut constraints := []Constraint{}
	for _ in 0 .. constraints_len {
		constraints << Constraint{
			id:          e.get_string()!
			title:       e.get_string()!
			description: e.get_string()!
			ctype:       unsafe { ConstraintType(e.get_u8()!) }
		}
	}
	o.constraints = constraints
}

@[params]
pub struct PrdArg {
pub mut:
	id             u32
	product_name   string @[required]
	version        string
	overview       string
	vision         string
	goals          []Goal
	use_cases      []UseCase
	requirements   []Requirement
	constraints    []Constraint
	securitypolicy u32
	tags           []string
}

pub fn (mut self DBPrd) new(args PrdArg) !ProductRequirementsDoc {
	mut o := ProductRequirementsDoc{
		product_name: args.product_name
		version:      args.version
		overview:     args.overview
		vision:       args.vision
		goals:        args.goals
		use_cases:    args.use_cases
		requirements: args.requirements
		constraints:  args.constraints
		updated_at:   ourtime.now().unix()
	}

	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!

	return o
}

pub fn (mut self DBPrd) set(o ProductRequirementsDoc) !ProductRequirementsDoc {
	return self.db.set[ProductRequirementsDoc](o)!
}

pub fn (mut self DBPrd) delete(id u32) !bool {
	if !self.db.exists[ProductRequirementsDoc](id)! {
		return false
	}
	self.db.delete[ProductRequirementsDoc](id)!
	return true
}

pub fn (mut self DBPrd) exist(id u32) !bool {
	return self.db.exists[ProductRequirementsDoc](id)!
}

pub fn (mut self DBPrd) get(id u32) !ProductRequirementsDoc {
	mut o, data := self.db.get_data[ProductRequirementsDoc](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBPrd) list() ![]ProductRequirementsDoc {
	return self.db.list[ProductRequirementsDoc]()!.map(self.get(it)!)
}

pub fn prd_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.prd.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut args := db.decode_generic[PrdArg](params)!
			mut o := f.prd.new(args)!
			if args.id != 0 {
				o.id = args.id
			}
			o = f.prd.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.prd.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'PRD with ID ${id} not found'
				)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.prd.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			res := f.prd.list()!
			return new_response(rpcid, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on prd'
			)
		}
	}
}
