# HeroServer Documentation System

The HeroServer features a built-in documentation system that automatically discovers and serves API documentation with a clean web interface.

## Adding New Documentation

1. **Create a markdown file** in `lib/hero/heroserver/templates/pages/`:

   ```bash
   # Example: lib/hero/heroserver/templates/pages/calendar.md
   ```

2. **Write your documentation** using standard markdown:

   ```markdown
   # Calendar API
   
   A comprehensive calendar management service.
   
   ## Endpoints
   
   ### Create Calendar
   
   **Endpoint:** `POST /calendars`
   
   **Request:**
   ```json
   {
     "name": "My Calendar"
   }
   ```

   **Response:**

   ```json
   {
     "id": "cal_123",
     "name": "My Calendar"
   }
   ```

3. **Restart the server** - Documentation available at `http://localhost:8080/docs/calendar`

## Features

- **Auto-Discovery**: Scans `templates/pages/` for `.md` files on startup
- **Built-in Viewer**: Professional web interface with sidebar navigation  
- **Dynamic Rendering**: Markdown converted to HTML on-demand
- **Zero Configuration**: Just add markdown files and they appear automatically

## Documentation Structure

Your markdown files should follow this structure:

```markdown
# API Name

Brief description of your API.

## Overview

Detailed overview...

## Endpoints

### Create Resource

**Endpoint:** `POST /resources`

**Request:**
```json
{
  "name": "example"
}
```

**Response:**

```json
{
  "id": "123",
  "name": "example"
}
```

## Error Handling

Standard HTTP status codes and error responses...

## Accessing Documentation

- **Main Index**: `http://localhost:8080/docs` (redirects to first available API)
- **Specific API**: `http://localhost:8080/docs/{api_name}`
- **Example**: `http://localhost:8080/docs/calendar`
