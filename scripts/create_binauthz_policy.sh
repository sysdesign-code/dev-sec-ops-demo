#Project variables for project and the GKE environments
LOCATION=us-central1
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
ATTESTOR_ID=cb-attestor
GKE_Test_Cluster_Name=test
GKE_Staging_Cluster_Name=staging
GKE_Prod_Cluster_Name=prod

#GKE variables for the 3 clusters where docker image will be deployed through Cloud Deploy pipeline
GKE_BA_Policy_Test=$LOCATION.$GKE_Test_Cluster_Name
GKE_BA_Policy_Staging=$LOCATION.$GKE_Staging_Cluster_Name
GKE_BA_Policy_Prod=$LOCATION.$GKE_Prod_Cluster_Name

#Container Image stored in Artifact Registry
REPO_NAME=test-repo
DIGEST_CONTAINER_PATH=$LOCATION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cd
REVISION_ID=$(gcloud container images list-tags $DIGEST_CONTAINER_PATH --format='value(tags)' --limit=1)
CONTAINER_PATH=$LOCATION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/cd:$REVISION_ID
DIGEST=$(gcloud container images describe ${CONTAINER_PATH} --format='get(image_summary.digest)')
CONTAINER_IMAGE_DIGEST_PATH=${DIGEST_CONTAINER_PATH}@${DIGEST}
echo $CONTAINER_IMAGE_DIGEST_PATH

#KMS Key Details
KEY_LOCATION=global
KEYRING=blog-keyring
KEY_NAME=cd-blog
KEY_VERSION=1

#To ensure everything worked as expected, you can list your attestations and the key that's assigned to that attestor for verification
#Print the list of attestors, you should now see a key registered:

gcloud container binauthz attestors list

#Next, sign the attestor with the specific container image path in artifact registry. This command simply takes in the details of the key you want to use for signing, and the specific container image you want to approve

gcloud beta container binauthz attestations sign-and-create  \
    --artifact-url="${CONTAINER_IMAGE_DIGEST_PATH}" \
    --attestor="${ATTESTOR_ID}" \
    --attestor-project="${PROJECT_ID}" \
    --keyversion-project="${PROJECT_ID}" \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}"

gcloud container binauthz attestations list \
   --attestor=$ATTESTOR_ID --attestor-project=${PROJECT_ID}

curl "https://binaryauthorization.googleapis.com/v1/projects/${PROJECT_ID}/policy" \
    -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    -H "x-goog-user-project: ${PROJECT_ID}" \
    --data-binary @- <<EOF 
    {
      "globalPolicyEvaluationMode": "ENABLE",
      "defaultAdmissionRule": {
          "enforcementMode": "ENFORCED_BLOCK_AND_AUDIT_LOG",
          "evaluationMode": "REQUIRE_ATTESTATION",
           "requireAttestationsBy": [
                "projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}"
            ]
      },
      "clusterAdmissionRules": {
          "${GKE_BA_Policy_Test}": {
            "enforcementMode": "ENFORCED_BLOCK_AND_AUDIT_LOG",
            "evaluationMode": "REQUIRE_ATTESTATION",
            "requireAttestationsBy": [
                "projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}"
            ]
          },
          "${GKE_BA_Policy_Staging}": {
            "enforcementMode": "ENFORCED_BLOCK_AND_AUDIT_LOG",
            "evaluationMode": "REQUIRE_ATTESTATION",
            "requireAttestationsBy": [
                "projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}"
            ]
          },
          "${GKE_BA_Policy_Prod}": {
            "enforcementMode": "ENFORCED_BLOCK_AND_AUDIT_LOG",
            "evaluationMode": "REQUIRE_ATTESTATION",
            "requireAttestationsBy": [
                "projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}"
            ]
          }
      },
      "name": "projects/${PROJECT_ID}/policy"
    }
EOF
