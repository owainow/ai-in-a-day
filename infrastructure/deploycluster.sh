# Login to Azure
az login

# Set the environment variables
# Retrieve the Azure subscription ID dynamically
export AZURE_SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
export AZURE_RESOURCE_GROUP="AIinaDay"
export AZURE_LOCATION="uksouth"
export CLUSTER_NAME="ai-model-cluster"

# Prompt the user for their initials
read -p "Enter your initials: " INITIALS

# Set the ACR_NAME variable and append the initials
export ACR_NAME="llmrepo${INITIALS}"

# Register the AIToolchainOperatorPreview feature
az feature register --namespace "Microsoft.ContainerService" --name "AIToolchainOperatorPreview"

# Wait for the feature to be registered
while true; do
    status=$(az feature show --namespace "Microsoft.ContainerService" --name "AIToolchainOperatorPreview" --query "properties.state" -o tsv)
    if [ "$status" == "Registered" ]; then
        echo "Feature is registered."
        break
    else
        echo "Waiting for feature to be registered..."
        sleep 30
    fi
done

# Create the resource group
az group create --name ${AZURE_RESOURCE_GROUP} --location ${AZURE_LOCATION}

# Echo to inform user for custom parquet
echo "If you want to fine tune your model for a different purpose review the python file that is created in the parquet folder."

# Create the Azure Container Registry
az acr create --resource-group $AZURE_RESOURCE_GROUP --name $ACR_NAME --sku Basic --location $AZURE_LOCATION

# Create the AKS cluster with the AIToolchainOperatorPreview feature enabled
az aks create \
  --location ${AZURE_LOCATION} \
  --tier standard \
  --resource-group ${AZURE_RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --enable-oidc-issuer \
  --enable-ai-toolchain-operator \
  --generate-ssh-keys \
  --enable-cost-analysis \
  --attach-acr ${ACR_NAME}

# Get the AKS cluster credentials
az aks get-credentials --resource-group ${AZURE_RESOURCE_GROUP} --name ${CLUSTER_NAME}

# Verify connection to the cluster
echo "Verifying connection to the cluster..."
kubectl get nodes

# Set the environment variables for the AIToolchainOperator FedCred
export MC_RESOURCE_GROUP=$(az aks show --resource-group ${AZURE_RESOURCE_GROUP} --name ${CLUSTER_NAME} --query nodeResourceGroup -o tsv)
export PRINCIPAL_ID=$(az identity show --name "ai-toolchain-operator-${CLUSTER_NAME}" --resource-group "${MC_RESOURCE_GROUP}" --query 'principalId' -o tsv)
export KAITO_IDENTITY_NAME="ai-toolchain-operator-${CLUSTER_NAME}"
export AKS_OIDC_ISSUER=$(az aks show --resource-group "${AZURE_RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --query "oidcIssuerProfile.issuerUrl" -o tsv)

# Create role assignment for KAITO
az role assignment create \
  --role "Contributor" \
  --assignee "${PRINCIPAL_ID}" \
  --scope "subscriptions/${AZURE_SUBSCRIPTION_ID}/resourcegroups/${AZURE_RESOURCE_GROUP}"

# Create the Federated Credential
az identity federated-credential create \
  --name "kaito-federated-identity" \
  --identity-name "${KAITO_IDENTITY_NAME}" \
  -g "${MC_RESOURCE_GROUP}" \
  --issuer "${AKS_OIDC_ISSUER}" \
  --subject system:serviceaccount:"kube-system:kaito-gpu-provisioner" \
  --audience api://AzureADTokenExchange

# Restart the KAITO provisioner
kubectl rollout restart deployment/kaito-gpu-provisioner -n kube-system
sleep 60

# Check the status of the KAITO provisioner
kubectl get deployment -n kube-system | grep kaito

# Log in to the Azure Container Registry
az acr login --name $ACR_NAME --resource-group $AZURE_RESOURCE_GROUP
az acr update --name $ACR_NAME --resource-group $AZURE_RESOURCE_GROUP --admin-enabled true

# Get the ACR login server name
echo "Getting ACR details..."
export ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $AZURE_RESOURCE_GROUP --query loginServer --output tsv)

# Build the Docker image
echo "Building the Docker image..."
docker build -t ${ACR_LOGIN_SERVER}/chatbot-react-app:latest ../application/chatbot-react-app

# Push the Docker image to ACR
echo "Pushing the Docker image to ACR..."
docker push ${ACR_LOGIN_SERVER}/chatbot-react-app:latest

# Get the ACR credentials
export ACR_USERNAME=$(az acr credential show --resource-group $AZURE_RESOURCE_GROUP --name $ACR_NAME --query username --output tsv)
export ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $AZURE_RESOURCE_GROUP --query passwords[0].value --output tsv)

