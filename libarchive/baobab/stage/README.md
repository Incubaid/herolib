
# Stage Module

The **Stage** module is a core component of the **Baobab** (Base Object and Actor Backend) library. It provides the infrastructure for handling RPC-based communication and managing the lifecycle of **Actors** and **Actions**. This module facilitates processing incoming requests, converting them to actions, and ensuring their correct execution.

## Architecture Overview

The **Stage** module operates based on the following architecture:

1. **RPC Request Handling**:
   - An **Interface Handler** receives an RPC request. Supported interfaces include:
     - **OpenRPC**
     - **JSON-RPC**
     - **OpenAPI**

2. **Action Creation**:
   - The **Interface Handler** converts the incoming request into an **Action**, which represents the task to be executed.

3. **Action Execution**:
   - The **Interface Handler** passes the **Action** to the **Director** for coordinated execution.
   - (Note: Currently, the **Director** is not fully implemented. Actions are passed directly to the **Actor** for execution.)

4. **Actor Processing**:
   - The **Actor** uses its `act` method to execute the **Action**.
   - The result of the **Action** is stored in its `result` field, and the **Action** is returned.

5. **RPC Response Generation**:
   - The **Interface Handler** converts the resulting **Action** back into the appropriate RPC response format and returns it.

---

## Key Components

### **Interface Handlers**
- **Responsibilities**:
  - Receive and parse incoming RPC requests.
  - Convert requests into **Actions**.
  - Convert resulting **Actions** into appropriate RPC responses.
- Files:
  - `interfaces/jsonrpc_interface.v`
  - `interfaces/openapi_interface.v`

### **Director**
- **Responsibilities**:
  - (Planned) Coordinate the execution of **Actions**.
  - Handle retries, timeouts, and error recovery.
- File:
  - `director.v`

### **Actors**
- **Responsibilities**:
  - Execute **Actions** using their `act` method.
  - Populate the `result` field of **Actions** with the execution result.
- File:
  - `actor.v`

### **Actions**
- **Responsibilities**:
  - Represent tasks to be executed by **Actors**.
  - Carry results back after execution.
- File:
  - `action.v`

### **Executor**
- **Responsibilities**:
  - Manage the assignment of **Actions** to **Actors**.
- File:
  - `executor.v`

---

## Directory Structure

```
stage/
  interfaces/
    jsonrpc_interface.v      # Converts JSON-RPC requests to Actions
    openapi_interface.v      # Converts OpenAPI requests to Actions
  actor.v                    # Defines the Actor and its behavior
  action.v                   # Defines the Action structure and utilities
  executor.v                 # Executes Actions on Actors
  director.v                 # (Planned) Coordinates actors, actions, and retries
```

---

## Workflow Example

### 1. Receiving an RPC Request
An RPC request is received by an interface handler:

```json
{
  "jsonrpc": "2.0",
  "method": "doSomething",
  "params": { "key": "value" },
  "id": 1
}
```

### 2. Converting the Request to an Action
The interface handler converts the request into an **Action**:

```v
action := jsonrpc_interface.jsonrpc_to_action(request)
```

### 3. Executing the Action
The action is passed directly to an **Actor** for execution:

```v
actor := MyActor{id: "actor-1"}
resulting_action := actor.act(action)
```

### 4. Returning the RPC Response
The interface handler converts the resulting **Action** back into a JSON-RPC response:

```json
{
  "jsonrpc": "2.0",
  "result": { "status": "success", "data": "..." },
  "id": 1
}
```

---

## Future Improvements

- **Director Implementation**:
  - Add retries and timeout handling for actions.
  - Provide better coordination for complex workflows.

- **Enhanced Interfaces**:
  - Add support for more RPC protocols.

---

This module is a crucial building block of the **Baobab** library, designed to streamline RPC-based communication and task execution with flexibility and scalability.
