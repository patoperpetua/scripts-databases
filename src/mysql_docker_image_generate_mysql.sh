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
  echo -e "First Argument: sql script file path."
  echo -e "Secound Argument: tag"
  echo -e "Third Argument: name"
  echo -e "Forth Argument: git commit sha"
}

FILE=
TAG=
BASENAME=registry.gitlab.com/ravimosharksas/databases/global/mysql

if [ -z "${DOCKER_IMAGE_BASE_NAME_MYSQL+x}" ]; then
  BASENAME=${DOCKER_IMAGE_BASE_NAME_MYSQL}
fi

CI_COMMIT_SHA=$(git rev-parse HEAD | cut -c 1-8)
if [ $# -lt  3 ]; then
  echo -e "Illegal number of parameters"
  echo -e "$(usage)"
else
    FILE="dist/${1}"
    BASENAME=${2}
    TAG=${3}
    if [ $# -ge  4 ]; then
      CI_COMMIT_SHA=${4}
    fi
fi

if [[ "$FILE" != *".sql" ]]; then
    FILE="${FILE}.sql"
fi

if [ ! -f "${FILE}" ]; then
  echo "ERROR: No such file ${FILE}"
fi
DATE="$(date --rfc-2822 | sed 's/ /T/; s/\(\....\).*-/\1-/g')"

docker build --rm -f docker/mysql/Dockerfile -t \
    "${BASENAME}:${TAG}" \
    --label "version=${TAG}" \
    --label "vcs-ref=${CI_COMMIT_SHA}" \
    --label "build-date=${DATE}" \
    --build-arg SQL_FILE_SCRIPT="./${FILE}" .