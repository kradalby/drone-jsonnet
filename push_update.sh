#!/usr/bin/env bash

set -eux pipefail

DRONE_JSONNET_DIR=$(pwd)
GIT_DIR="$HOME/git"
IGNORED="^(terraform-provider-opnsense|opnsense-go)$"

./update.sh

for config in *.jsonnet; do
    PROJECT_NAME="${config%.*}"
    if [[ "$PROJECT_NAME" =~ $IGNORED ]]; then
        echo
        echo "$PROJECT_NAME cannot be automatically pushed, ignoring..."
    else
        echo
        PROJECT_DIR="$GIT_DIR/$PROJECT_NAME"
        echo "$PROJECT_NAME will be updated"
        echo "Chaning directory to $PROJECT_DIR"
        cd "$PROJECT_DIR"

        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        BRANCH_TARGET="master"
        if [[ "$BRANCH" == "$BRANCH_TARGET" ]]; then
            echo
            git config pull.rebase false
            git pull
            git add .drone.yml
            git diff-index --quiet HEAD || git commit -m "Updating generated .drone.yml"
            git push origin master
        else
            echo "$PROJECT_NAME is not on branch master, ignoring..."
        fi

        echo "Finished updating $PROJECT_NAME"
        echo "Changing directory to $DRONE_JSONNET_DIR"
        cd "$DRONE_JSONNET_DIR"
    fi
done
