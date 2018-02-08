pipeline {
  agent {
    node {
      label 'master'
    }
    
  }
  stages {
    stage('Sync Code') {
      steps {
        echo 'Start sync code from Perforce server'
      }
    }
  }
  environment {
    DEPOT_ROOT = '/automotive/projects/shanghai_tmp'
  }
}
