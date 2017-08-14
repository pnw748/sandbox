#!/usr/bin/env groovy

import java.util.regex.Matcher;
import java.util.regex.Pattern;

def pre_check(String astra_path, String tools_path) {
    //do something
    println "Start run Pre-checking"
    println("Source file1: " + astra_path.toString());
    println("Source file2: " + tools_path.toString());

    // def proc = "pwd".execute();
    // def outputStream = new StringBuffer()
    // proc.waitForProcessOutput(outputStream, System.err)
    // println(outputStream .toString())

    // def cmd = "ls -al " + file.toString()
    // proc = cmd.execute();
    // outputStream = new StringBuffer()
    // proc.waitForProcessOutput(outputStream, System.err)
    // println(outputStream .toString())
}

return this