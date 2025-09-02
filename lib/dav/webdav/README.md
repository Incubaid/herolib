# **WebDAV Server in V**

This project implements a WebDAV server using the `veb` framework and modules from `crystallib`. The server supports essential WebDAV file operations such as reading, writing, copying, moving, and deleting files and directories. It also includes **authentication** and **request logging** for better control and debugging.

---

## **Features**

- **File Operations**:  
   Supports standard WebDAV methods: `GET`, `PUT`, `DELETE`, `COPY`, `MOVE`, and `MKCOL` (create directory) for files and directories.
- **Authentication**:  
   Basic HTTP authentication using an in-memory user database (`username:password`).
- **Request Logging**:  
   Logs incoming requests for debugging and monitoring purposes.
- **WebDAV Compliance**:  
   Implements WebDAV HTTP methods with proper responses to ensure compatibility with WebDAV clients.
- **Customizable Middleware**:  
   Extend or modify middleware for custom logging, authentication, or request handling.

---

## **Usage**

### Running the Server

```v

import freeflowuniverse.herolib.dav.webdav

mut app := webdav.new_app(
   root_dir: '/tmp/rootdir' // Directory to serve via WebDAV
   user_db: {
      'admin': 'admin' // Username and password for authentication
   }
)!

app.run()

```

### **Mounting the Server**

Once the server is running, you can mount it as a WebDAV volume:

```bash
sudo mount -t davfs <server_url> <mount_point>
```

For example:

```bash
sudo mount -t davfs http://localhost:8080 /mnt/webdav
```

**Important Note**:  
Ensure the `root_dir` is **not the same as the mount point** to avoid performance issues during operations like `ls`.

---

## **Supported Routes**

| **Method** | **Route**    | **Description**                                          |
|------------|--------------|----------------------------------------------------------|
| `GET`      | `/:path...`  | Retrieves the contents of a file.                        |
| `PUT`      | `/:path...`  | Creates a new file or updates an existing one.           |
| `DELETE`   | `/:path...`  | Deletes a file or directory.                             |
| `COPY`     | `/:path...`  | Copies a file or directory to a new location.            |
| `MOVE`     | `/:path...`  | Moves a file or directory to a new location.             |
| `MKCOL`    | `/:path...`  | Creates a new directory.                                 |
| `OPTIONS`  | `/:path...`  | Lists supported WebDAV methods.                          |
| `PROPFIND` | `/:path...`  | Retrieves properties (e.g., size, date) of a file or directory. |

---

## **Authentication**

This WebDAV server uses **Basic Authentication**.  
Set the `Authorization` header in your client to include your credentials in base64 format:

```http
Authorization: Basic <base64-encoded-credentials>
```

**Example**:  
For the credentials `admin:admin`, the header would look like this:

```http
Authorization: Basic YWRtaW46YWRtaW4=
```

---

## **Configuration**

You can configure the WebDAV server using the following parameters when calling `new_app`:

| **Parameter**   | **Type**          | **Description**                                               |
|-----------------|-------------------|---------------------------------------------------------------|
| `root_dir`      | `string`          | Root directory to serve files from.                           |
| `user_db`       | `map[string]string` | A map containing usernames as keys and passwords as values.   |
| `port` (optional) | `int`           | The port on which the server will run. Defaults to `8080`.    |

---

## **Example Workflow**

1. Start the server:

   ```bash
   v run webdav_server.v
   ```

2. Mount the server using `davfs`:

   ```bash
   sudo mount -t davfs http://localhost:8080 /mnt/webdav
   ```

3. Perform operations:
   - Create a new file:

     ```bash
     echo "Hello WebDAV!" > /mnt/webdav/hello.txt
     ```

   - List files:

     ```bash
     ls /mnt/webdav
     ```

   - Delete a file:

     ```bash
     rm /mnt/webdav/hello.txt
     ```

4. Check server logs for incoming requests and responses.

---

## **Performance Notes**

