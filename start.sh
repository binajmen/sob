#!/bin/sh

ls -la

# Run database migrations if available
echo "preparing to run migrations..."
if command -v dbmate >/dev/null 2>&1; then
    echo "running database migrations..."
    dbmate migrate
fi

# Start the application
echo "starting application..."
exec ./entrypoint.sh "$@"
