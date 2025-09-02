# module net.http.file


## Contents
- [serve](#serve)
- [Entity](#Entity)
- [StaticServeParams](#StaticServeParams)

## serve
```v
fn serve(params StaticServeParams)
```

serve will start a static files web server.

The most common usage is the following: `v -e 'import net.http.file; file.serve()'` will listen for http requests on port 4001 by default, and serve all the files in the current folder.

Another example: `v -e 'import net.http.file; file.serve(folder: "/tmp")'` will serve all files inside the /tmp folder.

Another example: `v -e 'import net.http.file; file.serve(folder: "~/Projects", on: ":5002")'` will expose all the files inside the ~/Projects folder, on http://localhost:5002/ .

[[Return to contents]](#Contents)

## Entity
```v
struct Entity {
	os.FileInfo
	path     string
	mod_time time.Time
	url      string
	fname    string
}
```

[[Return to contents]](#Contents)

## StaticServeParams
```v
struct StaticServeParams {
pub mut:
	folder         string        = $d('http_folder', '.')              // The folder, that will be used as a base for serving all static resources; If it was /tmp, then: http://localhost:4001/x.txt => /tmp/x.txt . Customize with `-d http_folder=vlib/_docs`.
	index_file     string        = $d('http_index_file', 'index.html') // A request for http://localhost:4001/ will map to `index.html`, if that file is present.
	auto_index     bool          = $d('http_auto_index', true)         // when an index_file is *not* present, a request for http://localhost:4001/ will list automatically all files in the folder.
	on             string        = $d('http_on', 'localhost:4001')     // on which address:port to listen for http requests.
	filter_myexe   bool          = true // whether to filter the name of the static file executable from the automatic folder listings for / . Useful with `v -e 'import net.http.file; file.serve()'`
	workers        int           = runtime.nr_jobs() // how many worker threads to use for serving the responses, by default it is limited to the number of available cores; can be controlled with setting VJOBS
	shutdown_after time.Duration = time.infinite // after this time has passed, the webserver will gracefully shutdown on its own
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
