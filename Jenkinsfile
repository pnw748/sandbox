pipeline {
  agent {
    node {
      label 'unv-shanghai-fu.nrc1.us.grid.nuance.com'
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