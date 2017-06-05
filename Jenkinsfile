pipeline {
  agent {
    node {
      // Define the default node for all stages
      label 'unv-shanghai-fu.nrc1.us.grid.nuance.com' 
    }
    
  }
  stages {
    stage('Sync Code') {
      steps {
        echo 'Start sync code from Perforce server'
        // Defin the custom workspace to sync code, all codes will store in this directory.
        ws(dir: '/home/shanghai_fu/jks_slave/workspace/customer_ws') {
          p4sync(credential: '0f2b0c8e-06fc-4f6e-afec-5191d03171ce', depotPath: '//depot/...')
        }
      }
    }
    stage('Build') {
      steps {
        // Build all platforms in parallel
        parallel(
          "Build Linux": {
            echo 'Start build Linux platform ...'
            // Restirct build Linux plftform on special node.
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
            
            
          },
          // Add this 'failFast' property to enable fail fast, for example: 
          // if this value is 'true', any one of platform failed will terminate other platform build.
          // if this value is 'false' (or not set this property), the pipeline will faild until all other platforms completed.
          failFast: true
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
        // Switch this path and then run command
        dir(path: '/home/shanghai_fu/jks_slave/workspace/customer_ws') {
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
  
  // Define post actions after Pipeline completed regardless it's failed or success.
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
