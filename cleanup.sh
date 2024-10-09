#!/bin/bash

set -e

log() {
  echo
  echo "##### $*"
}

oc delete -f prod-mesh/ || true
oc delete -f stage-mesh/ || true

oc delete project prod-mesh || true
oc delete project prod-bookinfo || true

oc delete project stage-mesh || true
oc delete project stage-bookinfo || true