module prd

// Basic enums for clarity

// Core PRD type, this is the root object
pub struct ProductRequirementsDoc {
pub:
	product_name string
	version      string
	overview     string
	vision       string
	goals        []Goal
	use_cases    []UseCase
	requirements []Requirement
	constraints  []Constraint
	risks        map[string]string // risk_id -> mitigation
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

pub struct constraint {
pub:
	id          string
	title       string
	description string
	ctype       ConstraintType
}

