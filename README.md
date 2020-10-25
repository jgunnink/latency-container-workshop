# Latency 2020 Demo Application

This is a demo application for the latency workshop for Serverless, Cloud-Native Containers!

## What's in this repository

- Dockerfile used for building the image
- cloudbuild.yml file for the deployment pipeline
- Stock standard ruby-on-rails application (without webpack/react), demonstrating a simple webpage served by a back-end
  container

## How to use

### 1. Create a Google Cloud Project

- If you don't already have a Google account, sign up for one, and then create a project in the console at
  <https://console.cloud.google.com>
- Activate the Cloud Run API by visiting the Cloud Run <https://console.cloud.google.com/run/>
- Activate the Cloud Build API by visiting <https://console.cloud.google.com/cloud-build/>

### 2. Copy the example code from this repository

You have two options for this section, you can either use your own machine, or if you prefer, you can use the
cloud-shell which is provided by GCP in-browser. If you want to use your own machine, you'll need the Google Cloud CLI
and Docker installed.

Latency Attendees: Please use cloud shell as bandwidth may be limited in the workshop space.

If you prefer to use cloud shell, click the terminal icon at the top right of any Google Cloud console webpage. It looks
like this: `>_` surrounded by a white square.

- Create a fork of the demo repository available here: `https://github.com/jgunnink/latency-container-workshop`
- Clone the repository (either to your local machine or cloud shell).
- `cd` into the directory, and build the image with the following command: `docker build -t my_app:latest .`
- The console may "hang" or appear to do nothing. If this happens, wait 2-3 minutes, before proceeding. The image is
  building but the web-interface can take time to catchup
- After it's built you'll see a message like this:

```
Successfully built 16587984de73
Successfully tagged my_app:latest
```

### 3. Push and deploy the example server

Once you've build the image, it's time to store it in GCR (Google Container Repository).

- Still at the command line, you'll need to set the project ID for your current GCP project. If you can't remember what
  your project ID is, just type `gcloud projects list` from the command line, and the command will show all projects in
  your account. Grab the project ID and set it as an environment variable. For example:

```
jgunnink@cloudshell:~/latency-container-workshop$ gcloud projects list
PROJECT_ID          NAME               PROJECT_NUMBER
containerworkshop   ContainerWorkshop  775632879874
```

- And set the environment variable with this command: `PROJECT_ID=containerworkshop`
- Verify it was set with `echo $PROJECT_ID`. Eg:

```
jgunnink@cloudshell:~/latency-container-workshop$ PROJECT_ID=containerworkshop
jgunnink@cloudshell:~/latency-container-workshop$ echo $PROJECT_ID
containerworkshop
```

- Now we need to tag the container with the URL for where we're going to store it:
  `docker tag my_app:latest gcr.io/$PROJECT_ID/my_app:latest`
- Finally, let's push it to the remote: `docker push gcr.io/$PROJECT_ID/my_app:latest`

### 4. Deploy to Cloud Run

In the console, we'll deploy the application for the first time before we move on to automated deployments.

- Navigate to <https://console.cloud.google.com/run/> and create a new service.
- Select Cloud Run (fully managed)
- Choose Australia Southeast 1 or another location if you want. Since we're in Australia, this will give us the best
  latency.
- Give your service a name, for this workshop, we'll use the \$PROJECT_ID - i.e. `containerworkshop` was my project ID,
  but yours will be different. Using the project ID will make deployments a little bit easier later.
- Since this is a public webserver, we'll enable unauthenticated invocations so choose that option.
- Press Next
- For the container URL, select the container we pushed to our repository in the previous step.
- Click to show the advanced settings.
- Under the "Container" tab, change the port number to be 3000. We configured rails runs on this port, and exposed it in
  our dockerfile.
- Change Memory to 1GiB and leave all other settings unchanged.
- Click create.

After a short time, the service will be deployed and serving traffic at the url provided. The first time the container
starts, it will be a little slower than subsequent starts.

Your URL will look something like: `https://container-workshop-f4hgxdldqa-ts.a.run.app` which you can visit and see your
deployed container running serverlessly in production.
