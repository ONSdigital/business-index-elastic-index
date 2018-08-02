#!/bin/sh

# This script will scp a job.properties configuration file onto the server which will
# be used to run the business-index parquet ingestion oozie job, which will result
# in a populated ElasticSearch index.

SCRIPT_NAME=$0
REQUIRED_NUM_ARGS=3

# Fail fast if we get any errors
set -e

usage() {
    echo "usage: ${SCRIPT_NAME} env host oozie_home"
    echo "  env                     environment dev/test/beta"
    echo "  host                    ssh target host"
    echo "  oozie_home              oozie home url"
    exit 1
}

# Fail the script if we recieve an incorrect number of arguments
if [ $# -ne $REQUIRED_NUM_ARGS ] ; then
    echo 'Error, you need to provide the correct number of arguments.'
    usage
fi

ENV=$1
HOST=$2
OOZIE_HOME=$3

# Create the directory for our job.properties file, then send it using scp
ssh bi-${ENV}-ci@${HOST} "mkdir -p bi-${ENV}-ingestion-parquet"
scp ./configuration/${ENV}/job.properties bi-${ENV}-ci@${HOST}:bi-${ENV}-ingestion-parquet
echo "Successfully transfered ./configuration/${ENV}/job.properties to bi-${ENV}-ci@${HOST}:bi-${ENV}-ingestion-parquet"

# Trigger the oozie job and get the job id, remove unused chars from the id and then poll it.
# JOB_ID is something like 'job: 213871982-213123123-asdasd', we remove 'job: '
ssh -tt bi-${ENV}-ci@${HOST} OOZIE_HOME=$OOZIE_HOME ENV=$ENV 'bash -s' << 'ENDSSH'
    TIMEOUT=1000
    INTERVAL=1
    OOZIE_ID_INDEX=5

    JOB_ID_UNFORMATTED=$(oozie job --oozie ${OOZIE_HOME} -config ./bi-${ENV}-ingestion-parquet/job.properties -run)

    JOB_ID=${JOB_ID_UNFORMATTED:${OOZIE_ID_INDEX}}
    echo "JOB_ID: [${JOB_ID}]"
    
    oozie job --oozie ${OOZIE_HOME} -poll ${JOB_ID} -interval ${INTERVAL} -timeout ${TIMEOUT} -verbose'
ENDSSH

echo "Oozie job was successful, data has been loaded into ElasticSearch index."