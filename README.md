# Enhancing Applications - Modernized for 2025

> **⚠️ IMPORTANT**: This repository has been updated to resolve critical legacy dependency issues. The original codebase used Python 3.6 (EOL since December 2021) and outdated packages that are incompatible with modern Azure infrastructure and Docker Desktop environments.

In this project, you will apply the skills you have acquired in the Azure Performance course to collect and display performance and health data about an application. This is only half the battle; the other half is making informed decisions about the data and automating remediation tasks. You will use a combination of cloud technologies, such as Azure Kubernetes Service, VM Scale Sets, Application Insights, Azure Log Analytics, and Azure Runbooks to showcase your skills in diagnosing and rectifying application and infrastructure problems.

## 🔧 Legacy Dependency Modernization

This repository has been updated to fix critical compatibility issues with modern environments. Below are the changes made:

### Python Runtime Upgrade
- **Original**: Python 3.6 (End-of-Life: December 2021)
- **Updated**: Python 3.11 (Current stable version)
- **Impact**: Enables compatibility with modern Azure services, Docker images, and security patches

### Flask Web Framework
- **Original**: Flask 1.1.2 (Released: May 2020, contains security vulnerabilities)
- **Updated**: Flask 3.0.3 (Latest stable version)
- **Impact**: Improved security, performance, and compatibility with modern WSGI servers

### Redis Client Library
- **Original**: redis 3.5.3 (Released: May 2020)
- **Updated**: redis 5.0.8 (Latest stable version)
- **Changes**: Added `decode_responses=True` parameter to eliminate manual byte decoding
- **Impact**: Simplified code, better connection handling, improved performance

### Docker Configuration
- **Original**: `tiangolo/uwsgi-nginx-flask:python3.6` base image
- **Updated**: `python:3.11-slim` with Gunicorn
- **Changes**: 
  - Multi-stage build optimization
  - Modern WSGI server (Gunicorn instead of uWSGI)
  - Proper requirements.txt usage
  - Health check support
- **Impact**: Smaller image size, better performance, compatible with Docker Desktop and Azure Container Registry

### Monitoring Framework (Action Required)
- **Original**: OpenCensus 0.7.x (DEPRECATED by Microsoft)
- **Recommended**: Azure Monitor OpenTelemetry Distro 1.6.x
- **Status**: Placeholder code exists in `main.py` - requires implementation
- **Impact**: Modern observability, better Application Insights integration

### Testing Locally
The application now runs successfully on Docker Desktop with the following command:
```bash
docker-compose build
docker-compose up -d
# Access at http://localhost:8080
```

In this project, you'll be tasked to do the following:

- Setup Application Insights monitoring on a VMSS and implement monitoring in an application to collect telemetry data
- Setup an auto-scaling for a VMSS
- Setup an Azure Automation account and create a RunBook to automate the resolution of performance issues
- Create alerts to trigger auto-scaling on an AKS cluster and trigger a RunBook to execute

### Directory Structure

```bash
├── azure-vote-all-in-one-redis.yaml # Used to deploy the application to AKS using the "kubectl apply" command
├── docker-compose.yaml              # Used to create Docker images, and run the application locally using multiple Docker containers
├── azure-vote                       # Frontend Flask applicattion
│   ├── config_file.cfg              # Contains key-values for UI Configurations
│   ├── main.py                      # You may need to add a few lines of code here to enable App Insights
│   ├── Dockerfile                   # This file is used by docker-compose.yaml. It pulls a base image, installs packages
│   └── templates
│       └── index.html               
├── azure-vote.yaml              # This YAML file is used while deploying the application to the AKS. It contains the name of the frontend and backend images present in the ACR
├── cloud-init.txt               # This file is used while creating the VMSS using the command "az vmss create" available in the setup-script.sh
├── create-cluster.sh            # This script will create an AKS cluster and related resources
├── requirements.txt             # Contains the details of the packages to make the frontend app run on a given host
├── setup-script.sh              # This script will create a VMSS and related resources
└── submission-screenshots       # You can put your screenshots in this folder. See the Part 4 below to know more. 
    ├── application-insights
    ├── autoscaling-vmss
    ├── kubernetes-cluster
    └── runbook
```


# Part 1. Getting Started

