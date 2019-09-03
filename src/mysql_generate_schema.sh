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

if ! type "java" &> /dev/null; then
    echo "java is not installed. Install it and then re launch"
    exit 1
fi

if ! type "liquibase" &> /dev/null; then
    echo "liquibase is not installed. Install it and then re launch"
    exit 1
fi

if ! type "sed" &> /dev/null; then
    echo "sed is not installed. Install it and then re launch"
    exit 1
fi

if ! type "ex" &> /dev/null; then
    echo "ex is not installed. Install it and then re launch"
    exit 1
fi

if ! type "awk" &> /dev/null; then
    echo "awk is not installed. Install it and then re launch"
    exit 1
fi

MAX_STAGES=9
echo "1/${MAX_STAGES} Checking drivers.."
FOLDER_DRIVER="dist/drivers"
if [ ! -d ${FOLDER_DRIVER} ]; then
    echo "Creating drivers folder."
    mkdir ${FOLDER_DRIVER} -p
fi

echo "2/${MAX_STAGES} Downloading drivers.."
if [ ! -f ${FOLDER_DRIVER}/mysql.jar ]; then
    curl -L http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.44/mysql-connector-java-5.1.44.jar \
    -o ${FOLDER_DRIVER}/mysql.jar
fi

echo "3/${MAX_STAGES} Checking files.."
FILE=
DIST_FILE=
REMOVE=0
HOST=
CREATE_CONTAINER=1
DATABASE_NAME=SAV
function usage(){
    echo "-c|--changeLogFile #IN: chagelog file refered to liquibase folder."
    echo "-s|--sqlFile #OUT: sql script output. Be created in dist folder."
    echo "-r|--remove: remove container after use. Default not removed. "
    echo "-N|--notCreateContainer : do not create container."
    echo "-h|--host: host. "
}

if [ $# -eq 0 ]; then
    echo "ERROR: no arguments provided."
    usage
    exit 1
fi

while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -N|--notCreateContainer)
            CREATE_CONTAINER=0
            shift # past argument
        ;;
        -r|--remove)
            REMOVE=1
            shift # past argument
        ;;
        -h|--host)
            HOST="${2}"
            shift # past argument
            shift # past value
        ;;
        -c|--changeLogFile)
            FILE="liquibase/${2}"
            shift # past argument
            shift # past value
        ;;
        -s|--sqlFile)
            DIST_FILE="${2}"
            shift # past argument
            shift # past value
        ;;
        *)    # unknown option
            echo "ERROR: unknown option. ${1}"
            usage
            exit 1
        ;;
    esac
done

#Exit script if while fails.
if [[ $? -eq 1 ]]; then
    exit 1
fi

if [[ $FILE != *".xml" ]]; then
    FILE=$FILE".xml"
fi
if [[ $DIST_FILE != *".sql" ]]; then
    DIST_FILE=$DIST_FILE".sql"
fi

echo "4/${MAX_STAGES} Running docker container.."
DEFAULT_PORT=3312
CONTAINER_NAME=schema
PASSWORD="PassWord"

if [ ${CREATE_CONTAINER} -eq 1 ]; then
    if ! type "docker" &> /dev/null; then
        echo "docker is not installed. Install it and then re launch"
        exit 1
    fi

    ./scripts/run_mysql_local.sh ${DEFAULT_PORT} ${CONTAINER_NAME} ${PASSWORD}

    RET_VAL_STATUS=$?
    if [ $RET_VAL_STATUS -ne 0 ]; then
        echo "ERROR: cannot run docker container."
        exit 1
    fi

    DEFAULT_PORT=$(docker port ${CONTAINER_NAME} | sed 's/^.*://')
    PASSWORD=$(docker inspect -f "{{ .Config.Env }}" ${CONTAINER_NAME} | sed 's/^.MYSQL_ROOT_PASSWORD=//' | cut -d ' ' -f1)
    CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_NAME})
else
    CONTAINER_IP=${HOST}
fi

DIST_FOLDER="dist/mysql"
if [ ! -d ${DIST_FOLDER} ]; then
    mkdir -p ${DIST_FOLDER}
fi

echo "5/${MAX_STAGES} Executing liquibase.."
liquibase --driver=com.mysql.jdbc.Driver \
    --classpath="${FOLDER_DRIVER}/mysql.jar" \
    --url="jdbc:mysql://${CONTAINER_IP}:3306" \
    --username=root \
    --password="${PASSWORD}" \
    --outputFile="${DIST_FOLDER}/${DIST_FILE}" \
    --changeLogFile="${FILE}" \
    updateSQL

#Replace database name.
# shellcheck disable=SC2006
echo "6/${MAX_STAGES} Replacing `` to database name (${DATABASE_NAME})"
# shellcheck disable=SC2016
sed -i -e 's/``/'"${DATABASE_NAME}"'/g' "${DIST_FOLDER}/${DIST_FILE}"

#Added line to create database.
echo "7/${MAX_STAGES} Adding line to create database if not exists."
ex -s -c '10i|CREATE DATABASE IF NOT EXISTS '"${DATABASE_NAME}"';' -c x "${DIST_FOLDER}/${DIST_FILE}"
ex -s -c '11i|USE '"${DATABASE_NAME};"'' -c x "${DIST_FOLDER}/${DIST_FILE}"

if [ "$HOST" == "" ]; then
    if [ ${REMOVE} -eq 1 ]; then
        echo "8/${MAX_STAGES} Stopping container.."
        docker stop ${CONTAINER_NAME} > /dev/null 2>&1
        echo "9/${MAX_STAGES} Removing container.."
        docker rm ${CONTAINER_NAME} > /dev/null 2>&1
    else
        echo "8/${MAX_STAGES} skipped.."
        echo "9/${MAX_STAGES} skipped.."
    fi
else
    echo "8/${MAX_STAGES} skipped.."
    echo "9/${MAX_STAGES} skipped.."
fi