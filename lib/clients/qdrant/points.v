module qdrant

import incubaid.herolib.core.httpconnection
import json
import rand

// Retrieves all details from multiple points.
@[params]
pub struct RetrievePointsParams {
pub mut:
	ids             []int  @[json: 'ids'; required]             // Look for points with ids
	collection_name string @[json: 'collection_name'; required] // Name of the collection
	shard_key       ?string // Specify in which shards to look for the points, if not specified - look in all shards
	with_payload    ?bool   // Select which payload to return with the response. Default is true.
	with_vectors    ?bool   // Options for specifying which vectors to include into response. Default is false.
}

pub struct RetrievePointsResponse {
pub mut:
	id          int               // Type, used for specifying point ID in user interface
	payload     map[string]string // Payload - values assigned to the point
	vector      []f64             // Vector of the point
	shard_id    string            // Shard name
	order_value f64               // Order value
}

// Parameters for scrolling through points
@[params]
pub struct ScrollPointsParams {
pub mut:
	collection_name string  @[json: 'collection_name'; required] // Name of the collection
	filter          ?Filter @[json: 'filter']                    // Filter conditions
	limit           int = 10     @[json: 'limit']                                 // Max number of results
	offset          ?string @[json: 'offset']                    // Offset from which to continue scrolling
	with_payload    ?bool   @[json: 'with_payload']              // Whether to include payload in the response
	with_vector     ?bool   @[json: 'with_vector']               // Whether to include vectors in the response
}

// Response structure for scroll operation
pub struct ScrollResponse {
pub mut:
	points           []PointStruct @[json: 'points']           // List of points
	next_page_offset ?string       @[json: 'next_page_offset'] // Offset for the next page
}

// Point structure for scroll results
pub struct PointStruct {
pub mut:
	id      string             @[json: 'id']      // Point ID
	payload ?map[string]string @[json: 'payload'] // Payload key-value pairs (optional)
	vector  ?[]f64             @[json: 'vector']  // Vector data (optional)
}

// Scroll through points with pagination
pub fn (mut self QDrantClient) scroll_points(params ScrollPointsParams) !QDrantResponse[ScrollResponse] {
	mut http_conn := self.httpclient()!

	req := httpconnection.Request{
		method: .post
		prefix: '/collections/${params.collection_name}/points/scroll'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error scrolling points: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[ScrollResponse], response.data)!
}

// Retrieves all details from multiple points.
pub fn (mut self QDrantClient) retrieve_points(params RetrievePointsParams) !QDrantResponse[RetrievePointsResponse] {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .post
		prefix: '/collections/${params.collection_name}/points'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error retrieving points: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[RetrievePointsResponse], response.data)!
}

// Parameters for upserting points into a Qdrant collection.
@[params]
pub struct UpsertPointsParams {
pub mut:
	collection_name string  @[json: 'collection_name'; required] // Name of the collection
	points          []Point @[json: 'points'; required]          // List of points to upsert
	shard_key       ?string // Optional shard key for sharding
	wait            ?bool   // Whether to wait until the changes have been applied
}

// Represents a single point to be upserted.
pub struct Point {
pub mut:
	id      string = rand.uuid_v4()            @[json: 'id'; required]            // Point ID (can be string or integer, serialized as string)
	payload map[string]string @[json: 'payload']          // Payload key-value pairs (optional)
	vector  []f64             @[json: 'vector'; required] // Vector data for the point
}

// Response structure for the upsert points operation.
pub struct UpsertPointsResponse {
pub mut:
	status       string @[json: 'status']
	operation_id int    @[json: 'operation_id']
}

// Upserts points into a Qdrant collection.
// Performs insert + update actions on specified points. Any point with an existing {id} will be overwritten.
pub fn (mut self QDrantClient) upsert_points(params UpsertPointsParams) !QDrantResponse[UpsertPointsResponse] {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .put
		prefix: '/collections/${params.collection_name}/points'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error upserting points: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[UpsertPointsResponse], response.data)!
}

// Parameters for getting a point by ID
@[params]
pub struct GetPointParams {
pub mut:
	collection_name string @[json: 'collection_name'; required] // Name of the collection
	id              string @[json: 'id'; required]              // ID of the point to retrieve
	with_payload    ?bool // Whether to include payload in the response
	with_vector     ?bool // Whether to include vector in the response
}

