#!/bin/sh

# Run database migrations if available
if command -v just >/dev/null 2>&1 && [ -f "justfile" ]; then
    echo "Running database migrations..."
    just server migrate
fi

# Start the application
exec ./entrypoint.sh "$@"
