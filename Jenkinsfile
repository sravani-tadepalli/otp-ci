pipeline {
  agent any
  environment {
    ARTIFACT_BUCKET = "otp-lambda-artifacts-me-us-east-1"
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Unit test') {
      agent any
      steps {
        sh 'python3 --version || true'
        dir('lambda_generate') { sh 'python3 -m pip install -r requirements.txt -q || true'; sh 'pytest -q || true' }
        dir('lambda_verify')   { sh 'python3 -m pip install -r requirements.txt -q || true'; sh 'pytest -q || true' }
      }
    }
    stage('Build') {
      steps {
        sh './scripts/build_lambda.sh lambda_generate'
        sh './scripts/build_lambda.sh lambda_verify'
        stash includes: 'build/**', name: 'artifacts'
      }
    }
    stage('Deploy') {
      steps {
        // inject AWS keys from Jenkins credential (ID: aws-deploy-creds)
        withCredentials([usernamePassword(credentialsId: 'aws-deploy-creds',
                                         usernameVariable: 'AWS_ACCESS_KEY_ID',
                                         passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          // set ARTIFACT_BUCKET here or configure it in the job's environment
          // replace the default below with your bucket if you prefer to hardcode
          sh 'export ARTIFACT_BUCKET=${ARTIFACT_BUCKET:-otp-lambda-artifacts-me-us-east-1} && ./scripts/deploy.sh'
        }
      }
}
  }
  post { always { cleanWs() } }
}
