module heromodels

import time

pub struct Profile {
pub:
	id               string
	user_id          string // a user can have more than one profile
	name             string
	summary          string
	headline         string
	location         string
	industry         string
	// urls to profile pictures
	picture_url      string 
	background_image_url string
	// contact info
	email            string
	phone            string
	website          string
	// experience
	experience       []Experience
	education        []Education
	skills           []string
	languages        []string
	// recommendations
	recommendations_received []Recommendation
	recommendations_given    []Recommendation
	// connections
	connections      []string // user_ids
	// groups the profile is part of
	group_ids        []string
	// creation and modification times
	created          time.Time
	modified         time.Time
}

pub struct Experience {
pub:
	title          string
	company        string
	location       string
	start_date     time.Time
	end_date       time.Time
	current        bool
	description    string
}

pub struct Education {
pub:
	school         string
	degree         string
	field_of_study string
	start_date     time.Time
	end_date       time.Time
	description    string
}

pub struct Recommendation {
pub:
	recommender_id string
	receiver_id    string
	text           string
	created        time.Time
}