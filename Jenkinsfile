@Library('shared_library') _

pipeline {
    agent any
    stages {
        //Pipeline script
        stage('Start') { 
            steps {
                //git url: 'https://github.com/voxpupuli/puppetboard'
                echo "Start..."
            }   
        }
        
        stage('Compile') { 
            steps {
                sh(libraryResource('com/nuance/python.sh'))
                common()
                common_with_para("shanghai")
                common_import("test")
                //evenOrOdd(currentBuild.getNumber())
                compileFile("puppetboard")
            }
        }
    } 
}
