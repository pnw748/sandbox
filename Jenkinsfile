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
        ws(dir: '/home/shanghai_fu/jks_slave/workspace/customer_ws') {
          p4sync(credential: '0f2b0c8e-06fc-4f6e-afec-5191d03171ce', depotPath: '//depot/...')
        }
        
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
            
            error 'Android build failed'
            
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
        input 'Continue to do Release?'
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
      echo 'Print this message regardless of the completion status of the Pipeline run.'
      
    }
    
    failure {
      echo 'Print this message if the current Pipeline has a "failed" status'
      emailext(subject: 'Job \'${JOB_NAME}\' (${BUILD_NUMBER}) failed', body: '''Please login in ${JENKINS_URL} first, 
 and then go to this url to get more information  ${JENKINS_URL}/blue/organizations/jenkins/${JOB_NAME}/detail/${JOB_NAME}/${BUILD_NUMBER}/pipeline''', attachLog: true, to: 'shanghai.fu@nuance.com')
      
    }
    
    success {
      echo 'Print this message if the current Pipeline has a "success" status'
      
    }
    
  }
}