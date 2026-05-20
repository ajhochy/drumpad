#!/bin/bash
cd "$(dirname "$0")/.."
python3 -m http.server 8080 &
SERVER_PID=$!
sleep 1
chromium-browser --kiosk --no-sandbox --disable-infobars \
  --disable-session-crashed-bubble \
  "http://localhost:8080" &
wait $SERVER_PID
