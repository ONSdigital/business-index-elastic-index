#!/usr/bin/env bash

# This script will get all the ElasticSearch indexes that uses a given alias, the alias will
# be removed from those indexes, before the index name that is passed into this script
# is aliased using the given alias.
# e.g. sh ./scripts/alias_index.sh localhost 9200 bi-dev-01082018 bi-dev
# - The indexes aliased to 'bi-dev' will have their aliases removed (if any exist).
# - The passed in index name will be aliased using the given alias ('bi-dev').
# https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html#indices-aliases

__SCRIPT_NAME=${BASH_SOURCE[0]}
REQUIRED_NUM_ARGS=4

# Fail fast if we get any errors
set -o errexit

usage() {
    echo "usage: ${__SCRIPT_NAME} host port index_to_alias alias"
    echo "  host                    elasticsearch hostname"
    echo "  port                    elasticsearch port"
    echo "  index_to_alias          name of new elasticsearch index to alias"
    echo "  alias                   alias"
    exit 1
}

# Fail the script if we recieve an incorrect number of arguments
if [[ $# -ne ${REQUIRED_NUM_ARGS} ]] ; then
    echo 'Error, you need to provide the correct number of arguments.'
    usage
fi

HOST=$1
PORT=$2
INDEX_TO_ALIAS=$3
ALIAS=$4

ELASTIC_URL="${HOST}:${PORT}"
ELASTIC_ALIAS_URL="${ELASTIC_URL}/_alias/${ALIAS}"

# Get all aliased indexes for a particular alias
# https://gist.github.com/maxcnunes/9f77afdc32df354883df
ALIAS_HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" -XGET -H "Content-Type: application/json" "${ELASTIC_ALIAS_URL}")
ALIAS_JSON=$(echo ${ALIAS_HTTP_RESPONSE} | sed -e 's/HTTPSTATUS\:.*//g')
ALIAS_HTTP_STATUS=$(echo ${ALIAS_HTTP_RESPONSE} | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [[ ${ALIAS_HTTP_STATUS} -eq 200 ]] ; then
    echo "The following aliases are present for alias [${ALIAS}]:"
    echo ${ALIAS_JSON}

    # Get the first match for anything between "" (first JSON key of aliased index)
    # use xargs to trim whitespace - https://stackoverflow.com/a/12973694
    CURRENT_ALIASED_INDEX=$(echo ${ALIAS_JSON} | awk -F'"' '{ print $2 }' | xargs)

    echo "Removing alias [${ALIAS}] from index [${CURRENT_ALIASED_INDEX}]"
    REMOVE_ACTION='{ "remove" : { "index" : "'"${CURRENT_ALIASED_INDEX}"'", "alias" : "'"${ALIAS}"'" } },'
elif [ $ALIAS_HTTP_STATUS -eq 404 ] ; then
    echo "No indexes aliased to [${ALIAS}], no need to remove any aliases."
    REMOVE_ACTION=""
else
    echo "Error, received status [${ALIAS_HTTP_STATUS}] and JSON [${ALIAS_JSON}] from request to [${ELASTIC_ALIAS_URL}]"
    exit 1
fi

echo "Adding alias [${ALIAS}] to index [${INDEX_TO_ALIAS}]"
ADD_ACTION='{ "add" : { "index" : "'"${INDEX_TO_ALIAS}"'", "alias" : "'"${ALIAS}"'" } }'

# Form the JSON we need to POST to ElasticSearch
ALIAS_POST_JSON='{"actions" : ['"${REMOVE_ACTION}"''"${ADD_ACTION}"']}'

echo "Using the following alias JSON to POST to ElasticSearch:"
echo ${ALIAS_POST_JSON}

curl --fail -XPOST --header "Content-Type: application/json" "${ELASTIC_URL}/_aliases" -d"${ALIAS_POST_JSON}"
echo

echo "Index [${INDEX_TO_ALIAS}] has been aliased to [${ALIAS}]"