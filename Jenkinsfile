pipeline {
  agent {
    node {
      label 'unv-shanghai-fu.nrc1.us.grid.nuance.com'
    }
    
  }
  stages {
    stage('Clean ENV') {
      steps {
        echo 'Start cleanup ...'
        sh '''cd "$DEPOT_ROOT"
export P4USER=jenkins
export P4PORT=10.1.4.60:1666
export P4CLIENT=jenkins_mrec_ws
pwd
#/usr/bin/p4 clean'''
      }
    }
  }
  environment {
    DEPOT_ROOT = '/automotive/projects/shanghai_tmp'
  }
}