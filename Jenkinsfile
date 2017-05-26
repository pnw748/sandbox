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
            node(label: 'master') {
              sh 'echo "Build..."'
            }
            
            
          },
          "Build Windowns": {
            echo 'Start build Windows platform ...'
            node(label: 'master') {
              sh 'echo "Build ..."'
            }
            
            
          },
          "build Mac": {
            echo 'Start build Mac platform ...'
            node(label: 'master') {
              sh 'echo "Build ..."'
            }
            
            
          }
        )
      }
    }
    stage('Testing') {
      steps {
        echo 'Start testing ...'
        mail(subject: 'Email test Subject', body: 'Email test Body $PARAMETER', to: 'shanghai_fu@nuance.com')
      }
    }
  }
  environment {
    PARAMETER = 'Value'
  }
  post {
    always {
      echo 'I will always say Hello again! ${params.PARAMETER}'
      echo "== ${params.PARAMETER} =="
    }
    failure {
      echo 'Current CI failed! ${params.PARAMETER}'
    }
    success {
      echo 'Current CI is successfule! ${params.PARAMETER}'
    }
    
  }
}
