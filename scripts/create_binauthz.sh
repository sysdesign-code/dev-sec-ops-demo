#!/bin/bash

#This script should only be run ONE TIME.
#It creates binary authorization attestor, associated attestor note, IAM policy assignment for that attestor, the associated keys to the attestor, and a custom binary authorization policy that can be assigned either to a GKE cluster or Kubernetes namespace.
#Author: Anjali Khatri

#List of all variables used in the script

#Enable the following GCP APIs
#Cloud Build, Binary Authorization, On-Demand Scanning, Resource Manager API, Artifact Registry API, Artifact Registry Vulnerability Scanning, Cloud Deploy API, and KMS API
gcloud services enable cloudbuild.googleapis.com
gcloud services enable binaryauthorization.googleapis.com
gcloud services enable ondemandscanning.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerscanning.googleapis.com
gcloud services enable clouddeploy.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable cloudfunctions.googleapis.com

#GCP Project Logistics
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


#Binary Authorization Attestor variables
ATTESTOR_ID=cb-attestor
NOTE_ID=cb-attestor-note

#KMS Details
KEY_LOCATION=global
KEYRING=blog-keyring
KEY_NAME=cd-blog
KEY_VERSION=1

#Apply the new binary authorization policy
#gcloud container binauthz policy import scripts/require_binauthz_gkecluster_policy.yaml

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

#curl -vvv -H "Authorization: Bearer $(gcloud auth print-access-token)" "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

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
#EOF \ "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

#Enable Cloud KMS API
#gcloud services enable --project "${PROJECT_ID}" cloudkms.googleapis.com

#Before you can use this attestor, your authority needs to create a cryptographic key pair that can be used to sign container images.
#Create a keyring to hold a set of keys specific for Attestation
gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}"

#Create a new asymmetric signing key pair for the attestor
#Create a key name that will be assigned to the above key ring. 
gcloud kms keys create "${KEY_NAME}" --keyring="${KEYRING}" --location="${KEY_LOCATION}" --purpose asymmetric-signing --default-algorithm="ec-sign-p256-sha256"

#Now, associate the key with your authority through the gcloud binauthz command:

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
gcloud artifacts repositories create newimagename --repository-format=Docker --location=us-central1 --description="Artifact Registry for GCP CICD Blog" --async
