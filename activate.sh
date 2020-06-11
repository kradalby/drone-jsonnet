#!/usr/bin/env bash

set -euxo pipefail

for config in *.jsonnet; do
    NAME="${config%.*}"
    drone repo enable "kradalby/$NAME"
done
