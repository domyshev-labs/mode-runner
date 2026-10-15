#!/bin/zsh
set -euo pipefail
PROJECT_DIRECTORY="${0:A:h:h}"
CONFIGURATION_DIRECTORY="${1:-${HOME}/.mode-runner}"
mkdir -p "${CONFIGURATION_DIRECTORY}"
MARKER="${CONFIGURATION_DIRECTORY}/.example-initialized"
if [[ -e "${MARKER}" ]]; then
    exit 0
fi
CONFIGURATION_FILES=("${CONFIGURATION_DIRECTORY}"/config.yaml(N.) "${CONFIGURATION_DIRECTORY}"/config.?*.yaml(N.))
if (( ${#CONFIGURATION_FILES} == 0 )); then
    # Keep demo source outside the application bundle so dependencies can be installed locally.
    tar -C "${PROJECT_DIRECTORY}" --exclude=node_modules --exclude=dist --exclude=.demo-state -cf - DemoApplications |
        tar -C "${CONFIGURATION_DIRECTORY}" -xf -
    sed 's|../DemoApplications/|./DemoApplications/|g' "${PROJECT_DIRECTORY}/Examples/config.example.yaml" > "${CONFIGURATION_DIRECTORY}/config.example.yaml"
    print "Created example: ${CONFIGURATION_DIRECTORY}/config.example.yaml"
fi
touch "${MARKER}"
