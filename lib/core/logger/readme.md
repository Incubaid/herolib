# Logger Module

A simple logging system that provides structured logging with search capabilities.

Logs are stored in hourly files with a consistent format that makes them both human-readable and machine-parseable.

## Features

- Structured logging with categories and error types
- Automatic timestamp management
- Multi-line message support
- Search functionality with filtering options
- Human-readable log format

## Usage

```v
import incubaid.herolib.core.logger
import incubaid.herolib.data.ourtime

// Create a new logger
mut l := logger.new(path: '/var/logs')!

// Log a message
l.log(
    cat: 'system',
    log: 'System started successfully',
    logtype: .stdout
)!

// Log an error
l.log(
    cat: 'system',
    log: 'Failed to connect\nRetrying in 5 seconds...',
    logtype: .error
)!

// Search logs
results := l.search(
    timestamp_from: ourtime.now().warp("-24h"), // Last 24 hours
    cat: 'system',                               // Filter by category
    log: 'failed',                              // Search in message content
    logtype: .error,                            // Only error messages
    maxitems: 100                               // Limit results
)!
```

## Log Format

Each log file is named using the format `YYYY-MM-DD-HH.log` and contains entries in the following format:

```
21:23:42
 system     - This is a normal log message
 system     - This is a multi-line message
              second line with proper indentation
              third line maintaining alignment
E error_cat - This is an error message
E             second line of error
E             third line of error
```

### Format Rules

- Time stamps (HH:MM:SS) are written once per second when the log time changes
- Categories are:
  - Limited to 10 characters maximum
  - Padded with spaces to exactly 10 characters
  - Any `-` in category names are converted to `_`
- Each line starts with either:
  - ` ` (space) for normal logs (LogType.stdout)
  - `E` for error logs (LogType.error)
- Multi-line messages maintain consistent indentation (14 spaces after the prefix)
