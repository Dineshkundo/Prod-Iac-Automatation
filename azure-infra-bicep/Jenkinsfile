pipeline {
    agent any

    environment {
        SUBSCRIPTION_ID = ""
        RESOURCE_GROUP  = "CODA_RG"
        LOCATION        = "eastus"
    }

    parameters {
        choice(
            name: 'ENV',
            choices: ['dev','qa','uat','prod'],
            description: 'Environment (dev/qa/uat/prod)'
        )
        choice(
            name: 'SERVICES',
            choices: [
                'Jenkins-vm',
                'Matching-Service',
                'Matching-Service-QA-Backup',
                'Boomi_Integration',
                'RHELDevQa',
                'RedhatServerUAT',
                'keyvault',
                'storage',
                'network',
                'sql',
                'aks'
            ],
            description: 'Select service to deploy'
        )
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "📥 Checking out Bicep repo..."
                git branch: 'main',
                    url: 'https://github.com/Dineshkundo/Prod-Iac-Automatation.git'
            }
        }

        stage('Azure Login (Managed Identity)') {
            steps {
                echo "🔑 Logging in to Azure using Managed Identity..."
                sh '''
                    az login --identity
                    az account set --subscription $SUBSCRIPTION_ID
                '''
            }
        }

        stage('Dry Run (What-If Analysis)') {
            steps {
                script {
                    def services = [params.SERVICES] // single choice selection
                    for (svc in services) {
                        svc = svc.trim()
                        def paramFile = "azure-infra-bicep/parameters/${params.ENV}.${svc}.json"

                        if (fileExists(paramFile)) {
                            echo "🔮 Running What-If for service: ${svc} using parameters: ${paramFile} ..."
                            sh """
                                az deployment group what-if \
                                  --resource-group $RESOURCE_GROUP \
                                  --template-file azure-infra-bicep/main.bicep \
                                  --parameters @${paramFile} \
                                  --mode Incremental \
                                  --output table
                            """
                        } else {
                            echo "⚠️ Parameter file ${paramFile} not found. Skipping ${svc}."
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up workspace..."
            cleanWs()
        }
    }
}
