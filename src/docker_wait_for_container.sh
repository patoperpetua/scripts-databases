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

MYSQL_USER=${MYSQL_USER}
if [ "${MYSQL_USER}" == "" ]; then
    MYSQL_USER=root
fi

maxcounter=
counter=1
while ! mysql --protocol TCP -u"${MYSQL_USER}" -p"${MYSQL_ROOT_PASSWORD}" -e "show databases;" > /dev/null 2>&1; do
    sleep 1
    counter=$(("${counter}" + 1))
    if [ "${counter}" -gt "${maxcounter}" ]; then
        >&2 echo "We have been waiting for MySQL too long already; failing."
        exit 1
    fi;
done