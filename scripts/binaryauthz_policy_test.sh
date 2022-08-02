#GKE Cluster that will be allowed deployed via Binary Authorization
PROJECT_ID=anjali-cicd
LOCATION=us-central1
GKE_NS=workingimages

GKE_Test_Cluster_Name=test
GKE_Staging_Cluster_Name=staging
GKE_Prod_Cluster_Name=prod

GKE_Test_Cluster_Config=gke_${PROJECT_ID}_${LOCATION}_${GKE_Test_Cluster_Name}
GKE_Staging_Cluster_Config=gke_${PROJECT_ID}_${LOCATION}_${GKE_Staging_Cluster_Name}
GKE_Prod_Cluster_Config=gke_${PROJECT_ID}_${LOCATION}_${GKE_Prod_Cluster_Name}

#OPTIONAL - TESTING ONLY
#This step is supposed to run in cloud deploy skaffold.yaml file. 
#But to test via the latest binary authorization policy, create a pod directly in your GKE cluster to validate binary authorization allows the recently signed ${CONTAINER_IMAGE_DIGEST_PATH}.
#

#OPTIONAL - Test binary authorization policy violation against GKE cluster (Test) - This deployment will FAIL b/c BA policy is not applied to this GKE cluster
#
kubectl config use-context $GKE_Test_Cluster_Config
kubectl delete ns $GKE_NS
kubectl create ns $GKE_NS
kubectl run test-pod -n $GKE_NS --image=$CONTAINER_IMAGE_DIGEST_PATH
sleep 5s
#
#Validate the pod is running within the GKE_NS.
#
kubectl get pods -n $GKE_NS

#OPTIONAL - Test binary authorization policy violation against GKE cluster (Staging) - This deployment will WORK b/c BA policy allows images to be deployed to this GKE cluster 
#
kubectl config use-context $GKE_Staging_Cluster_Config
kubectl delete ns $GKE_NS
kubectl create ns $GKE_NS
kubectl run test-pod -n $GKE_NS --image=$CONTAINER_IMAGE_DIGEST_PATH
sleep 5s
#
#Validate the pod is running within the GKE_NS.
#
kubectl get pods -n $GKE_NS

#OPTIONAL - Test binary authorization policy violation against GKE cluster (Prod) - This deployment will WORK b/c BA policy allows images to be deployed to this GKE cluster
#
kubectl config use-context $GKE_Prod_Cluster_Config
kubectl delete ns $GKE_NS
kubectl create ns $GKE_NS
kubectl run test-pod -n $GKE_NS --image=$CONTAINER_IMAGE_DIGEST_PATH
sleep 5s
#
#Validate the pod is running within the GKE_NS.
#
kubectl get pods -n $GKE_NS