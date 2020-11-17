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
- Activate the Container Registry by visiting <https://console.cloud.google.com/gcr>

### 2. Copy the example code from this repository

You have two options for this section, you can either use your own machine, or if you prefer, you can use the
cloud-shell which is provided by GCP in-browser. If you want to use your own machine, you'll need the Google Cloud CLI
and Docker installed.

Latency Attendees: Please use cloud shell as bandwidth may be limited in the workshop space.

If you prefer to use cloud shell, click the terminal icon at the top right of any Google Cloud console webpage. It looks
like this: `>_` surrounded by a white square.

- Create a fork of the demo repository available here: `https://github.com/jgunnink/latency-container-workshop`
- Clone the repository (either to your local machine or cloud shell). If you need setup SSH Git Auth, you can follow the
  following steps:
  <https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent>
- `cd` into the directory, and build the image with the following command: `docker build -t my_app:latest .`
- The console may "hang" or appear to do nothing. If this happens, wait 2-3 minutes, before proceeding. The image is
  building but the web-interface can take time to catchup. You may also get a message about Authorising Cloud Shell for
  API permissions. It's ok to click the Authorise button.
- After it's built you'll see a message like this:

```bash
Successfully built 16587984de73
Successfully tagged my_app:latest
```

### 3. Push and deploy the example server

Once you've build the image, it's time to store it in GCR (Google Container Repository).

- Still at the command line, you'll need to set the project ID for your current GCP project. If you can't remember what
  your project ID is, just type `gcloud projects list` from the command line, and the command will show all projects in
  your account. Grab the project ID and set it as an environment variable. For example:

```bash
jgunnink@cloudshell:~/latency-container-workshop$ gcloud projects list
PROJECT_ID          NAME               PROJECT_NUMBER
containerworkshop   ContainerWorkshop  123456789101
```

- And set the environment variable with this command: `PROJECT_ID=containerworkshop`
- Verify it was set with `echo $PROJECT_ID`. Eg:

```bash
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
- Press Next
- For the container URL, select the container we pushed to our repository in the previous step.
- Click to show the advanced settings.
- Under the "Container" tab, change the port number to be 3000. We configured rails to run on this port, and exposed it
  in our dockerfile.
- Change Memory to 1GiB and leave all other settings unchanged.
- Press Next
- Since this is a public webserver, we'll enable unauthenticated invocations so choose that option.
- Click create.

After a short time, the service will be deployed and serving traffic at the url provided. The first time the container
starts, it will be a little slower than subsequent starts.

Your URL will look something like: `https://container-workshop-f4hgxdldqa-ts.a.run.app` which you can visit and see your
deployed container running serverlessly in production.

---

## It's now time for the morning tea break

If you're here well before the 10:30 break, you're free to continue with the workshop, think about your entry to the
competition, or help a nearby person who looks like they need it!

---

Now that we're back from morning tea, the fun resumes! Automating deployments and testing traffic splitting. With git!

### 5. Connect Cloudbuild

In Github, navigate to <https://github.com/marketplace> and type "google" into the search box. In the results, look for
"Google Cloud Build" and add it to your account. You'll be taken to the console to authorise the application for use
with your Google account.

Then back in Github, go to configure your installation. If you're lost, you can continue from here:
<https://github.com/settings/installations>. Next to Google Cloud Build, click the configure button and under the
"Repository Access" section either add "All repositories" or select repos and choose the fork you've made of the
"latency-container-workshop" and add the repo by clicking save.

You'll be taken to google cloud to confirm the link. You'll select the project, then the repo to link to that project.

Finally you can configure the trigger settings. Here you would set when you wanted cloudbuild to fire. Click next to
save the default for now, you can change it later.

### 6. Permissions for Cloudbuild

In order for cloudbuild to deploy and manage our cloudrun containers, we need to give it permission to do so. Let's get
some more project information into our environment variables.

```bash
jgunnink@cloudshell:~/latency-container-workshop$ gcloud projects list
PROJECT_ID          NAME               PROJECT_NUMBER
containerworkshop   ContainerWorkshop  123456789101
```

Let's note again the PROJECT_ID and PROJECT_NUMBER, and store them for reuse later.

