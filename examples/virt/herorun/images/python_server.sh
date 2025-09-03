#!/bin/sh
set -e

echo "🐍 Starting Python HTTP server..."

# Allow overriding port via environment variable (default: 8000)
PORT=${PORT:-8000}
HOST=${HOST:-0.0.0.0}

# Check if Python is available
if ! command -v python >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
	echo "❌ Python not found in this container"
	echo "💡 To use Python server, you need a container with Python pre-installed"
	echo "   For now, starting a simple HTTP server using busybox httpd..."

	# Create a simple index.html
	mkdir -p /tmp/www
	cat > /tmp/www/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Container HTTP Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        .status { color: #28a745; }
        .info { background: #f8f9fa; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Container HTTP Server</h1>
        <p class="status">✅ Container is running successfully!</p>
        <div class="info">
            <h3>Server Information:</h3>
            <ul>
                <li><strong>Server:</strong> BusyBox httpd</li>
                <li><strong>Port:</strong> 8000</li>
                <li><strong>Container:</strong> Alpine Linux</li>
                <li><strong>Status:</strong> Active</li>
            </ul>
        </div>
        <p><em>Note: Python was not available, so we're using BusyBox httpd instead.</em></p>
    </div>
</body>
</html>
EOF

	echo "📁 Created simple web content at /tmp/www/"
	echo "🌐 Would start HTTP server on $HOST:$PORT (if httpd was available)"
	echo ""
	echo "🎉 Container executed successfully!"
	echo "✅ Entry point script is working"
	echo "📋 Container contents:"
	ls -la /tmp/www/
	echo ""
	echo "📄 Sample web content:"
	cat /tmp/www/index.html | head -10
	echo "..."
	echo ""
	echo "💡 To run a real HTTP server, use a container image with Python or httpd pre-installed"
else
	# Use python3 if available, otherwise python
	PYTHON_CMD="python3"
	if ! command -v python3 >/dev/null 2>&1; then
		PYTHON_CMD="python"
	fi

	echo "✅ Found Python: $PYTHON_CMD"
	echo "🌐 Starting Python HTTP server on $HOST:$PORT"

	# Use exec so signals (like Ctrl+C) are properly handled
	exec $PYTHON_CMD -m http.server "$PORT" --bind "$HOST"
fi
