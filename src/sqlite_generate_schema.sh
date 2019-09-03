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

MAX_STAGES=6
echo "1/${MAX_STAGES} Checking drivers.."
FOLDER_DRIVER="dist/drivers"
if [ ! -d "${FOLDER_DRIVER}" ]; then
    echo "Creating drivers folder."
    mkdir ${FOLDER_DRIVER} -p
fi

echo "2/${MAX_STAGES} Downloading drivers.."
if [ ! -f "${FOLDER_DRIVER}/sqlite.jar" ]; then
    curl -L http://central.maven.org/maven2/org/xerial/sqlite-jdbc/3.23.1/sqlite-jdbc-3.23.1.jar \
    -o ${FOLDER_DRIVER}/sqlite.jar
fi
echo "3/${MAX_STAGES} Checking files.."
FILE=
DIST_FILE=
DATABASE_NAME=FISCALIZAR
BUILD_FOLDER=build
DATABASE_FILE=${BUILD_FOLDER}/db
function usage(){
    echo "-c|--changeLogFile #IN: chagelog file refered to liquibase folder."
    echo "-s|--sqlFile #OUT: sql script output. Be created in dist folder."
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

DIST_FOLDER="dist/sqlite"
if [ ! -d ${DIST_FOLDER} ]; then
    mkdir -p ${DIST_FOLDER}
fi

if [ ! -d ${BUILD_FOLDER} ]; then
    mkdir -p ${BUILD_FOLDER}
fi

echo "4/${MAX_STAGES} Executing liquibase.."
liquibase --driver=org.sqlite.JDBC \
    --classpath=${FOLDER_DRIVER}/sqlite.jar \
    --url=jdbc:sqlite:${DATABASE_FILE} \
    --outputFile="${DIST_FOLDER}/${DIST_FILE}" \
    --changeLogFile="$FILE" \
    updateSQL

#Replace database name.
# shellcheck disable=SC2006
# shellcheck disable=SC2016
echo "5/${MAX_STAGES} Replacing `` to database name (${DATABASE_NAME})"
# shellcheck disable=SC2016
sed -i -e 's/``/'"${DATABASE_NAME}"'/g' "${DIST_FOLDER}/${DIST_FILE}"

#Added line to create database.
echo "6/${MAX_STAGES} Adding line to create database if not exists."
ex -s -c '10i|CREATE DATABASE IF NOT EXISTS '"${DATABASE_NAME}"';' -c x "${DIST_FOLDER}/${DIST_FILE}"
ex -s -c '11i|USE '"${DATABASE_NAME};"'' -c x "${DIST_FOLDER}/${DIST_FILE}"