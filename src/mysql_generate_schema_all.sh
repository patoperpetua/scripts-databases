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

function usage(){
    echo "ERROR: no arguments provided."
    echo "-N|--notCreateContainer : do not create container."
    echo "-h|--host: mysql host. "
}

MYSQL_HOST_NAME=
FOLDER="dist/mysql"
CREATE_CONTAINER=1
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -N|--notCreateContainer)
            CREATE_CONTAINER=0
            shift # past argument
        ;;
        -h|--host)
            MYSQL_HOST_NAME="${2}"
            shift # past argument
            shift # past value
        ;;
        *)    # unknown option
            usage
            exit 1
        ;;
    esac
done

if [ -d "${FOLDER}" ]; then
    for filename in ${FOLDER}/mysql*.sql; do
        if [ -f "${filename}" ]; then
            rm "${filename}"
        fi
    done
fi

mkdir -p ${FOLDER}

DEFAULT_PORT=3312
CONTAINER_NAME=generate-all
PASSWORD=PassWord
if [ ${CREATE_CONTAINER} -eq 1 ]; then
    if ! type "docker" &> /dev/null; then
        echo "Docker is not installed. Install it and then re launch"
        exit 1
    fi
    ./scripts/run_mysql_local.sh ${DEFAULT_PORT} ${CONTAINER_NAME} ${PASSWORD}
    MYSQL_HOST_NAME=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_NAME})
fi

for filename in liquibase/*.xml; do
    filename=$(basename -- "$filename")
    filename="${filename%.*}"
    ./scripts/generate_schema_mysql.sh -c "${filename}" -s "mysql-${filename}" -h "${MYSQL_HOST_NAME}" -N
done

if [ ${CREATE_CONTAINER} -eq 1 ]; then
    docker stop ${CONTAINER_NAME} > /dev/null 2>&1
    docker rm ${CONTAINER_NAME} > /dev/null 2>&1
fi