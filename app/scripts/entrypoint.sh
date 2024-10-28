#!/bin/bash

PORT=${PORT:-8000}
LOG_LEVEL=${LOG_LEVEL:-debug}

exec gunicorn -b 0.0.0.0:$PORT --log-level $LOG_LEVEL api:app