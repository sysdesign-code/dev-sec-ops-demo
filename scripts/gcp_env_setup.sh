#!/bin/bash

#Run the following ONE-TIME-SCRIPT which creates and provisions the necessary GCP cloud services that will be required to create the DevSecOps CICD pipeline for a sample docker application. Here's all the service deployments that will occur once the script finishes:

#Author: Anjali Khatri & Nitin Vashishtha

#Enable the following GCP APIs
#Cloud Build, Binary Authorization, On-Demand Scanning, Resource Manager API, Artifact Registry API, Artifact Registry Vulnerability Scanning, Cloud Deploy API, KMS API and Cloud Functions.
gcloud services enable cloudbuild.googleapis.com
gcloud services enable binaryauthorization.googleapis.com
gcloud services enable ondemandscanning.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerscanning.googleapis.com
gcloud services enable clouddeploy.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable cloudfunctions.googleapis.com

#GCP Project Variables
LOCATION=us-central1
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')
CLOUD_BUILD_SA_EMAIL="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

#Create the following custom IAM role
gcloud iam roles create cicdblogrole --project=${PROJECT_ID} \
    --title="cicdblogrole" \
    --description="Custom Role for GCP CICD Blog" \
    --permissions="artifactregistry.repositories.create,container.clusters.get,binaryauthorization.attestors.get,binaryauthorization.attestors.list,binaryauthorization.policy.update,clouddeploy.deliveryPipelines.get,clouddeploy.releases.get,cloudkms.cryptoKeyVersions.useToSign,cloudkms.cryptoKeyVersions.viewPublicKey,containeranalysis.notes.attachOccurrence,containeranalysis.notes.create,containeranalysis.notes.listOccurrences,containeranalysis.notes.setIamPolicy,iam.serviceAccounts.actAs,ondemandscanning.operations.get,ondemandscanning.scans.analyzePackages,ondemandscanning.scans.listVulnerabilities,serviceusage.services.enable,storage.objects.get" \
    --stage=Beta

#Add the newly created custom role, and "Cloud Deploy Admin" to the Cloud Build Service Account
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="projects/${PROJECT_ID}/roles/cicdblogrole"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role='roles/clouddeploy.admin'

#Add the following: "Artifact Registry Reader", "Cloud Deploy Runner" and "Kubernetes Engine Admin" IAM Role to the Compute Engine Service Account
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" --role='roles/artifactregistry.reader'

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" --role='roles/clouddeploy.jobRunner'

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" --role='roles/container.admin'

#Create a Default VPC and its embedded Subnet. This is under the assumption that the new GCP project did NOT automatically create a default VPC and Subnet.
#If the creation of a default VPC is not needed, comment out the following 3 commands.

SUBNET_RANGE=10.128.0.0/20
gcloud compute networks create default --subnet-mode=custom --bgp-routing-mode=regional --mtu=1460
gcloud compute networks subnets create default --project=$PROJECT_ID --range=$SUBNET_RANGE --network=default --region=$LOCATION

#Binary Authorization Attestor variables
ATTESTOR_ID=cb-attestor
NOTE_ID=cb-attestor-note

#KMS variables
KEY_LOCATION=global
KEYRING=blog-keyring
KEY_NAME=cd-blog
KEY_VERSION=1

curl "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}" \
  --request "POST" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $(gcloud auth print-access-token)" \
  --header "X-Goog-User-Project: ${PROJECT_ID}" \
  --data-binary @- <<EOF
    {
      "name": "projects/${PROJECT_ID}/notes/${NOTE-ID}",
      "attestation": {
        "hint": {
          "human_readable_name": "Attestor Note is Created, Requires the creation of an attestor"
        }
      }
    }
EOF

#Create attestor and attach to the Container Analysis Note created in the step above
gcloud container binauthz attestors create $ATTESTOR_ID \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=${PROJECT_ID}

#Before you can use this attestor, you must grant Binary Authorization the appropriate permissions to view the Container Analysis Note you created.
#Make a curl request to grant the necessary IAM role

curl "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy" \
  --request "POST" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $(gcloud auth print-access-token)" \
  --header "x-goog-user-project: ${PROJECT_ID}" \
  --data-binary @- <<EOF
    {
      'resource': 'projects/${PROJECT_ID}/notes/${NOTE_ID}',
      'policy': {
        'bindings': [
          {
          'role': 'roles/containeranalysis.notes.occurrences.viewer',
          'members': [
            'serviceAccount:${BINAUTHZ_SA_EMAIL}'
            ]
          }
        ]
      }
    } 
EOF

#Before you can use this attestor, your authority needs to create a cryptographic key pair that can be used to sign container images.
#Create a keyring to hold a set of keys specific for Attestation
gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}"

#Create a key name that will be assigned to the above key ring. 
gcloud kms keys create "${KEY_NAME}" \
    --keyring="${KEYRING}" \
    --location="${KEY_LOCATION}" --purpose asymmetric-signing \
    --default-algorithm="ec-sign-p256-sha256"

#Now, associate the key with your authority:
gcloud beta container binauthz attestors public-keys add  \
    --attestor="${ATTESTOR_ID}"  \
    --keyversion-project="${PROJECT_ID}"  \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}"

#Validate the note is registered with attestor with KMS key
gcloud container binauthz attestors list

#Create Artifact Registry Repository where images will be stored
gcloud artifacts repositories create test-repo \
    --repository-format=Docker \
    --location=us-central1 \
    --description="Artifact Registry for GCP DevSecOps CICD Blog" \
    --async

#Create two Pub/Sub topics for email approval notification and error logging
gcloud pubsub topics create clouddeploy-approvals
gcloud pubsub topics create clouddeploy-operations

#Create Cloud Function for email approval notification to deploy any worloads to productions
gcloud functions deploy cd-approval \
  --region=us-central1 \
  --runtime=nodejs16 \
  --source=./cloud-function \
  --entry-point=cloudDeployApproval \
  --trigger-topic=clouddeploy-approvals \
  --env-vars-file env.yaml

#Create Cloud Function for email notification if the workload deployment fails 
gcloud functions deploy cd-deploy-notification \
  --region=us-central1 \
  --runtime=nodejs16 \
  --source=./cloud-function/deployment-notification \
  --entry-point=cloudDeployStatus \
  --trigger-topic=clouddeploy-operations \
  --env-vars-file env.yaml
  
#Create three GKE clusters for test, staging and production. The Node.js docker image will be deployed as a release through the Cloud Deploy pipeline first in "dev". Next, the image deployment will be rolled to the "staging" cluster and once its successful, pending approval, the final image roll-out will deploy to the "prod" cluster.
#NOTE: If you're using a different VPC, ensure you change the --subnetwork config value to match against your VPC subnet

#GKE Cluster for Test environment, uncomment --subnetwork if you want to use a non-default VPC
gcloud container clusters create test \
    --project=$PROJECT_ID \
    --machine-type=n1-standard-2 \
    --region $LOCATION \
    --num-nodes=1 \
    --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE \
    --labels=app=vulnapp-test \
    --subnetwork=default
 
#GKE Cluster for Staging environment
gcloud container clusters create staging \
    --project=$PROJECT_ID \
    --machine-type=n1-standard-2 \
    --region $LOCATION \
    --num-nodes=1 \
    --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE \
    --labels=app=vulnapp-staging \
    --subnetwork=default

#GKE Cluster for Production environment
gcloud container clusters create prod \
    --project=$PROJECT_ID \
    --machine-type=n1-standard-2 \
    --region $LOCATION \
    --num-nodes=1 \
    --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE \
    --labels=app=vulnapp-prod \
    --subnetwork=default
