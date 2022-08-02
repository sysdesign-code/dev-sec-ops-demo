#!/bin/bash

#This script should only be run ONE TIME.
#It creates binary authorization attestor, associated attestor note, IAM policy assignment for that attestor, the associated keys to the attestor, and a custom binary authorization policy that can be assigned either to a GKE cluster or Kubernetes namespace.
#Author: Anjali Khatri

#List of all variables used in the script

#GCP Project Logistics
LOCATION=us-central1
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')
CLOUD_BUILD_SA_EMAIL="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

#Binary Authorization Attestor
ATTESTOR_ID=cb-attestor
NOTE_ID=cb-attestor-note

#KMS Key Details
KEY_LOCATION=global
KEYRING=blog-keyring
KEY_NAME=cd-blog-two
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
          "human_readable_name": "Attestor Note is Created, Requires an attestor"
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
EOF \ "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

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