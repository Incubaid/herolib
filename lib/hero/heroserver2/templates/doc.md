# @{handler_type} API Documentation

@{spec.info.description}

**Version:** @{spec.info.version}

## Overview

This documentation provides details about the @{handler_type} API endpoints and their usage.

@{methods}

## Authentication

All API requests require a valid session key obtained through the authentication flow:

1. **Register**: Submit your public key to register
2. **Request Challenge**: Get an authentication challenge  
3. **Authenticate**: Sign the challenge and submit for session key
4. **Use Session**: Include session key in subsequent API requests

## Error Handling

The API uses standard JSON-RPC 2.0 error codes:

- `-32700`: Parse error
- `-32600`: Invalid Request  
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error