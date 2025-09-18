module heroserver

import freeflowuniverse.herolib.crypt.herocrypt
import freeflowuniverse.herolib.schemas.openrpc
import time
import veb

// Main server configuration
@[params]
pub struct HeroServerConfig {
pub mut:
	port         int    = 9977
	host         string = 'localhost'
	auth_enabled bool   = true // Whether to enable authentication
	// CORS configuration
	cors_enabled    bool     = true  // Whether to enable CORS
	allowed_origins []string = ['*'] // Allowed origins for CORS, default allows all
	// Optional crypto client, will create default if not provided
	crypto_client ?&herocrypt.HeroCrypt
}

// Main server struct
pub struct HeroServer {
	veb.Middleware[Context]
mut:
	port            int
	host            string
	crypto_client   &herocrypt.HeroCrypt
	sessions        map[string]Session          // sessionkey -> Session
	handlers        map[string]&openrpc.Handler // handlertype -> handler
	challenges      map[string]AuthChallenge
	cors_enabled    bool
	allowed_origins []string
pub mut:
	auth_enabled bool = true // Whether authentication is required
}

// Authentication challenge data
pub struct AuthChallenge {
pub mut:
	pubkey     string
	challenge  string // unique hashed challenge
	created_at time.Time
	expires_at time.Time
}

// Home page data for template rendering
pub struct HomePageData {
pub mut:
	base_url     string
	handlers     map[string]&openrpc.Handler
	auth_enabled bool
	host         string
	port         int
}

// Active session data
pub struct Session {
pub mut:
	session_key   string
	pubkey        string
	created_at    time.Time
	last_activity time.Time
	expires_at    time.Time
}

// Authentication request structures
pub struct RegisterRequest {
pub:
	pubkey string
}

pub struct AuthRequest {
pub:
	pubkey string
}

pub struct AuthResponse {
pub:
	challenge string
}

pub struct AuthSubmitRequest {
pub:
	pubkey    string
	signature string // signed challenge
}

pub struct AuthSubmitResponse {
pub:
	session_key string
}

// API request wrapper
pub struct APIRequest {
pub:
	session_key string
	method      string
	params      map[string]string
}

// JSON response structures for homepage
pub struct ServerInfoJSON {
pub:
	server_name  string
	version      string
	description  string
	base_url     string
	host         string
	port         int
	auth_enabled bool
	handlers     []HandlerInfoJSON
	endpoints    EndpointsJSON
	features     []FeatureJSON
	quick_start  QuickStartJSON
}

pub struct HandlerInfoJSON {
pub:
	name         string
	title        string
	description  string
	version      string
	api_endpoint string
	doc_endpoint string
	md_endpoint  string
	methods      []MethodInfoJSON
}

pub struct MethodInfoJSON {
pub:
	name        string
	summary     string
	description string
}

pub struct EndpointsJSON {
pub:
	api_pattern           string
	documentation_pattern string
	markdown_pattern      string
	home_json             string
	home_html             string
}

pub struct FeatureJSON {
pub:
	title       string
	description string
	icon        string
}

pub struct QuickStartJSON {
pub:
	description string
	example     ExampleRequestJSON
}

pub struct ExampleRequestJSON {
pub:
	method      string
	url         string
	headers     map[string]string
	body        string
	description string
}

// Context struct for VEB
pub struct Context {
	veb.Context
}
