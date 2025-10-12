module graphdb

import incubaid.herolib.data.encoder

const version_v1 = u8(1)

// Serializes a Node struct to bytes
pub fn serialize_node(node Node) []u8 {
	mut e := encoder.new()

	// Add version byte
	e.add_u8(version_v1)

	// Serialize node ID
	e.add_u32(node.id)

	// Serialize node type
	e.add_string(node.node_type)

	// Serialize properties
	e.add_u16(u16(node.properties.len)) // Number of properties
	for key, value in node.properties {
		e.add_string(key)
		e.add_string(value)
	}

	// Serialize outgoing edges
	e.add_u16(u16(node.edges_out.len)) // Number of outgoing edges
	for edge in node.edges_out {
		e.add_u32(edge.edge_id)
		e.add_string(edge.edge_type)
	}

	// Serialize incoming edges
	e.add_u16(u16(node.edges_in.len)) // Number of incoming edges
	for edge in node.edges_in {
		e.add_u32(edge.edge_id)
		e.add_string(edge.edge_type)
	}

	return e.data
}

// Deserializes bytes to a Node struct
pub fn deserialize_node(data []u8) !Node {
	if data.len < 1 {
		return error('Invalid node data: too short')
	}

	mut d := encoder.decoder_new(data)

	// Check version
	version := d.get_u8()!
	if version != version_v1 {
		return error('Unsupported version: ${version}')
	}

	mut node := Node{
		properties: map[string]string{}
		edges_out:  []EdgeRef{}
		edges_in:   []EdgeRef{}
	}

	// Deserialize node ID
	node.id = d.get_u32()!

	// Deserialize node type
	node.node_type = d.get_string()!

	// Deserialize properties
	num_properties := d.get_u16()!
	for _ in 0 .. num_properties {
		key := d.get_string()!
		value := d.get_string()!
		node.properties[key] = value
	}

	// Deserialize outgoing edges
	num_edges_out := d.get_u16()!
	for _ in 0 .. num_edges_out {
		edge_id := d.get_u32()!
		edge_type := d.get_string()!
		node.edges_out << EdgeRef{
			edge_id:   edge_id
			edge_type: edge_type
		}
	}

	// Deserialize incoming edges
	num_edges_in := d.get_u16()!
	for _ in 0 .. num_edges_in {
		edge_id := d.get_u32()!
		edge_type := d.get_string()!
		node.edges_in << EdgeRef{
			edge_id:   edge_id
			edge_type: edge_type
		}
	}

	return node
}

// Serializes an Edge struct to bytes
pub fn serialize_edge(edge Edge) []u8 {
	mut e := encoder.new()

	// Add version byte
	e.add_u8(version_v1)

	// Serialize edge ID
	e.add_u32(edge.id)

	// Serialize edge metadata
	e.add_u32(edge.from_node)
	e.add_u32(edge.to_node)
	e.add_string(edge.edge_type)
	e.add_u16(edge.weight)

	// Serialize properties
	e.add_u16(u16(edge.properties.len))
	for key, value in edge.properties {
		e.add_string(key)
		e.add_string(value)
	}

	return e.data
}

// Deserializes bytes to an Edge struct
pub fn deserialize_edge(data []u8) !Edge {
	if data.len < 1 {
		return error('Invalid edge data: too short')
	}

	mut d := encoder.decoder_new(data)

	// Check version
	version := d.get_u8()!
	if version != version_v1 {
		return error('Unsupported version: ${version}')
	}

	mut edge := Edge{
		properties: map[string]string{}
	}

	// Deserialize edge ID
	edge.id = d.get_u32()!

	// Deserialize edge metadata
	edge.from_node = d.get_u32()!
	edge.to_node = d.get_u32()!
	edge.edge_type = d.get_string()!
	edge.weight = d.get_u16()!

	// Deserialize properties
	num_properties := d.get_u16()!
	for _ in 0 .. num_properties {
		key := d.get_string()!
		value := d.get_string()!
		edge.properties[key] = value
	}

	return edge
}
