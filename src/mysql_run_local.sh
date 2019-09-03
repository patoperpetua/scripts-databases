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
    echo "ERROR: docker is not installed. Install it and then re launch"
    exit 1
fi

if ! type "sed" &> /dev/null; then
    echo "ERROR: sed is not installed. Install it and then re launch"
    exit 1
fi

if ! type "cut" &> /dev/null; then
    echo "ERROR: cut is not installed. Install it and then re launch"
    exit 1
fi

if ! type "nc" &> /dev/null; then
    echo "ERROR: nc is not installed. Install it and then re launch"
    exit 1
fi

DEFAULT_PORT=
CONTAINER_NAME=
PASSWORD=
IMAGE_VERSION=5.7
IMAGE_NAME=mysql
E_VARIABLES=
if [ $# -ge 3 ]; then
    DEFAULT_PORT="${1}"
    CONTAINER_NAME="${2}"
    PASSWORD="${3}"
    if [ $# -ge 4 ];then
        IMAGE_NAME="${4}"
    fi
    if [ $# -ge 5 ];then
        IMAGE_VERSION="${5}"
    fi
    if [ $# -ge 6 ];then
        E_VARIABLES="${6}"
    fi
else
    echo "ERROR: Provide a port (1), docker container name (2) and password (3)"
    echo "OPTIONAL: image name(4) and image version(5)"
    exit 1
fi

#Check if container exists
if [ "$(docker ps -aq -f name="${CONTAINER_NAME}")" ]; then
    #If container is not running, then run.
    if [ "$(docker ps -aq -f status=exited -f name="${CONTAINER_NAME}")" ]; then
        docker start "${CONTAINER_NAME}" > /dev/null 2>&1
    fi
    DEFAULT_PORT=$(docker port "${CONTAINER_NAME}" | sed 's/^.*://')
    PASSWORD=$(docker inspect -f "{{ .Config.Env }}" "${CONTAINER_NAME}" | sed 's/MYSQL_ROOT_PASSWORD=//' | cut -d ' ' -f2)
else
    # shellcheck disable=SC2143
    if [ ! -z "$(netstat -lntu | grep "${DEFAULT_PORT}")" ]; then
        echo "ERROR: Port already taken."
        exit 1
    fi
    docker run -e "MYSQL_ROOT_PASSWORD=${PASSWORD}" "${E_VARIABLES}" -p "${DEFAULT_PORT}:3306" -d \
    --name "${CONTAINER_NAME}" "${IMAGE_NAME}:${IMAGE_VERSION}" > /dev/null 2>&1

    CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${CONTAINER_NAME}")
    echo "Waiting port to be open ${CONTAINER_IP}:3306..."
    while ! nc -z "${CONTAINER_IP}" 3306; do
        sleep 0.5 # wait for 1/10 of the second before check again
    done
    echo "Container ready"
fi

DEFAULT_PORT=$(docker port "${CONTAINER_NAME}" | sed 's/^.*://')
PASSWORD=$(docker inspect -f "{{ .Config.Env }}" "${CONTAINER_NAME}" | sed 's/^.MYSQL_ROOT_PASSWORD=//' | cut -d ' ' -f1)
CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${CONTAINER_NAME}")

echo "Mysql Container running. Port:${DEFAULT_PORT}, Name:${CONTAINER_NAME}, Password:${PASSWORD}, ImageVersion:${IMAGE_VERSION}, ImageName: ${IMAGE_NAME}, IP:${CONTAINER_IP}"