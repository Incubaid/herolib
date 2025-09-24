# Key-Value HTTP Service with Master-Worker Architecture over Mycelium

## Overview

This project implements a distributed key-value storage service exposed via an HTTP API. It uses a master-worker architecture to handle read and write operations efficiently, with internal communication facilitated by the [Mycelium network](https://github.com/threefoldtech/mycelium). The system is built in [V](https://vlang.io/) and uses [OurDB](https://github.com/incubaid/herolib/tree/main/lib/data/ourdb) for embedded key-value storage.

### Key Features

- **HTTP API**: Users can perform `GET` (read), `SET` (write), and `DELETE` operations on key-value pairs via an HTTP server.
- **Master-Worker Architecture**:
  - **Master**: Handles all write operations (`SET`, `DELETE`) to ensure data consistency.
  - **Workers**: Handle read operations (`GET`) to distribute the load.
- **Data Synchronization**: Changes made by the master are propagated to all workers to ensure consistent reads.
- **Mycelium Integration**: Internal communication between the HTTP server, master, and workers is handled over the Mycelium network, an encrypted IPv6 overlay network.
- **Embedded Storage**: Uses OurDB, a lightweight embedded key-value database, for data persistence on each node.

### Use Case

This service is ideal for applications requiring a simple, distributed key-value store with strong consistency guarantees, such as configuration management, decentralized data sharing, or caching in a peer-to-peer network.

## Architecture

The system is designed with a clear separation of concerns, ensuring scalability and consistency. Below is a simplified diagram of the architecture:

```
+-----------------+
|     User        |
| (HTTP Client)   |
+-----------------+
          |
          | HTTP Requests
          v
+-----------------+
|   HTTP Server   |<----+
+-----------------+     | External Interface
          |             |
          | Mycelium    |
          | Network     |
          v             v
+-----------------+     +-----------------+
|    Master       |---->|    Workers      |
| (Writes)        |     | (Reads)         |
|    OurDB        |     |    OurDB        |
+-----------------+     +-----------------+
```

### Components

1. **HTTP Server**:
   - Acts as the entry point for user requests.
   - Routes write requests (`SET`, `DELETE`) to the master.
   - Routes read requests (`GET`) to one of the workers (e.g., using load balancing).

2. **Master**:
   - Handles all write operations to ensure data consistency.
   - Stores data in a local OurDB instance.
   - Propagates updates to workers via the Mycelium network.

3. **Workers**:
   - Handle read operations to distribute the load.
   - Store a synchronized copy of the data in a local OurDB instance.
   - Receive updates from the master via the Mycelium network.

4. **Mycelium Network**:
   - Provides secure, encrypted peer-to-peer communication between the HTTP server, master, and workers.

5. **OurDB**:
   - An embedded key-value database used by the master and workers for data storage.

## Prerequisites

To run this project, you need the following:

- [V](https://vlang.io/) (Vlang compiler) installed.
- [Mycelium](https://github.com/threefoldtech/mycelium) network configured (either public or private).
- [OurDB](https://github.com/incubaid/herolib/tree/main/lib/data/ourdb) library included in your project (part of the HeroLib suite).

## Installation

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <repository-name>
   ```

2. **Install Dependencies**:
   Ensure V is installed and the `ourdb` library is available. You may need to pull the HeroLib dependencies:
   ```bash
   v install
   ```

3. **Configure Mycelium**:
   - Set up a Mycelium network (public or private) and note the addresses of the master and worker nodes.
   - Update the configuration in the HTTP server to point to the correct Mycelium addresses.

4. **Build the Project**:
   Compile the V code for the HTTP server, master, and workers:
   ```bash
   v run main.v
   ```

## Usage

### Running the System

1. **Start the Master**:
   Run the master node to handle write operations:
   ```bash
   v run master.v
   ```

2. **Start the Workers**:
   Run one or more worker nodes to handle read operations:
   ```bash
   v run worker.v
   ```

3. **Start the HTTP Server**:
   Run the HTTP server to expose the API to users:
   ```bash
   v run server.v
   ```

### Making Requests

The HTTP server exposes the following endpoints:

- **SET a Key-Value Pair**:
  ```bash
  curl -X POST http://localhost:8080/set -d "key=mykey&value=myvalue"
  ```
  - Writes the key-value pair to the master, which syncs it to workers.

- **GET a Value by Key**:
  ```bash
  curl http://localhost:8080/get?key=mykey
  ```
  - Retrieves the value from a worker.

- **DELETE a Key**:
  ```bash
  curl -X POST http://localhost:8080/delete -d "key=mykey"
  ```
  - Deletes the key-value pair via the master, which syncs the deletion to workers.

## Development

### Code Structure

- streamer
   - `streamer.v`: Implements the HTTP server and request routing logic.
   - `nodes.v`: Implements the master/worker node, handling writes and synchronization.

- http_server
   - `server.v`: Implements the HTTP server and request routing logic.

- examples
   - `master_example.v`: A simple example that starts the streamer and master node.
   - `worker_example.v`: A simple example that starts the streamer and worker node.
   - `db_example.v`: A simple example that starts the streamer, master, and worker nodes.

### Extending the System

- **Add More Workers**: Scale the system by starting additional worker nodes and updating the HTTP server’s worker list.
- **Enhance Synchronization**: Implement more advanced replication strategies (e.g., conflict resolution, versioning) if needed.
- **Improve Load Balancing**: Add sophisticated load balancing for read requests (e.g., based on worker load or latency).
