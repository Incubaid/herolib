module webdav

import encoding.xml
import log
import incubaid.herolib.core.pathlib
import incubaid.herolib.vfs
import incubaid.herolib.vfs.vfs_db
import os
import time
import incubaid.herolib.core.texttools
import net.http
import veb

@['/:path...'; propfind]
fn (mut server Server) propfind(mut ctx Context, path string) veb.Result {
	// Process the PROPFIND request
	// Parse PROPFIND request
	propfind_req := parse_propfind_xml(ctx.req) or {
		return ctx.error(WebDAVError{
			status:  .bad_request
			message: 'Failed to parse PROPFIND XML: ${err}'
			tag:     'propfind-parse-error'
		})
	}

	log.debug('[WebDAV] Propfind Request: ${propfind_req.typ}')

	// Check if resource is locked
	if server.lock_manager.is_locked(ctx.req.url) {
		// If the resource is locked, we should still return properties
		// but we might need to indicate the lock status in the response
		// This is handled in the property generation
		log.info('[WebDAV] Resource is locked: ${ctx.req.url}')
	}

	entry := server.vfs.get(path) or {
		return ctx.error(
			status:  .not_found
			message: 'Path ${path} does not exist'
			tag:     'resource-must-be-null'
		)
	}

	responses := server.get_responses(entry, propfind_req, path) or {
		return ctx.server_error('Failed to get entry properties ${err}')
	}

	// Add WsgiDAV-like headers
	ctx.set_header(.content_type, 'application/xml; charset=utf-8')
	ctx.set_custom_header('Date', texttools.format_rfc1123(time.utc())) or {
		return ctx.server_error(err.msg())
	}
	ctx.set_custom_header('Server', 'WsgiDAV-compatible WebDAV Server') or {
		return ctx.server_error(err.msg())
	}

	// Create multistatus response using the responses
	ctx.res.set_status(.multi_status)
	return ctx.send_response_to_client('application/xml', responses.xml())
}

// returns the properties of a filesystem entry
fn (mut server Server) get_entry_property(entry &vfs.FSEntry, name string) !Property {
	// Handle property names with namespace prefixes
	// Strip any namespace prefix (like 'D:' or 's:') from the property name
	property_name := if name.contains(':') { name.all_after(':') } else { name }

	return match property_name {
		'creationdate' {
			Property(CreationDate(format_iso8601(entry.get_metadata().created_time())))
		}
		'getetag' {
			Property(GetETag(entry.get_metadata().id.str()))
		}
		'resourcetype' {
			Property(ResourceType(entry.is_dir()))
		}
		'getlastmodified', 'lastmodified_server' {
			// Both standard getlastmodified and custom lastmodified_server properties
			// return the same information
			Property(GetLastModified(texttools.format_rfc1123(entry.get_metadata().modified_time())))
		}
		'getcontentlength' {
			Property(GetContentLength(entry.get_metadata().size.str()))
		}
		'quota-available-bytes' {
			Property(QuotaAvailableBytes(16184098816))
		}
		'quota-used-bytes' {
			Property(QuotaUsedBytes(16184098816))
		}
		'quotaused' {
			Property(QuotaUsed(16184098816))
		}
		'quota' {
			Property(Quota(16184098816))
		}
		'displayname' {
			// RFC 4918, Section 15.2: displayname is a human-readable name for UI display
			// For now, we use the filename as the displayname, but this could be enhanced
			// to support custom displaynames stored in metadata or configuration
			Property(DisplayName(entry.get_metadata().name))
		}
		'getcontenttype' {
			// RFC 4918, Section 15.5: getcontenttype contains the Content-Type header value
			// For collections (directories), return httpd/unix-directory
			// For files, determine the MIME type based on file extension
			mut content_type := ''
			if entry.is_dir() {
				content_type = 'httpd/unix-directory'
			} else {
				content_type = get_file_content_type(entry.get_metadata().name)
			}
			Property(GetContentType(content_type))
		}
		'lockdiscovery' {
			// RFC 4918, Section 15.8: lockdiscovery provides information about locks
			// Always show as unlocked for now to ensure compatibility
			Property(LockDiscovery(''))
		}
		else {
			// For any unimplemented property, return an empty string instead of panicking
			// This improves compatibility with various WebDAV clients
			log.info('[WebDAV] Unimplemented property requested: ${name}')
			Property(DisplayName(''))
		}
	}
}

// get_responses returns all properties for the given path and depth
fn (mut server Server) get_responses(entry vfs.FSEntry, req PropfindRequest, path string) ![]PropfindResponse {
	mut responses := []PropfindResponse{}

	if req.typ == .prop {
		mut properties := []Property{}
		mut erronous_properties := map[int][]Property{} // properties that have errors indexed by error code
		for name in req.props {
			if property := server.get_entry_property(entry, name.trim_string_left('D:')) {
				properties << property
			} else {
				// TODO: implement error reporting
			}
		}
		// main entry response
		responses << PropfindResponse{
			href: ensure_leading_slash(if entry.is_dir() {
				'${path.trim_string_right('/')}/'
			} else {
				path
			})
			// not_found: entry.get_unfound_properties(req)
			found_props: properties
		}
	} else {
		responses << PropfindResponse{
			href: ensure_leading_slash(if entry.is_dir() {
				'${path.trim_string_right('/')}/'
			} else {
				path
			})
			// not_found: entry.get_unfound_properties(req)
			found_props: server.get_properties(entry)
		}
	}

	if !entry.is_dir() || req.depth == .zero {
		return responses
	}

	entries := server.vfs.dir_list(path) or {
		log.error('Failed to list directory for ${path} ${err}')
		return responses
	}
	for e in entries {
		child_path := if path.ends_with('/') {
			path + e.get_metadata().name
		} else {
			path + '/' + e.get_metadata().name
		}
		responses << server.get_responses(e, PropfindRequest{
			...req
			depth: if req.depth == .one { .zero } else { .infinity }
		}, child_path)!
	}
	return responses
}

// Helper function to ensure a path has a leading slash
fn ensure_leading_slash(path string) string {
	if path.starts_with('/') {
		return path
	}
	return '/' + path
}

// returns the properties of a filesystem entry
fn (mut server Server) get_properties(entry &vfs.FSEntry) []Property {
	mut props := []Property{}

	metadata := entry.get_metadata()
	// Display name
	props << DisplayName(metadata.name)
	props << GetLastModified(texttools.format_rfc1123(metadata.modified_time()))

	if entry.is_dir() {
		props << QuotaAvailableBytes(16184098816)
		props << QuotaUsedBytes(16184098816)
	} else {
		props << GetContentType(if entry.is_dir() {
			'httpd/unix-directory'
		} else {
			get_file_content_type(entry.get_metadata().name)
		})
	}
	props << ResourceType(entry.is_dir())
	// props << SupportedLock('')
	// props << LockDiscovery('')

	// Content length (only for files)
	if !entry.is_dir() {
		props << GetContentLength(metadata.size.str())
	}

	// Creation date
	props << CreationDate(format_iso8601(metadata.created_time()))
	return props
}
