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
            sh './run_training.sh'
            echo 'type this message if previous shell succeeded'
          } catch (err) {
            echo "Failed: ${err}"
            echo 'print this message if previous sheel failed'
            error "Failed information: ${err}"
          } finally {
            echo 'Printed whether above succeeded or failed.'
          }
        }
      }
    }
  }
  environment {
    DEPOT_ROOT = '/automotive/projects/shanghai_tmp'
  }
}
