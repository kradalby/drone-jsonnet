#!/usr/bin/env bash

# set -euxo pipefail
set -x

KUBERNETES_REPOS="kubernetes.json"
ACTION=${1:=add}

for PROJECT in $(cat "$KUBERNETES_REPOS" | jq -r '.[] | @text'); do
    REPO=$(echo "$PROJECT" | jq -r '.repo')
    NAMESPACE=$(echo "$PROJECT" | jq -r '.namespace')

    echo "Ensure repo is enabled: $REPO"
    drone repo enable "$REPO"

    if [ "$ACTION" == "rm" ]; then
        echo "Deleting secrets for $REPO from namespace $NAMESPACE"
        drone secret rm --repository "$REPO" --name kubernetes_server
        drone secret rm --repository "$REPO" --name kubernetes_cert
        drone secret rm --repository "$REPO" --name kubernetes_token

    elif [ "$ACTION" == "add" ]; then
        echo "Adding secrets for $REPO from namespace $NAMESPACE"
        kubespace drone -n "$NAMESPACE" -r "$REPO" | sh
    fi

done

# Special cases
if [ "$ACTION" == "rm" ]; then

    drone secret rm --repository "kradalby/hugin" --name demo_kubernetes_server
    drone secret rm --repository "kradalby/hugin" --name demo_kubernetes_cert
    drone secret rm --repository "kradalby/hugin" --name demo_kubernetes_token

    # drone secret rm kradalby/packer --name vcenter_password --data "$VCENTER_PASSWORD"
    # drone secret rm kradalby/packer --name vcenter_login --data "$VCENTER_LOGIN"
    # drone secret rm kradalby/packer --name vcenter_host --data "$VCENTER_HOST"

    # drone secret rm kradalby/hugin --name hugin_sentry_dsn --data "$HUGIN_SENTRY_DSN"
    # drone secret rm kradalby/hugin --name hugin_rollbar_access_token --data "$HUGIN_ROLLBAR_ACCESS_TOKEN"
    # drone secret rm kradalby/hugin --name hugin_mapbox_access_token --data "$HUGIN_MAPBOX_ACCESS_TOKEN"

elif [ "$ACTION" == "add" ]; then
    HUGINDEMO_DRONE=$(kubespace drone -n hugindemo -r kradalby/hugin)
    echo "${HUGINDEMO_DRONE//kubernetes/demo_kubernetes}" | bash

    # drone secret add kradalby/packer --name vcenter_password --data "$VCENTER_PASSWORD"
    # drone secret add kradalby/packer --name vcenter_login --data "$VCENTER_LOGIN"
    # drone secret add kradalby/packer --name vcenter_host --data "$VCENTER_HOST"

    # drone secret add kradalby/hugin --name hugin_sentry_dsn --data "$HUGIN_SENTRY_DSN"
    # drone secret add kradalby/hugin --name hugin_rollbar_access_token --data "$HUGIN_ROLLBAR_ACCESS_TOKEN"
    # drone secret add kradalby/hugin --name hugin_mapbox_access_token --data "$HUGIN_MAPBOX_ACCESS_TOKEN"

fi
