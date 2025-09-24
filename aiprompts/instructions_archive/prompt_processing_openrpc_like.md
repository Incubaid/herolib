

# how to manage my agenda

## Metadata for function calling

functions_metadata = [
    {
        "name": "event_add",
        "description": "Adds a calendar event.",
        "parameters": {
            "type": "object",
            "properties": {
                "title": {"type": "string", "description": "Title of the event."},
                "start": {"type": "string", "description": "Start date and time in 'YYYY/MM/DD hh:mm' format."},
                "end": {"type": "string", "description": "End date or duration (e.g., +2h)."},
                "description": {"type": "string", "description": "Event description."},
                "attendees": {"type": "string", "description": "Comma-separated list of attendees' emails."},
            },
            "required": ["title", "start"]
        }
    },
    {
        "name": "event_delete",
        "description": "Deletes a calendar event by title.",
        "parameters": {
            "type": "object",
            "properties": {
                "title": {"type": "string", "description": "Title of the event to delete."},
            },
            "required": ["title"]
        }
    }
]

## example call

{
    "function": "event_add",
    "parameters": {
        "title": "Team Sync",
        "start": "2025/02/01 10:00",
        "end": "+1h",
        "description": "",
        "attendees": "alice@example.com, bob@example.com"
    }
}

## how to use

Parse the user query to determine intent (e.g., "schedule" maps to event_add, "cancel" maps to event_delete).

Extract required parameters (e.g., title, start date).

Invoke the appropriate function with the extracted parameters.

Return the function's result as the response.