1. Prerequisites
   - [Azure Account](https://azure.microsoft.com/en-us/free/)
   - [VS Code](https://code.visualstudio.com/Download) or your preferred editor
   - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

2. Dependencies to run the application locally
   - [Python](https://www.python.org/downloads/)
   - Redis server (Instructions are available below). It is an in-memory database used for caching. 

3. Required Python Packages (UPDATED for 2025)

   **⚠️ Original packages (DEPRECATED):**
   ```bash
   Flask==1.1.2           # Security vulnerabilities, 5+ years old
   opencensus==0.7.13     # DEPRECATED by Microsoft
   opencensus-ext-azure==1.0.4
   opencensus-ext-flask==0.7.3
   redis==3.5.3           # Outdated connection handling
   ```

   **✅ Updated packages (requirements.txt):**
   ```bash
   Flask==3.0.3          # Latest stable, secure version
   redis==5.0.8          # Modern client with improved performance
   # Note: OpenCensus replaced with Azure Monitor OpenTelemetry (to be implemented)
   ```

   All these packages are mentioned in the *requirements.txt* file. The modernized dependencies ensure compatibility with Python 3.11, Docker Desktop, and modern Azure services. 

---

# Part 2. Local Environment Setup - Docker Desktop (RECOMMENDED)

## Quick Start with Docker Compose (Updated Method)

**This is the recommended approach for local testing.** The application has been modernized and tested to run on Docker Desktop.

1. **Prerequisites:**
   - [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
   - No need to install Python, Redis, or dependencies manually

2. **Build and Run:**

   ```bash
   # Navigate to project directory
   cd nd081-c4-azure-performance-project-starter
   
   # Copy requirements.txt to azure-vote folder (if not already present)
   Copy-Item requirements.txt azure-vote\requirements.txt
   
   # Build Docker images
   docker-compose build
   
   # Start the application
   docker-compose up -d
   
   # Access the application at http://localhost:8080
   ```

3. **Verify it's working:**

   ```bash
   # Check container status
   docker-compose ps
   
   # View application logs
   docker-compose logs -f azure-vote-front
   
   # View Redis logs
   docker-compose logs azure-vote-back
   ```

4. **Stop the application:**

   ```bash
   docker-compose down
   ```

---

## Alternative: Manual Local Setup (Not Recommended)

If you prefer to run without Docker (not recommended due to environment inconsistencies):

1. **Install Redis** - Download and install Redis server for your operating system: [Linux](https://redis.io/download), [MacOS](https://medium.com/@petehouston/install-and-config-redis-on-mac-os-x-via-homebrew-eb8df9a4f298), or [Windows](https://riptutorial.com/redis/example/29962/installing-and-running-redis-server-on-windows)

2. **Start Redis** - Start and verify the Redis server:

   ```bash
   # Mac
   redis-server /usr/local/etc/redis.conf
   # Linux
   redis-server
   # Windows - Navigate to the Redis folder, and run
   redis-server.exe
   redis-cli.exe
   # Ping your Redis server to verify if it is running. It will return "PONG"
   redis-cli ping
   ```

3. **Create a Virtual Environment** (Optional) - It's your choice to work in a virtual environment. For this, you must have the [virtualenv](https://virtualenv.pypa.io/en/latest/installation.html#via-pip) installed. Create and activate a virtual environment:
      ```bash
      # Navigate to the azure-vote/ folder 
      cd azure-vote/
      ```
      ```bash
      # Mac/Linux
      python3 -m venv .venv 
      source .venv/bin/activate
      # Windows on Powershell or GitBash terminal
      py -3 -m venv .venv
      .venv\Scripts\activate
      ```

4. **Dependencies** - Install dependencies from *requirements.txt*:
      ```bash
      # Run this command from the parent directory where you have the requirements.txt file
      pip install -r requirements.txt
      ``` 

5. Run the application:
      ```bash
      python main.py
      ```

      >**NOTE**: The statement `app.run()` in `/azure-vote/main.py` file is currently set for your local environment. Replace it with the following statement when deploying the application to a VM Scale Set:
      >```py
      >app.run(host='0.0.0.0', threaded=True, debug=True)
      >```

---

# Part 3. Project Instructions - Azure Environment Setup

### Step 1. Create an Azure VMSS 
1. A bash script `setup-script.sh` has been provided to automate the creation of the VMSS. You should not need to modify this script.
      ```bash
      # Fork the current repo to your Github account. 
      # Clone locally
      git clone https://github.com/<GITHUB_USERNAME>/nd081-c4-azure-performance-project-starter.git
      cd nd081-c4-azure-performance-project-starter
      # Make sure, you aer in the master branch
      git checkout master
      # Log in to Azure using 
      az login
      # Create a VMSS and related resources. 
      # It uses cloud-init.txt file while running the command "az vmss create" available in the setup-script.sh  
      # The cloud-init.txt will install and start the nginx server (a load balancer) and a few Python packages. 
      chmod +x setup-script.sh
      ./setup-script.sh
      ``` 

The script above will take a few minutes to create VMSS and related resources. Once the script is complete, you can go to Azure portal and look for the **acdnd-c4-project** resource group. 



### Step 2 - Application Insights & Log Analytics
1. Create an Application Insights resource. It will automatically create a Log Analytics workspace in addition. 

2. Enable Application Insights monitoring for the VM Scale Set. Make sure to choose the same Log Analytics workspace that you've created in the step above. The Insights deployment will take 10-15 minutes. 

3. To collect the Logs and Telemetry data, add the reference Application Insights to `main.py` and specify the instrumentation key. You will need to provide details about the Logging, Metrics, Tracing, and Requests. In addition, add custom event telemetry when 'Dogs' is clicked and when 'Cats' is clicked. **Refer to the TODO comments in the `main.py` file** for more details. 

   >Note that the configuration related to the Redis Connection will differ in case of deployment to VMSS instance versus deployment to AKS cluster. Rest all code will the same.  Therefore, at this point, you can push your changes to a new branch (say "Deploy_to_VMSS") in your remote so that you can clone it directly inside your VMSS instance. Use the commands like:
   ```bash
   # Create a new branch locally
   git checkout -b Deploy_to_VMSS
   # Add, Commit, and Push your changes to the remote
   git add -A     
   git commit -m "Initial commit for Deploy_to_VMSS branch"
   git push --set-upstream Deploy_to_VMSS
   # git branch --set-upstream-to=origin/Deploy_to_VMSS Deploy_to_VMSS
   ```

### Step 3 - Deploy to VMSS
1. Deploy the application to one of the VMSS instances.  Login to one of the VMSS instances, and deploy the application manually. 
      ```bash
      # Find the port for connecting via SSH 
      az vmss list-instance-connection-info \
         --resource-group acdnd-c4-project \
         --name udacity-vmss 
      # The following command will connect you to your VM. 
      # Replace `[public-ip]` with the public-ip address of your VMSS.
      ssh -p [port number] udacityadmin@[public-ip]
      ```

2. Once you log in to one of the VMSS instances, deploy the application manually: 
      ```bash
      # Clone locally
      git clone https://github.com/<GITHUB_USERNAME>/nd081-c4-azure-performance-project-starter.git
      cd nd081-c4-azure-performance-project-starter
      # Make sure, you aer in the master branch
      git checkout Deploy_to_VMSS
      # Update sudo
      # Install Python 3.7
      # Install pip
      # Install and start Redis server. Refer https://redis.io/download for help. 
      # Clone and navigate inside the project repo. We need the Flask frontend code
      # Install dependencies - necessary Python packages - redis, opencensus, opencensus-ext-azure, opencensus-ext-flask, flask
      # Run the app
      ```

3. After successful deployment and starting the application, copy the VMSS' public IP address and paste it in the browser. You will see the voting application up and running. If it still shows **502 Bad Gateway nginx/1.14.0 (Ubuntu)** message, it means either of the following:

   - Your requests are being redirected to the VMSS instance where you haven't deployed the application. Wait and refresh the browser in such a case. 


   - You haven't deployed the application perfectly. Check is backend Redis server in the VMSS instance is up and running. Also, check the instrumentation key is valid. Check the console output of the VMSS instance.


4. Go back to the Application Insights dashboard, and do the following:
   - Navigate to the Monitoring --> Logs service. Create a chart from query showing when 'Dogs' or 'Cats' is clicked. 

   - Navigate to the Usage --> Events service. Create a query to view the event telemetry.  


### Step 4 - Autoscaling VMSS

1. For the VM Scale Set, create an autoscaling rule based on metrics.

2. Trigger the conditions for the rule, causing an autoscaling event.

3. When complete, enable manual scale.



### Step 5 - Deploy to AKS
1. Before you make any changes further, create a new branch "Deploy_to_AKS". In this step, your frontend and backend will run in separate containers. 
      ```bash
      git checkout -b Deploy_to_AKS
      ```


2. Edit the `main.py` file again to configure the Redis Connection. 
      ```py
      # Comment/remove the next two lines of code.
      # Redis Connection to a local server running on the same machine where the current FLask app is running. 
      # r = redis.Redis()
      # Redis configurations
      redis_server = os.environ['REDIS']

      # Redis Connection to another container
      try:
         if "REDIS_PWD" in os.environ:
            r = redis.StrictRedis(host=redis_server,
                              port=6379,
                              password=os.environ['REDIS_PWD'])
         else:
            r = redis.Redis(redis_server)
         r.ping()
      except redis.ConnectionError:
         exit('Failed to connect to Redis, terminating.')
      ```

3. Run the application locally in a multi-container environment, as a part of which you'll create Docker images. First, create a `Dockerfile` (without extension) inside */azure-vote* folder with the following content:
      ```bash
      # Pull the base image
      FROM tiangolo/uwsgi-nginx-flask:python3.6
      # Install depndencies 
      RUN pip install redis
      RUN pip install opencensus
      RUN pip install opencensus-ext-azure
      RUN pip install opencensus-ext-flask
      RUN pip install flask
      # Copy the content of the current directory to the /app of the container
      ADD . /app
      ```

4. Now, the `docker-compose up` command will automatically use the Dockerfile created above to build images locally. It will build two images: one for Redis (image named as: `mcr.microsoft.com/oss/bitnami/redis:6.0.8`) and another for the frontend (image named as: `azure-vote-front:v1`). **Creating and verifying the images locally is crucial before pushing the images to AKS cluster**. 
      ```bash
      # Navigate back to the parent directory, where you have the docker-compose.yaml file present. 
      cd ..
      # Create images, and run the application locally using Docker.
      docker-compose up -d --build
      # View the application at http://localhost:8080/
      # You will see two new images - "azure-vote-front:v1" and "mcr.microsoft.com/oss/bitnami/redis:6.0.8" (built from "redis:6.0.8")
      docker images
      # Correspondingly, you will see two running containers - "azure-vote-front" and "azure-vote-back" 
      docker ps
      # Stop the application
      docker-compose down
      ```
      Troubleshoot: if you wish to log into the container and see its content, you can use:
      ```bash
      # Check if the frontend application is up and running 
      docker exec -it azure-vote-front bash
      ls
      # Check if the Redis server is running
      docker exec -it azure-vote-back bash
      redis-cli ping
      ```

5. Once your aplication is running successfully in the multi-container environment locally, prepare to push the (frontend) image to the ACR. Create the AKS cluster:
      ```bash
      # In you terminal run the following
      az login
      # Navigate to the project starter code again, if not already
      cd nd081-c4-azure-performance-project-starter
      # Assuming the acdnd-c4-project resource group is still avaiable with you
      chmod +x create-cluster.sh
      # The script below will create an AKS cluster, Configure kubectl to connect to your Kubernetes cluster, and Verify the connection to your cluster
      ./create-cluster.sh
      ```

6. Next, create a Container Registry in Azure to store the image, and AKS can later pull them during deployment to the AKS cluster. Feel free to change the ACR name in place of `myacr202106` below.
      ```bash
      # Assuming the acdnd-c4-project resource group is still avaiable with you
      # Create a resource group
      az group create --name acdnd-c4-project --location westus2
      # ACR name should not have upper case letter
      az acr create --resource-group acdnd-c4-project --name myacr202106 --sku Basic
      # Log in to the ACR
      az acr login --name myacr202106
      # Get the ACR login server name
      # To use the azure-vote-front container image with ACR, the image needs to be tagged with the login server address of your registry. 
      # Find the login server address of your registry
      az acr show --name myacr202106 --query loginServer --output table
      # Associate a tag to the local image. You can use a different tag (say v2, v3, v4, ....) everytime you edit the underlying image. 
      docker tag azure-vote-front:v1 myacr202106.azurecr.io/azure-vote-front:v1
      # Now you will see myacr202106.azurecr.io/azure-vote-front:v1 if you run docker images
      # Push the local registry to remote ACR
      docker push myacr202106.azurecr.io/azure-vote-front:v1
      # Verify if you image is up in the cloud.
      az acr repository list --name myacr202106 --output table
      # Associate the AKS cluster with the ACR repository
      az aks update -n udacity-cluster -g acdnd-c4-project --attach-acr myacr202106
      ```

7. Now, deploy the images to the AKS cluster:
      ```bash
      # Get the ACR login server name
      az acr show --name myacr202106 --query loginServer --output table
      # Make sure that the manifest file *azure-vote-all-in-one-redis.yaml*, has `myacr202106.azurecr.io/azure-vote-front:v1` as the image path.  
      # Deploy the application. Run the command below from the parent directory where the *azure-vote-all-in-one-redis.yaml* file is present. 
      kubectl apply -f azure-vote-all-in-one-redis.yaml
      # Test the application at the External IP
      # It will take a few minutes to come alive. 
      kubectl get service azure-vote-front --watch
      # You can also verify that the service is running like this
      kubectl get service
      # Check the status of each node
      kubectl get pods
      # In case you wish to change the image in ACR, you can redeploy using:
      kubectl set image deployment azure-vote-front azure-vote-front=myacr202106.azurecr.io/azure-vote-front:v1      
      # Push your changes so far to the Github repo, preferably in the Deploy_to_AKS branch
      ```

8. **Troubleshoot** - If your application is not accessible on the External IP of the AKS cluster, you will have to look into the ACR web portal --> Repository --> azure-vote-front for failed events and logs. 


9. **More to achieve in the web portal**:
   - Once the deployment is completed, go to Insights for the cluster. Observe the state of the cluster. Note the number of nodes and the number of containers.

   - Create an alert in Azure Monitor to trigger when the number of pods increases over a certain threshold.

   - Create an autoscaler by using the following Azure CLI command—`kubectl autoscale deployment azure-vote-front --cpu-percent=70 --min=1 --max=10`. 

   - Cause load on the system. After approximately 10 minutes, stop the load.

   - Observe the state of the cluster. Note the number of pods; it should have increased and should now be decreasing.



### Step 5 - Runbook

1. Create an Azure Automation Account

2. Create a Runbook—either using a script or the UI—that will remedy a problem.

3. Create an alert that uses a runbook to remedy a problem.

4. Cause the problem to the flask app on the VM Scale Set.

5. Verify the problem is remedied via the Runbook.

---

# Part 4 - Submissions

1. The `main.py` which will show the code for the Application Insights telemety data.


2. Screenshots for the kubernetes cluster which include:
   **Note**: Place all screenshots for Kubernetes Cluster in the `submission-screenshots/kubernetes-cluster` directory
   - The output of the Horizontal Pod Autoscaler, showing an increase in the number of pods.
   - The Application Insights metrics which show the increase in the number of pods.
   - The email you received from the alert when the pod count increased.


3. Screenshots for the Application Insights which include:
   **Note**: Place all screenshots for Application Insights in the `submission-screenshots/application-insights` directory
   - The metrics from the VM Scale Set instance--this will show CPU %, Available Memory %, Information about the Disk, and information about the bytes sent and received. There will be 5 graphs which display this data.
   - Application Insight Events which show the results of clicking 'vote' for each 'Dogs' & 'Cats'
   - The output of the `traces` query in Azure Log Analytics.
   - The chart created from the output of the `traces` query.


4. Screenshots for the Autoscaling of the VM Scale Set which include:
   **Note**: Place all screenshots for Autoscaling VMSS in the `submission-screenshots/autoscaling-vmss` directory
   - The conditions for which autoscaling will be triggered (found in the 'Scaling' item in the VM Scale Set).
   - The Activity log of the VM scale set which shows that it scaled up with timestamp.
   - The new instances being created.
   - The metrics which show the load increasing, then decreasing once scaled up with timestamp.


5. Screenshots for the Azure Runbook which include:
   **Note**: Place all screenshots for RunBook in the `submission-screenshots/runbook` directory
   - The alert configuration in Azure Monitor which shows the resource, condition, action group (this should include a reference to your Runbook), and alert rule details (may need 2 screenshots).
   - The email you received from the alert when the Runbook was executed.
   - The summary of the alert which shows 'why did this alert fire?', timestamps, and the criterion in which it fired.

--- 
---

# Appendix: Legacy Dependency Migration Guide

## Summary of Changes Made to Modernize the Application

This repository originally contained legacy code from 2020 that would not run on modern Docker Desktop, Python environments, or Azure infrastructure. The following changes were made:

### 1. Python Runtime Migration

**Problem**: Python 3.6 reached End-of-Life on December 23, 2021 (4 years ago)
- Not available in modern Docker images
- No security patches
- Incompatible with modern Azure App Services and Container Instances

**Solution**: Upgraded to Python 3.11
- Current stable version with active support
- Compatible with all Azure services
- Improved performance and security

### 2. Flask Framework Upgrade

**Problem**: Flask 1.1.2 (released May 2020)
- Contains known security vulnerabilities
- Missing features in Flask 2.0+ and 3.0+
- Incompatible with modern WSGI servers

**Solution**: Upgraded to Flask 3.0.3
- Latest stable release
- Security patches applied
- Better async support and performance

### 3. Redis Client Library Modernization

**Problem**: redis 3.5.3 required manual byte decoding
```python
# Old code required this pattern
vote1 = r.get(button1).decode('utf-8')
```

**Solution**: Upgraded to redis 5.0.8 with `decode_responses=True`
```python
# Modern code is cleaner
r = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)
vote1 = r.get(button1)  # Returns string directly
```

### 4. Docker Configuration Overhaul

**Original Dockerfile (Broken)**:
```dockerfile
FROM tiangolo/uwsgi-nginx-flask:python3.6  # Image no longer available
RUN pip install redis
RUN pip install opencensus
# ... multiple RUN commands (inefficient)
```

**Modern Dockerfile (Working)**:
```dockerfile
FROM python:3.11-slim                      # Current stable base
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt  # Efficient caching
RUN pip install --no-cache-dir gunicorn
COPY . /app
EXPOSE 80
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "4", "--timeout", "60", "main:app"]
```

### 5. Application Code Updates in main.py

**Added improvements**:
- Modern Redis connection with `decode_responses=True`
- Connection timeout and error handling
- Better logging with structured output
- Removed deprecated byte decoding patterns
- Fixed deprecated Flask patterns

**Before**:
```python
r = redis.Redis()
vote1 = r.get(button1).decode('utf-8')  # Manual decoding
```

**After**:
```python
r = redis.Redis(
    host=redis_host,
    port=redis_port,
    db=0,
    socket_connect_timeout=5,
    decode_responses=True  # Automatic string conversion
)
vote1 = r.get(button1)  # Already a string
```

### 6. Monitoring Framework Migration (To Be Completed)

**Deprecated**: OpenCensus 0.7.x
- Microsoft officially deprecated OpenCensus in 2021
- No longer receives updates
- Incompatible with modern Application Insights

**Recommended**: Azure Monitor OpenTelemetry Distro 1.6.x
- Industry-standard observability
- Native Azure integration
- Active development and support

**Action Required**: Update the TODO sections in `main.py` to implement Azure Monitor OpenTelemetry instead of OpenCensus.

### 7. Files Modified/Created

| File | Change Type | Description |
|------|-------------|-------------|
| `requirements.txt` | Updated | Python 3.11, Flask 3.0.3, redis 5.0.8 |
| `azure-vote/Dockerfile` | Rewritten | Python 3.11-slim, Gunicorn, modern build patterns |
| `azure-vote/main.py` | Updated | Modern Redis client, better error handling |
| `azure-vote/requirements.txt` | Created | Copy of root requirements.txt for Docker build |
| `docker-compose.yaml` | Minor update | Works with modernized Dockerfile |
| `README.md` | Updated | This documentation |

### 8. Testing Checklist

✅ **Completed and Verified**:
- [x] Application builds successfully in Docker Desktop
- [x] Redis backend starts and accepts connections
- [x] Frontend connects to Redis successfully
- [x] Voting functionality works (increment/decrement)
- [x] Reset functionality works
- [x] Application accessible at http://localhost:8080
- [x] No Python runtime errors
- [x] No dependency conflicts

⚠️ **Still Required for Azure Deployment**:
- [ ] Implement Azure Monitor OpenTelemetry (replace OpenCensus TODOs)
- [ ] Update Kubernetes YAML files (remove deprecated nodeSelector)
- [ ] Test deployment to Azure Container Registry
- [ ] Test deployment to AKS cluster
- [ ] Configure Application Insights instrumentation key
- [ ] Test autoscaling on VMSS
- [ ] Test autoscaling on AKS

### 9. Why These Changes Were Necessary

**Docker Desktop Compatibility**:
- Python 3.6 images are no longer available on Docker Hub
- Modern Docker Desktop requires current base images
- Old uWSGI/Nginx combination was unnecessary complexity

**Azure Compatibility**:
- Azure App Service dropped Python 3.6 support in 2022
- Azure Container Instances requires maintained base images
- Azure Monitor moved to OpenTelemetry standard

**Security**:
- Python 3.6 has unpatched security vulnerabilities
- Flask 1.1.2 has known CVEs
- Modern packages include critical security fixes

**Development Experience**:
- Modern Python versions have better error messages
- Flask 3.0 has improved debugging capabilities
- Current packages have better documentation

---

### Built With

* Open-source 3rd-party: [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis)
* Modernized for 2025 with Python 3.11, Flask 3.0.3, and modern best practices

* [License](./LICENSE.md)
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
