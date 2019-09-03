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

MUST_HAVE_BINARIES=("java" "liquibase" "mysql")
for binary in "${MUST_HAVE_BINARIES[@]}"
do
    echo -ne "Checking for binary: ${binary}..."
    if ! type "${binary}" &> /dev/null; then
        echo "NOT installed. Install it and then re launch"
        exit 1
    else
        echo "done"
    fi
done

function usage(){
    echo -e "First Argument: file name."
    echo -e "Second Argument: container name. (optional)"
    echo -e "Third Argument: mysql password. (optional)"
    echo -e "Forth Argument: mysql host. (optional)"
    echo -e "Fifth Argument: mysql port. (optional)"
}

CONTAINER_NAME=
FOLDER=#"dist/mysql/"
FILE=
HOST=
PASSWORD="PassWord"
DEFAULT_PORT=3312
if [ $# -lt 1 ]; then
    echo -e "Illegal number of parameters"
    echo -e "$(usage)"
else
    FILE=${1}
    if [ $# -ge 2 ]; then
        CONTAINER_NAME=${2}
        if [ $# -ge 3 ]; then
            PASSWORD=${3}
            if [ $# -ge 4 ]; then
                HOST=${4}
                if [ $# -ge 5 ]; then
                    DEFAULT_PORT=${5}
                fi
            fi
        fi
    fi
fi

FILE_PATH=${FOLDER}${FILE}
if [[ $FILE_PATH != *".sql" ]]; then
    FILE_PATH=$FILE_PATH".sql"
fi

if [ ! -z "${HOST}" ]; then
    mysql -h "${HOST}" -u root -p"${PASSWORD}" <./"${FILE_PATH}"
else
    if [ "${CONTAINER_NAME}" == "" ]; then
        CONTAINER_NAME=test-files
        ./scripts/run_mysql_local.sh "${DEFAULT_PORT}" "${CONTAINER_NAME}" "${PASSWORD}"
        docker exec "${CONTAINER_NAME}" mysql -u root -p"${PASSWORD}" <./"${FILE_PATH}"
        docker stop "${CONTAINER_NAME}" > /dev/null 2>&1
        docker rm "${CONTAINER_NAME}" > /dev/null 2>&1
    else
        docker exec "${CONTAINER_NAME}" mysql -u root -p"${PASSWORD}" <./"${FILE_PATH}"
    fi
fi