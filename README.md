# AI In a Day - KAITO and GitHub Copilot to accelerate application deployment.
This repository has been developed as part of this Microsoft Tech Blog:

I would encourage you to read through it prior to deploying this repository. 

In the blog post I document my experience of spending a full day using KAITO and CoPilot to accelerate deployment and development of a self managed AI enabled chatbot deployed with a fine tuned LLM in a Kubernetes cluster. AI Apps to create AI Apps!

## Pre-Requisites

The only real pre-requisite for this example is to have GPU Quota for KAITO to use in the cluster deployment location selected. In this blog I use 12vCPU of the NCv3 Series which are powered by NVIDIA Tesla V100 GPUs. To learn how to make changes to your subscription quota please review the quota panel in your Azure Subscription.

## Deploy repository

Simply run the bash script and once you complete the login flow and enter your initials for unique resource creation the rest of the deployment will be handled for you from tuning to app deployment. Once complete navigate to the URL shown at the bottom of the terminal and play with the chatbot that has been created. 

The bash script can be run from the infrastructure folder of the cloned directory using the following command:
```
cd infrastructure
. deploycluster.sh
```

The script will take over an hour to run from start to finish with interaction required for sign in and entering initials at the start. You may also need to interact later on if this is not the first time you have ran the script and you have not cleared your old kubeconfigs. 
