
# Building a secure DevSecOps CICD delivery pipeline using Google Cloud.

## Introduction  

DevOps is a concept which allows software development teams to release software in an automated and stable way. DevOps itself is not just one thing, its a combinatin of culture and technology, which togather make the actual implementation of DevOps successful. In this blog, we will be focusing on the tools and technology side of DevOps. At the core of the technicla aspect of DevOps concept is Continous Integration and Continous Delivery (CI/CD). The idea behind CI/CD concept is to create an automated software delivery pipeline which continoiusly deploys the new software releases in an automated fashion. The flow begins with the developers commitng the code chnages to a source code repository, which automatically triggers the pipeline by building and dpeloying the code changes into various enviornments starting from non-prod enviornments to production enviornment. 

Also, as we build the CI/CD pipelines for faster and reliable software delivery, the security aspect should not be ignored and must be incorporated into the pipeline right from the beginning. When we build our source code, we typically make use of various open source libraries and container images and its imperetive to have some security safe guards within the CI/CD piepline to ensure that the software we are building and deploying is free from any vulnerability. Additionally, its equally important to have control over what type of code/container image should be allowed to be deployed on your target runtime enviornment. Security is everyone's responsibility. [Shifting left](https://cloud.google.com/architecture/devops/devops-tech-shifting-left-on-security) on security is a DevOps practice which allows you to address security concerns early in the software development lifecycle. Vulnerability scaning of the container images and putting security policies in place using binary Authorization to allow only known/trusted images to be dpeloyed on GKE are a couple of ways to implement this policy to make your pipelines more secure. 

- What are we building -

In this blog post, we will show how to build a secure CI/CD pipeline using Google Cloud's native services. We will create a secure software delivery pipeline which builds a sample Nodjs application as a container image and deploys it on GKE clusters. 

- How are we building the pipeline - 

We we going to use the following Google Cloud native services to build the pipeline - 


1. [Cloud Build](https://cloud.google.com/build) - Cloud Build is a completely serverless CI/CD platform allows you to automate your build, test and deploy tasks.
2. [Artifact Registry](https://cloud.google.com/artifact-registry) - Artifact Registry is a service to securely store and manage your build artifacts.
3. [Cloud Deploy](https://cloud.google.com/deploy) - Cloud Deploy is a fully managed Continous Delivery service for GKE and Anthos.
4. [Binary Authorization](https://cloud.google.com/binary-authorization) - Binary Authorization provides deploy time security controls for GKE and Cloud Run deployments.
5. [GKE](https://cloud.google.com/kubernetes-engine) - GKE is a fully managed Kubernetes platform.
6. [Google Pub/Sub](https://cloud.google.com/pubsub) - A serverless messaging platform.
7. [Cloud Functions](https://cloud.google.com/functions) - A serverless platform to run your code.

We are are using github as a source code reporsitory and Sendgrid APIs to send email.

The CI/CD piepeline is setup in a way that a Cloud Build trigger is configured to sense any code push to a certain reporsitory and branch in the github, it starts the build process.

Below is the flow of how the CI/CD piepeline is setup, without any security policy enforecement -

1. Developer checks in the code to a github repo
2. A Cloud Build trigger is configured to sense any new code push to this github repo and start the 'build' process. A successful build results into a docker container image.
3. The container image is stored into Artifacts Registry.
4. The Build process kicks of a Cloud Deploy deployment process which deploys the container image to three different GKE clusters, which are pre-configured as the deployment pipeline mimicing the test, staging and production environments. 
5. Cloud Deploy is configured to go through an approval step before deploying the image to the Production GKE cluster. 
6. Pre-configured email id recieves an email notifying that a Cloud Deploy release requires your approval. The reciever of the email can then either approve or reject the deployment to the production GKE cluster. Cloud function code can be found [here](https://github.com/sysdesign-code/dev-sec-ops-demo/blob/main/cloud-function/index.js)


In order to secure this CI/CD pipeline, we will make use of a couple of Google Cloud's native features and services. First, we will enable vulerability check on the Artificats registry, which is a out of the box feature. Then finally, we will create a security policy using Binary Authorization service which only allows certain image to be deployed on a GKE cluster. 

Below is the flow when we try to build and deploy a container image which has vulerability present -

1. Developer checks in the code to a github repo
2. A Cloud Build trigger is configured to sense any new code push to this github repo and start the 'build' process. 
3. The build process fails with the error message that some critical vulerabilities were found in the image.

Below is the flow when we try to deploy a container image to GKE which voilates a Binary Authorization policy -

1. Developer checks in the code to a github repo
2. A Cloud Build trigger is configured to sense any new code push to this github repo and start the 'build' process. A successful build results into a docker container image.
3. The container image is stored into Artifacts Registry.
4. The Build process kicks of a Cloud Deploy deployment process which deploys the container image to three different GKE clusters, which are pre-configured as the deployment pipeline mimicing the test, staging and production environments. 
5. Cloud Deploy fails as the GKE clusters reject the incoming image as it voilates the Binary Authorization policy. Please note that an approval email is still triggered before the production deployment, the reciever of the email is expected to reject this release based upon the failures in the previous stages.
An email is sent about the deployment failure. Cloud function code can be found [here](https://github.com/sysdesign-code/dev-sec-ops-demo/tree/main/cloud-function/deployment-notification).
Note - The deployment fails after the timeout value is exceeded set for your pipeline, which is 10 minutes by default, but you can change this value according to your needs, see [here](https://cloud.google.com/deploy/docs/deploying-application#change_the_deployment_timeout) for more details. 


- Note : The Cloud Functions code provided for the rollout approval email and deployment failure notification is under the folder cloud-functions in this repo. You will still have to create these cloud functions with this code in your Google Cloud project to recieve email notifications.

## ANJALI: Solution Details - Design diagram of the complete flow

- Diagram of the secure CI/CD pipeline, create architecture diagram
- Brief introduction of all the GCP services used in the solution

## ANJALI: Step-by-Step instructions of building the CI/CD piepline:

### GCP Environment Setup

#### Pre-Requisities

These steps are required to setup and prepare your GCP environment. We highly recommend you create a new GCP Project as you're going to be running multiple cloud services within region "us-central1". 

1. Fork the following GitHub Repo: `https://github.com/sysdesign-code/dev-sec-ops-demo 
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

## Conclusion and Further Reading - 

In this blog post, we built a secure CI/CD pipeline using Google Cloud's native services. We saw how we can secure the pipeline using Google Cloud's native services such as Binary Authorization and Vulenerabiloity scaning of the container images. We only saw one way to put some control on which images can be dpeloyed on GKE cluster, but Binary Authorization also offers [Build Verification](https://cloud.google.com/binary-authorization/docs/overview#attestations) in which Binary Authorization uses attestations to verify that an image was built by a specific build system or continuous integration (CI) pipeline such as Cloud Build. Additionally, Binary Authorization also writes all the events where the deployment of a container image is blocked due to the constraints defined by the security policy, to the audit logs. You can create alerts on these log entries and notify the appropriate team members about the blocked deployment event.



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
