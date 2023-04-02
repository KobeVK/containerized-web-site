#!groovy

def ENVIRONMENT = ""
def buildNumber = env.BUILD_NUMBER as int
def mailTo = 'skvaknin@gmail.com'

pipeline {
	agent any
	parameters {
		string(name: 'region', defaultValue: 'eu-west-3')
		
	}

	environment {
      branch = "${env.GIT_BRANCH}"
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
					// abort a running Pipeline build if a new one is started
                    // https://support.cloudbees.com/hc/en-us/articles/360034881371-How-can-I-abort-a-running-Pipeline-build-if-a-new-one-is-started-
                    if (buildNumber > 1) milestone(buildNumber - 1)
                    milestone(buildNumber)
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
						if (branch == 'main') {
							env.ENVIRONMENT = 'production'
							env.prevent_destroy = "true"
							deployENV()
						} else {
							env.ENVIRONMENT = 'staging'
							deployENV()	
						}
					}
				}
			}
		}

		stage('Verify') {	
			steps {
				withCredentials([sshUserPrivateKey(credentialsId: "aws", keyFileVariable: 'KEY')]) {
					script{
						access_ip = sh (
							script: """
								terraform output -raw web_app_access_ip
							""", returnStdout: true
						).trim()
						env.IP = access_ip
						println "the machine terraform created is  = " + access_ip
						sh """
							sudo -- sh -c "sed 's/.*ssh-rsa/${access_ip} ssh-rsa/' /home/ubuntu/.ssh/known_hosts > /dev/null"
							sudo -- sh -c "echo ${access_ip} | sudo tee -a /home/ubuntu/Versatile/hosts > /dev/null "
							sleep 60 
							ansible ${access_ip} -m ping --private-key=$KEY
						"""
					}
				}
			}
		}
		
		stage('install') {	
			steps {
				withCredentials([sshUserPrivateKey(credentialsId: "aws", keyFileVariable: 'KEY')]) {
					script{
						sh """
							sed -i 's/hosts: all/hosts: ${env.IP}/' deploy_app_playbook.yml > /dev/null 1>&2
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
							buildNumber: "${buildNumber}",
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

def deployENV() {
	def buildNumber = env.BUILD_NUMBER
	sh """
		echo "Starting Terraform init"
		terraform init
		terraform plan -out myplan -var="environment=${env.ENVIRONMENT}" -var="id=${buildNumber}"  
		terraform apply -auto-approve -var="environment=${env.ENVIRONMENT}" -var="id=${buildNumber}"
	"""
}

def destroyENV() {
	def buildNumber = env.BUILD_NUMBER
	sh """
		sleep 600
		echo "Starting Terraform destroy"
		terraform destroy -auto-approve -var="environment=${env.ENVIRONMENT}" -var="id=${buildNumber}"
	"""
}

def sendEmail(mailTo) {
    println "send mail to recipients - " + mailTo
    def strSubject = "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
    def strBody = """<p>FAILED: Job <b>'${env.JOB_NAME} [${env.BUILD_NUMBER}]'</b>:</p>
        <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>"""
    emailext body: strBody, subject: strSubject, to: mailTo, mimeType: "text/html"
}
