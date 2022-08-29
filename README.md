
# Building a secure DevSecOps CICD delivery pipeline using Google Cloud  

## Anjali/Nitin, lets do this at the end: Introduction 

- A very brief introduction text about the DevOps and DevSecOps concept. 
- Introduction to secure CI/CD pipeline.
- Introduction to what this blog post is going to be about.

## NITIN: Outline

- The need of a secure software delivery pipeline (why)
- Google cloud native services used in the solution (What)
- How are we going to accomplish this goal by putthing these services togather (How)
- Google's SRE best practices <link>



## NITIN: We are going to use the following development enviornment and Google cloud services - Nitin

- Local Node.js docker based application that's using VS Code
- Google Cloud Artifacts Registry with Vulnerability Scanning
- Google Cloud Build
- Google Binary Authorization 
- Google Cloud Deploy
- Google Kubernetes Engine (GKE)
- Google Pub/Sub
- Google Cloud Functions
- **todo** Logging and Monitoring of the pipeline, Alert email from Audit logs via the Cloud Function for Vernability scanning/BinAuth check failure


## ANJALI: Solution Details - Design diagram of the complete flow

- Diagram of the secure CI/CD pipeline, create architecture diagram
- Brief introduction of all the GCP services used in the solution

## ANJALI: Step-by-Step instructions of building the CI/CD piepline:

### GCP Environment Setup

#### Pre-Requisities

These steps are required to setup and prepare your GCP environment. We highly recommend you create a new GCP Project as you're going to be running multiple cloud services within region "us-central1". 

1. Clone the following GitHub Repo: `https://github.com/sysdesign-code/dev-sec-ops-demo 
2. Create a new GCP Project, follow the steps here around how to provision and create one: https://cloud.google.com/resource-manager/docs/creating-managing-projects
3. Once your new project is created, enable Cloud SDK to allow CLI access for `gcloud`. Follow the steps here: https://cloud.google.com/sdk/docs/install
4. Once you've enabled CLI access, either through your Cloud Shell or local workstation, set your project ID:

    ```
    gcloud config set project YOUR_PROJECT_ID
    ```

#### Run the following one-time script 

This one time script creates and provisions the necessary GCP cloud services that will be required to create the DevSecOps CICD pipeline. Here's all the service deployments that will occur once the script finishes:

1. Enables all the required cloud service APIs such as: Cloud Build, Binary Authorization, Kubernertes Service, Artiface Registry, Cloud Deploy and many more.
2. Create three (3) GKE clusters for test, staging and production to show image roll-out deployments, across these clusters, using Cloud Deploy.
2. Bind all the necessary IAM roles and permissions for Cloud Build and Cloud Deploy.
3. Create Binary Authorization attestor, associated container note, cryptographic KMS key and all the associated IAM role and permissions to allow container note access for the attestor.
4. Create the artifact registry repository where the docker image will be stored.
5. Finally, Create a pub/sub topic and cloud function which will create email approvals for any Kubernetes deployment to the prod cluster.

To execute this script, run the following command:

    ```
    sh /scripts/gcp_env_setup.sh
    ```

This script will approximately take 20-22 minutes to complete. Once finished, the output should look similar to something like [this](/scripts/gcp_env_setup_OUTPUT.txt).

### Configure Cloud Build access for GitHub

### Configure and create Cloud Deploy Pipeline

### Setup and Enable Email Approval for GKE Production Cluster Deployment

## ANJALI: Step by Step instructions of testing and validation of the CI/CD piepline

### Run Cloud Build Configuration File for "Happy" Docker Path

### Run Cloud Build Configuration File for "Vulnerable" Docker Path
1) Ensure your GitHub Repo is connected as a repository in Cloud Build.
2) Edit the existing Trigger and update the Cloud Build configuration file location to be: "cloudbuild-vulnerable.yaml"
3) Update the "_SEVERITY" environment variable to be "HIGH" instead of "CRITICAL". Notes: This env variable value is case-sensitive, they should be all caps.
4) Make an update to one of the repo files and this will automatically kick start the cloud build process. The build will fail in "Step 2: Check For Vulnerabilities within the Image" because this image contains HIGH vunerabilities and cloud build will NOT push the image to be stored in artifact registry.
5) Go back to the Trigger for this cloud build and revert the "_SEVERITY" environment variable to be "CRITICAL".
6) Re-run the build and validate the GKE release deployment via Cloud Build fails in both "test" and "staging" GKE clusters because the new docker_vulnerable image deployment defined by this cloud build is NOT allowed because of binary authorization policy enforcement.
### Validate Image Deployment for "Happy" and "Vulnerable" paths for GKE

In order to test and validate the pipeline, perform the following steps - 

- Step 1 - Kickoff the build process by pushing a code change to the github repo
- Step 2 - Monitor the Cloud Build and check the build logs to ensure deployment is successful to test and staging
- Step 3
- .
- .
- Step n - Done

## Anjali/Nitin, lets do this after the end. Conclusion, Next Steps/Further Reading: 

- Conclude with what we accomplished.
- Refer to some other related avaialble GCP services which can be sued to enhance the pipeline and add more capabilities


----------------
Flow of the blog below.



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
