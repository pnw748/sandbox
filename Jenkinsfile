pipeline {
  agent {
    node {
      // Define the default node for all stages
      label 'master'
    }
    
  }
  stages {
    stage('Sync Code') {
      steps {
        // Define the custom workspace to sync code, all codes will store in this directory.
        ws(dir: '.') {
          echo 'Start sync code'
          //p4sync(credential: '0f2b0c8e-06fc-4f6e-afec-5191d03171ce', depotPath: '//depot/...')
        }
        
      }
    }
    stage('Build') {
      steps {
        // Build all platforms in parallel
        parallel(
          "Build Linux": {
            echo 'Start build Linux platform ...'
            node(label: 'master') {
              sh 'echo "Build..."'
              sleep 30
            }
            
            
          },
          "Build Android": {
            node(label: 'master') {
              echo 'Start  build Android platform'
            }
            
            
          },
          "Build Windows": {
            // Restirct build plftform on special node.
            node(label: 'TextProc-bn-lm-nl7.nuance.com') {
              script {
                try {
                  bat 'dir'
                } catch (err) {
                  echo "Failed: ${err}"
                  // comment below line, if you want to ignore the error in 'try' section 
                  error "Failed information: ${err}"
                } finally {
                  echo 'Printed whether above succeeded or failed.'
                }
                echo 'print in script section'
                //dir(path: '/home/shanghai_fu/jks_node/workspace/customer_ws') {
                //  sh 'echo "Start build Windows"'
                //}
              }
              
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
        parallel(
          "Unit Test": {
            echo 'Start testing ...'
            
          },
          "Regression Test": {
            timeout(time: 30, unit: 'MINUTES') {
              sh 'echo "do test"'
            }
            
            
          }
        )
      }
    }
    stage('Release') {
      steps {
        echo 'Start release ...'
      }
    }
    stage('Post Action') {
      steps {
        // Switch this path and then run command
        dir(path: '.') {
          sh 'echo "Start build document ..."'
        }
        
        // re-try below command three times  
        retry(count: 3) {
          echo 'Run this command three times'
        }
        
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
