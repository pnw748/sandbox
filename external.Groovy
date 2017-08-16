#!/usr/bin/env groovy

import java.util.regex.Matcher;
import java.util.regex.Pattern;

def verify_parameters (String param1, String param2) {
    //do something
    println "Start verify parameters"
    println("Start verify:" + param1.toString());
    println("Start verify: " + param2.toString());

    String pattern = "[0-9]{2,2}.[0-9]{2,2}.[0-9]{3,3}.[0-9]{5,5}";

    // Create a Pattern object
    Pattern r = Pattern.compile(pattern);

    // Now create matcher object.
    Matcher m = r.matcher(param2);
    if (m.find( )) {
        println("Matched")
    } else {
        println("Unmatched")
    }
}

def load_para () {
    println "Start load parameters"
    //return "x\ny\nz"
    return "abc"
}

return this