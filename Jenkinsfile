pipeline {
  agent {
    node {
      label 'master'
    }
    
  }

  parameters {
        string(name: 'Based_Version', defaultValue: 'NA', description: 'Which version (based label) need to pickup to do release?')
        string(name: 'Release_Version', defaultValue: 'NA', description: 'Input the version which you want to release, only for Release branch')
        string(name: 'P4_Stream_Name', defaultValue: 'development', description: 'Should be one of development/mainline/release, default is development')
  }

  stages {
    stage('Print Version ') {
      steps {
        echo "${params.Based_Version}"
        echo "${params.Release_Version}"
        echo "${params.P4_Stream_Name}"
      }
    }
    stage('Get ASTRA-Project-tools ') {
      steps {
        echo 'Get ASTRA-Project-tools from Perforce'
      }
    }
    stage('Sync ASTRA code') {
      steps {
        echo 'Get ASTRA code from Perforce'
      }
    }
    stage('ASTRA Build') {
      steps {
        echo 'Start build ASTRA'
        sh "lsxx || true"
      }
    }

    stage('Training') {
      steps {
        echo "Start to training"
        script{
          def trainings = [:]
          def Training_cmd_map = [:]
          def props = readProperties  file:"parameters-${params.P4_Stream_Name}.conf"
          def Training_lst_str= props['TRAINING_LIST']
          def Training_cmd_str= props['TRAINING_CMD']
          
          def training_elem = Training_cmd_str.split(",")
          for(elem in training_elem)
          {
            def object = elem.split("/")
            Training_cmd_map.put(object[0], object[1])
          }
          
          def labels = []
          def training_array=Training_lst_str.split(",")
          for(x in training_array){
              labels.add(x)
          }

          for(y in labels){
            def index = y
            trainings[y] = {
                node('master') {
                  echo "Build Command: " + Training_cmd_map.get(index)
                  echo "Build Command: " + props[index]
                }
              }
          }
          parallel trainings
        }
      }
    }

    stage('Tag label') {
      steps {
        echo 'Start label'
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