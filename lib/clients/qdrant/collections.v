module qdrant

import incubaid.herolib.core.httpconnection
import json

// Configuration of the collection
pub struct CollectionConfig {
pub mut:
	params              CollectionParams    // Collection parameters
	hnsw_config         HNSWConfig          // HNSW configuration
	optimizer_config    OptimizerConfig     // Optimizer configuration
	wal_config          WALConfig           // WAL configuration
	quantization_config ?QuantizationConfig // Optional quantization configuration, Nullable field
	strict_mode_config  StrictModeConfig    // Strict mode configuration
}

// Parameters of the collection
pub struct CollectionParams {
pub mut:
	vectors                  VectorConfig // Vector configuration
	shard_number             int          // Number of shards
	replication_factor       int          // Replication factor
	write_consistency_factor int          // Write consistency factor
	on_disk_payload          bool         // On-disk payload
}

// Vector configuration
pub struct VectorConfig {
pub mut:
	size     int    // Size of the vectors
	distance string // Distance function
}

// HNSW (Hierarchical Navigable Small World) configuration
pub struct HNSWConfig {
pub mut:
	m                    int  // Number of neighbors
	ef_construct         int  // Number of neighbors
	full_scan_threshold  int  // Full scan threshold
	max_indexing_threads int  // Maximum indexing threads
	on_disk              bool // On-disk storage
}

// Optimizer configuration
pub struct OptimizerConfig {
pub mut:
	deleted_threshold        f64  // Deleted threshold
	vacuum_min_vector_number int  // Minimum vector number
	default_segment_number   int  // Default segment number
	max_segment_size         ?int // Nullable field
	memmap_threshold         ?int // Nullable field
	indexing_threshold       int  // Indexing threshold
	flush_interval_sec       int  // Flush interval
	max_optimization_threads ?int // Nullable field
}

// Write-Ahead Log (WAL) configuration
pub struct WALConfig {
pub mut:
	wal_capacity_mb    int // WAL capacity in megabytes
	wal_segments_ahead int // WAL segments ahead
}

// Quantization configuration (nullable)
pub struct QuantizationConfig {
pub mut:
	scalar ?ScalarQuantization // Nullable field
}

// Scalar quantization configuration
pub struct ScalarQuantization {
pub mut:
	typ string @[json: 'type'] // Quantization type
}

// Strict mode configuration
pub struct StrictModeConfig {
pub mut:
	enabled bool // Enabled
}

// Result field containing detailed information about the collection
pub struct GetCollectionResponse {
pub mut:
	status                string            // Status
	optimizer_status      string            // Optimizer status
	indexed_vectors_count int               // Indexed vectors count
	points_count          int               // Points count
	segments_count        int               // Segments count
	config                CollectionConfig  // Collection configuration
	payload_schema        map[string]string // Payload schema
}

// Get a collection arguments
@[params]
pub struct GetCollectionParams {
pub mut:
	collection_name string @[required] // Name of the collection
}

// Get a collection
pub fn (mut self QDrantClient) get_collection(params GetCollectionParams) !QDrantResponse[GetCollectionResponse] {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .get
		prefix: '/collections/${params.collection_name}'
	}

	mut response := http_conn.get_json(req)!
	return json.decode(QDrantResponse[GetCollectionResponse], response)!
}

// Create a collection arguments
@[params]
pub struct CreateCollectionParams {
pub mut:
	collection_name string @[required] // Name of the collection
	size            int    @[required] // Size of the vectors
	distance        string @[required] // Distance function
}

// Create a collection
pub fn (mut self QDrantClient) create_collection(params CreateCollectionParams) !QDrantResponse[bool] {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .put
		prefix: '/collections/${params.collection_name}'
		data:   json.encode(VectorConfig{
			size:     params.size
			distance: params.distance
		})
	}

	mut response := http_conn.send(req)!

	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error creating collection: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[bool], response.data)!
}

// Delete a collection arguments
@[params]
pub struct DeleteCollectionParams {
pub mut:
	collection_name string @[required] // Name of the collection
}