- Avoid mounting the WebDAV server directly into its own root directory (`root_dir`), as this can cause significant slowdowns for file operations like `ls`.  
- Use tools like `cadaver`, `curl`, or `davfs` for interacting with the WebDAV server.

---

## **Dependencies**

- V Programming Language
- Crystallib VFS Module (for WebDAV support)

---

## **Future Enhancements**

- Support for advanced WebDAV methods like `LOCK` and `UNLOCK`.
- Integration with persistent databases for user credentials.
- TLS/SSL support for secure connections.

# WebDAV Property Model

This file implements the WebDAV property model as defined in [RFC 4918](https://tools.ietf.org/html/rfc4918). It provides a set of property types that represent various WebDAV properties used in PROPFIND and PROPPATCH operations.

## Overview

The `model_property.v` file defines:

1. A `Property` interface that all WebDAV properties must implement
2. Various property type implementations for standard WebDAV properties
3. Helper functions for XML serialization and time formatting

## Property Interface

```v
pub interface Property {
 xml() string
 xml_name() string
}
```

All WebDAV properties must implement:

- `xml()`: Returns the full XML representation of the property with its value
- `xml_name()`: Returns just the XML tag name of the property (used in property requests)

## Property Types

The file implements the following WebDAV property types:

| Property Type | Description |
|---------------|-------------|
| `DisplayName` | The display name of a resource |
| `GetLastModified` | Last modification time of a resource |
| `GetContentType` | MIME type of a resource |
| `GetContentLength` | Size of a resource in bytes |
| `ResourceType` | Indicates if a resource is a collection (directory) or not |
| `CreationDate` | Creation date of a resource |
| `SupportedLock` | Lock capabilities supported by the server |
| `LockDiscovery` | Active locks on a resource |

## Helper Functions

- `fn (p []Property) xml() string`: Generates XML for a list of properties
- `fn format_iso8601(t time.Time) string`: Formats a time in ISO8601 format for WebDAV

## Usage

These property types are used when responding to WebDAV PROPFIND requests to describe resources in the WebDAV server.

# WebDAV Locker

This file implements a locking mechanism for resources in a WebDAV context. It provides functionality to manage locks on resources, ensuring that they are not modified by multiple clients simultaneously.

## Overview

The `locker.v` file defines:

1. A `Locker` structure that manages locks for resources.
2. A `LockResult` structure that represents the result of a lock operation.
3. Methods for locking and unlocking resources, checking lock status, and managing locks.

## Locker Structure

```v
struct Locker {
mut:
 locks map[string]Lock
}
```

- `locks`: A mutable map that stores locks keyed by resource name.

## LockResult Structure

```v
pub struct LockResult {
pub:
 token       string // The lock token
 is_new_lock bool   // Whether this is a new lock or an existing one
}
```

- `token`: The unique identifier for the lock.
- `is_new_lock`: Indicates if this is a new lock or an existing one.

## Locking and Unlocking

- `pub fn (mut lm Locker) lock(l Lock) !Lock`: Attempts to lock a resource for a specific owner. Returns a `LockResult` with the lock token and whether it's a new lock.
- `pub fn (mut lm Locker) unlock(resource string) bool`: Unlocks a resource by removing its lock.
- `pub fn (lm Locker) is_locked(resource string) bool`: Checks if a resource is currently locked.
- `pub fn (lm Locker) get_lock(resource string) ?Lock`: Returns the lock object for a resource if it exists and is valid.
- `pub fn (mut lm Locker) unlock_with_token(resource string, token string) bool`: Unlocks a resource if the correct token is provided.

## Recursive Locking

- `pub fn (mut lm Locker) lock_recursive(l Lock) !Lock`: Locks a resource recursively, allowing for child resources to be locked (implementation for child resources is not complete).

## Cleanup

- `pub fn (mut lm Locker) cleanup_expired_locks()`: Cleans up expired locks (implementation is currently commented out).
