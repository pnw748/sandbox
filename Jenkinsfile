pipeline {
  agent {
    node {
      label 'ASTRA-unv-astra'
    }
    
  }
  stages {
    stage('Print Version ') {
      steps {
        echo "${Based_Version}"
        echo "${Release_Version}"
        echo "${params.P4_Stream_Name}"
        sh '''
          echo "=======================1"
          echo "${P4_Stream_Name}"
          echo "=======================2"
          echo $P4_Stream_Name
          echo "=======================3"
          #echo ${env.P4_Stream_Name}
          echo "=======================4"
        '''
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
        //ws(dir: '/ceph/archive/groups/dragon_other/data/app-dragon-jenkins/demo_for_astra') {
        //  checkout([$class: 'PerforceScm', credential: '930db830-524a-44b6-aeda-575ec6115963', populate: [$class: 'AutoCleanImpl', delete: true, modtime: false, parallel: [enable: false, minbytes: '1024', minfiles: '1', path: '/usr/local/bin/p4', threads: '4'], pin: '', quiet: true, replace: true], workspace: [$class: 'ManualWorkspaceImpl', charset: 'none', name: 'jenkins-${NODE_NAME}-${JOB_NAME}', pinHost: false, spec: [allwrite: false, backup: false, clobber: false, compress: false, line: 'LOCAL', locked: false, modtime: false, rmdir: false, serverID: '', streamName: '', type: 'WRITABLE', view: '//depot/... //jenkins-${NODE_NAME}-${JOB_NAME}/depot/...']]])
        //}

      }
    }
    stage('ASTRA Build') {
      steps {
        echo 'update print message'
        sh 'lsxx || true'
        script {
          def rootDir = pwd()
          echo "Current location1: " + rootDir
          echo "Current location2: ${rootDir}"
          def ASTRA_training = load "${rootDir}/Groovy/ASTRA_training.Groovy"
          ASTRA_training.run_training_1()
          //ASTRA_training.run_training_3()

          
        }
      }
    }
    stage('Training') {
      steps {
        echo 'Start to training'
        script {
          def trainings = [:]
          def props = readProperties  file:"parameters-${params.P4_Stream_Name}.conf"
          def Training_lst_str= props['TRAINING_LIST']

          def labels = []
          def training_array=Training_lst_str.split(",")
          for(x in training_array){
            labels.add(x)
          }
          
          for(y in labels){
            def index = y
            trainings[y] = {
              node('ASTRA-unv-astra') {
                
                def cmd = props[index]
                echo "Build Command1: " + props[index]
                sh '''
                  ${cmd}
                  pwd
                  echo "=================="
                  '''
                //sh "cmd=${cmd}; " + 'echo "from shell cmd=$cmd"'
                //sh '''
                //  cmd=${cmd};
                  //echo "from shell cmd=$cmd"
                //  '''
                //sh "'echo \"from shell cmd=${cmd}\"'"
                //sh "'echo \"==== ${cmd} ===\"'"

                //sh '''
                //  'echo \"==== ${cmd} ===\"'
                //'''
                def proc = "pwd".execute();
                def outputStream = new StringBuffer()
                proc.waitForProcessOutput(outputStream, System.err)
                println(outputStream .toString())
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
    stage('post action') {
      steps {
        sh 'date'
      }
    }
  }
  environment {
    PARAMETER = 'Valuexxxxxxxxxxxxx'
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
  parameters {
    string(name: 'Based_Version', defaultValue: 'NA', description: 'Which version (based label) need to pickup to do release?')
    string(name: 'Release_Version', defaultValue: 'NA', description: 'Input the version which you want to release, only for Release branch')
    string(name: 'P4_Stream_Name', defaultValue: 'development', description: 'Should be one of development/mainline/release, default is development')
  }
}