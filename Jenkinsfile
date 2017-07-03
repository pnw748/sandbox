pipeline {
  agent {
    node {
      label 'master'
    }
    
  }

  parameters {
        string(name: 'Greeting', defaultValue: 'Hello', description: 'How should I greet the world?')
        string(name: 'Based_Version', defaultValue: 'r00.01', description: 'Which version need to pickup to do release?')
  }

  stages {
    stage('Get ASTRA-Project-tools ') {
      steps {
        echo 'Get ASTRA-Project-tools from Perforce'
        echo "${params.Greeting} World!"
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

    stage('Groovy debug') {
      steps {
        echo "Start to run Groovy script"
        script{
          def map = [:]
          def data = "session=234567893egshdjchasd&userId=12345673456&timeOut=1800000"
          //def map = [:]
          //data.findAll(/([^&=]+)=([^&]+)/) { full, name, value ->  map[name] = value }
          def data_elem = data.split("&")
          for(elem in data_elem){
            echo "==== ${elem}"
            def object = elem.split("=")
            echo "======="
            echo object[0]
            echo object[1]
            echo "======="
            //echo "==object[0]==, ==object[1]=="
            map.put(object[0], object[1]) 
          }
          println map
        }
      }
    }

    stage('Training') {
      steps {
        echo "Start to training"
        script{
          def props = readProperties  file:'parameters.conf'
          def training_str= props['TRAINING_LIST']
          echo "training_str=${training_str}"

          def trainings = [:]
          //for (int i = 0; i < 4; i++) {
          //    def index = i
          //    trainings["branch${i}"] = {
          //        echo "${index}"
          //    }
          //}
          def labels = []
          
          def training_array=training_str.split(",")

          for(x in training_array){
              labels.add(x)
          }

          for(y in labels){
            def index = y
            trainings[y] = {
                node('master') {
                  echo "Start training in ${index} ..."
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