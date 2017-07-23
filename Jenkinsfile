pipeline {
  agent {
    node {
      label 'ASTRA-unv-jjcaballero'
    }
  }


  parameters {
    string(name: 'Based_Version', defaultValue: 'NA', description: 'Which version (based label) need to pickup to do release?')
    string(name: 'Release_Version', defaultValue: 'NA', description: 'Input the version which you want to release, only for Release branch')
    string(name: 'P4_Stream_Name', defaultValue: 'development', description: 'Should be one of development/mainline/release, default is development')
  }

  stages {
    stage('Pipeline info ') {
      steps {
        echo "${params.Based_Version}"
        echo "${params.Release_Version}"
        echo "${params.P4_Stream_Name}"
      }
    }
    stage('ASTRA-Project-tools checkout') {
      steps {
        echo 'Get ASTRA-Project-tools from Perforce'
        sh '''
	        echo $PWD
          echo 'Activate commonlib virt env'
          source ${COMMONLIB_VIRTENV} > /dev/null
          TOOL="ASTRA-project-tools"
          [ -d $WORKSPACE/$TOOL ] && rm -rf $WORKSPACE/$TOOL
          #pseudotty sudo -u astra p4wrapper clone $TOOL --delete_client -b main -p "${P4_Stream_Name}-debug-pipeline" -o $TOOL
          p4wrapper clone $TOOL --delete_client -b main -p "${P4_Stream_Name}-debug-pipeline" -o $TOOL
        '''
      }
    }
    stage('ASTRA checkout') {
      steps {
        echo 'Get ASTRA code from Perforce'
        sh '''
          echo 'Activate commonlib virt env'
          source ${COMMONLIB_VIRTENV} > /dev/null
          TOOL="ASTRA"
          [ -d $WORKSPACE/$TOOL ] && rm -rf $WORKSPACE/$TOOL
          #pseudotty sudo -u astra p4wrapper clone $TOOL --delete_client -b dev -p "${P4_Stream_Name}-debug-pipeline" -o $TOOLw
          p4wrapper clone $TOOL --delete_client -b main -p "${P4_Stream_Name}-debug-pipeline" -o $TOOL
        '''
      }
    }
    stage('ASTRA Build') {
      steps {
        echo 'Start build ASTRA'
        dir(path: 'ASTRA') {
          sh '''
            export GPU_QUEUE_NAME='gpudev' # build and run tests in gpudev.q
            $WORKSPACE/ASTRA-project-tools/job-runner/build_astra.sh -g
          '''
        }
      }
    }

    stage('ASTRA Tests') {
      steps {
        echo 'Start ASTRA tests'
        dir(path: 'ASTRA') {
          sh '''
            export GPU_QUEUE_NAME='gpudev' # build and run tests in gpudev.q
            export SGE_OPTS=" -q gpudev.q@@HGk10*"  # run at k10 only for due to speed regression
            $WORKSPACE/ASTRA-project-tools/job-runner/run-unit-tests.sh -s -a ./
          '''
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
    COMMONLIB_VIRTENV = '/amr/tools/commonlib/current/bin/activate'
    STREAM = ${params.P4_Stream_Name}
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
