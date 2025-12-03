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
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Scan Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            # Install Trivy inside Kaniko container
            apk add --no-cache curl tar gzip
            TRIVY_VERSION=0.43.2
            curl -L https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz | tar xz -C /kaniko/

            # Create Docker config for Kaniko
            echo "{\\"auths\\":{\\"https://index.docker.io/v1/\\":{\\"auth\\":\\"$(echo -n $DOCKERHUB_CREDENTIALS_USR:$DOCKERHUB_CREDENTIALS_PSW | base64)\\"}}}" > /kaniko/.docker/config.json

            # Build image with Kaniko
            /kaniko/executor \
              --dockerfile=Dockerfile \
              --context=dir://${WORKSPACE}/app \
              --destination=${IMAGE_NAME}:${IMAGE_TAG} \
              --cache=true \
              --cache-ttl=24h

            # Scan the image
            /kaniko/trivy image --exit-code 1 ${IMAGE_NAME}:${BUILD_NUMBER} || echo "Vulnerabilities found, but continuing..."

          '''
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \
              --dockerfile=Dockerfile \
              --context=dir://${WORKSPACE}/app \
              --destination=${IMAGE_NAME}:${IMAGE_TAG} \
              --destination=${IMAGE_NAME}:latest
          '''
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        container('kubectl') {
          sh """
            echo "Deploying to EKS cluster..."
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
      echo "Pipeline completed successfully!"
      echo "Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
    }
    failure {
      echo "Pipeline failed!"
    }
  }
}