// Delete a collection
pub fn (mut self QDrantClient) delete_collection(params DeleteCollectionParams) !QDrantResponse[bool] {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .delete
		prefix: '/collections/${params.collection_name}'
	}

	mut response := http_conn.send(req)!
	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error deleting collection: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[bool], response.data)!
}

// Get a collection arguments
@[params]
pub struct ListCollectionParams {
	collections []CollectionNameParams // List of collection names
}

// Get a collection arguments
@[params]
pub struct CollectionNameParams {
pub mut:
	collection_name string @[json: 'name'; required] // Name of the collection
}

// List a collection
pub fn (mut self QDrantClient) list_collections() !QDrantResponse[ListCollectionParams] {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .get
		prefix: '/collections'
	}

	mut response := http_conn.send(req)!
	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error listing collection: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[ListCollectionParams], response.data)!
}

// Check collection existence
pub struct CollectionExistenceResponse {
pub mut:
	exists bool // Collection existence
}

// Check collection existence
@[params]
pub struct CollectionExistenceParams {
pub mut:
	collection_name string @[json: 'name'; required] // Name of the collection
}

// Check collection existence
pub fn (mut self QDrantClient) is_collection_exists(params CollectionExistenceParams) !QDrantResponse[CollectionExistenceResponse] {
	mut http_conn := self.httpclient()!
	req := httpconnection.Request{
		method: .get
		prefix: '/collections/${params.collection_name}/exists'
	}

	mut response := http_conn.send(req)!
	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error checking collection: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[CollectionExistenceResponse], response.data)!
}

// Parameters for creating an index
@[params]
pub struct CreateIndexParams {
pub mut:
	collection_name string      @[json: 'collection_name'; required] // Name of the collection
	field_name      string      @[json: 'field_name'; required]      // Name of the field to create index for
	field_schema    FieldSchema @[json: 'field_schema'; required]    // Schema of the field
	wait            ?bool       @[json: 'wait']                      // Whether to wait until the changes have been applied
}

// Field schema for index
pub struct FieldSchema {
pub mut:
	field_type string @[json: 'type'; required] // Type of the field (keyword, integer, float, geo)
}

// Response structure for index operations
pub struct IndexOperationResponse {
pub mut:
	status       string @[json: 'status']
	operation_id int    @[json: 'operation_id']
}

// Create an index for a field in a collection
pub fn (mut self QDrantClient) create_index(params CreateIndexParams) !QDrantResponse[IndexOperationResponse] {
	mut http_conn := self.httpclient()!

	mut data := {
		'field_name':   params.field_name
		'field_schema': json.encode(params.field_schema)
	}

	if params.wait != none {
		data['wait'] = params.wait.str()
	}

	req := httpconnection.Request{
		method: .put
		prefix: '/collections/${params.collection_name}/index'
		data:   json.encode(data)
	}

	mut response := http_conn.send(req)!
	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error creating index: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[IndexOperationResponse], response.data)!
}

// Parameters for deleting an index
@[params]
pub struct DeleteIndexParams {
pub mut:
	collection_name string @[json: 'collection_name'; required] // Name of the collection
	field_name      string @[json: 'field_name'; required]      // Name of the field to delete index for
	wait            ?bool  @[json: 'wait']                      // Whether to wait until the changes have been applied
}

// Delete an index for a field in a collection
pub fn (mut self QDrantClient) delete_index(params DeleteIndexParams) !QDrantResponse[IndexOperationResponse] {
	mut http_conn := self.httpclient()!

	mut url := '/collections/${params.collection_name}/index/${params.field_name}'

	if params.wait != none {
		url += '?wait=${params.wait}'
	}

	req := httpconnection.Request{
		method: .delete
		prefix: url
	}

	mut response := http_conn.send(req)!
	if response.code >= 400 {
		error_ := json.decode(QDrantErrorResponse, response.data)!
		return error('Error deleting index: ' + error_.status.error)
	}

	return json.decode(QDrantResponse[IndexOperationResponse], response.data)!
}
