/* complie with: dtrace -h -s dtrace.d */

/* -*- Mode: C -*- */

provider nu {
    probe list_eval_begin(char*, int);
    probe list_eval_end(char*, int);
};

#pragma D attributes Evolving/Evolving/Common provider nu provider
#pragma D attributes Private/Private/Common provider nu module
#pragma D attributes Private/Private/Common provider nu function
#pragma D attributes Evolving/Evolving/Common provider nu name
#pragma D attributes Evolving/Evolving/Common provider nu args
