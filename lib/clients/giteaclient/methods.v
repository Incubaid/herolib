// File: lib/clients/giteaclient/methods.v
module giteaclient

import freeflowuniverse.herolib.core.httpconnection
import json
import net.http

// List a user's own repositories
pub fn (mut client GiteaClient) user_list_repos() ![]Repository {
	req := httpconnection.Request{
		method: .get
		prefix: '/user/repos'
	}
	mut http_client := client.httpclient()!
	r := http_client.get_json_list_generic[Repository](req)!
	return r
}

// Get a repository
pub fn (mut client GiteaClient) get_repo(owner string, repo string) !Repository {
	req := httpconnection.Request{
		method: .get
		prefix: '/repos/${owner}/${repo}'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_generic[Repository](req)!
}

// Create a repository for the authenticated user.
pub fn (mut client GiteaClient) create_current_user_repo(args CreateRepoOption) !Repository {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/user/repos'
		data:       json.encode(args)
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Repository](req)!
}

//
// Issue Operations
//

// List a repository's issues
pub fn (mut client GiteaClient) list_repo_issues(owner string, repo string) ![]Issue {
	req := httpconnection.Request{
		method: .get
		prefix: '/repos/${owner}/${repo}/issues'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_list_generic[Issue](req)!
}

// Get an issue
pub fn (mut client GiteaClient) get_issue(owner string, repo string, index i64) !Issue {
	req := httpconnection.Request{
		method: .get
		prefix: '/repos/${owner}/${repo}/issues/${index}'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_generic[Issue](req)!
}

// Create an issue
pub fn (mut client GiteaClient) create_issue(owner string, repo string, args CreateIssueOption) !Issue {
	req := httpconnection.Request{
		method:     .post
		prefix:     '/repos/${owner}/${repo}/issues'
		data:       json.encode(args)
		dataformat: .json
	}
	mut http_client := client.httpclient()!
	return http_client.post_json_generic[Issue](req)!
}

//
// User Operations
//

// get_user gets a user by username
pub fn (mut client GiteaClient) get_user(username string) !User {
	req := httpconnection.Request{
		method: .get
		prefix: '/users/${username}'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_generic[User](req)!
}

// get_current_user gets the authenticated user
pub fn (mut client GiteaClient) get_current_user() !User {
	req := httpconnection.Request{
		method: .get
		prefix: '/user'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_generic[User](req)!
}

//
// Admin Operations
//

// list_users lists all users
pub fn (mut client GiteaClient) admin_list_users() ![]User {
	req := httpconnection.Request{
		method: .get
		prefix: '/admin/users'
	}
	mut http_client := client.httpclient()!
	return http_client.get_json_list_generic[User](req)!
}
