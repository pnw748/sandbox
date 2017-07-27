pipeline
{
    // Desc:
    //  This is an automated build process designed to accomplish as many of the steps
    //  outlined in 
    // PARAMS:
    //  S2_VERSION    NN.NN.NNN.NNNNN (e.g. 12.20.300.03574)
    //  S2_FORK       "main" or
    //                "forks/NN.NN/NNN" where: NN.NN corresponds to first two numbers of S2_VERSION
    //                                         NNN corresponds to the fork revision
    //  RELNOTES_TEXT multiline text provided by user to be inserted into the relnotes.txt
    //  TEST_PIPELINE indicates this is a test of the pipeline vs. a production run
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // v00.01.15
    // Changes:
    // Old History Removed - starting from 00.01.xx as of 07-20-17
    // 01-03:
    //   fixed errors with throw, echo outside of steps, environment/params, subString
    // 04: work around inexplicable sh cmd failure using std bash file test condition:
    //     sh 'if [-e filename] then' results in: " ... [-e: command not found "
    // 05: add param TEST_PIPELINE
    // 06: different artifacts for TEST_PIPELINE
    // 07: fix bug: archiveArtifacts cmd needs full path
    // 08: remove 'Cleanup Test' stage, enable TEST_PIPELINE in 'Cleanup' stage
    // 09: major reorg for parallelization and sparse use of customWorkspace
    // 10: Added another stage - cannot have two parallels in one stage:
    //     "The parallel step can only be used as the only top-level step in a stages step block"
    // 11: Fix unadorned script block.
    // 15: missing "s3" in some "make" cmds!
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // env-vars required to be set up before running:
    //    P4PORT=bn-perforce03:1666
    //    P4USER=srv-s2_automation // or user with valid P4TICKET 
    //    P4PASSWD=P4TICKET
    //
    environment
    {
        //RELEASE_PATH_WIN = 'V:\\release\\s3'
        //RELEASE_PATH_LIN = '/v/release/s3'
        RELEASE_PATH_WIN = 'V:\\release\\sandbox\\s3_test'
        RELEASE_PATH_LIN = '/v/release/sandbox/s3_test'
        CHECK_EXISTENCE  = 'check_exists.txt'
    }

    agent
    {
        node
        {
            // The default execution node for all stages if not specified
            label 'S2-bn-s2-bld-n1'
        }
    }

    stages
    {
        stage('Verification of PARAMS')
        {
            //
            // ${S2_VERSION} should conform to this format: nn.nn.nnn.nnnnn
            // ${S2_FORK} should either be "main" or conform to this format: "forks/nn.nn/nnn"
            // ${RELNOTES_TEXT} should start with "Changes:\n--------\n" etc. as in S3/relnotes.txt
            //
            steps
            {
                //bat  'echo P4USER:%P4USER%'
                echo "Perforce Params for Job:${JOB_NAME}"
                echo "P4PORT     :${P4PORT}"
                echo "P4USER     :${P4USER}"
                echo "S2_FORK    :${S2_FORK}"
                echo "S2_VERSION :{S2_VERSION}"

                script
                {
                    if (! params.S2_VERSION ==~ /[0-9]{2,2}.[0-9]{2,2}.[0-9]{3,3}.[0-9]{5,5}/)
                    {
                        echo 'Invalid entry for S2_VERSION: params.S2_VERSION.'
                        echo 'Must be of the form: "nn.nn.nnn.nnnnn" e.g. "12.20.000.03705".'
                        error "Invalid input parameter S2_VERSION"
                    }
                    if (! params.S2_FORK ==~ /forks\/[0-9]{2,2}.[0-9]{2,2}\/[0-9]{3,3}/ &&
                        ! params.S2_FORK ==~ /main/ )
                    {
                        echo 'Invalid entry for S2_FORK: params.S2_FORK.'
                        echo 'Must be either "main" or "forks/nn.nn/nnn" e.g. forks/12.20/100'
                        error "Invalid input parameter S2_FORK"
                    }
                    if (! params.RELNOTES_TEXT ==~ /^Changes:\s+--------\s+\*/)
                    {
                        echo 'Invalid entry for RELNOTES_TEXT: params.RELNOTES_TEXT.'
                        echo ''
                        echo 'Please conform to the conventions for the Changes section in S3/relnotes.txt.'
                        error "Invalid input parameter RELNOTES_TEXT"
                    }
                }
            }
        }

        stage('Create Perforce Client and Source Tree')
        {
            // NOTE: we are using the 'customWorkspace' directive here simply for
            //       the convenience of automatic prefacing of each step with
            //       "cd ..." to the work area.
            // Also Note that it is not possible to use this universally because
            // it cannot be specified as a node attribute within "steps", it is
            // a property of the "agent" directive when used in this manner below.
            //
            agent
            {
                node
                {
                    // The default execution node for all stages if not specified
                    label 'S2-bn-s2-bld-n1'
                    customWorkspace 'V:\\release\\sandbox\\s3_test'
                    // customWorkspace ${env.RELEASE_PATH_WIN}
                }
            }

            steps
            {
                // make a release dir if not already existing
                // exec a Groovy script to use native filesystem utilities
                script
                {
                    String releaseString = params.S2_VERSION
                    // echo 'Release version:' + releaseString 
                    String releaseBaseDir = releaseString.substring(0,9)

                    // if (fileExists releaseBaseDir) < generates syntax error
                    def baseDirExists = fileExists releaseBaseDir
                    if (baseDirExists)
                    {
                        echo 'Release version base dir exists: ' + releaseBaseDir
                        // check if there is already a release version subdir
                        String releaseVersionDir = releaseString.substring(10,15)

                        // if (fileExists releaseVersionDir) < generates syntax error
                        def versDirExists = fileExists releaseVersionDir
                        if (versDirExists)
                        {
                            echo 'Release version dir exists: ' + releaseVersionDir
                            // at this point we want to fail out
                            // in the future we may prompt and allow overwriting...
                            // but for now we require the dir be removed manually.
                            echo 'Please remove ' + releaseVersionDir + ' and restart pipeline job'
                            // Need to determine best status and error-handling method
                            error "Invalid input parameter S2_VERSION"
                        }
                    }
                    else
                    {
                        echo 'Creating release version base dir.'
                        bat '''
                            mkdir %S2_VERSION:~0,9%
                            '''
                    }
                }
                // change directory to release 'base' dir and get the source tree
                script
                {
                    if (params.TEST_PIPELINE)
                    {
                        // *TEST_PIPELINE*
                        bat '''
                            cd %S2_VERSION:~0,9%
                            echo p4m new_client --lf -n -v @%S2_VERSION% %S2_VERSION:~10,5% %P4PORT% //depot/S2/%S2_FORK%
                            mkdir %S2_VERSION:~10,5%
                            cd %S2_VERSION:~10,5%
                            // Leave a breadcrumb for test/verification
                            echo 'THIS IS A PLACEHOLDER TO ALLOW FOLLOWING TEST STEPS TO VERIFY' > %CHECK_EXISTENCE%
                            '''
                    }
                    else
                    {
                        // *REAL*
                        bat '''
                            cd %S2_VERSION:~0,9%
                            p4m new_client --lf -n -v @%S2_VERSION% %S2_VERSION:~10,5% %P4PORT% //depot/S2/%S2_FORK%
                            '''
                    }
                }
            }
        }
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        stage('Build and Test Stage 1 of 2')
        {
            steps
            {
                parallel (
                    "Build Windows inmlr":
                    {
                        // Step 3 from doc
                        node (label: 'S2-bn-s2-bld-n1')
                        {
                            script
                            {
                                if (params.TEST_PIPELINE)
                                {
                                    // *TEST_PIPELINE*
                                    bat '''
                                        cd /D %RELEASE_PATH_WIN%\\%S2_VERSION:~0,9%\\%S2_VERSION:~10,5%
                                        if exist %CHECK_EXISTENCE% (
                                            echo 'pmake s3 COMPDIR=inmlr' > pmake_inmlr.cmd
                                        ) else (
                                            echo 'Verification step failed.'
                                            exit 1
                                        )
                                        '''
                                }
                                else
                                {
                                    // *REAL*
                                    bat '''
                                        cd /D %RELEASE_PATH_WIN%\\%S2_VERSION:~0,9%\\%S2_VERSION:~10,5%
                                        pmake s3 COMPDIR=inmlr
                                        '''
                                }
                            }
                        }
                    },
                    "Build Linux ilglx":
                    {
                        // Step 6(a) from doc
                        // echo "Build Linux platform  - ${env.RELEASE_PATH_LIN}"
                        node (label: 'S2-bn-s2-bld-l1')
                        {
                            script
                            {
                                if (params.TEST_PIPELINE)
                                {
                                    // *TEST_PIPELINE*
                                    sh  '''
                                        cd $RELEASE_PATH_LIN/${S2_VERSION:0:9}/${S2_VERSION:10:5}
                                        if [![ -e $CHECK_EXISTENCE ]]
                                        then
                                            echo "verification-check file does not exist."
                                            exit 1
                                        fi
                                        echo 'make s3 COMPDIR=ilglx' > make_ilglx.cmd
                                        '''
                                }
                                else
                                {
                                    // *REAL*
                                    sh  '''
                                        cd $RELEASE_PATH_LIN/${S2_VERSION:0:9}/${S2_VERSION:10:5}
                                        make s3 COMPDIR=ilglx
                                        '''
                                }
                            }
                        }
                    }
                )
            }
        }
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        stage('Build and Test Stage 2 of 2')
        {
            steps
            {
                parallel (
                    "Build Linux ilglr":
                    {
                        // Step 6(b) from doc
                        node (label: 'S2-bn-s2-bld-l1')
                        {
                            script
                            {
                                if (params.TEST_PIPELINE)
                                {
                                    // *TEST_PIPELINE*
                                    sh  '''
                                        cd $RELEASE_PATH_LIN/${S2_VERSION:0:9}/${S2_VERSION:10:5}
                                        echo 'make s3 COMPDIR=ilglr' > make_ilglr.cmd
                                        '''
                                }
                                else
                                {
                                    // *REAL*
                                    sh  '''
                                        cd $RELEASE_PATH_LIN/${S2_VERSION:0:9}/${S2_VERSION:10:5}
                                        make s3 COMPDIR=ilglr
                                        '''
                                }
                            }
                        }
                    },
                    "Build Windows inmlx":
                    {
                        // Step 7 from doc
                        node (label: 'S2-bn-s2-bld-n1')
                        {
                            script
                            {
                                if (params.TEST_PIPELINE)
                                {
                                    // *TEST_PIPELINE*
                                    bat '''
                                        cd /D %RELEASE_PATH_WIN%\\%S2_VERSION:~0,9%\\%S2_VERSION:~10,5%
                                        if exist %CHECK_EXISTENCE% (
                                            echo 'pmake s3 COMPDIR=inmlr' > pmake_inmlr.cmd
                                        ) else (
                                            echo 'Verification step failed.'
                                            exit 1
                                        )
                                        '''
                                }
                                else
                                {
                                    // *REAL*
                                    bat '''
                                        cd /D %RELEASE_PATH_WIN%\\%S2_VERSION:~0,9%\\%S2_VERSION:~10,5%
                                        pmake s3 COMPDIR=inmlr
                                        '''
                                }
                            }
                        }
                    },
                    "Test Linux ilglx":
                    {
                        // Step 8 from doc
                        node (label: 'S2-bn-s2-bld-l1')
                        {
                            script
                            {
                                if (params.TEST_PIPELINE)
                                {
                                    // *TEST_PIPELINE*
                                    sh  '''
                                        cd $RELEASE_PATH_LIN/${S2_VERSION:0:9}/${S2_VERSION:10:5}
                                        echo make s3tests COMPDIR=ilglx MEM_LEAKS=1 > make_s3_tests_ilglx.cmd
                                        '''
                                }
                                else
                                {
                                    // *REAL*
                                    sh  '''
                                        cd $RELEASE_PATH_LIN/${S2_VERSION:0:9}/${S2_VERSION:10:5}
                                        make s3tests COMPDIR=ilglx MEM_LEAKS=1
                                        '''
                                }
                            }
                        }
                    }
                )
            }
        }
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        stage('Release Notes')
        {
            // See comments about the 'customWorkspace' directive above
            //
            agent
            {
                node
                {
                    // The default execution node for all stages if not specified
                    label 'S2-bn-s2-bld-n1'
                    customWorkspace 'V:\\release\\sandbox\\s3_test'
                    // customWorkspace ${env.RELEASE_PATH_WIN}
                }
            }
            steps
            {
                script
                {
                    if (params.TEST_PIPELINE)
                    {
                        // *TEST_PIPELINE*
                        bat '''
                            echo Modifying S3/relnotes.txt
                            cd %S2_VERSION:~0,9%\\%S2_VERSION:~10,5%
                            echo p4m edit S3/relnotes.txt 
                            echo 'pmake s3relnotes COMPDIR=inmlr' > pmake_s3relnotes.cmd
                            '''
                    }
                    else
                    {
                        // *REAL*
                        bat '''
                            echo Modifying S3/relnotes.txt
                            cd %S2_VERSION:~0,9%\\%S2_VERSION:~10,5%
                            p4m edit S3/relnotes.txt 
                            pmake s3relnotes COMPDIR=inmlr
                            '''
                    }
                }
            }
        }

        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        stage('Cleanup')
        {
            // See comments about the 'customWorkspace' directive above,
            // but NOTE that the paths below assume that it is being used.
            //
            agent
            {
                node
                {
                    // The default execution node for all stages if not specified
                    label 'S2-bn-s2-bld-n1'
                    customWorkspace 'V:\\release\\sandbox\\s3_test'
                    // customWorkspace ${env.RELEASE_PATH_WIN}
                }
            }
            steps
            {
                script
                {
                    String releaseString = params.S2_VERSION
                    String releaseDir = releaseString.substring(0,9) + "\\" + releaseString.substring(10,15)
                    if (params.TEST_PIPELINE)
                    {
                        // *TEST_PIPELINE*
                        def productsExist = fileExists releaseDir + "\\make_ilglx.cmd"
                        productsExist    |= fileExists releaseDir + "\\make_ilglr.cmd"
                        productsExist    |= fileExists releaseDir + "\\pmake_inmlr.cmd"
                        productsExist    |= fileExists releaseDir + "\\make_s3tests_ilglx.cmd"
                        productsExist    |= fileExists releaseDir + "\\pmake_s3relnotes.cmd"

                        if (productsExist)
                        {
                            echo 'all products made in pipeline test.'
                            archiveArtifacts artifacts: releaseDir + "\\*.cmd", onlyIfSuccessful: true
                            bat '''
                                echo deleting directory: %S2_VERSION:~0,9%\\%S2_VERSION:~10,5%
                                RMDIR /S /Q %S2_VERSION:~0,9%\\%S2_VERSION:~10,5%
                                '''
                        }
                        else
                        {
                            error 'products missing from pipeline test.'
                        }
                    }
                    else
                    {
                        // *REAL*
                        // enable this for now - in order to pass to other pipelines
                        archiveArtifacts artifacts: releaseDir + "\\_s3_release", onlyIfSuccessful: true

                        // The client cannot be deleted until after all the steps
                        // involving the release notes aqnd publishing have been completed.
                        // So far all steps have not been codified in the pipeline,
                        // so we cannot perform the client deletion as a cleanup step yet.
                        //
                        bat '''
                            echo client deletion for %P4CLIENT% DISABLED for now.
                            echo p4m delete_client
                            '''
                    }
                }
            }
        }
    }
    post
    {
        always
        {
            echo 'Print this message regardless of the completion status of the Pipeline run.'
        }

        failure
        {
            echo 'The Pipeline failed.'
            mail to: 'ericsson.broadbent@nuance.com',
                subject: "Failed Pipeline: ${currentBuild.fullDisplayName}-${S2_VERSION}",
                body: "Something is wrong with ${env.BUILD_URL}"
        }

        success
        {
            echo 'The Pipeline succeeded.'
        }
    }
}
