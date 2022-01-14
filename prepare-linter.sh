#!/bin/bash

# This will compile lslint inside a docker container
# For using it: docker run -t -v [host/path]:[container/path] lslint linter/lslint [file]
# You can use it with the vscode extension: runonsave https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave

if ! command -v docker &> /dev/null
then
    echo "Install Docker. https://docs.docker.com/engine/install/"
    echo
    echo "Exiting."
    echo
    exit 1
fi

docker build -t lslint .
