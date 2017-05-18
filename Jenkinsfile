pipeline {
  agent any
  stages {
    stage('p4m update') {
      steps {
        sh 'p4m update'
      }
    }
    stage('Linux platform build and test') {
      steps {
        parallel(
          "Linux platform build and test": {
            echo 'test'
            
          },
          "Windows platform build and test": {
            echo 'Windows'
            
          },
          "Mac platform build and test": {
            echo 'Mac'
            
          },
          "Android platform build and test": {
            echo 'Android'
            
          }
        )
      }
    }
    stage('Archive output') {
      steps {
        echo 'arhive'
      }
    }
    stage('Sync to Grid') {
      steps {
        echo 'sync code'
      }
    }
    stage('Release') {
      steps {
        echo 'release'
      }
    }
  }
}