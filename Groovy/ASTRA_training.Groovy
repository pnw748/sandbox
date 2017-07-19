def run_training_1() {
    //do something
    println "Start run training1"

    //Invoke system command to print current path
    //def proc = "pwd".execute()
    //proc.waitForProcessOutput(System.out, System.err)

    def proc = "pwd".execute();
    def outputStream = new StringBuffer()
    proc.waitForProcessOutput(outputStream, System.err)
    println(outputStream .toString())
}
def run_training_2() {
    println "Start run training2" 
}
def run_training_n() {
    println "Start run trainingn" 
}
return this
