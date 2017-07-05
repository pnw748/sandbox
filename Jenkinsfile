pipeline {
  agent {
    node {
      label 'master'
    }
    
  }
  stages {
    stage('Training') {
      steps {
        sh './run_training.sh'
      }
    }
  }
  environment {
    DEPOT_ROOT = '/automotive/projects/shanghai_tmp'
  }
}