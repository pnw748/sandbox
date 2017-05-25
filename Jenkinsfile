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
        sh '''export P4USER=your_name
export P4TICKETS=.../p4tickets
export P4TRUST=.../p4trust
# p4 sync'''
      }
    }
    stage('Build') {
      steps {
        parallel(
          "Build Linux": {
            echo 'Start build Linux platform ...'
            sh 'echo "type your build command here"'
            
          },
          "Build Windowns": {
            echo 'Start build Windows platform ...'
            
          },
          "Mac": {
            catchError() {
              sh '''# type your build command here
echo "xxx"

xffw'''
            }
            
            
          }
        )
      }
    }
  }
  environment {
    PARAMETER = 'Value'
  }
}