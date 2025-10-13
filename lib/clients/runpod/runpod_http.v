module runpod

import x.json2
import net.http { Method }
import incubaid.herolib.core.httpconnection

// GraphQL response wrapper
struct GqlResponse[T] {
pub mut:
	data   map[string]T
	errors []map[string]string
}

// #### Internally method doing a network call to create a new on-demand pod.
// - Build the required query based pn the input sent by the user and send the request.
// - Decode the response received from the API into two objects `Data` and `Error`.
// - The data field should contains the pod details same as `PodResult` struct.
// - The error field should contain the error message.
fn (mut rp RunPod) create_on_demand_pod_request(input PodFindAndDeployOnDemandRequest) !PodResult {
	mut fields := []Field{}
	mut machine_fields := []Field{}
	mut output_fields := []Field{}
	mut builder := QueryBuilder{}

	machine_fields << new_field(name: 'podHostId')
	output_fields << new_field(name: 'id')
	output_fields << new_field(name: 'imageName')
	output_fields << new_field(name: 'env')
	output_fields << new_field(name: 'machineId')
	output_fields << new_field(name: 'desiredStatus')
	output_fields << new_field(name: 'machine', sub_fields: machine_fields)
	fields << new_field(
		name:       'podFindAndDeployOnDemand'
		arguments:  {
			'input': '\$arguments'
		}
		sub_fields: output_fields
	)

	builder.add_operation(
		operation: .mutation
		fields:    fields
		variables: {
			'\$arguments': 'PodFindAndDeployOnDemandInput'
		}
	)
	mut variables := {
		'arguments': json2.Any(type_to_map(input)!)
	}
	query := builder.build_query(variables: variables)

	response := rp.make_request[GqlResponse[PodResult]](.post, '/graphql', query)!
	return response.data['podFindAndDeployOnDemand'] or {
		return error('Could not find "podFindAndDeployOnDemand" in response data: ${response.data}')
	}
}

// #### Internally method doing a network call to create a new spot pod.
// - Build the required query based pn the input sent by the user and send the request.
// - Decode the response received from the API into two objects `Data` and `Error`.
// - The data field should contains the pod details same as `PodResult` struct.
// - The error field should contain the error message.
fn (mut rp RunPod) create_spot_pod_request(input PodRentInterruptableInput) !PodResult {
	mut fields := []Field{}
	mut machine_fields := []Field{}
	mut output_fields := []Field{}
	mut builder := QueryBuilder{}

	machine_fields << new_field(name: 'podHostId')
	output_fields << new_field(name: 'id')
	output_fields << new_field(name: 'imageName')
	output_fields << new_field(name: 'env')
	output_fields << new_field(name: 'machineId')
	output_fields << new_field(name: 'desiredStatus')
	output_fields << new_field(name: 'machine', sub_fields: machine_fields)
	fields << new_field(
		name:       'podRentInterruptable'
		arguments:  {
			'input': '\$arguments'
		}
		sub_fields: output_fields
	)

	builder.add_operation(
		operation: .mutation
		fields:    fields
		variables: {
			'\$arguments': 'PodRentInterruptableInput!'
		}
	)
	mut variables := {
		'arguments': json2.Any(type_to_map(input)!)
	}
	query := builder.build_query(variables: variables)

	response := rp.make_request[GqlResponse[PodResult]](.post, '/graphql', query)!
	return response.data['podRentInterruptable'] or {
		return error('Could not find "podRentInterruptable" in response data: ${response.data}')
	}
}

// #### Internally method doing a network call to start on demand pod.
// - Build the required query based pn the input sent by the user and send the request.
// - Decode the response received from the API into two objects `Data` and `Error`.
// - The data field should contains the pod details same as `PodResult` struct.
// - The error field should contain the error message.
fn (mut rp RunPod) start_on_demand_pod_request(input PodResumeInput) !PodResult {
	mut fields := []Field{}
	mut machine_fields := []Field{}
	mut output_fields := []Field{}
	mut builder := QueryBuilder{}

	machine_fields << new_field(name: 'podHostId')
	output_fields << new_field(name: 'id')
	output_fields << new_field(name: 'imageName')
	output_fields << new_field(name: 'env')
	output_fields << new_field(name: 'machineId')
	output_fields << new_field(name: 'desiredStatus')
	output_fields << new_field(name: 'machine', sub_fields: machine_fields)
	fields << new_field(
		name:       'podResume'
		arguments:  {
			'input': '\$arguments'
		}
		sub_fields: output_fields
	)

	builder.add_operation(
		operation: .mutation
		fields:    fields
		variables: {
			'\$arguments': 'PodResumeInput!'
		}
	)
	mut variables := {
		'arguments': json2.Any(type_to_map(input)!)
	}
	query := builder.build_query(variables: variables)

	response := rp.make_request[GqlResponse[PodResult]](.post, '/graphql', query)!
	return response.data['podResume'] or {
		return error('Could not find "podResume" in response data: ${response.data}')
	}
}

