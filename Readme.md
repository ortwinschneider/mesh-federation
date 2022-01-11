# Getting started with OpenShift ServiceMesh Federation

## Installation 

### 1. OpenShift ServiceMesh Installation

The very first step is to have at least one OpenShift cluster where we install OpenShift ServiceMesh 2.1+. Basically we have to install 4 operators in the following order:

- OpenShift Elasticsearch (Optional)
- Jaeger
- Kiali
- Red Hat OpenShift Service Mesh 

You’ll find the complete installation instructions here: [Installing the Operators - Service Mesh 2.x | Service Mesh | OpenShift Container Platform 4.9](https://docs.openshift.com/container-platform/4.9/service_mesh/v2x/installing-ossm.html)

### Deploy on Linux

Clone this repository and make the deploy script executable.

```sh
chmod +x deploy.sh
```

Login to your OpenShift environment and start the deploy script.

```sh
./deploy.sh
```

### Deploy on MacOS

As the sed commandline program behaves a bit different on Mac, there is a chance that the deploy script will be interrupted. 
In this case you could mount the git repository in a Linux container and deploy from there.

```sh
docker run -d \
  -it \
  --name deploy-mesh \
  --mount type=bind,source="$(pwd)",target=/git \
  openshift/origin-cli

docker exec -it deploy-mesh bash

[root@51c09eeb8f64 /] cd git && chmod +x deploy.sh

[root@51c09eeb8f64 git] ./deploy.sh
```
