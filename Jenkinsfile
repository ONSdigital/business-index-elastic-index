#!groovy
@Library('jenkins-pipeline-shared') _

pipeline {
    parameters {
        choice(choices: 'dev\ntest\nbeta', description: 'Which ElasticSearch index to create + load data?', name: 'ENVIRONMENT')
    }
    environment {
        MASTER_BRANCH = "master"
        ELASTIC_HOST = "${BI_ELASTIC_HOST}"
        ELASTIC_PORT = "${BI_ELASTIC_PORT}"
        ENVIRONMENT = "${params.ENVIRONMENT}"
        ALIAS = "bi-${ENVIRONMENT}"
        INDEX_NAME = "bi-${ENVIRONMENT}-${new Date().format('ddMMyyyy-HHmmss')}"
        SSH_HOST = "${BI_CDHUT_SSH_HOST}"
        OOZIE_URL = "${BI_OOZIE_URL}"
        INDEX_JSON_PATH = "./business-index-api/conf/updated_index.json"
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
            when { branch MASTER_BRANCH }
            steps {
                dir('business-index-api') {
                    git(url: "https://github.com/ONSdigital/business-index-api.git", branch: "master")
                }
            }
        }

        stage('Index Exists?'){
            agent any
            when { branch MASTER_BRANCH }
            steps {
                colourText("info", "Checking to see if index [$INDEX_NAME] exists")
                sh "business-index-api/conf/scripts/index_exists.sh $ELASTIC_HOST $ELASTIC_PORT $INDEX_NAME"
                colourText("info", "No ElasticSearch index [${env.INDEX_NAME}] exists, continuing to Create Index step.")
            }
        }

        stage('Create Index'){
            agent any
            when { branch MASTER_BRANCH }
            steps {
                colourText("info", "Creating index [$INDEX_NAME]")
                sh "business-index-api/conf/scripts/create_index.sh $ELASTIC_HOST $ELASTIC_PORT $INDEX_NAME $INDEX_JSON_PATH"
            }
        }
      
        stage('Trigger Oozie Job'){
            agent any
            when { branch MASTER_BRANCH }
            steps {
                colourText("info", "Triggering Oozie Job to load ElasticSearch index [$INDEX_NAME]")
                // We need to get the (environment specific) job.properties file from Gitlab
                dir('configuration') {
                    git(url: "$GITLAB_URL/BusinessIndex/business-index-elastic-index.git", credentialsId: "bi-gitlab-id", branch: "master")
                }
                withCredentials([usernamePassword(credentialsId: "bi-${ENVIRONMENT}-ci-user-pass", passwordVariable: "PASSWORD", usernameVariable: "USERNAME")]) {
                    sshagent(credentials: ["bi-${ENVIRONMENT}-ci-ssh-key"]) {
                        sh './scripts/trigger_oozie_job.sh "$PASSWORD" "$ENVIRONMENT" "$SSH_HOST" "$OOZIE_URL" "$INDEX_NAME"'
                    }
                }
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