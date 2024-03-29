#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

directory=$1

# Make sure to start with a clean 'manifests' dir
rm -rf clusters/$directory/manifests
mkdir -p clusters/$directory/manifests/setup

# Calling gojsontoyaml is optional, but we would like to generate yaml, not json
jsonnet -J vendor -m clusters/$directory/manifests example.jsonnet | xargs -I{} sh -c 'cat {} | $(go env GOPATH)/bin/gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete
rm -f kustomization

