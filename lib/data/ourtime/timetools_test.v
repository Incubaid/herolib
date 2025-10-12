module ourtime

import incubaid.herolib.data.ourtime
import time

// TODO: need to update the tests

fn check_input(input_string string, seconds int) {
	nnow := time.now().unix()
	thetime := parse(input_string) or { panic('cannot get expiration for ${input_string}') }
	assert thetime == (nnow + seconds), 'expiration was incorrect for ${input_string}'
}

// check every period
fn test_every_period() {
	input_strings := {
		'+5s': 5
		'+3m': 180
		'+2h': 7200
		'+1d': 86_400
		'+1w': 604_800
		'+1M': 2_592_000
		'+1Q': 7_776_000
		'+1Y': 31_536_000
	}

	for key, value in input_strings {
		check_input(key, value)
	}
}

// check multiple periods input
fn test_combined_periods() {
	input_strings := {
		'+5s +1h +1d': 90_005
		'+1h +2s +1Y': 31_539_602
	}

	for key, value in input_strings {
		check_input(key, value)
	}
}

// check negative inputs
fn test_negative_periods() {
	input_strings := {
		'-15s': -15
		'-5m':  -300
		'-2h':  -7200
		'-1d':  -86_400
		'-1w':  -604_800
		'-1M':  -2_592_000
		'-1Q':  -7_776_000
		'-1Y':  -31_536_000
	}

	for key, value in input_strings {
		check_input(key, value)
	}
}

// check positive and negative combinations
fn test_combined_signs() {
	input_strings := {
		'+1h -10s':             3_590
		'+1d -2h':              79_200
		'+1Y -2Q +2M +4h -60s': 21_182_340
	}

	for key, value in input_strings {
		check_input(key, value)
	}
}

// check varied input styles
fn test_input_variations() {
	input_strings := {
		'   +1s   ':     1
		' - 1 s ':       -1
		'+    1s-1h ':   -3599
		'- 1s+   1   h': 3599
	}

	for key, value in input_strings {
		check_input(key, value)
	}
}

// check that standard formats can be inputted
fn test_absolute_time() {
	input_strings := {
		'2022-12-5':          1670198400
		' 2022-12-05 ':       1670198400
		'2022-12-5 1':        1670198400 + 3600
		'2022-12-5 20':       1670198400 + 3600 * 20
		'2022-12-5 20:14':    1670198400 + 3600 * 20 + 14 * 60
		'2022-12-5 20:14:35': 1670198400 + 3600 * 20 + 14 * 60 + 35
	}
	for key, value in input_strings {
		println(' ===== ${key} ${value}')
		thetime := new(key) or { panic('cannot get ourtime for ${key}.\n${err}') }
		assert value == get_unix_from_absolute(key)!
		assert thetime.unix() == value, 'expiration was incorrect for ${key}'
	}

	a := get_unix_from_absolute('2022-12-5')!
	a2 := get_unix_from_absolute('2022-12-05')!
	b := get_unix_from_absolute('2022-12-5 1')!
	c := get_unix_from_absolute('2022-12-5 1:00')!
	d := get_unix_from_absolute('2022-12-5 01:00')!
	e := get_unix_from_absolute('2022-12-5 01:1')!

	assert a == a2
	assert b == a + 3600
	assert b == c
	assert b == d
	assert e == d + 60
}

fn test_from_epoch() {
	mut t := new_from_epoch(1670271275)
	assert t.str() == '2022-12-05 20:14'
}

// NEXT: need some better test to see if time parsing works, more full tests

fn test_parse_date() {
	input_strings := {
		'12/01/1999': 916099200
		'2000/09/09': 968457600
	}

	for key, value in input_strings {
		test_value := new(key) or { panic('parse_date failed for ${key}, with error ${err}') }

		assert test_value.unix() == value
	}
}
