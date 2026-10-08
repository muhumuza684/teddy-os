#!/bin/sh
# Copies the shipped sources next to the tests. system-ipc.js gets a .cjs name because tests/package.json is "type":"module".
cd "$(dirname "$0")" && mkdir -p src/apps src/components electron \
 && cp ../desktop/src/apps/*.jsx src/apps/ && mkdir -p src/utils && cp ../desktop/src/utils/version.js src/utils/ \
 && cp ../desktop/src/components/Notifications.jsx src/components/ \
 && cp ../desktop/electron/system-ipc.js electron/system-ipc.cjs
