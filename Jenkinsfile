pipeline {
  agent {
    node {
      label 'master'
    }
    
  }
  stages {
    stage('Training') {
      steps {
        script {
          try {
            sh 'pwd'
            echo '[Success] Print this message if previous shell succeeded'
          } catch (err) {
            echo "Failed: ${err}"
            echo '[FAILED] print this message if previous sheel failed'
            error "Failed information: ${err}"
          } finally {
            echo 'Printed whether above succeeded or failed.'
          }
        }
        
      }
    }
    stage('release') {
      steps {
        echo 'start release'
      }
    }
  }
  environment {
    DEPOT_ROOT = '/automotive/projects/shanghai_tmp'
  }
}
