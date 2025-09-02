# module assets


## Contents
- [minify_css](#minify_css)
- [minify_js](#minify_js)
- [AssetType](#AssetType)
- [Asset](#Asset)
- [AssetManager](#AssetManager)
  - [handle_assets](#handle_assets)
  - [handle_assets_at](#handle_assets_at)
  - [get_assets](#get_assets)
  - [add](#add)
  - [cleanup_cache](#cleanup_cache)
  - [exists](#exists)
  - [include](#include)
  - [combine](#combine)

## minify_css
```v
fn minify_css(css string) string
```



Todo: implement proper minification

[[Return to contents]](#Contents)

## minify_js
```v
fn minify_js(js string) string
```



Todo: implement proper minification

[[Return to contents]](#Contents)

## AssetType
```v
enum AssetType {
	css
	js
	all
}
```

[[Return to contents]](#Contents)

## Asset
```v
struct Asset {
pub:
	kind          AssetType
	file_path     string
	last_modified time.Time
	include_name  string
}
```

[[Return to contents]](#Contents)

## AssetManager
```v
struct AssetManager {
mut:
	css               []Asset
	js                []Asset
	cached_file_names []string
pub mut:
	// when true assets will be minified
	minify bool
	// the directory to store the cached/combined files
	cache_dir string
	// how a combined file should be named. For example for css the extension '.css'
	// will be added to the end of `combined_file_name`
	combined_file_name string = 'combined'
}
```

[[Return to contents]](#Contents)

## handle_assets
```v
fn (mut am AssetManager) handle_assets(directory_path string) !
```

handle_assets recursively walks `directory_path` and adds any assets to the asset manager

[[Return to contents]](#Contents)

## handle_assets_at
```v
fn (mut am AssetManager) handle_assets_at(directory_path string, prepend string) !
```

handle_assets_at recursively walks `directory_path` and adds any assets to the asset manager. The include name of assets are prefixed with `prepend`

[[Return to contents]](#Contents)

## get_assets
```v
fn (am AssetManager) get_assets(asset_type AssetType) []Asset
```

get all assets of type `asset_type`

[[Return to contents]](#Contents)

## add
```v
fn (mut am AssetManager) add(asset_type AssetType, file_path string, include_name string) !
```

add an asset to the asset manager

[[Return to contents]](#Contents)

## cleanup_cache
```v
fn (mut am AssetManager) cleanup_cache() !
```

cleanup_cache removes all files in the cache directory that aren't cached at the time this function is called

[[Return to contents]](#Contents)

## exists
```v
fn (am AssetManager) exists(asset_type AssetType, include_name string) bool
```

check if an asset is already added to the asset manager

[[Return to contents]](#Contents)

## include
```v
fn (am AssetManager) include(asset_type AssetType, include_name string) veb.RawHtml
```

include css/js files in your veb app from templates Usage example:
```html
@{app.am.include(.css, 'main.css')}
```


[[Return to contents]](#Contents)

## combine
```v
fn (mut am AssetManager) combine(asset_type AssetType) !string
```

combine assets of type `asset_type` into a single file and return the outputted file path. If you call `combine` with asset type `all` the function will return an empty string, the minified files will be available at `combined_file_name`.`asset_type`

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:17:41
