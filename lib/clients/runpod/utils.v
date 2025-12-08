module runpod

import incubaid.herolib.core.httpconnection
import x.json2

enum OperationType {
	query
	mutation
}

struct QueryBuilder {
pub mut:
	operation OperationType
	fields    []Field
	variables map[string]string
}

struct Field {
	name       string
	arguments  map[string]string
	sub_fields []Field
}

@[params]
pub struct NewFieldArgs {
pub:
	name       string
	arguments  map[string]string
	sub_fields []Field
}

fn new_field(args NewFieldArgs) Field {
	return Field{
		name:       args.name
		arguments:  args.arguments
		sub_fields: args.sub_fields
	}
}

fn build_arguments(args map[string]string) string {
	if args.len == 0 {
		return ''
	}

	mut sb := ''
	sb += '('

	for key, value in args {
		if value.len == 0 {
			continue
		}

		sb += '${key}: ${value}, '
	}

	return sb.trim_right(', ') + ')'
}

fn build_fields(fields []Field) string {
	mut sb := ' { '
	for field in fields {
		sb += field.name
		if field.arguments.len > 0 {
			sb += build_arguments(field.arguments)
		}

		if field.sub_fields.len > 0 {
			sb += build_fields(field.sub_fields)
		}

		sb += ' '
	}
	sb += ' } '
	return sb
}

@[params]
pub struct AddOperationArgs {
pub:
	operation OperationType
	fields    []Field
	variables map[string]string
}

fn (mut q QueryBuilder) add_operation(args AddOperationArgs) {
	q.operation = args.operation
	q.fields = args.fields
	q.variables = args.variables.clone()
}

@[params]
pub struct BuildQueryArgs {
pub:
	variables map[string]json2.Any
}

fn (q QueryBuilder) build_query(args BuildQueryArgs) string {
	mut query := ''
	query += '${q.operation}' + ' myOperation'

	if q.variables.len > 0 {
		query += build_arguments(q.variables)
	}

	query += build_fields(q.fields)

	mut q_map := {
		'query':     json2.Any(query)
		'variables': json2.Any(args.variables)
	}

	return json2.encode(q_map)
}

fn type_to_map[T](t T) !map[string]json2.Any {
	encoded_input := json2.encode(t)
	    return json2.decode[json2.Any](encoded_input)!.as_map()
}
