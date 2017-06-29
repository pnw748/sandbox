pipeline {
  agent {
    node {
      label 'master'
        //def props = readProperties  file:'parameters.conf'
        //def Var1= props['PARA_A']
        //def Var2= props['PARA_B']
        //echo "Var1=${Var1}"
        //echo "Var2=${Var2}"
    }
    
  }

  parameters {
        string(name: 'Greeting', defaultValue: 'Hello', description: 'How should I greet the world?')
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
      }
    }
    stage('Training') {
      steps {
        parallel(
          "Training1": {
            echo 'Start training 1'
            
          },
          "Traing2": {
            echo 'Start training'
            
          },
          "Training 3": {
            echo 'Start training'
            
          }
        )
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