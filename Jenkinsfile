@Library('shared_library') _
import com.nuance.FileCompiler

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
                //compileFile("puppetboard")

                script{
                    fc = new FileCompiler(this, "testproject")
                    fc.analyze('requirements.txt')
                    fc.analyze('setup.py')

                    //println(fc.verifpara('4000'))
                    def var = fc.verifpara('6666')
                    println var
                }
            }
        }
    } 
}