```bash
# Config
PROJECT_ID=containerworkshop
PROJECT_NUMBER=your-gcp-project-number

# Grant the Cloud Run Admin role to the Cloud Build service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role roles/run.admin

# Grant the IAM Service Account User role to the Cloud Build service account on the Cloud Run runtime service account
gcloud iam service-accounts add-iam-policy-binding \
  $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

It's worth noting that we've given Admin permissions to cloudbuild to manage our cloud run service. In practice, it's
better to provide specific permissions that you intend cloudbuild to use.

### 7. The cloudbuild.yml file

In the root of this repository you'll see a cloudbuild.yml file. In it, there are some instructions which tell our
cloudbuild instance how to build our application. Right now, it's configured to deploy a new version and then send all
traffic (i.e. 100%) to the new version once the health checks are passing.

Let's change the command to deploy new versions of the container, but not send any traffic to them just yet.

In the cloudbuild.yml file look for the deployment step, and the argument to `--no-traffic` as seen here:

```yaml
# Deploy to cloud run
- name: "gcr.io/cloud-builders/gcloud"
  args: [
      "run",
      "deploy",
      "$PROJECT_ID",
      "--image",
      "gcr.io/$PROJECT_ID/my_app:latest",
      "--no-traffic", # Add this line
      "--region",
      "australia-southeast1",
      "--platform",
      "managed",
    ]
```

To read more about how this works, check out the documentation here:
<https://cloud.google.com/sdk/gcloud/reference/run/deploy#--no-traffic>

> Setting this flag assigns any traffic assigned to the LATEST revision to the specific revision bound to LATEST before
> the deployment. The effect is that the revision being deployed will not receive traffic.
>
> After a deployment with this flag the LATEST revision will not receive traffic on future deployments. To restore
> sending traffic to the LATEST revision by default, run the `gcloud run services update-traffic` command with
> `--to-latest`.

Now when we make a change to our code, cloudbuild will build the image, deploy it, but cloudrun won't send any traffic
to it.

Let's change that.

```yaml
# Switch 50% of all traffic over to the latest version.
- name: "gcr.io/cloud-builders/gcloud"
  args: [
      "run",
      "services",
      "update-traffic",
      "$PROJECT_ID",
      "--to-latest", # Delete this line
      "--to-revisions=LATEST=50", # Add this line
      "--region",
      "australia-southeast1",
      "--platform",
      "managed",
    ]
```

### 8. Make a small change

In the folders in the repo, navigate to the file at:

`app > views > welcome > index.html.erb`

Make a small change here, for example, change the text `version 1` to `version 2`.

Let's save all files make a commit and push our changes to our repo.

In the cloudbuild console you'll see cloudbuild running! It will build and deploy your app with no traffic initially,
then make a change to route 50% of the traffic over.

In the cloud run console you should see two versions of your application running. Test it by accessing the URL of your
application and validating that version 1 and 2 show up! (Keep hitting refresh if you don't see it straight away.)

In the cloud run console you'll be able to manually adjust the percentage of traffic between versions, feel free to play
around with it, if you like.

## End

Congratulations, you've made it to the end of the workshop. If you've finished early, below you'll find some more tasks
which you can try to extend what you've learned.

## Bonus tasks

These tasks are designed to make you think about your learnings and extend them into creating a more robust service. One
that can be used in workplaces and create good DevOps practices. They also show some of the power of the cloud and how
you can control deployments using code, commits and controls.

1. Completely automate the entire application we've created today using the services we've connected on GCP using
   infrastructure as code templates. Using Terraform or similar.

   Helpful links:

   - <https://learn.hashicorp.com/collections/terraform/gcp-get-started>
   - <https://cloud.google.com/solutions/infrastructure-as-code/>

1. Add some automation (by any means necessary) to promote a workload from 50% traffic to 100% traffic after the
   application is reporting zero errors after a given amount of time.

1. Using the tools we've covered, setup some automated testing. Where will it be added in the flow of code to
   production? (note, to complete this exercise a script which exits with a code zero to prove the concept is fine)

1. Configure your pipeline to only deploy when git tags are created in the master branch.

   Helpful Links:

   - <https://git-scm.com/book/en/Git-Basics-Tagging>
   - <https://docs.github.com/en/free-pro-team@latest/rest/reference/git#tags>

1. Observe the memory and CPU utilisation with the metrics provided.

   - Have we right-sized this application? How can you tell?
   - What happens to the performance of the application if we increase or decrease CPU or Memory?

   Understanding the metrics of our application can help ensure we have the capacity to serve customers quickly and also
   ensure we don't create services which cost extra unnecessarily. See what monitoring and observability you can setup
   for the application using native cloud tools to pro-actively monitor your application. Hint: take a look at
   Stackdriver

1. Completed all the above in the workshop? Come find me for employment opportunities.
