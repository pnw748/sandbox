pipeline {
  // 1. Define the default node for all stages
  // 2. Define the parameters which need user input
  // 3. Define the environment (global) variable which can used in whole Pipeline
  // 4. Verify parameters
  // 5. Use 'error' to failed the pipeline
  // 6. Sync code from Perforce
  // 7. Run build in parallel
  // 8. Restirct build on special node
  // 9. Ignore error to don’t fail Pipeline
  // 10. try ... catch function
  // 11. Fast fail the pipeline when one of pipeline step failed
  // 12. Get parameters from configure files
  // 13. Retry function
  // 14. Define the timeout time
  // 15. Invoke existing job
  // 16. Post action which pending on Pipeline result

  agent {
    node {
      label 'master' // Define the default node for all stages
    }
  }

  // Define the parameters which need user input
  parameters {
    string(name: 'Parameter_1', defaultValue: 'NA', description: 'Please input the parameter')
    string(name: 'Parameter_2', defaultValue: 'NA', description: 'Please input the parameter')
  }
  
  // Define the environment (global) variable which can used in whole Pipeline
  environment {
    Parameter_3 = 'Value'
  }

  stages {
    stage('Print and verify parameters') { 
      steps {
        echo "${params.Parameter_1}"
        echo "${params.Parameter_2}"
        echo "${env.Parameter_3}"
        
        //Verify parameters 
        script{
          if ( params.Parameter_1 == "" ){
            echo 'Please entry the Parameter_1'
            error "Parameter_1 is empty" //Use 'error' to failed the pipeline
          }
          if ( params.Parameter_2 =~ /forks\/[0-9]{2,2}.[0-9]{2,2}.[0-9]{3,3}.[0-9]{5,5}/ || params.Parameter_2 =~ /main/)
          {
            echo "Matched!!!!!"
          }
          else
          {
            echo 'Invalid entry for S2_VERSION: params.S2_VERSION.'
            echo 'Must be of the form: "nn.nn.nnn.nnnnn" e.g. "12.20.000.03705".'
            //error "Invalid input parameter S2_VERSION"
          }
        }
      }
    }

    // Sync code from Perforce
    // The pipeline job is different with freestyle job, the P4 plugin in pipeline job will sync code to workspace of master
    // so we need to use below method to sync code into workspace of Jenkins node
    stage('Sync Code') {
      steps {
        node('master'){ //'master' should replace actual node name
          ws(dir: '.') { // Define the custom workspace to sync code, all codes will store in this directory.
            echo 'Start sync code'
            //p4sync(credential: '0f2b0c8e-06fc-4f6e-afec-5191d03171ce', depotPath: '//depot/...') 
              // '0f2b0c8e-xxxx' is ID of credential
          }
        }
      }
    }

    stage('Build') {
      steps {
        // Run build in parallel (Linux/Android/Windows)
        parallel(
          "Build Linux": {
            echo 'Start build Linux platform ...'
            node(label: 'master') { // Restirct build on special node.
              dir(path: '.') { // // Switch to '.' and then run command, you need to replace it with actual path, such as '/home/shsanghai_fu/depot/demo'
                sh '''
                  echo "Build..."
                  pwd
                  #make all
                '''
              }
              // replace above command to actual command
              
              sleep 10 // sleep
              
              // another method to do build
              sh '''
                echo "Build..."
                #cd /home/shsanghai_fu/depot/demo
                pwd
                #make all
              '''
            }
          },
          "Build Android": {
            node(label: 'master') { // Restirct build plftform on special node.
              echo 'Start  build Android platform'
              // Ignore error to don’t fail Pipeline, add '|| true' to ignore error when command failed, the Android build failed will not failed whole Pipeline.
              sh 'ls xxx || true'
            }
          },
          "Build Windows": {
            node(label: 'master') { // Need to replace master with actual Windows node
              script {
                // try ... catch function
                try {
                  echo "Start to build Windows..."
                  // There is not Windows node, so I have to disable those command
                  //bat '''
                    //mkdir tmp_directory
                    //cd tmp_directory
                  //'''
                } catch (err) {
                  echo "Failed: ${err}"
                  // comment below line, if you want to ignore the error in 'try' section, and you can add more action here
                  error "Failed information: ${err}"
                } finally {
                  echo 'Printed whether above succeeded or failed.'
                }
                echo 'print in script section'
              }
            }
          },
          // Fast fail the pipeline when one of pipeline step failed, Default value of failFast is false.
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
            retry(count: 3) { // Retry function
              echo 'Start testing ...'
              //sh "ls xxxx"
            }
            
          },
          "Regression Test": {
            timeout(time: 30, unit: 'MINUTES') { // Define the timeout time
              sh 'echo "do test"'
            }
          }
        )
      }
    }
    
    stage('Training') {
      steps {
        echo "Start to training"
        script{
          
          // Get parameters from configure files
          def rootDir = pwd()
          def props = readProperties  file:rootDir + "/parameters.conf"
          def Training_lst_str= props['TRAINING_LIST']

          // Convert string to array
          def tmp_array = []
          def training_array=Training_lst_str.split(",")
          for(item in training_array){
              tmp_array.add(item)
          }

          def trainings = [:]
          for(training_name in tmp_array){
            def index = training_name
            trainings[training_name] = {
              node('master') {
                def cmd = props[index]
                sh "echo \"[INFO] Acctual command:\" ${cmd} "
                sh "${cmd}"
                //build job: 'Training_dummy', parameters: [string(name: 'ASTRA_PATH', value: props[index])]
                }
            }
          }
          
          // Fast fail the pipeline when one of pipeline step failed, Default value of failFast is false.
          // If failFast = true, one of training failed, it will terminate other training immediately, or the pipeline will faild until all other training complete.
          trainings.failFast = true
          
          parallel trainings 
        }
      }
    }

    stage('Release') {
      steps {
        echo 'Start release ...'
      }
    }

    stage('Invoke External Groovy') {
      steps {
        echo 'Start invoke external Groovy script ...'
        script{
          // ### The Groovy script only run Jenkins master node ###
          def rootDir = pwd()
          def external = load "${rootDir}/external.Groovy"
          external.verify_parameters(params.Parameter_1, params.Parameter_2)
        }
      }
    }

    stage('Deploy') {
      steps {
        echo "Start to deploy..."
        script{
          def branches = [:]
          for (int i = 0; i < 3; i++) {
            def index = i
            branches["branch${i}"] = {
              // Invoke existing job
              //build job: 'existing_job', parameters: [string(name: 'param1', value: "${index}")]
            }
          }
          parallel branches
        }  
      }
    }

    stage('Post Action') {
      steps {
        echo 'Start run post action ...'
      }
    }
  }

  // Post action which pending on Pipeline result
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
      emailext body: 'body_test', recipientProviders: [[$class: 'RequesterRecipientProvider']], subject: 'subject_test', to: '13882261570@163.com'  
    }
    
  }
}