// Response structure for the get point operation
pub struct GetPointResponse {
pub mut:
	id      string            // Point ID
	payload map[string]string // Payload key-value pairs
	vector  ?[]f64            // Vector data (optional)
}

// Get a point by ID
pub fn (mut self QDrantClient) get_point(params GetPointParams) !QDrantResponse[GetPointResponse] {
	mut http_conn := self.httpclient()!

	mut url := '/collections/${params.collection_name}/points/${params.id}'

	// Add query parameters if provided
	mut query_params := []string{}
	if params.with_payload != none {
		query_params << 'with_payload=${params.with_payload}'
	}
	if params.with_vector != none {
		query_params << 'with_vector=${params.with_vector}'
	}

	if query_params.len > 0 {
		url += '?' + query_params.join('&')
	}

	req := httpconnection.Request{
		method: .get
		prefix: url
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error getting point: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[GetPointResponse], response.data)!
}

// Filter condition for field matching
pub struct FieldCondition {
pub mut:
	key           string  @[json: 'key'; required] // Field name to filter by
	match_        ?string @[json: 'match']         // Exact match value (string)
	match_integer ?int    @[json: 'match']         // Exact match value (integer)
	match_float   ?f64    @[json: 'match']         // Exact match value (float)
	match_bool    ?bool   @[json: 'match']         // Exact match value (boolean)
	range         ?Range  @[json: 'range']         // Range condition
}

// Range condition for numeric fields
pub struct Range {
pub mut:
	lt  ?f64 @[json: 'lt']  // Less than
	gt  ?f64 @[json: 'gt']  // Greater than
	gte ?f64 @[json: 'gte'] // Greater than or equal
	lte ?f64 @[json: 'lte'] // Less than or equal
}

// Filter structure for search operations
pub struct Filter {
pub mut:
	must     ?[]FieldCondition @[json: 'must']     // All conditions must match
	must_not ?[]FieldCondition @[json: 'must_not'] // None of the conditions should match
	should   ?[]FieldCondition @[json: 'should']   // At least one condition should match
}

// Parameters for searching points
@[params]
pub struct SearchParams {
pub mut:
	collection_name string  @[json: 'collection_name'; required] // Name of the collection
	vector          []f64   @[json: 'vector'; required]          // Vector to search for
	filter          ?Filter @[json: 'filter']                    // Filter conditions
	limit           int = 10     @[json: 'limit']                                 // Max number of results
	offset          ?int    @[json: 'offset']                    // Offset of the first result to return
	with_payload    ?bool   @[json: 'with_payload']              // Whether to include payload in the response
	with_vector     ?bool   @[json: 'with_vector']               // Whether to include vectors in the response
	score_threshold ?f64    @[json: 'score_threshold']           // Minimal score threshold
}

// Scored point in search results
pub struct ScoredPoint {
pub mut:
	id      string             @[json: 'id']      // Point ID
	payload ?map[string]string @[json: 'payload'] // Payload key-value pairs (optional)
	vector  ?[]f64             @[json: 'vector']  // Vector data (optional)
	score   f64                @[json: 'score']   // Similarity score
}

// Response structure for search operation
pub struct SearchResponse {
pub mut:
	points []ScoredPoint @[json: 'points'] // List of scored points
}

// Search for points based on vector similarity
pub fn (mut self QDrantClient) search(params SearchParams) !QDrantResponse[SearchResponse] {
	mut http_conn := self.httpclient()!

	req := httpconnection.Request{
		method: .post
		prefix: '/collections/${params.collection_name}/points/search'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error searching points: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[SearchResponse], response.data)!
}

// Points selector for delete operation
pub struct PointsSelector {
pub mut:
	points ?[]string @[json: 'points'] // List of point IDs to delete
	filter ?Filter   @[json: 'filter'] // Filter condition to select points for deletion
}

// Parameters for deleting points
@[params]
pub struct DeletePointsParams {
pub mut:
	collection_name string         @[json: 'collection_name'; required] // Name of the collection
	points_selector PointsSelector @[json: 'points_selector'; required] // Points selector
	wait            ?bool          @[json: 'wait']                      // Whether to wait until the changes have been applied
}

