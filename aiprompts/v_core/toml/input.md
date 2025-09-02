# module input


## Contents
- [Config](#Config)
  - [read_input](#read_input)

## Config
```v
struct Config {
pub:
	text      string // TOML text
	file_path string // '/path/to/file.toml'
}
```

Config is used to configure input to the toml module. Only one of the fields `text` and `file_path` is allowed to be set at time of configuration.

[[Return to contents]](#Contents)

## read_input
```v
fn (c Config) read_input() !string
```

read_input returns either Config.text or the read file contents of Config.file_path depending on which one is not empty.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
