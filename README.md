# hello-world-nodejs-mongodb-helm-k8s

## Overview

This is a hello-world simple Node.JS app that uses Mongoose to connect to MongoDB.
The database connection was made following the 12FA approach (no hard-coded values for the database connection) and is done in db.js

server.js is including db.js and will shows:
  - Hello world - dev (when deploying dev-cluster, visible under http://nodejs-hello.local.dev)
  - Hello world - prod (when deploying prod-cluster, visible under http://nodejs-hello.local.prod)

To avoid the `/etc/hosts` pollution problem, we installed ingress-dns addon and created per cluster a specific file (for macOS) `/etc/resolver/<our-file>` to magically access all local services.

## Set up your tools

```bash
# HyperKit
brew install hyperkit

# Docker
brew cask install docker

# Kubernetes CLI & kubectl
brew install kubernetes-cli

# Minikube => Local Kubernetes
brew install minikube

# Helm => Chart management
brew install helm

```

## Enable insecure registries

We want to enable insecure-reistries to use our local regestry instead of Docker HUB.
The docker configuration can be found here `~/.docker/daemon.json`
Add the 3 lines marked below:

```js'
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "debug": true,
  "experimental": false,
  "insecure-registries": [      <-----
    "local.dev:30007"           <-----
  ]                             <-----
}

```

## How to run the application
> Disclaimer: This was developed and tested in a macOS environment (Catalina), might need some tweaks to the Makefile script to work under Linux because of the ingress-dns minikube addon. See [Ingress DNS](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/#mac-os)

1. Clone this repo locally
2. Run the Makefile script like the following (to create a dev cluster):
```
make dev
```
3. Run the Makefile script like the following (to create a prod cluster):
```
make prod
```
4. Run the Makefile script like the following (to create a dev and prod clusters at once):
```
make all
```

## Known issues

The deployment of helloworld-chart can fail with the following message:
```
Release "helloworld-chart" does not exist. Installing it now.
Error: Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io": Post "https://ingress-nginx-controller-admission.ingress-nginx.svc:443/networking/v1/ingresses?timeout=10s": context deadline exceeded
```
There is a chance that the ingress controller was unavailable for any reason while we are trying to apply the ingress object. I re-executed the same command again and then it woas working !
