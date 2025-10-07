pipeline {
    agent any

    environment {
        AZURE_SUBSCRIPTION_ID = '<your-subscription-id>'
        AZURE_CREDENTIALS = 'azure-service-principal'  // Jenkins credential ID
        RESOURCE_GROUP = 'rg-${ENVIRONMENT}'
        LOCATION = 'eastus'
    }

    parameters {
        string(name: 'ENVIRONMENT', defaultValue: 'dev', description: 'Environment: dev/uat/prod')
    }

    stages {

        stage('Login to Azure') {
            steps {
                echo "Logging into Azure..."
                withCredentials([azureServicePrincipal(credentialsId: "${AZURE_CREDENTIALS}", subscriptionIdVariable: 'SUBSCRIPTION_ID', clientIdVariable: 'CLIENT_ID', clientSecretVariable: 'CLIENT_SECRET', tenantIdVariable: 'TENANT_ID')]) {
                    sh '''
                    az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID
                    az account set --subscription $SUBSCRIPTION_ID
                    '''
                }
            }
        }

        stage('Create Resource Group') {
            steps {
                echo "Creating Resource Group if not exists..."
                sh """
                az group create --name ${RESOURCE_GROUP} --location ${LOCATION}
                """
            }
        }

        stage('Deploy Key Vault & Secrets') {
            steps {
                echo "Deploying Key Vault and secrets..."
                sh """
                az deployment group create \
                    --resource-group ${RESOURCE_GROUP} \
                    --template-file iac/modules/keyvault.bicep \
                    --parameters @iac/variables/${ENVIRONMENT}.parameters.json
                """
            }
        }

        stage('Deploy Networking') {
            steps {
                echo "Deploying VNet and subnets..."
                sh """
                az deployment group create \
                    --resource-group ${RESOURCE_GROUP} \
                    --template-file iac/modules/network.bicep \
                    --parameters @iac/variables/${ENVIRONMENT}.parameters.json
                """
            }
        }

        stage('Deploy VMs') {
            steps {
                echo "Deploying Virtual Machines..."
                sh """
                az deployment group create \
                    --resource-group ${RESOURCE_GROUP} \
                    --template-file iac/main.bicep \
                    --parameters @iac/variables/${ENVIRONMENT}.parameters.json
                """
            }
        }

        stage('Deploy Storage / AKS / Others') {
            steps {
                echo "Deploying Storage, AKS, and other resources..."
                sh """
                az deployment group create \
                    --resource-group ${RESOURCE_GROUP} \
                    --template-file iac/modules/storage.bicep \
                    --parameters @iac/variables/${ENVIRONMENT}.parameters.json
                """
                sh """
                az deployment group create \
                    --resource-group ${RESOURCE_GROUP} \
                    --template-file iac/modules/aks.bicep \
                    --parameters @iac/variables/${ENVIRONMENT}.parameters.json
                """
            }
        }
    }

    post {
        success {
            echo "Deployment completed successfully for ${ENVIRONMENT}"
        }
        failure {
            echo "Deployment failed for ${ENVIRONMENT}"
        }
    }
}
