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
/usr/bin/p4 clean'''
      }
    }
    stage('Sync Code') {
      steps {
        echo 'Start sync code from Perforce server'
        sh '''export P4USER=jenkins
export P4PORT=10.1.4.60:1666
export P4CLIENT=jenkins_mrec_ws
/usr/bin/p4 sync'''
      }
    }
    stage('Build inhouse Linux 64bit') {
      steps {
        parallel(
          "Build inhouse Linux 64bit": {
            echo 'Start Build ilgli ...'
            dir(path: '/automotive/projects/shanghai_tmp/depot/MREC/main') {
              sh '''pwd
echo $PATH
export PLATFORM=UNIX
make COMPDIR=ilgli'''
            }
            
            
          },
          "Build crosscheck Linux 64bit": {
            echo 'Start build Cross check...'
            dir(path: '/automotive/projects/shanghai_tmp/depot/MREC/main') {
              sh '''pwd
echo $PATH
export PLATFORM=UNIX
make COMPDIR=ilglc'''
            }
            
            
          },
          "Build optimized debug Linux 64bit": {
            echo 'Start build Build crosscheck Linux 64bit'
            dir(path: '/automotive/projects/shanghai_tmp/depot/MREC/main') {
              sh '''pwd
echo $PATH
export PLATFORM=UNIX
make COMPDIR=ilglg'''
            }
            
            
          }
        )
      }
    }
    stage('Test') {
      steps {
        dir(path: '/automotive/projects/shanghai_tmp/depot/MREC/main/test') {
          sh '''pwd
echo $PATH
export PLATFORM=UNIX
make COMPDIR=ilgli all
make COMPDIR=ilglq qnative'''
        }
        
      }
    }
  }
  environment {
    DEPOT_ROOT = '/automotive/projects/shanghai_tmp'
  }
}