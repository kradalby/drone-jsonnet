#!/usr/bin/env bash

set -euxo pipefail

for config in *.jsonnet; do
    base="${config%.*}"
    echo "Updating $base"
    jsonnet -y "$config" >"$HOME/git/$base/.drone.yml"
done
