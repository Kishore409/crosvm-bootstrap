#! /bin/bash

# system-packages_internal.sh
# Install support packages and configure system.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

# Install all system dependencies.
sudo apt-get install -y  --no-install-recommends --no-install-suggests docker
sudo apt-get install -y  --no-install-recommends --no-install-suggests docker.io
sudo apt-get install -y  --no-install-recommends --no-install-suggests docker-compose
