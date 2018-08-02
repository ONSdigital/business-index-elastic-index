#!groovy
@Library('jenkins-pipeline-shared') _

pipeline {
    parameters {
        string(name: 'index_name', defaultValue: 'example-bi-dev', description: 'Name of the ElasticSearch index to create.')
    }
    environment {
        MASTER_BRANCH = "master"
        ELASTIC_HOST = ""
        ELASTIC_PORT = ""
        INDEX_NAME = "${params.index_name}"
        ENVIRONMENT = "dev"
        ALIAS = "bi-$ENVIRONMENT"
        INDEX_JSON_PATH = "./business-index-api/conf/index.json"
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    agent any
    stages {
        stage('Checkout'){
            agent any
            when{ branch MASTER_BRANCH }
            steps {
                dir('business-index-api') {
                    git(url: "https://github.com/ONSdigital/business-index-api.git", branch: "master")
                }
            }
        }

        stage('Index Exists?'){
            agent any
            when{ branch MASTER_BRANCH }
            steps {
                colourText("info", "Checking to see if index [$INDEX_NAME] exists")
                sh "business-index-api/conf/scripts/index_exists.sh $ELASTIC_HOST $ELASTIC_PORT $INDEX_NAME"
                colourText("info", "No ElasticSearch index [${env.INDEX_NAME}] exists, continuing to Create Index step.")
            }
        }

        stage('Create Index'){
            agent any
            when{ branch MASTER_BRANCH }
            steps {
                colourText("info", "Creating index [$INDEX_NAME]")
                sh "business-index-api/conf/scripts/create_index.sh $ELASTIC_HOST $ELASTIC_PORT $INDEX_NAME $INDEX_JSON_PATH"
            }
        }

        stage('Alias Index'){
            agent any
            when{ branch MASTER_BRANCH }
            steps {
                colourText("info", "Aliasing index [$INDEX_NAME] with alias [$ALIAS]")
                sh "./scripts/alias_index.sh $ELASTIC_HOST $ELASTIC_PORT $INDEX_NAME $ALIAS"
            }
        }
    }
}