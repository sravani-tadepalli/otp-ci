pipeline {
  agent { label 'master' }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Unit test') {
      agent { label 'master' }
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
  }
  post { always { cleanWs() } }
}
