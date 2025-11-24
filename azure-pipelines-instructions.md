# Azure Pipeline Deployment Instructions (Updated for 2025)

> **⚠️ IMPORTANT**: These instructions have been updated to reflect the modernized application dependencies (Python 3.11, Flask 3.0.3, redis 5.0.8). The `azure-pipelines.yaml` file has been updated to use current Ubuntu images and package versions.

## Prerequisites

Before starting, ensure your VMSS instances meet these requirements:
- **Python 3.11** (not Python 3.6)
- **Ubuntu 22.04 or later** (not Ubuntu 16.04)
- Modern package versions specified in `requirements.txt`

## Setup Instructions

1. Clone this repo
2. Create new repo on your GitHub account and push the contents up to it
3. [Create a free Azure DevOps account](https://azure.microsoft.com/en-us/pricing/details/devops/azure-devops-services/) (Click **Start Free** under **Azure Pipelines**) if you haven't already
4. Create a new Project

   <img src="instruction-screenshots/create-new-project.png" width="860">

5. Once the project is created, you're taken to the New Pipeline page. Select **GitHub**

   <img src="instruction-screenshots/create-new-pipeline.png" width="860">

6. Select your GitHub repo
7. Configure your pipeline by choosing **Existing Azure Pipelines YAML File** and select the `azure-piplines.yaml` file in the menu that pops out on the right.

   <img src="instruction-screenshots/configure-pipeline.png" width="860">

8. On the **Review** page, use the drop down arrow next to **Run** and select **Save**. Don't run the pipeline just yet. This will create an environment for the next step.

   <img src="instruction-screenshots/review-pipeline.png" width="860">

9. Click on **Environments** and you should see an environment named **ACDND-C4-Project**. Click on it.

   <img src="instruction-screenshots/view-environment.png" width="860">

10. Once inside the environment, click on **Add resource**.

      <img src="instruction-screenshots/add-resource.png" width="860">

11. Select **Virtual Machine**.

      <img src="instruction-screenshots/add-resource-vm.png" width="860">

12. Select **Linux** as the OS. You'll then need to copy the registration script to your clipboard and run this on the VM terminal.

      <img src="instruction-screenshots/add-resource-vm-2.png" width="860">

13. You should see a similar output from the script in the screenshot below. You can skip entering environment VM resource tags by inputting **N**.

      <img src="instruction-screenshots/pipeline-connection.png" width="860">

14. If everything was successful, you should see this output from the connection test. **Note**: Be sure to `cd ~` or disconnect from the VM once the registration script completes. If you are still in the `azagent` directory during deployment, you'll most likely run into an issue.

      <img src="instruction-screenshots/pipeline-connection-success.png" width="860">

**NOTE**: If the registration script shows `sudo: ./svc.sh: command not found`, run the following command in your VM terminal and then try the registration script again.

```bash
sudo bin/installdependencies.sh
cd ..
sudo rm -rf azagent
```

15. Back on Azure DevOps portal in Environments, you can close out the **Add resource** menu and refresh the page. You should now see the newly added VM resource listed under **Resources**.

      <img src="instruction-screenshots/add-resource-vm-3.png" width="860">

16. We're ready to deploy our application! Navigate to **Pipelines** and click **Run pipeline**.

      <img src="instruction-screenshots/run-pipeline.png" width="860">

This will go through the process of downloading the application files and zip them up as an artifact to be uploaded to the VM. Then it will run through the bash script in the `azure-pipelines.yaml` file, installing all dependencies and moving the artifact .zip file to an `app` directory where it will unzip the contents. If you get all green checks, you're ready to head back to the VM.

17. This should be the final step. Connect to the VM if you aren't already. `cd` into the app directory and run `python3 main.py`.

If you visit the public IP address for the VMSS in your browser, you should see your deployed application.

---

## ⚠️ Important Notes for Modernized Application

### Python Version Requirements
The pipeline now installs:
- **Flask 3.0.3** (was Flask 1.1.2)
- **redis 5.0.8** (was redis 3.5.3)
- **OpenCensus removed** (deprecated by Microsoft)

### VMSS Setup Changes Required
If you're using the `setup-script.sh` to create your VMSS:
1. Ensure VMs are running **Ubuntu 22.04** (not Ubuntu 16.04 or 18.04)
2. Python 3.11 should be available by default on Ubuntu 22.04
3. The `cloud-init.txt` may need updates for Python 3.11 compatibility

### Application Insights Integration
The TODO sections in `main.py` for Application Insights need to be completed with:
- **Azure Monitor OpenTelemetry** (not OpenCensus)
- Connection string (recommended) or instrumentation key
- Proper logging, metrics, and tracing configuration

### Troubleshooting
If the application fails to start after deployment:
1. **Check Python version**: Run `python3 --version` (should be 3.11+)
2. **Verify packages**: Run `pip3 list | grep -E "Flask|redis"`
3. **Check Redis connection**: Ensure Redis service is running: `sudo systemctl status redis`
4. **Review logs**: Check application output for import errors or connection issues

### Alternative: Docker Deployment (Recommended)
For more reliable deployments, consider:
1. Building the Docker image from the modernized Dockerfile
2. Pushing to Azure Container Registry
3. Deploying to Azure Container Instances or AKS instead of VMSS

This approach ensures consistent Python 3.11 environment and eliminates manual dependency installation issues.

---

Head back to the main [README](README.md#project-instructions) for further instructions.
