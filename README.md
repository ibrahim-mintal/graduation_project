# URL Shortener - DEPI Graduation Project

A Laravel-based URL shortener application deployed on AWS EKS with automated CI/CD using Jenkins and Kaniko.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS EKS Cluster                     │
│                                                             │
│  ┌──────────────────────┐      ┌──────────────────────┐   │
│  │   jenkins-ns         │      │      app-ns          │   │
│  │                      │      │                      │   │
│  │  ┌────────────────┐  │      │  ┌────────────────┐  │   │
│  │  │ Jenkins        │  │      │  │ URL Shortener  │  │   │
│  │  │ (CI/CD)        │──┼──────┼─▶│ Application    │  │   │
│  │  └────────────────┘  │      │  └────────────────┘  │   │
│  │                      │      │                      │   │
│  └──────────────────────┘      └──────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- kubectl installed
- Terraform v1.0+
- Docker Hub account
- Git

## 🚀 Deployment Guide

### Step 1: Infrastructure Setup with Terraform

Deploy the EKS cluster and supporting infrastructure:

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

**What gets created:**
- VPC with public subnets across 2 availability zones
- EKS cluster with control plane
- Two node groups (jenkins-ng and app-ng)
- Security groups for EKS, nodes, and load balancers
- IAM roles and policies
- EBS CSI driver for persistent storage

### Step 2: Configure kubectl

```bash
# Update kubeconfig to connect to the EKS cluster
aws eks update-kubeconfig --region us-east-1 --name depi-graduation
```

### Step 3: Deploy Namespaces

```bash
cd ../kubernetes

# Create namespaces
kubectl apply -f namespaces/
```

### Step 4: Deploy Jenkins

```bash
cd jenkins

# Deploy in order:
kubectl apply -f storageclass-ebs.yaml
kubectl apply -f jenkins-pvc.yaml
kubectl apply -f jenkins-sa.yaml
kubectl apply -f jenkins-role-app-deployment.yaml
kubectl apply -f jenkins-rolebinding-app-deployment.yaml
kubectl apply -f jenkins-role-pod-management.yaml
kubectl apply -f jenkins-rolebinding-pod-management.yaml
kubectl apply -f jenkins-deployment.yaml
kubectl apply -f jenkins-service.yaml
```

**Wait for Jenkins to be ready:**
```bash
kubectl rollout status deployment/jenkins-deployment -n jenkins-ns
```

### Step 5: Access Jenkins

Get the LoadBalancer URL:
```bash
kubectl get svc jenkins-service -n jenkins-ns
```

Access Jenkins at: `http://<EXTERNAL-IP>:8080`

**Get initial admin password:**
```bash
kubectl exec -n jenkins-ns <jenkins-pod-name> -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### Step 6: Configure Jenkins

1. **Install Required Plugins:**
   - Kubernetes plugin
   - Pipeline plugin

2. **Add DockerHub Credentials:**
   - Go to: Manage Jenkins → Manage Credentials
   - Add credentials with ID: `dockerhub-credentials`
   - Username: Your DockerHub username
   - Password: Your DockerHub token

3. **Configure Kubernetes Cloud:**
   - Go to: Manage Jenkins → Manage Nodes and Clouds → Configure Clouds
   - Add Kubernetes cloud:
     - **Kubernetes URL**: `https://kubernetes.default.svc.cluster.local`
     - **Kubernetes Namespace**: `jenkins-ns`
     - **Jenkins URL**: `http://jenkins-service.jenkins-ns.svc.cluster.local:8080`
     - **Jenkins tunnel**: `jenkins-service.jenkins-ns.svc.cluster.local:50000`
   - Test connection (should show "Connected to Kubernetes...")

### Step 7: Create Jenkins Pipeline

1. **Create New Pipeline Job:**
   - New Item → Pipeline
   - Name: `shortner-app`

2. **Configure Pipeline:**
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/Mohamedfathy90/URL-Shortner-DEPI.git`
   - Branch: `main`
   - Script Path: `Jenkinsfile-kaniko`

3. **Save and Build**

### Step 8: Deploy Application (Manual - First Time)

```bash
cd ../app

# Deploy application
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml

# Wait for deployment
kubectl rollout status deployment/app-deployment -n app-ns
```

**Get application URL:**
```bash
kubectl get svc myapp-service -n app-ns
```

Access your application at: `http://<EXTERNAL-IP>`

## 🔄 CI/CD Pipeline

The Jenkins pipeline automatically:

1. **Checkout** - Pulls code from GitHub
2. **Build & Push** - Builds Docker image using Kaniko and pushes to DockerHub
3. **Deploy** - Updates the deployment in EKS with the new image

### Pipeline Stages

```groovy
Checkout → Build & Push (Kaniko) → Deploy to EKS
```

## 📁 Project Structure

```
.
├── terraform/                 # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/              # VPC module
│   │   ├── security-groups/  # Security groups module
│   │   ├── iam/              # IAM roles module
│   │   ├── eks/              # EKS cluster module
│   │   └── ebs-csi/          # EBS CSI driver module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
│
├── kubernetes/               # Kubernetes manifests
│   ├── namespaces/
│   │   ├── app-namespace.yaml
│   │   └── jenkins-namespace.yaml
│   ├── jenkins/
│   │   ├── storageclass-ebs.yaml
│   │   ├── jenkins-pvc.yaml
│   │   ├── jenkins-sa.yaml
│   │   ├── jenkins-role-*.yaml
│   │   ├── jenkins-rolebinding-*.yaml
│   │   ├── jenkins-deployment.yaml
│   │   └── jenkins-service.yaml
│   └── app/
│       ├── app-deployment.yaml
│       └── app-service.yaml
│
└── Jenkinsfile-kaniko        # CI/CD pipeline definition
```

## 🔐 Security Features

- **No Privileged Containers**: Uses Kaniko instead of Docker-in-Docker
- **RBAC**: Least privilege access with dedicated service accounts
- **Namespace Isolation**: Jenkins and app run in separate namespaces
- **IAM Roles**: Proper AWS IAM roles for EKS and EBS CSI
- **Security Groups**: Network isolation at VPC level

## 🛠️ Technologies Used

- **Infrastructure**: Terraform, AWS EKS, VPC, EBS
- **Container Orchestration**: Kubernetes
- **CI/CD**: Jenkins with Kubernetes plugin
- **Container Build**: Kaniko (daemon-less)
- **Container Registry**: Docker Hub

## 📊 Resource Specifications

### Jenkins Pod
- Memory: 1-2Gi
- CPU: 0.5-2 cores
- Storage: 10Gi EBS volume

### Application Pod
- Replicas: 1
- Container Port: 80
- Service Type: LoadBalancer

### Node Groups
- **jenkins-ng**: t3.small instances
- **app-ng**: t3.small instances

## 🔍 Monitoring & Troubleshooting

### Check Pod Status
```bash
# Jenkins pods
kubectl get pods -n jenkins-ns

# Application pods
kubectl get pods -n app-ns
```

### View Logs
```bash
# Jenkins logs
kubectl logs -n jenkins-ns <jenkins-pod-name>

# Application logs
kubectl logs -n app-ns <app-pod-name>
```

### Check Services
```bash
kubectl get svc -n jenkins-ns
kubectl get svc -n app-ns
```

### Describe Resources
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl describe deployment <deployment-name> -n <namespace>
```

## 🧹 Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources
kubectl delete -f kubernetes/app/
kubectl delete -f kubernetes/jenkins/
kubectl delete -f kubernetes/namespaces/

# Destroy infrastructure
cd terraform
terraform destroy
```








