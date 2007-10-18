;; test_system.nu
;;  tests for Nu system-level operators.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestSystem is NuTestCase
     
     (imethod (id) testSystem is
          ('(255 22 0) each: 
           (do (code)          
               (set command <<-END
nush -e '(set exit (NuBridgedFunction functionWithName:"exit" signature:"vi"))' -e '(exit #{code})'END)
               (set result (system command))
               ;; make sure that we get the return code that we wanted.
               (assert_equal code result)))))