// #### Internally method doing a network call to start spot pod.
// - Build the required query based pn the input sent by the user and send the request.
// - Decode the response received from the API into two objects `Data` and `Error`.
// - The data field should contains the pod details same as `PodResult` struct.
// - The error field should contain the error message.
fn (mut rp RunPod) start_spot_pod_request(input PodBidResumeInput) !PodResult {
	mut fields := []Field{}
	mut machine_fields := []Field{}
	mut output_fields := []Field{}
	mut builder := QueryBuilder{}

	machine_fields << new_field(name: 'podHostId')
	output_fields << new_field(name: 'id')
	output_fields << new_field(name: 'imageName')
	output_fields << new_field(name: 'env')
	output_fields << new_field(name: 'machineId')
	output_fields << new_field(name: 'desiredStatus')
	output_fields << new_field(name: 'machine', sub_fields: machine_fields)
	fields << new_field(
		name:       'podBidResume'
		arguments:  {
			'input': '\$arguments'
		}
		sub_fields: output_fields
	)

	builder.add_operation(
		operation: .mutation
		fields:    fields
		variables: {
			'\$arguments': 'PodBidResumeInput!'
		}
	)
	mut variables := {
		'arguments': json2.Any(type_to_map(input)!)
	}
	query := builder.build_query(variables: variables)

	response := rp.make_request[GqlResponse[PodResult]](.post, '/graphql', query)!
	return response.data['podBidResume'] or {
		return error('Could not find "podBidResume" in response data: ${response.data}')
	}
}

// #### Internally method doing a network call to stop a pod.
// - Build the required query based pn the input sent by the user and send the request.
// - Decode the response received from the API into two objects `Data` and `Error`.
// - The data field should contains the pod details same as `PodResult` struct.
// - The error field should contain the error message.
fn (mut rp RunPod) stop_pod_request(input PodStopInput) !PodResult {
	mut fields := []Field{}
	mut machine_fields := []Field{}
	mut output_fields := []Field{}
	mut builder := QueryBuilder{}

	machine_fields << new_field(name: 'podHostId')
	output_fields << new_field(name: 'id')
	output_fields << new_field(name: 'imageName')
	output_fields << new_field(name: 'env')
	output_fields << new_field(name: 'machineId')
	output_fields << new_field(name: 'desiredStatus')
	output_fields << new_field(name: 'machine', sub_fields: machine_fields)
	fields << new_field(
		name:       'podStop'
		arguments:  {
			'input': '\$arguments'
		}
		sub_fields: output_fields
	)

	builder.add_operation(
		operation: .mutation
		fields:    fields
		variables: {
			'\$arguments': 'PodStopInput!'
		}
	)
	mut variables := {
		'arguments': json2.Any(type_to_map(input)!)
	}
	query := builder.build_query(variables: variables)

	response := rp.make_request[GqlResponse[PodResult]](.post, '/graphql', query)!
	return response.data['podStop'] or {
		return error('Could not find "podStop" in response data: ${response.data}')
	}
}

fn (mut rp RunPod) terminate_pod_request(input PodTerminateInput) ! {
	mut fields := []Field{}
	mut builder := QueryBuilder{}

	fields << new_field(
		name:      'podTerminate'
		arguments: {
			'input': '\$arguments'
		}
	)

	builder.add_operation(
		operation: .mutation
		fields:    fields
		variables: {
			'\$arguments': 'PodTerminateInput!'
		}
	)
	mut variables := {
		'arguments': json2.Any(type_to_map(input)!)
	}
	query := builder.build_query(variables: variables)

	response := rp.make_request[GqlResponse[PodResult]](.post, '/graphql', query)!
	_ := response.data['podTerminate'] or {
		return error('Could not find "podTerminate" in response data: ${response.data}')
	}
}

fn (mut rp RunPod) get_pod_request(input PodFilter) !PodResult {
	mut fields := []Field{}
	mut machine_fields := []Field{}
	mut output_fields := []Field{}
	mut builder := QueryBuilder{}

	machine_fields << new_field(name: 'podHostId')
	output_fields << new_field(name: 'id')
	output_fields << new_field(name: 'imageName')
	output_fields << new_field(name: 'env')
	output_fields << new_field(name: 'machineId')
	output_fields << new_field(name: 'desiredStatus')
	output_fields << new_field(name: 'machine', sub_fields: machine_fields)
	fields << new_field(
		name:       'pod'
		arguments:  {
			'input': '\$arguments'
		}
		sub_fields: output_fields
	)

	builder.add_operation(
		operation: .query
		fields:    fields
		variables: {
			'\$arguments': 'PodFilter'
		}
	)
	mut variables := {
		'arguments': json2.Any(type_to_map(input)!)
	}
	query := builder.build_query(variables: variables)

	response := rp.make_request[GqlResponse[PodResult]](.post, '/graphql', query)!
	return response.data['pod'] or {
		return error('Could not find "pod" in response data: ${response.data}')
	}
}

// Represents the main structure for interacting with the RunPod API.
// Provides utilities to manage HTTP connections and perform GraphQL queries.
fn (mut rp RunPod) httpclient() !&httpconnection.HTTPConnection {
	mut http_conn := httpconnection.new(
		name:  'runpod_vclient_${rp.name}'
		url:   rp.base_url
		cache: true
		retry: 3
	)!
	http_conn.default_header.add(.authorization, 'Bearer ${rp.api_key}')
	return http_conn
}

// Sends an HTTP request to the RunPod API with the specified method, path, and data.
fn (mut rp RunPod) make_request[T](method Method, path string, data string) !T {
	mut request := httpconnection.Request{
		prefix:     path
		data:       data
		debug:      true
		dataformat: .json
	}

	mut http_client := rp.httpclient()!
	mut response := T{}

	match method {
		.get {
			request.method = .get
			response = http_client.get_json_generic[T](request)!
		}
		.post {
			request.method = .post
			response = http_client.post_json_generic[T](request)!
		}
		.put {
			request.method = .put
			response = http_client.put_json_generic[T](request)!
		}
		.delete {
			request.method = .delete
			response = http_client.delete_json_generic[T](request)!
		}
		else {
			return error('unsupported method: ${method}')
		}
	}

	if response.errors.len > 0 {
		return error('Error while sending the request due to: ${response.errors[0]['message']}')
	}

	return response
}
