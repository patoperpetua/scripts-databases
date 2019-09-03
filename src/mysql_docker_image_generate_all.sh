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
  echo -e "First Argument: git commit sha"
  echo -e "Second Argument: basename image."
}

FOLDER="dist/mysql"
if [ -z "${BASENAME+x}" ]; then
    BASENAME=registry.gitlab.com/ravimosharksas/databases/global
fi

CI_COMMIT_SHA=$(git rev-parse HEAD | cut -c 1-8)

if [ $# -lt 1 ]; then
  echo -e "Illegal number of parameters"
  echo -e "$(usage)"
  # read -r -p "Do you want to run script with IMAGE_NAME=${BASENAME}? [y/N] " response
  # if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
  # then
  #   echo "Running with IMAGE_NAME=${BASENAME}"
  # else
  #   exit 1;
  # fi
else
    CI_COMMIT_SHA=${1}
    if [ $# -eq 2 ]; then
        BASENAME=${2}
    fi
fi

for filename in "${FOLDER}"/*.sql; do
    filename=$(basename -- "$filename")
    filename="${filename%.*}"
    tag=${filename#"mysql-"}
    ./scripts/generate_docker_image_mysql.sh "mysql/${filename}" "${BASENAME}/mysql" "${tag}" "${CI_COMMIT_SHA}"
done

