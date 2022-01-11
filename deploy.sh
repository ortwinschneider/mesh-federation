#!/bin/bash

set -e

log() {
  echo
  echo "##### $*"
}

log "Creating projects for prod-mesh"
oc new-project prod-mesh || true
oc new-project prod-bookinfo || true

log "Installing control plane for prod-mesh"
oc apply -f prod-mesh/smcp.yaml
oc apply -f prod-mesh/smmr.yaml

log "Creating projects for stage-mesh"
oc new-project stage-mesh || true
oc new-project stage-bookinfo || true

log "Installing control plane for stage-mesh"
oc apply -f stage-mesh/smcp.yaml
oc apply -f stage-mesh/smmr.yaml

log "Waiting for prod-mesh installation to complete"
oc wait --for condition=Ready -n prod-mesh smmr/default --timeout 300s

log "Waiting for stage-mesh installation to complete"
oc wait --for condition=Ready -n stage-mesh smmr/default --timeout 300s

log "Installing details v2 service in stage-mesh"
oc apply -n stage-bookinfo -f stage-mesh/stage-detail-v2-deployment.yaml
oc apply -n stage-bookinfo -f stage-mesh/stage-detail-v2-service.yaml

log "Installing bookinfo application in prod-mesh"
oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml
oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml

log "Retrieving Istio CA Root certificates"
PROD_MESH_CERT=$(oc get configmap -n prod-mesh istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | sed ':a;N;$!ba;s/\n/\\\n    /g')
STAGE_MESH_CERT=$(oc get configmap -n stage-mesh istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | sed ':a;N;$!ba;s/\n/\\\n    /g')

log "Enabling federation for prod-mesh"
sed "s:{{STAGE_MESH_CERT}}:$STAGE_MESH_CERT:g" prod-mesh/stage-mesh-ca-root-cert.yaml | oc apply -f -
oc apply -f prod-mesh/smp.yaml
oc apply -f prod-mesh/iss.yaml

log "Enabling federation for stage-mesh"
sed "s:{{PROD_MESH_CERT}}:$PROD_MESH_CERT:g" stage-mesh/prod-mesh-ca-root-cert.yaml | oc apply -f -
oc apply -f stage-mesh/smp.yaml
oc apply -f stage-mesh/ess.yaml

log "Installing VirtualService for prod-mesh"
oc apply -n prod-bookinfo -f prod-mesh/vs-mirror-details.yaml
# oc apply -f prod-mesh/vs-split-details.yaml

log "INSTALLATION COMPLETE

Run the following command in the prod-mesh to check the connection status:

  oc -n prod-mesh get servicemeshpeer stage-mesh -o json | jq .status

Run the following command to check the connection status in stage-mesh:

  oc -n stage-mesh get servicemeshpeer prod-mesh -o json | jq .status

Check if services from stage-mesh are imported into prod-mesh:

  oc -n prod-mesh get importedservicesets stage-mesh -o json | jq .status

Check if services from stage-mesh are exported:

  oc -n stage-mesh get exportedservicesets prod-mesh -o json | jq .status

To see federation in action, create some load in the bookinfo app in prod-mesh. For example:

  BOOKINFO_URL=$(oc -n prod-mesh get route istio-ingressgateway -o json | jq -r .spec.host)
  while true; do sleep 1; curl http://$BOOKINFO_URL/productpage &> /dev/null; done

"