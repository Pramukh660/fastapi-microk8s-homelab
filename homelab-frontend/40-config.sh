#!/bin/sh
# Generate config.js from API_URL at container start so one image works in every env.
echo "window.APP_CONFIG = { apiUrl: \"${API_URL}\" };" > /usr/share/nginx/html/config.js