# Create the falcon-kaito namespace
kubectl create namespace falcon-kaito

# Create a Kubernetes secret for the ACR
echo "Creating the secret for the ACR in falcon-kaito namespace"
kubectl create secret docker-registry acr-secret \
  --namespace falcon-kaito \
  --docker-server=$ACR_LOGIN_SERVER \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD

# Substitute environment variables in the falcon-7b-instruct.yaml template
echo "Adding login server dynamically to the tuning workspace yaml"
envsubst < kubernetes/falcon-7b-instruct-template.yaml > kubernetes/falcon-7b-instruct.yaml

echo "Adding login server dynamically to the inference workspace yaml"
envsubst < kubernetes/falcon-7b-inference-template.yaml > kubernetes/falcon-7b-inference.yaml

# Deploy the tuning workspace
echo "Deploying Workspace for tuning"
kubectl apply -f kubernetes/falcon-7b-instruct.yaml --namespace falcon-kaito

echo "Checking for workspace creation..."
kubectl get workspace -n falcon-kaito

echo "Checking for job tuning creation..."
echo "Waiting for the job to be created..."
while true; do
    job_count=$(kubectl get jobs -n falcon-kaito --no-headers | wc -l)
    if [ "$job_count" -gt 0 ]; then
        echo "Job found."
        kubectl get jobs -n falcon-kaito
        break
    else
        echo "No jobs found. Waiting..."
        sleep 30
    fi
done

# Monitor the tuning workspace status
while true; do
    status=$(kubectl get workspace workspace-tuning-falcon-7b-instruct -n falcon-kaito -o jsonpath='{.status.conditions[?(@.type=="WorkspaceSucceeded")].status}')
    if [ "$status" == "True" ]; then
        echo "Model Workspace is complete."
        echo "Image has been created and pushed to ACR."
        break
    else
        echo "Waiting for workspace to be ready..."
        sleep 30
    fi
done

# Deploy the inference workspace
echo "Deploying Workspace for inference"
kubectl apply -f kubernetes/falcon-7b-inference.yaml --namespace falcon-kaito

# Monitor the inference workspace status
while true; do
    status=$(kubectl get workspace workspace-falcon-7b-inference-adapter -n falcon-kaito -o jsonpath='{.status.conditions[?(@.type=="WorkspaceSucceeded")].status}')
    if [ "$status" == "True" ]; then
        echo "Model Workspace is complete and ready for inference."
        break
    else
        echo "Waiting for workspace to be ready..."
        sleep 30
    fi
done

################################################################################
# DEPLOY THE LLM PROXY (Nginx)
################################################################################
echo "Deploying llm-proxy to expose the Falcon inference as a LoadBalancer..."
kubectl apply -f kubernetes/llm-proxy.yaml --namespace falcon-kaito

echo "Waiting to get an external IP for llm-proxy-service..."
while true; do
    PROXY_IP=$(kubectl get svc llm-proxy-service -n falcon-kaito -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$PROXY_IP" ]; then
        echo "Proxy IP: $PROXY_IP"
        break
    else
        echo "Waiting for load balancer to be assigned..."
        sleep 30
    fi
done

# Set the LLM_ENDPOINT environment variable to the llm-proxy-service load balancer IP
export LLM_ENDPOINT="http://${PROXY_IP}/chat"

################################################################################
# DEPLOY THE CHATBOT APP
################################################################################

# Create the namespace for the Chatbot App
kubectl create namespace chatbot-app

# Substitute environment variables in the chatbot-app.yaml template
echo "Adding image name and ACR dynamically to the chatbot-app.yaml"
envsubst < kubernetes/chatbot-app-template.yaml > kubernetes/chatbot-app.yaml

# Deploy the Chatbot App
echo "Deploying Chatbot..."
kubectl apply -f kubernetes/chatbot-app.yaml --namespace chatbot-app

# Get the external service IP address for the chatbot UI
echo "Waiting for the chatbot-react-app load balancer IP..."
while true; do
    EXTERNAL_IP=$(kubectl get svc chatbot-react-app -n chatbot-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$EXTERNAL_IP" ]; then
        echo "External IP is: $EXTERNAL_IP"
        break
    else
        echo "Waiting for external IP to be assigned to chatbot..."
        sleep 30
    fi
done

echo "Creation complete. You can access your application at: http://$EXTERNAL_IP"