# Qdrant Client for HeroLib

This is a V client for [Qdrant](https://qdrant.tech/), a high-performance vector database and similarity search engine.

## Features

- Collection management (create, list, delete, get info)
- Points management (upsert, delete, search, get)
- Service information and health checks
- Support for filters, payload management, and vector operations

## Usage

### Initialize Client

```v
// Create a new Qdrant client
import incubaid.herolib.clients.qdrant

mut client := qdrant.get()!

// Or create with custom configuration
mut custom_client := qdrant.QDrantClient{
    name: 'custom',
    url: 'http://localhost:6333',
    secret: 'your_api_key' // Optional
}
qdrant.set(custom_client)!
```

### Collection Management

```v
// Create a collection
vectors_config := qdrant.VectorsConfig{
    size: 128,
    distance: .cosine
}

client.create_collection(
    collection_name: 'my_collection',
    vectors: vectors_config
)!

// List all collections
collections := client.list_collections()!

// Get collection info
collection_info := client.get_collection(
    collection_name: 'my_collection'
)!

// Delete a collection
client.delete_collection(
    collection_name: 'my_collection'
)!
```

### Points Management

```v
// Upsert points
points := [
    qdrant.PointStruct{
        id: '1',
        vector: [f32(0.1), 0.2, 0.3, 0.4],
        payload: {
            'color': 'red',
            'category': 'furniture'
        }
    },
    qdrant.PointStruct{
        id: '2',
        vector: [f32(0.2), 0.3, 0.4, 0.5],
        payload: {
            'color': 'blue',
            'category': 'electronics'
        }
    }
]

client.upsert_points(
    collection_name: 'my_collection',
    points: points,
    wait: true
)!

// Search for points
search_result := client.search(
    collection_name: 'my_collection',
    vector: [f32(0.1), 0.2, 0.3, 0.4],
    limit: 10
)!

// Get a point by ID
point := client.get_point(
    collection_name: 'my_collection',
    id: '1'
)!

// Delete points
client.delete_points(
    collection_name: 'my_collection',
    points_selector: qdrant.PointsSelector{
        points: ['1', '2']
    },
    wait: true
)!
```

### Service Information

```v
// Get service info
service_info := client.get_service_info()!

// Check health
is_healthy := client.health_check()!
```

## Advanced Usage

### Filtering

```v
// Create a filter
filter := qdrant.Filter{
    must: [
        qdrant.FieldCondition{
            key: 'color',
            match: 'red'
        },
        qdrant.FieldCondition{
            key: 'price',
            range: qdrant.Range{
                gte: 10.0,
                lt: 100.0
            }
        }
    ]
}

// Search with filter
search_result := client.search(
    collection_name: 'my_collection',
    vector: [f32(0.1), 0.2, 0.3, 0.4],
    filter: filter,
    limit: 10
)!
```

## Example HeroScript

```hero
!!qdrant.configure
    name: 'default'
    secret: 'your_api_key'
    url: 'http://localhost:6333'
```

## Installation

Qdrant server can be installed using the provided installer script:

```bash
~/code/github/incubaid/herolib/examples/installers/db/qdrant.vsh
```

This will install and start a Qdrant server locally.
