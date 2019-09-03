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
    echo "Java is not installed. Install it and then re launch"
    exit 1
fi

if ! type "liquibase" &> /dev/null; then
    echo "Liquibase is not installed. Install it and then re launch"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "ERROR: no arguments provided."
    echo "-c|--changeLogFile #IN: chagelog file refered to liquibase folder."
    echo "-h|--host: configurated host. "
    echo "-n|--nameImage: image name. Default mysql:5.7"
    echo "-r|--remove: remove container after use. Default not removed. "
    exit 1
fi
MAX_STAGES=7
HOST=
FILE=
SQL_FILE=
SCHEMA_NAME=FISCALIZAR
IMAGE_NAME=mysql:5.7
REMOVE=0
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
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
            SQL_FILE="dist/${2}"
            shift # past argument
            shift # past value
        ;;
        -n|--nameImage)
            IMAGE_NAME="${2}"
            shift # past argument
            shift # past value
        ;;
        -r|--remove)
            REMOVE=1
            shift # past argument
        ;;
        *)    # unknown option
            echo "ERROR: no arguments provided."
            echo "-c|--changeLogFile #IN: chagelog file refered to liquibase folder."
            echo "-s|--sqlFile #OUT: sql script output. Be created in dist folder."
            echo "-h|--host: configurated host. "
            echo "-n|--nameImage: image name. Default mysql:5.7"
            echo "-r|--remove: remove container after use. Default not removed. "
            exit 1
        ;;
    esac
done

echo "1/${MAX_STAGES} Checking drivers.."
FOLDER_DRIVER=dist/drivers
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

if [[ $FILE != *".xml" ]]; then
    FILE=$FILE".xml"
fi

if [[ $SQL_FILE != *".sql" ]]; then
    SQL_FILE=$SQL_FILE".sql"
fi

# if [ ! -f ${FILE} ]; then
#     echo "Liquibase file not such file. ${FILE}"
#     exit 1
# fi
# if [ ! -f ${SQL_FILE} ]; then
#     echo "SQL file not such file. ${SQL_FILE}"
#     exit 1
# fi

echo "4/${MAX_STAGES} Running docker container.."
DEFAULT_PORT=3312
CONTAINER_NAME=schema
PASSWORD="PassWord"
if [ "$HOST" == "" ]; then
    if ! type "docker" &> /dev/null; then
        echo "docker is not installed. Install it and then re launch"
        exit 1
    fi

    source ./scripts/run_mysql_local.sh "${DEFAULT_PORT}" "${CONTAINER_NAME}" "${PASSWORD}" "${IMAGE_NAME}" "-e MYSQL_DATABASE=${SCHEMA_NAME}"

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

echo "5/${MAX_STAGES} Running liquibase.."
liquibase --driver=com.mysql.jdbc.Driver \
    --classpath=${FOLDER_DRIVER}/mysql.jar \
    --url=jdbc:mysql://"${CONTAINER_IP}:3306/${SCHEMA_NAME}" \
    --username=root \
    --password="${PASSWORD}" \
    --changeLogFile="${FILE}" \
    update

if [ "$HOST" == "" ]; then
    if [ ${REMOVE} -eq 1 ]; then
        echo "6/${MAX_STAGES} Stopping container.."
        docker stop ${CONTAINER_NAME} > /dev/null 2>&1
        echo "7/${MAX_STAGES} Removing container.."
        docker rm ${CONTAINER_NAME} > /dev/null 2>&1
    else
        echo "6/${MAX_STAGES} skipped.."
        echo "7/${MAX_STAGES} skipped.."
    fi
else
    echo "6/${MAX_STAGES} skipped.."
    echo "7/${MAX_STAGES} skipped.."
fi