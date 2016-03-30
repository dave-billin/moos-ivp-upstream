#!/bin/bash

set -o errexit    # Exit on first error
set -o nounset    # Disallow unset variables

# Get the directory where this script is located
_script_dir="$(readlink -f $(dirname ${0}))"

# Build MOOS libraries bundled with IvP sources
${_script_dir}/build-moos.sh ${@}

# Build the IvP sources
${_script_dir}/build-ivp.sh ${@}

