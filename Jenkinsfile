
def ASTRA_training
node('ASTRA-unv-jjcaballero'){
    def rootDir = pwd()
    println("root path in groovy load:" + rootDir)
    ASTRA_training = load "${rootDir}/Groovy/ASTRA_training.Groovy"
}


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
          #[ -d $WORKSPACE/$TOOL ] && rm -rf $WORKSPACE/$TOOL
          #pseudotty sudo -u astra p4wrapper clone $TOOL --delete_client -b main -p "${P4_Stream_Name}-BO-pipeline" -o $TOOL
	        #p4wrapper clone $TOOL --delete_client -b main -p "${P4_Stream_Name}-BO-pipeline" -o $TOOL
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
          #[ -d $WORKSPACE/$TOOL ] && rm -rf $WORKSPACE/$TOOL
          #pseudotty sudo -u astra p4wrapper clone $TOOL --delete_client -b dev -p "${P4_Stream_Name}-BO-pipeline" -o $TOOLw
          #p4wrapper clone $TOOL --delete_client -b main -p "${P4_Stream_Name}-BO-pipeline" -o $TOOL
        '''
      }
    }
    stage('ASTRA Build') {
      steps {
        echo 'Start build ASTRA'
        dir(path: 'ASTRA') {
          sh '''
            export GPU_QUEUE_NAME='gpudev' # build and run tests in gpudev.q
            #$WORKSPACE/ASTRA-project-tools/job-runner/build_astra.sh -g
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
            #$WORKSPACE/ASTRA-project-tools/job-runner/run-unit-tests.sh -s -a ./
          '''
        }
      }
    }

    stage('Training') {
      steps {
        echo "Start to training"

	script{
	  def rootDir = pwd();
	  def astra_path = rootDir + "/ASTRA";
	  def tools_path = rootDir + "/ASTRA-project-tools";
	  println("astra path:" + astra_path);
	  println("tools path:" + tools_path);

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
                node('ASTRA-unv-jjcaballero') {
		          echo "# Training: " + props[index]
              build job: 'training_demo', parameters: [string(name: 'TRAINING_NAME', value: props[index])]
		          //ASTRA_training.run_training(astra_path, tools_path, props[index]);
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
