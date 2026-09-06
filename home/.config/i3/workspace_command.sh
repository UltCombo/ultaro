#!/bin/bash

set -o pipefail

i3-msg -t subscribe -m '["workspace", "output"]' | {
    i3-msg -t get_workspaces;
    while read EVENT; do i3-msg -t get_workspaces; done;
} | jq --unbuffered -c '[ .[] | select(.name != "Private") ]' || echo "workspace command crashed" >> /tmp/ultaro.log && exec "$0" "$@"
