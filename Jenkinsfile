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
    stage('Training') {
      steps {
        echo "xxx"
      }
    }

    stage('Tag label') {
      steps {
        echo 'Start label'
        script {
          def props = readProperties  file:'parameters.conf'
          def Var1= props['PARA_A']
          def Var2= props['PARA_B']
          def Var3= props['TRAIN_LIST']
          echo "Var1=${Var1}"
          echo "Var2=${Var2}"
          echo "Var3=${Var3}"

          def split=Var3.split(",")
          for(item in split){  
              println item 
          }  

          //def labels = ['master', 'master']
          def labels = []
          labels.add("l1")
          labels.add("l2")
          labels.add("l3")

          for (x in labels) {
            def label = x
            echo label
            echo "${label}"
          }

          def branches = [:]
          for (int i = 0; i < 4; i++) {
              def index = i
              branches["branch${i}"] = {
                  //build job: 'P1-3-1-Test1', parameters: [string(name: 'param1', value: "${index}")]
                  echo "${index}"
              }
          }
          parallel branches
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