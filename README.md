
# Building secure software delivery pipeline on Google Cloud - This is the content for the blog post....


- A very brief introduction text about the DevOps and DevSecOps concept. 
- Introduction to secure CI/CD pipeline.
- Introduction to what this blog post is going to be about.

Outline -

- The need of a secure software delivery pipeline (why)
- Google cloud native services used in the solution (What)
- How are we going to accomplish this goal by putthing these services togather (How)



We are going to use the following development enviornment and Google cloud services :

- Local nodejs development using VS Code
- Google Cloud Artifacts Registry with Vulnerability Scanning
- Google Cloud Build
- Google Binary Authorization 
- Google Cloud Deploy
- Google Kubernetes Engine (GKE)
- Google pub/sub
- Google Cloud Functions
- **todo** Logging and Monitoring of the pipeline, Alert email from Audit logs via the Cloud Function for Vernability scanning/BinAuth check failure


### Solution Details - Design diagram of the complete flow:

- Diagram of the secure CI/CD pipeline
- Brief introduction of all the GCP services used in the solution

### Step by Step instructions of building the CI/CD piepline

- Step 1 - Clone this repo
- Step 2 - Execute this ONE time script under scripts/create_binauthz.sh to: enable all the required GCP APIs, define environment variables for CICD pipeline within GCP, create the necessary IAM roles and permissions for Cloud Build and Cloud Deploy, Create binary authorization attestation and its necessary IAM, KMS keys and creating the artifact registry repository that will store the Docker Image.
- Step 3 - 
- Step 4 - 
- .
- Step n - Done

### Step by Step instructions of testing and validation of the CI/CD piepline

In order to test and validate the pipeline, perform the following steps - 

- Step 1 - Kickoff the build process by pushing a code change to the github repo
- Step 2 - Monitor the Cloud Build and check the build logs to ensure deployment is successful to test and staging
- Step 3
- .
- .
- Step n - Done

## Conclusion, Next Steps/Further Reading:

- Conclude with what we accomplished.
- Refer to some other related avaialble GCP services which can be sued to enhance the pipeline and add more capabilities






# Github page content
A demonstration of how to create a secure CI/CD pipeline on GCP


## Introduction:


DevSecOps is a practice to ensure that the software is delivered in continious and secure manner. DevSecOps is a combination if many things in itself, which includes multiple factors including process and people changes in your organization, however, in this blog post we will be just focsing on the technology aspect and show how you can create secure Continious Integration and Continious Deployment pipelines using Google Cloud's native services. More specifically, we will demonstrate how to build and deploy cotainer images on GKE clusters automatically using Gogle Cloud Build and Cloud Deploy, while securing your images and deployments using Google cloud Binary authorization and scanning your container images for vernabilities. This is important to note that this blog post uses Google cloud's native services to achive this, however, its entirely possible to use many open source and third party products for various stages of this secure software delivery piepline. Also, the entire setup is not dependent upon the specific programming language for the application and choice of porgramming language is completely independent. In other words, you can choose to run any container image which you are capable of developing in your local enviornment.


### Services and Development enviornment used:



We will also be Sendgrid APIs to send email as part of the approval process during the CI/CD pipeline.

## To test out the code:

#### Step 1 :

Setup gcloud cli on your local development enviornment. See details [here.](https://cloud.google.com/sdk/docs/install)

#### Step 1 :

Within the workspace, Clone this repo 

```
git clone https://github.com/sysdesign-code/dev-sec-ops-demo.git

```

Note - git client should be installed and setup on your local development enviornment. See instructions [here](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) 

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
