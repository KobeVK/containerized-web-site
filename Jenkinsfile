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
            choices: ['ami-0a89a7563fc68be84'],
            description: 'Select AMI'
        )
        choice(
            name: 'type',
            choices: ['t2.micro', 'm5.large', 'c5.xlarge', 'r5.4xlarge'],
            description: 'Select the insctance type'
        )
		// choice('region', ['us-west-1', 'us-east-1', 'eu-west-1', 'ap-southeast-2'], 'Select region.')
		// choice('ami', ['ami-0a887e401f7654935', 'ami-03d64741867e7a62c', 'ami-0b2f6494ff7a4d4b4', 'ami-0e4d4ad174dc9fca9'], 'Select AMI.')
		// choice('type', ['t2.micro', 'm5.large', 'c5.xlarge', 'r5.4xlarge'], 'Select the insctance type.')
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
