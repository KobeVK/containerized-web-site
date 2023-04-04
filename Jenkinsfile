#!groovy

def mailTo = 'skvaknin@gmail.com'

pipeline {
	
	agent any
	parameters {
        choice(
            name: 'region',
            choices: ['eu-west-3', 'us-east-1', 'eu-west-1', 'ap-southeast-2'],
            description: 'Select region'
        )
        choice(
            name: 'ami',
            choices: ['ami-08c4559b664a2c695'],
            description: 'Select AMI'
        )
        choice(
            name: 'type',
            choices: ['t2.micro', 'm5.large', 'c5.xlarge', 'r5.4xlarge'],
            description: 'Select the insctance type'
        )
	}

	environment {
	  GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no"
	}

	options {
		timestamps()
	}

	stages {

		stage('starting-fresh') {
            steps {
                script {
                    deleteDir()
					cleanWs()
                    checkout scm
                }
            }
        }

		stage('Properties Set-up') {
			steps {
				script {
					properties([
						disableConcurrentBuilds()
					])
				}
			}
		}

		stage('deploy') {
			steps {
                withAWS(credentials: 'aws-access-key') {
					script {
							env.prevent_destroy = "true"
								sh """
									echo "Starting Terraform init"
									terraform init
									terraform plan -out myplan -var="ami=${ami}" -var="region=${region}" -var="type=${type}"
         							terraform apply -auto-approve -var="ami=${ami}" -var="region=${region}" -var="type=${type}"
								"""
					}
				}
			}
		}

		stage('verify hosts are reachable') {
			steps {
				withCredentials([sshUserPrivateKey(credentialsId: "sshUserPrivateKey", keyFileVariable: 'KEY')]) {
:wq!					script {
						access_ip = sh (
						script: """
							terraform output -raw web_app_access_ip
						""", returnStdout: true
						).trim()
						env.IP = access_ip
						def success = false
						def startTime = currentBuild.startTimeInMillis
						def timeout = 120000 // 2 minutes
						def interval = 50 // 10 seconds
						while (!success && (currentBuild.startTimeInMillis - startTime) < timeout) {
							try {
								sh """	
									ansible all -m ping
								"""
								success = true
							} catch (Exception e) {
								println "trying to reach host"
								sleep interval
							}
						}
						if (!success) {
							error "Timed out while trying to reach host"
						}
					}
				}
			}
		}
		
		stage('install') {	
			steps {
				withCredentials([sshUserPrivateKey(credentialsId: "aws", keyFileVariable: 'KEY')]) {
					script{
						sh """
							ansible-playbook deploy_app_playbook.yml
							echo "your deployed web-app can be access here -> http://${env.IP}:8000"
						"""
					}
				}
			}
		}

		stage('test') {
			steps {
				script{
					sh """
                    	bash ./tests/health_check.sh ${env.IP}
                	"""
				}
			}
			post{
			    failure {
				    script{
					    sendEmail(mailTo)
				    }
			    }
		    }	
		}

		stage('Release') {
			steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]){
					script{
						sh """
							sed -i 's/hosts: all/hosts: ${env.IP}/' release_docker_playbook.yml > /dev/null 1>&2
						"""
					}
					ansiblePlaybook(
						playbook: 'release_docker_playbook.yml',
						extraVars: [
							usr: "${USERNAME}",
							pass: "${PASSWORD}",
							envioronment: "${env.ENVIRONMENT}"
						]
					)
				}
			}
		}

		stage('destroy image') {
            when {
                expression {
                    branch != "main"
                }
            }
			steps {
				withCredentials([sshUserPrivateKey(credentialsId: "aws", keyFileVariable: 'KEY')]) {
					script{
						destroyENV()
					}
				}
			}
		}
	}
}

// def deployENV() {
// 	sh """
// 		echo "Starting Terraform init"
// 		terraform init
// 		terraform plan -out myplan -var="ami=${ami}" -var="region=${region}" -var="type=${type}"
// 		terraform apply -auto-approve -var="ami=${ami}" -var="region=${region}" -var="type=${type}"
// 	"""
// }

def destroyENV(ami,region,type) {
	sh """
		sleep 600
		echo "Starting Terraform destroy"
		terraform destroy -auto-approve -var="ami=${ami}" -var="region=${region}" -var="type=${type}"
	"""
}

def sendEmail(mailTo) {
    println "send mail to recipients - " + mailTo
    def strSubject = "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
    def strBody = """<p>FAILED: Job <b>'${env.JOB_NAME} [${env.BUILD_NUMBER}]'</b>:</p>
        <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>"""
    emailext body: strBody, subject: strSubject, to: mailTo, mimeType: "text/html"
}
