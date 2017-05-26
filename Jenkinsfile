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
            
            
          },
          "Build Android": {
            node(label: 'master') {
              echo 'Start  build Android platform'
            }
            
            
          }
        )
      }
    }
    stage('Testing') {
      steps {
        echo 'Start testing ...'
      }
    }
    stage('Release') {
      steps {
        echo 'Start release ...'
      }
    }
    stage('Build Documents') {
      steps {
        dir(path: '.') {
          sh 'echo "Start build document ..."'
        }
        
      }
    }
    stage('Generate release notes') {
      steps {
        sh 'echo "Start generate release notes ..."'
      }
    }
    stage('Build and sync image') {
      steps {
        sh 'echo "Start release image ..."'
      }
    }
    stage('Publish release notes') {
      steps {
        parallel(
          "Publish release notes": {
            echo 'Publish release notes'
            
          },
          "Send email": {
            echo 'send email'
            
          },
          "Close Fogbugz cases": {
            echo 'Close Fogbugz cases'
            
          }
        )
      }
    }
  }
  environment {
    PARAMETER = 'Value'
  }
  post {
    always {
      echo "Print this message regardless of the completion status of the Pipeline run."
      
    }
    
    failure {
      echo 'Print this message if the current Pipeline has a "failed" status'
      emailext(subject: 'Job \'${JOB_NAME}\' (${BUILD_NUMBER}) failed', body: 'Please login in ${JENKINS_URL} first, \n and then go to this url to get more information  ${JENKINS_URL}/blue/organizations/jenkins/${JOB_NAME}/detail/${JOB_NAME}/${BUILD_NUMBER}/pipeline', attachLog: true, to: 'shanghai.fu@nuance.com')
      
    }
    
    success {
      echo 'Print this message if the current Pipeline has a "success" status'
      
    }
    
  }
}