// Response structure for delete points operation
pub struct DeletePointsResponse {
pub mut:
	status       string @[json: 'status']
	operation_id int    @[json: 'operation_id']
}

// Delete points from a collection
pub fn (mut self QDrantClient) delete_points(params DeletePointsParams) !QDrantResponse[DeletePointsResponse] {
	mut http_conn := self.httpclient()!

	req := httpconnection.Request{
		method: .post
		prefix: '/collections/${params.collection_name}/points/delete'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error deleting points: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[DeletePointsResponse], response.data)!
}

// Parameters for counting points
@[params]
pub struct CountPointsParams {
pub mut:
	collection_name string  @[json: 'collection_name'; required] // Name of the collection
	filter          ?Filter @[json: 'filter']                    // Filter conditions
	exact           ?bool   @[json: 'exact']                     // Whether to calculate exact count
}

// Response structure for count operation
pub struct CountResponse {
pub mut:
	count int @[json: 'count'] // Number of points matching the filter
}

// Count points in a collection
pub fn (mut self QDrantClient) count_points(params CountPointsParams) !QDrantResponse[CountResponse] {
	mut http_conn := self.httpclient()!

	req := httpconnection.Request{
		method: .post
		prefix: '/collections/${params.collection_name}/points/count'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error counting points: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[CountResponse], response.data)!
}

// Parameters for setting payload
@[params]
pub struct SetPayloadParams {
pub mut:
	collection_name string            @[json: 'collection_name'; required] // Name of the collection
	payload         map[string]string @[json: 'payload'; required]         // Payload to set
	points          ?[]string         @[json: 'points']                    // List of point IDs to set payload for
	filter          ?Filter           @[json: 'filter']                    // Filter condition to select points
	wait            ?bool             @[json: 'wait']                      // Whether to wait until the changes have been applied
}

// Response structure for payload operations
pub struct PayloadOperationResponse {
pub mut:
	status       string @[json: 'status']
	operation_id int    @[json: 'operation_id']
}

// Set payload for points
pub fn (mut self QDrantClient) set_payload(params SetPayloadParams) !QDrantResponse[PayloadOperationResponse] {
	mut http_conn := self.httpclient()!

	req := httpconnection.Request{
		method: .post
		prefix: '/collections/${params.collection_name}/points/payload'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error setting payload: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[PayloadOperationResponse], response.data)!
}

// Parameters for deleting payload
@[params]
pub struct DeletePayloadParams {
pub mut:
	collection_name string    @[json: 'collection_name'; required] // Name of the collection
	keys            []string  @[json: 'keys'; required]            // List of payload keys to delete
	points          ?[]string @[json: 'points']                    // List of point IDs to delete payload from
	filter          ?Filter   @[json: 'filter']                    // Filter condition to select points
	wait            ?bool     @[json: 'wait']                      // Whether to wait until the changes have been applied
}

// Delete payload for points
pub fn (mut self QDrantClient) delete_payload(params DeletePayloadParams) !QDrantResponse[PayloadOperationResponse] {
	mut http_conn := self.httpclient()!

	req := httpconnection.Request{
		method: .post
		prefix: '/collections/${params.collection_name}/points/payload/delete'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error deleting payload: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[PayloadOperationResponse], response.data)!
}

// Parameters for clearing payload
@[params]
pub struct ClearPayloadParams {
pub mut:
	collection_name string    @[json: 'collection_name'; required] // Name of the collection
	points          ?[]string @[json: 'points']                    // List of point IDs to clear payload for
	filter          ?Filter   @[json: 'filter']                    // Filter condition to select points
	wait            ?bool     @[json: 'wait']                      // Whether to wait until the changes have been applied
}

// Clear payload for points
pub fn (mut self QDrantClient) clear_payload(params ClearPayloadParams) !QDrantResponse[PayloadOperationResponse] {
	mut http_conn := self.httpclient()!

	req := httpconnection.Request{
		method: .post
		prefix: '/collections/${params.collection_name}/points/payload/clear'
		data:   json.encode(params)
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error clearing payload: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[PayloadOperationResponse], response.data)!
}
