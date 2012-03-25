;; test_system.nu
;;  tests for Nu system-level operators.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(unless (eq (uname) "iOS")

(class TestSystem is NuTestCase
     
     (- (id) testSystem is
        ('(255 22 0) each:
          (do (code)
              (set command <<-END
nush -e '(set exit (NuBridgedFunction functionWithName:"exit" signature:"vi"))' -e '(exit #{code})'END)
              (set result (system command))
              ;; make sure that we get the return code that we wanted.
              (assert_equal code result))))
     
     (- (id) testStringWithShellCommand is
        (set s (NSString stringWithShellCommand:"cat" standardInput:"Hello"))
        (assert_equal "Hello" s)
        (set s (NSString stringWithShellCommand:"echo 'Goodbye'"))
        (assert_equal "Goodbye" s))
     
     (- (id) testDataWithShellCommand is
        (set d (NSData dataWithShellCommand:"cat" standardInput:"Hello"))
        (set s (NSString stringWithData:d encoding:NSUTF8StringEncoding))
        (assert_equal "Hello" s)
        (set d (NSData dataWithShellCommand:"echo 'Goodbye'"))
        (set s (NSString stringWithData:d encoding:NSUTF8StringEncoding))
        (assert_equal "Goodbye\n" s))))

