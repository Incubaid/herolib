module bizmodel

import os
import incubaid.herolib.biz.spreadsheet
import incubaid.herolib.data.ourtime

@[heap]
pub struct BizModel {
pub mut:
	name        string
	description string
	workdir     string = '${os.home_dir()}/hero/var/bizmodel'
	sheet       &spreadsheet.Sheet
	employees   map[string]&Employee
	departments map[string]&Department
	costcenters map[string]&Costcenter
	products    map[string]&Product
}

@[heap]
pub struct Employee {
pub:
	name                 string
	description          string
	title                string
	department           string
	role                 string
	cost                 string
	cost_percent_revenue f64
	nrpeople             string
	indexation           f64
	cost_center          string
	page                 string
	fulltime_perc        f64
	start_date           ?ourtime.OurTime
}

@[heap]
pub struct Department {
pub:
	name             string
	description      string
	page             string
	title            string
	order            int
	avg_monthly_cost string = '6000USD'
	avg_indexation   string = '2%'
}

pub struct Costcenter {
pub:
	name        string
	description string
	department  string
}

pub struct Product {
pub mut:
	name                string
	title               string
	description         string
	order               int
	has_revenue         bool
	has_items           bool
	has_oneoffs         bool
	nr_months_recurring int
}
