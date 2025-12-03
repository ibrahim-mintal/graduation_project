pipeline {
  agent {
    kubernetes {
      namespace 'jenkins-ns'
      yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins-sa
  containers:
  # Kaniko container for building images
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - /busybox/cat
    tty: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "512m"
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  
  # kubectl container for Kubernetes operations
  - name: kubectl
    image: alpine/k8s:1.28.3
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
  # Trivy container for security scanning 
  - name: trivy
    image: aquasec/trivy:latest
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "200m"
  volumes:
  - name: docker-config
    emptyDir: {}
'''
    }
  }

  environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    IMAGE_NAME = "ibrahimmintal/shorten-url"
    IMAGE_TAG = "${BUILD_NUMBER}"
  }

  stages {
    // Checkout source code
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    // Build and push Docker image
    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            # Create Docker config for Kaniko authentication
            echo "{\\"auths\\":{\\"https://index.docker.io/v1/\\":{\\"auth\\":\\"$(echo -n $DOCKERHUB_CREDENTIALS_USR:$DOCKERHUB_CREDENTIALS_PSW | base64)\\"}}}" > /kaniko/.docker/config.json
            
            # Build and push with Kaniko
            /kaniko/executor \
              --dockerfile=Dockerfile \
              --context=dir://${WORKSPACE} \
              --destination=${IMAGE_NAME}:${IMAGE_TAG} \
              --destination=${IMAGE_NAME}:latest \
              --cache=true \
              --cache-ttl=24h
          '''
        }
      }
    }
    // Security scan with Trivy
    stage('Security Scan with Trivy') {
      steps {
        container('trivy') {
          sh """
            echo " Scanning image ${IMAGE_NAME}:${IMAGE_TAG} for vulnerabilities..."
            trivy image --severity HIGH,CRITICAL --exit-code 1 ${IMAGE_NAME}:${IMAGE_TAG} || {
              echo " Vulnerabilities found! Failing the build."
              exit 1
            }
            echo " No critical vulnerabilities found."
          """
        }
      }
    }
    // Deploy to EKS cluster
    stage('Deploy to EKS') {
      steps {
        container('kubectl') {
          sh """
            echo " Deploying to EKS cluster..."
            kubectl set image deployment/app-deployment app-container=${IMAGE_NAME}:${IMAGE_TAG} -n app-ns
            kubectl rollout restart deployment/app-deployment -n app-ns
            kubectl rollout status deployment/app-deployment -n app-ns --timeout=5m
          """
        }
      }
    }

  }

  post {
    success {
      echo " Pipeline completed successfully!"
      echo " Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
    }
    failure {
      echo " Pipeline failed!"
    }
  }
}
