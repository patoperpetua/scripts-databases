#!/usr/bin/env bash

# Web Page of BASH best practices https://kvz.io/blog/2013/11/21/bash-best-practices/
#Exit when a command fails.
set -o errexit
#Exit when script tries to use undeclared variables.
set -o nounset
#The exit status of the last command that threw a non-zero exit code is returned.
set -o pipefail

#Trace what gets executed. Useful for debugging.
#set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename "${__file}" .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)"

echo "Script name: ${__base}"
echo "Executing at ${__root}"

if ! type "docker" &> /dev/null; then
  echo "Docker is not installed. Install it and then re launch"
  exit 1
fi

function usage(){
  echo -e "First Argument: basename image."
}

if [ -z "${BASENAME+x}" ]; then
  BASENAME=registry.gitlab.com/ravimosharksas/databases/global
fi

if [ $# -eq 1 ]; then
    BASENAME=${1}
fi

for filename in dist/mysql/*.sql; do
    filename=$(basename -- "$filename")
    filename="${filename%.*}"
    tag=${filename#"mysql-"}
    docker push "${BASENAME}:${tag}"
done