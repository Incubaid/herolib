# module time


## Contents
- [Constants](#Constants)
- [date_from_days_after_unix_epoch](#date_from_days_after_unix_epoch)
- [day_of_week](#day_of_week)
- [days_from_unix_epoch](#days_from_unix_epoch)
- [days_in_month](#days_in_month)
- [is_leap_year](#is_leap_year)
- [new](#new)
- [new_stopwatch](#new_stopwatch)
- [now](#now)
- [offset](#offset)
- [parse](#parse)
- [parse_format](#parse_format)
- [parse_iso8601](#parse_iso8601)
- [parse_rfc2822](#parse_rfc2822)
- [parse_rfc3339](#parse_rfc3339)
- [portable_timegm](#portable_timegm)
- [since](#since)
- [sleep](#sleep)
- [sys_mono_now](#sys_mono_now)
- [ticks](#ticks)
- [unix](#unix)
- [unix_micro](#unix_micro)
- [unix_microsecond](#unix_microsecond)
- [unix_milli](#unix_milli)
- [unix_nano](#unix_nano)
- [unix_nanosecond](#unix_nanosecond)
- [utc](#utc)
- [Time.new](#Time.new)
- [Duration](#Duration)
  - [days](#days)
  - [debug](#debug)
  - [hours](#hours)
  - [microseconds](#microseconds)
  - [milliseconds](#milliseconds)
  - [minutes](#minutes)
  - [nanoseconds](#nanoseconds)
  - [seconds](#seconds)
  - [str](#str)
  - [sys_milliseconds](#sys_milliseconds)
  - [timespec](#timespec)
- [FormatDate](#FormatDate)
- [FormatDelimiter](#FormatDelimiter)
- [FormatTime](#FormatTime)
- [C.mach_timebase_info_data_t](#C.mach_timebase_info_data_t)
- [C.timespec](#C.timespec)
- [C.timeval](#C.timeval)
- [C.tm](#C.tm)
- [StopWatch](#StopWatch)
  - [start](#start)
  - [restart](#restart)
  - [stop](#stop)
  - [pause](#pause)
  - [elapsed](#elapsed)
- [StopWatchOptions](#StopWatchOptions)
- [Time](#Time)
  - [-](#-)
  - [<](#<)
  - [==](#==)
  - [add](#add)
  - [add_days](#add_days)
  - [add_seconds](#add_seconds)
  - [as_local](#as_local)
  - [as_utc](#as_utc)
  - [clean](#clean)
  - [clean12](#clean12)
  - [custom_format](#custom_format)
  - [day_of_week](#day_of_week)
  - [days_from_unix_epoch](#days_from_unix_epoch)
  - [ddmmy](#ddmmy)
  - [debug](#debug)
  - [format](#format)
  - [format_rfc3339](#format_rfc3339)
  - [format_rfc3339_micro](#format_rfc3339_micro)
  - [format_rfc3339_nano](#format_rfc3339_nano)
  - [format_ss](#format_ss)
  - [format_ss_micro](#format_ss_micro)
  - [format_ss_milli](#format_ss_milli)
  - [format_ss_nano](#format_ss_nano)
  - [from_json_number](#from_json_number)
  - [from_json_string](#from_json_string)
  - [get_fmt_date_str](#get_fmt_date_str)
  - [get_fmt_str](#get_fmt_str)
  - [get_fmt_time_str](#get_fmt_time_str)
  - [hhmm](#hhmm)
  - [hhmm12](#hhmm12)
  - [hhmmss](#hhmmss)
  - [http_header_string](#http_header_string)
  - [is_utc](#is_utc)
  - [local](#local)
  - [local_to_utc](#local_to_utc)
  - [long_weekday_str](#long_weekday_str)
  - [md](#md)
  - [relative](#relative)
  - [relative_short](#relative_short)
  - [smonth](#smonth)
  - [str](#str)
  - [strftime](#strftime)
  - [unix](#unix)
  - [unix_micro](#unix_micro)
  - [unix_milli](#unix_milli)
  - [unix_nano](#unix_nano)
  - [utc_string](#utc_string)
  - [utc_to_local](#utc_to_local)
  - [week_of_year](#week_of_year)
  - [weekday_str](#weekday_str)
  - [year_day](#year_day)
  - [ymmdd](#ymmdd)
- [TimeParseError](#TimeParseError)
  - [msg](#msg)

## Constants
```v
const second = Duration(1000 * millisecond)
```

[[Return to contents]](#Contents)

```v
const long_months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
	'September', 'October', 'November', 'December']
```

[[Return to contents]](#Contents)

```v
const nanosecond = Duration(1)
```

[[Return to contents]](#Contents)

```v
const absolute_zero_year = i64(-292277022399)
```

The unsigned zero year for internal calculations. Must be 1 mod 400, and times before it will not compute correctly, but otherwise can be changed at will.

[[Return to contents]](#Contents)

```v
const days_string = 'MonTueWedThuFriSatSun'
```

[[Return to contents]](#Contents)

```v
const long_days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']!
```

[[Return to contents]](#Contents)

```v
const month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]!
```

[[Return to contents]](#Contents)

```v
const seconds_per_hour = 60 * seconds_per_minute
```

[[Return to contents]](#Contents)

```v
const millisecond = Duration(1000 * microsecond)
```

[[Return to contents]](#Contents)

```v
const days_per_4_years = days_in_year * 4 + 1
```

[[Return to contents]](#Contents)

```v
const microsecond = Duration(1000 * nanosecond)
```

[[Return to contents]](#Contents)

```v
const days_per_400_years = days_in_year * 400 + 97
```

[[Return to contents]](#Contents)

```v
const minute = Duration(60 * second)
```

[[Return to contents]](#Contents)

```v
const days_before = [
	0,
	31,
	31 + 28,
	31 + 28 + 31,
	31 + 28 + 31 + 30,
	31 + 28 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 + 31,
]!
```

[[Return to contents]](#Contents)

```v
const months_string = 'JanFebMarAprMayJunJulAugSepOctNovDec'
```

[[Return to contents]](#Contents)

```v
const seconds_per_week = 7 * seconds_per_day
```

[[Return to contents]](#Contents)

```v
const hour = Duration(60 * minute)
```

[[Return to contents]](#Contents)

```v
const days_per_100_years = days_in_year * 100 + 24
```

[[Return to contents]](#Contents)

```v
const seconds_per_minute = 60
```

[[Return to contents]](#Contents)

```v
const days_in_year = 365
```

[[Return to contents]](#Contents)

```v
const infinite = Duration(i64(9223372036854775807))
```

day         = Duration(24 * hour)

[[Return to contents]](#Contents)

```v
const seconds_per_day = 24 * seconds_per_hour
```

[[Return to contents]](#Contents)

## date_from_days_after_unix_epoch
```v
fn date_from_days_after_unix_epoch(days int) Time
```

date_from_days_after_unix_epoch - convert number of `days` after the unix epoch 1970-01-01, to a Time. Only the year, month and day of the returned Time will be set, everything else will be 0.

[[Return to contents]](#Contents)

## day_of_week
```v
fn day_of_week(y int, m int, d int) int
```

day_of_week returns the current day of a given year, month, and day, as an integer.

[[Return to contents]](#Contents)

## days_from_unix_epoch
```v
fn days_from_unix_epoch(year int, month int, day int) int
```

days_from_unix_epoch - return the number of days since the Unix epoch 1970-01-01. A detailed description of the algorithm here is in: http://howardhinnant.github.io/date_algorithms.html Note that function will return negative values for days before 1970-01-01.

[[Return to contents]](#Contents)

## days_in_month
```v
fn days_in_month(month int, year int) !int
```

days_in_month returns a number of days in a given month.

[[Return to contents]](#Contents)

## is_leap_year
```v
fn is_leap_year(year int) bool
```

is_leap_year checks if a given a year is a leap year.

[[Return to contents]](#Contents)

## new
```v
fn new(t Time) Time
```

new returns a time struct with the calculated Unix time.

[[Return to contents]](#Contents)

## new_stopwatch
```v
fn new_stopwatch(opts StopWatchOptions) StopWatch
```

new_stopwatch initializes a new StopWatch with the current time as start.

[[Return to contents]](#Contents)

## now
```v
fn now() Time
```

now returns the current local time.

[[Return to contents]](#Contents)

## offset
```v
fn offset() int
```

offset returns time zone UTC offset in seconds.

[[Return to contents]](#Contents)

## parse
```v
fn parse(s string) !Time
```

parse returns the time from a date string in "YYYY-MM-DD HH:mm:ss" format.

[[Return to contents]](#Contents)

## parse_format
```v
fn parse_format(s string, format string) !Time
```

parse_format parses the string `s`, as a custom `format`, containing the following specifiers:

|Category| Format | Description |
|:-----  | :----- | :---------- |
|Year    | YYYY   | 4 digit year, 0000..9999 |
|        | YY     | 2 digit year, 00..99 |
|Month   | M      | month, 1..12 |
|        | MM     | month, 2 digits, 01..12 |
|        | MMM    | month, three letters, Jan..Dec |
|        | MMMM   | name of month |
|Day     | D      | day of the month, 1..31 |
|        | DD     | day of the month, 01..31 |
|        | d      | day of week, 0..6 |
|        | c      | day of week, 1..7 |
|        | dd     | day of week, Su..Sa |
|        | ddd    | day of week, Sun..Sat |
|        | dddd   | day of week, Sunday..Saturday |
|Hour    | H      | hour, 0..23 |
|        | HH     | hour, 00..23 |
|        | h      | hour, 0..23 |
|        | hh     | hour, 0..23 |
|        | k      | hour, 0..23 |
|        | kk     | hour, 0..23 |
|Minute  | m      | minute, 0..59 |
|        | mm     | minute, 0..59 |
|Second  | s      | second, 0..59 |
|        | ss     | second, 0..59 |


[[Return to contents]](#Contents)

## parse_iso8601
```v
fn parse_iso8601(s string) !Time
```

parse_iso8601 parses the ISO 8601 time format yyyy-MM-ddTHH:mm:ss.dddddd+dd:dd as local time. The fraction part is difference in milli seconds, and the last part is offset from UTC time. Both can be +/- HH:mm . See https://en.wikipedia.org/wiki/ISO_8601 . Remarks: not all of ISO 8601 is supported; checks and support for leapseconds should be added.

[[Return to contents]](#Contents)

## parse_rfc2822
```v
fn parse_rfc2822(s string) !Time
```

parse_rfc2822 returns the time from a date string in RFC 2822 datetime format.

[[Return to contents]](#Contents)

## parse_rfc3339
```v
fn parse_rfc3339(s string) !Time
```

parse_rfc3339 returns the time from a date string in RFC 3339 datetime format. See also https://ijmacd.github.io/rfc3339-iso8601/ for a visual reference of the differences between ISO-8601 and RFC 3339.

[[Return to contents]](#Contents)

## portable_timegm
```v
fn portable_timegm(t &C.tm) i64
```

portable_timegm does the same as C._mkgmtime, but unlike it, can work with dates before the Unix epoch of 1970-01-01 .

[[Return to contents]](#Contents)

## since
```v
fn since(t Time) Duration
```

since returns the time duration elapsed since a given time.

[[Return to contents]](#Contents)

## sleep
```v
fn sleep(duration Duration)
```

sleep suspends the execution of the calling thread for a given duration (in nanoseconds).

[[Return to contents]](#Contents)

## sys_mono_now
```v
fn sys_mono_now() u64
```

sys_mono_now returns a *monotonically increasing time*, NOT a time adjusted for daylight savings, location etc.

[[Return to contents]](#Contents)

## ticks
```v
fn ticks() i64
```

ticks returns the number of milliseconds since the UNIX epoch. On Windows ticks returns the number of milliseconds elapsed since system start.

[[Return to contents]](#Contents)

## unix
```v
fn unix(epoch i64) Time
```

unix returns a Time calculated from the given Unix timestamp in seconds since 1970-01-01 .

[[Return to contents]](#Contents)

## unix_micro
```v
fn unix_micro(us i64) Time
```

unix_micro returns a Time calculated from the given Unix timestamp in microseconds since 1970-01-01 .

[[Return to contents]](#Contents)

## unix_microsecond
```v
fn unix_microsecond(epoch i64, microsecond int) Time
```

unix_microsecond returns a Time struct, given an Unix timestamp in seconds, and a microsecond value.

[[Return to contents]](#Contents)

## unix_milli
```v
fn unix_milli(ms i64) Time
```

unix_milli returns a Time calculated from the given Unix timestamp in milliseconds since 1970-01-01 .

[[Return to contents]](#Contents)

## unix_nano
```v
fn unix_nano(ns i64) Time
```

unix_nano returns a Time calculated from the given Unix timestamp in nanoseconds since 1970-01-01 .

[[Return to contents]](#Contents)

## unix_nanosecond
```v
fn unix_nanosecond(abs_unix_timestamp i64, nanosecond int) Time
```

unix_nanosecond returns a Time struct given a Unix timestamp in seconds and a nanosecond value.

[[Return to contents]](#Contents)

## utc
```v
fn utc() Time
```

utc returns the current UTC time.

[[Return to contents]](#Contents)

## Time.new
```v
fn Time.new(t Time) Time
```

Time.new static method returns a time struct with the calculated Unix time.

[[Return to contents]](#Contents)

## Duration
```v
type Duration = i64
```

A lot of these are taken from the Go library.

[[Return to contents]](#Contents)

## days
```v
fn (d Duration) days() f64
```

days returns the duration as a floating point number of days.

[[Return to contents]](#Contents)

## debug
```v
fn (d Duration) debug() string
```

debug returns a detailed breakdown of the Duration, as: 'Duration: - 50days, 4h, 3m, 7s, 541ms, 78us, 9ns'.

[[Return to contents]](#Contents)

## hours
```v
fn (d Duration) hours() f64
```

hours returns the duration as a floating point number of hours.

[[Return to contents]](#Contents)

## microseconds
```v
fn (d Duration) microseconds() i64
```

microseconds returns the duration as an integer number of microseconds.

[[Return to contents]](#Contents)

## milliseconds
```v
fn (d Duration) milliseconds() i64
```

milliseconds returns the duration as an integer number of milliseconds.

[[Return to contents]](#Contents)

## minutes
```v
fn (d Duration) minutes() f64
```

minutes returns the duration as a floating point number of minutes.

[[Return to contents]](#Contents)

## nanoseconds
```v
fn (d Duration) nanoseconds() i64
```

nanoseconds returns the duration as an integer number of nanoseconds.

[[Return to contents]](#Contents)

## seconds
```v
fn (d Duration) seconds() f64
```

The following functions return floating point numbers because it's common to consider all of them in sub-one intervals seconds returns the duration as a floating point number of seconds.

[[Return to contents]](#Contents)

## str
```v
fn (d Duration) str() string
```

str pretty prints the duration

```
h:m:s      // 5:02:33
m:s.mi<s>  // 2:33.015
s.mi<s>    // 33.015s
mi.mc<ms>  // 15.007ms
mc.ns<ns>  // 7.234us
ns<ns>     // 234ns
```


[[Return to contents]](#Contents)

## sys_milliseconds
```v
fn (d Duration) sys_milliseconds() int
```

some *nix system functions (e.g. `C.poll()`, C.epoll_wait()) accept an `int` value as *timeout in milliseconds* with the special value `-1` meaning "infinite"

[[Return to contents]](#Contents)

## timespec
```v
fn (d Duration) timespec() C.timespec
```

return absolute timespec for now()+d

[[Return to contents]](#Contents)

## FormatDate
```v
enum FormatDate {
	ddmmyy
	ddmmyyyy
	mmddyy
	mmddyyyy
	mmmd
	mmmdd
	mmmddyy
	mmmddyyyy
	no_date
	yyyymmdd
	yymmdd
}
```

FormatDelimiter contains different date formats.

[[Return to contents]](#Contents)

## FormatDelimiter
```v
enum FormatDelimiter {
	dot
	hyphen
	slash
	space
	no_delimiter
}
```

FormatDelimiter contains different time/date delimiters.

[[Return to contents]](#Contents)

## FormatTime
```v
enum FormatTime {
	hhmm12
	hhmm24
	hhmmss12
	hhmmss24
	hhmmss24_milli
	hhmmss24_micro
	hhmmss24_nano
	no_time
}
```

FormatDelimiter contains different time formats.

[[Return to contents]](#Contents)

## C.mach_timebase_info_data_t
```v
struct C.mach_timebase_info_data_t {
	numer u32
	denom u32
}
```

[[Return to contents]](#Contents)

## C.timespec
```v
struct C.timespec {
pub mut:
	tv_sec  i64
	tv_nsec i64
}
```

in most systems, these are __quad_t, which is an i64

[[Return to contents]](#Contents)

## C.timeval
```v
struct C.timeval {
pub:
	tv_sec  u64
	tv_usec u64
}
```

C.timeval represents a C time value.

[[Return to contents]](#Contents)

## C.tm
```v
struct C.tm {
pub mut:
	tm_sec    int
	tm_min    int
	tm_hour   int
	tm_mday   int
	tm_mon    int
	tm_year   int
	tm_wday   int
	tm_yday   int
	tm_isdst  int
	tm_gmtoff int
}
```

[[Return to contents]](#Contents)

## StopWatch
```v
struct StopWatch {
mut:
	elapsed u64
pub mut:
	start u64
	end   u64
}
```

StopWatch is used to measure elapsed time.

[[Return to contents]](#Contents)

## start
```v
fn (mut t StopWatch) start()
```

start starts the stopwatch. If the timer was paused, it continues counting.

[[Return to contents]](#Contents)

## restart
```v
fn (mut t StopWatch) restart()
```

restart restarts the stopwatch. If the timer was paused, it restarts counting.

[[Return to contents]](#Contents)

## stop
```v
fn (mut t StopWatch) stop()
```

stop stops the timer, by setting the end time to the current time.

[[Return to contents]](#Contents)

## pause
```v
fn (mut t StopWatch) pause()
```

pause resets the `start` time and adds the current elapsed time to `elapsed`.

[[Return to contents]](#Contents)

## elapsed
```v
fn (t StopWatch) elapsed() Duration
```

elapsed returns the Duration since the last start call.

[[Return to contents]](#Contents)

## StopWatchOptions
```v
struct StopWatchOptions {
pub:
	auto_start bool = true
}
```

[[Return to contents]](#Contents)

## Time
```v
struct Time {
	unix i64
pub:
	year       int
	month      int
	day        int
	hour       int
	minute     int
	second     int
	nanosecond int
	is_local   bool // used to make time.now().local().local() == time.now().local()
}
```

Time contains various time units for a point in time.

[[Return to contents]](#Contents)

## -
```v
fn (lhs Time) - (rhs Time) Duration
```

Time subtract using operator overloading.

[[Return to contents]](#Contents)

## <
```v
fn (t1 Time) < (t2 Time) bool
```

operator `<` returns true if provided time is less than time

[[Return to contents]](#Contents)

## ==
```v
fn (t1 Time) == (t2 Time) bool
```

operator `==` returns true if provided time is equal to time

[[Return to contents]](#Contents)

## add
```v
fn (t Time) add(duration_in_nanosecond Duration) Time
```

add returns a new time with the given duration added.

[[Return to contents]](#Contents)

## add_days
```v
fn (t Time) add_days(days int) Time
```

add_days returns a new time struct with an added number of days.

[[Return to contents]](#Contents)

## add_seconds
```v
fn (t Time) add_seconds(seconds int) Time
```

add_seconds returns a new time struct with an added number of seconds.

[[Return to contents]](#Contents)

## as_local
```v
fn (t Time) as_local() Time
```

as_local returns the exact same time, as the receiver `t`, but with its .is_local field set to true. See also #Time.utc_to_local .

[[Return to contents]](#Contents)

## as_utc
```v
fn (t Time) as_utc() Time
```

as_utc returns the exact same time, as the receiver `t`, but with its .is_local field set to false. See also #Time.local_to_utc .

[[Return to contents]](#Contents)

## clean
```v
fn (t Time) clean() string
```

clean returns a date string in a clean form. It has the following format:- a date string in "HH:mm" format (24h) for current day
- a date string in "MMM D HH:mm" format (24h) for date of current year
- a date string formatted with format function for other dates


[[Return to contents]](#Contents)

## clean12
```v
fn (t Time) clean12() string
```

clean12 returns a date string in a clean form. It has the following format:- a date string in "hh:mm" format (12h) for current day
- a date string in "MMM D hh:mm" format (12h) for date of current year
- a date string formatted with format function for other dates


[[Return to contents]](#Contents)

## custom_format
```v
fn (t Time) custom_format(s string) string
```

custom_format returns a date with custom format

| Category         | Token | Output                                 |
|:-----------------|:------|:---------------------------------------|
|          Era     | N     | BC AD                                  |
|                  | NN    | Before Christ, Anno Domini             |
|         Year     | YY    | 70 71 ... 29 30                        |
|                  | YYYY  | 1970 1971 ... 2029 2030                |
|      Quarter     | Q     | 1 2 3 4                                |
|                  | QQ    | 01 02 03 04                            |
|                  | Qo    | 1st 2nd 3rd 4th                        |
|        Month     | M     | 1 2 ... 11 12                          |
|                  | Mo    | 1st 2nd ... 11th 12th                  |
|                  | MM    | 01 02 ... 11 12                        |
|                  | MMM   | Jan Feb ... Nov Dec                    |
|                  | MMMM  | January February ... November December |
| Week of Year     | w     | 1 2 ... 52 53                          |
|                  | wo    | 1st 2nd ... 52nd 53rd                  |
|                  | ww    | 01 02 ... 52 53                        |
| Day of Month     | D     | 1 2 ... 30 31                          |
|                  | Do    | 1st 2nd ... 30th 31st                  |
|                  | DD    | 01 02 ... 30 31                        |
|  Day of Year     | DDD   | 1 2 ... 364 365                        |
|                  | DDDo  | 1st 2nd ... 364th 365th                |
|                  | DDDD  | 001 002 ... 364 365                    |
|  Day of Week     | d     | 0 1 ... 5 6 (Sun-Sat)                  |
|                  | c     | 1 2 ... 6 7 (Mon-Sun)                  |
|                  | dd    | Su Mo ... Fr Sa                        |
|                  | ddd   | Sun Mon ... Fri Sat                    |
|                  | dddd  | Sunday Monday ... Friday Saturday      |
|        AM/PM     | A     | AM PM                                  |
|                  | a     | am pm                                  |
|         Hour     | H     | 0 1 ... 22 23                          |
|                  | HH    | 00 01 ... 22 23                        |
|                  | h     | 1 2 ... 11 12                          |
|                  | hh    | 01 02 ... 11 12                        |
|                  | i     | 0 1 ... 11 12 1 ... 11                 |
|                  | ii    | 00 01 ... 11 12 01 ... 11              |
|                  | k     | 1 2 ... 23 24                          |
|                  | kk    | 01 02 ... 23 24                        |
|       Minute     | m     | 0 1 ... 58 59                          |
|                  | mm    | 00 01 ... 58 59                        |
|       Second     | s     | 0 1 ... 58 59                          |
|                  | ss    | 00 01 ... 58 59                        |
|       Offset     | Z     | -7 -6 ... +5 +6                        |
|                  | ZZ    | -0700 -0600 ... +0500 +0600            |
|                  | ZZZ   | -07:00 -06:00 ... +05:00 +06:00        |

Usage:
```v
println(time.now().custom_format('MMMM Mo YY N kk:mm:ss A')) // output like: January 1st 22 AD 13:45:33 PM
```


[[Return to contents]](#Contents)

## day_of_week
```v
fn (t Time) day_of_week() int
```

day_of_week returns the current day as an integer.

[[Return to contents]](#Contents)

## days_from_unix_epoch
```v
fn (t Time) days_from_unix_epoch() int
```

days_from_unix_epoch - return the number of days since the Unix epoch 1970-01-01. A detailed description of the algorithm here is in: http://howardhinnant.github.io/date_algorithms.html Note that method will return negative values for days before 1970-01-01.

[[Return to contents]](#Contents)

## ddmmy
```v
fn (t Time) ddmmy() string
```

ddmmy returns a date string in "DD.MM.YYYY" format.

[[Return to contents]](#Contents)

## debug
```v
fn (t Time) debug() string
```

debug returns detailed breakdown of time (`Time{ year: YYYY month: MM day: dd hour: HH: minute: mm second: ss nanosecond: nanos unix: unix }`).

[[Return to contents]](#Contents)

## format
```v
fn (t Time) format() string
```

format returns a date string in "YYYY-MM-DD HH:mm" format (24h).

[[Return to contents]](#Contents)

## format_rfc3339
```v
fn (t Time) format_rfc3339() string
```

format_rfc3339 returns a date string in "YYYY-MM-DDTHH:mm:ss.123Z" format (24 hours, see https://www.rfc-editor.org/rfc/rfc3339.html) RFC3339 is an Internet profile, based on the ISO 8601 standard for for representation of dates and times using the Gregorian calendar. It is intended to improve consistency and interoperability, when representing and using date and time in Internet protocols.

[[Return to contents]](#Contents)

## format_rfc3339_micro
```v
fn (t Time) format_rfc3339_micro() string
```

format_rfc3339_micro returns a date string in "YYYY-MM-DDTHH:mm:ss.123456Z" format (24 hours, see https://www.rfc-editor.org/rfc/rfc3339.html)

[[Return to contents]](#Contents)

## format_rfc3339_nano
```v
fn (t Time) format_rfc3339_nano() string
```

format_rfc3339_nano returns a date string in "YYYY-MM-DDTHH:mm:ss.123456789Z" format (24 hours, see https://www.rfc-editor.org/rfc/rfc3339.html)

[[Return to contents]](#Contents)

## format_ss
```v
fn (t Time) format_ss() string
```

format_ss returns a date string in "YYYY-MM-DD HH:mm:ss" format (24h).

[[Return to contents]](#Contents)

## format_ss_micro
```v
fn (t Time) format_ss_micro() string
```

format_ss_micro returns a date string in "YYYY-MM-DD HH:mm:ss.123456" format (24h).

[[Return to contents]](#Contents)

## format_ss_milli
```v
fn (t Time) format_ss_milli() string
```

format_ss_milli returns a date string in "YYYY-MM-DD HH:mm:ss.123" format (24h).

[[Return to contents]](#Contents)

## format_ss_nano
```v
fn (t Time) format_ss_nano() string
```

format_ss_nano returns a date string in "YYYY-MM-DD HH:mm:ss.123456789" format (24h).

[[Return to contents]](#Contents)

## from_json_number
```v
fn (mut t Time) from_json_number(raw_number string) !
```

from_json_string implements a custom decoder for json2 (unix)

[[Return to contents]](#Contents)

## from_json_string
```v
fn (mut t Time) from_json_string(raw_string string) !
```

from_json_string implements a custom decoder for json2 (iso8601/rfc3339/unix)

[[Return to contents]](#Contents)

## get_fmt_date_str
```v
fn (t Time) get_fmt_date_str(fmt_dlmtr FormatDelimiter, fmt_date FormatDate) string
```

get_fmt_time_str returns a date string with specified FormatDelimiter and FormatDate type.

[[Return to contents]](#Contents)

## get_fmt_str
```v
fn (t Time) get_fmt_str(fmt_dlmtr FormatDelimiter, fmt_time FormatTime, fmt_date FormatDate) string
```

get_fmt_str returns a date string with specified FormatDelimiter, FormatTime type, and FormatDate type.

[[Return to contents]](#Contents)

## get_fmt_time_str
```v
fn (t Time) get_fmt_time_str(fmt_time FormatTime) string
```

get_fmt_time_str returns a date string with specified FormatTime type.

[[Return to contents]](#Contents)

## hhmm
```v
fn (t Time) hhmm() string
```

hhmm returns a date string in "HH:mm" format (24h).

[[Return to contents]](#Contents)

## hhmm12
```v
fn (t Time) hhmm12() string
```

hhmm12 returns a date string in "hh:mm" format (12h).

[[Return to contents]](#Contents)

## hhmmss
```v
fn (t Time) hhmmss() string
```

hhmmss returns a date string in "HH:mm:ss" format (24h).

[[Return to contents]](#Contents)

## http_header_string
```v
fn (t Time) http_header_string() string
```

http_header_string returns a date string in the format used in HTTP headers, as defined in RFC 2616. e.g. "Sun, 06 Nov 1994 08:49:37 GMT"

[[Return to contents]](#Contents)

## is_utc
```v
fn (t Time) is_utc() bool
```

is_utc returns true, when the receiver `t` is a UTC time, and false otherwise. See also #Time.utc_to_local .

[[Return to contents]](#Contents)

## local
```v
fn (t Time) local() Time
```

local returns t with the location set to local time.

[[Return to contents]](#Contents)

## local_to_utc
```v
fn (t Time) local_to_utc() Time
```

local_to_utc converts the receiver `t` to the corresponding UTC time, if it contains local time. If the receiver already does contain UTC time, it returns it unchanged.

[[Return to contents]](#Contents)

## long_weekday_str
```v
fn (t Time) long_weekday_str() string
```

long_weekday_str returns the current day as a string.

[[Return to contents]](#Contents)

## md
```v
fn (t Time) md() string
```

md returns a date string in "MMM D" format.

[[Return to contents]](#Contents)

## relative
```v
fn (t Time) relative() string
```

relative returns a string representation of the difference between t and the current time.

Sample outputs:
```
// future
now
in 5 minutes
in 1 day
on Feb 17
// past
2 hours ago
last Jan 15
5 years ago
```


[[Return to contents]](#Contents)

## relative_short
```v
fn (t Time) relative_short() string
```

relative_short returns a string saying how long ago a time occurred as follows: 0-30 seconds: `"now"`; 30-60 seconds: `"1m"`; anything else is rounded to the nearest minute, hour, day, or year

Sample outputs:
```
// future
now
in 5m
in 1d
// past
2h ago
5y ago
```


[[Return to contents]](#Contents)

## smonth
```v
fn (t Time) smonth() string
```

smonth returns the month name abbreviation.

[[Return to contents]](#Contents)

## str
```v
fn (t Time) str() string
```

str returns the time in the same format as `parse` expects ("YYYY-MM-DD HH:mm:ss").

[[Return to contents]](#Contents)

## strftime
```v
fn (t Time) strftime(fmt string) string
```

strftime returns the formatted time using `strftime(3)`.

[[Return to contents]](#Contents)

## unix
```v
fn (t Time) unix() i64
```

unix returns the UNIX time with second resolution.

[[Return to contents]](#Contents)

## unix_micro
```v
fn (t Time) unix_micro() i64
```

unix_micro returns the UNIX time with microsecond resolution.

[[Return to contents]](#Contents)

## unix_milli
```v
fn (t Time) unix_milli() i64
```

unix_milli returns the UNIX time with millisecond resolution.

[[Return to contents]](#Contents)

## unix_nano
```v
fn (t Time) unix_nano() i64
```

unix_nano returns the UNIX time with nanosecond resolution.

[[Return to contents]](#Contents)

## utc_string
```v
fn (t Time) utc_string() string
```

This is just a TEMPORARY function for cookies and their expire dates

[[Return to contents]](#Contents)

## utc_to_local
```v
fn (u Time) utc_to_local() Time
```

utc_to_local converts the receiver `u` to the corresponding local time, if it contains UTC time. If the receiver already does contain local time, it returns it unchanged.

[[Return to contents]](#Contents)

## week_of_year
```v
fn (t Time) week_of_year() int
```

week_of_year returns the current week of year as an integer. follow ISO 8601 standard

[[Return to contents]](#Contents)

## weekday_str
```v
fn (t Time) weekday_str() string
```

weekday_str returns the current day as a string 3 letter abbreviation.

[[Return to contents]](#Contents)

## year_day
```v
fn (t Time) year_day() int
```

year_day returns the current day of the year as an integer. See also #Time.custom_format .

[[Return to contents]](#Contents)

## ymmdd
```v
fn (t Time) ymmdd() string
```

ymmdd returns a date string in "YYYY-MM-DD" format.

[[Return to contents]](#Contents)

## TimeParseError
```v
struct TimeParseError {
	Error
	code    int
	message string
}
```

TimeParseError represents a time parsing error.

[[Return to contents]](#Contents)

## msg
```v
fn (err TimeParseError) msg() string
```

msg implements the `IError.msg()` method for `TimeParseError`.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:30
