# dev-sec-ops-demo
A demonstration of how to create a secure CI/CD pipeline on GCP

## To test out the code:

#### Step 1 :

Clone this repo

#### Step 2 :

Setup Cloud Build Trigger with your github repo

#### Step 3 :

Create a repository in Artifacts Registry service 

#### Step 4 :

Create substitution env variable on your Cloud Build trigger with name '_CONTAINER_REPO_NAME' and the value as the name of your Artifact Registry created in previous step

#### Step 5 :

Craete a Cloud Deploy pipeline with the name as 'ci-cd-test'

#### Step 6 :

Craete three GKE clusters with the names as 'test', 'staging' and 'prod'


#### Step 7 :

Assign appropriate IAM permissions to your GKE service account to pull the images from Artifacts Registry

#### Step 8 :

Create a pub/sub topic with the name as 'clouddeploy-approvals'

#### Step 9 :

Craete a SendGrid free developer account to obtain an API key

#### Step 10 :

Create and configure a cloud function (code is given under the cloud-function folder of this repo), with the trigger as the 'clouddeploy-approvals' pub/sub


#### Step 11 :

Make a code change and commit the change to trigger the build and deploy process


## Varification:


#### Step 1 :

A Cloud Build process should trigger automatically as soon as the commit is made to the github repo


#### Step 2 :

Verify that the build is successful and the Cloud deploy process is triggered automatically


#### Step 3 :

The rollout should be deployed successfully to the 'staging' and 'test' GKE clusters but should be pending approval on the 'prod' cluster


#### Step 4 :

Check the email for the link to approve or reject the deployment release


#### Step 5 :

Approve or Reject the release and the pipeline should proceed as expected