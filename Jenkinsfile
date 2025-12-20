#!/usr/bin/env groovy
library identifier: 'jenkins-shared-library-master@main', retriever: modernSCM(
    [$class: 'GitSCMSource',
    remote: 'https://github.com/WhisperNet/jenkins-shared-library-master.git'
    ]
)
pipeline {
    agent any
    tools {
        maven 'maven-3.9.11'
    }
    stages {
        stage("test"){
            steps {
                script{
                    sh "mvn test"
                }
            }
        }
        stage("Increment version"){
            steps{
                script{
                    incrementVersionMvn()
                }
            }
        }
        stage("build jar"){
            steps{
                script{
                    echo "Building jar"
                    buildJar()
                }
            }
        }
        stage("build and push docker image"){
            steps{
                script{
                    echo "Building and pushing the docker image"
                    def credentialsId = "docker-hub"
                    buildImage("whispernet/tf-cicd-java-image:${env.IMAGE_NAME}")
                    dockerLogin(credentialsId)
                    dockerPush("whispernet/tf-cicd-java-image:${env.IMAGE_NAME}")
                }
            }
        }
        stage('Provision Infra') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_accesss_key')
                TF_VAR_env_prefix = 'test'
            }
            steps {
                script {
                    dir('terraform') {
                        sh 'terraform init'
                        sh 'terrafrom apply --auto-approve'
                        EC2_PUBLIC_IP = sh(
                            script: "terrafrom output ec2-public-ip"

                        ).trim()
                    }
                }
            }

        }
        stage('deploy') {
            environment {
                DOCKER_CREDS = credentials('docker-hub')
            }

            steps {
                script {
                    echo "Waiting for infra initialization"
                    sleep(time:90,unit: "SECONDS")

                    echo "Deploying docker image into provisoined EC2"
                    echo "EC2 IP: ${EC2_PUBLIC_IP}"

                    def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"
                    def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

                    sshagent(['server-ssh-key']) {
                        sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2Instance}:/home/ec2-user"
                        sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                        sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                    }
                }
            }

        }
        // stage("Commit incremented version"){
        //     steps{
        //         script{
        //             echo "Committing the incremented version"
        //             def branch = "master"
        //             def gitCreds = "github-repo-access"
        //             def origin = "git@github.com:WhisperNet/CI-CD-Pipeline-with-k8s.git"
        //             pushVersioIncrement(branch, gitCreds,origin)
        //         }
        //     }
        // }
    }

}


