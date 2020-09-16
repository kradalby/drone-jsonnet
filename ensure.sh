#!/usr/bin/env bash

set -euxo pipefail

drone=$(pwd)

for config in *.jsonnet; do
    base="${config%.*}"
    echo "Updating $base"

    PRETTIER=".prettierignore"
    cd "$HOME/git/$base" || exit
    if [ ! -f "$PRETTIER" ]; then
        echo ".drone.yml" >$PRETTIER
        git add $PRETTIER
        git commit -m "Add .drone.yml to $PRETTIER"
    fi
    cd "$drone" || exit

done
