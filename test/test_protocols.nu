;; test_protocols.nu
;;  tests for Nu protocol support.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(if (eq (uname) "Darwin")
    (set version (NSString stringWithShellCommand:"uname -r"))
    (set v (((version componentsSeparatedByString:".") 0) intValue))
    (if (< v 10) ;; We can't do this in Snow Leopard
        
        (class TestProtocols is NuTestCase
             
             (- (id) testSimple is
                ;; first define a class with two methods
                (class Foo is NSObject
                     (- hello is "hello")
                     (- goodbye is "goodbye"))
                ;; make sure that both methods work
                (set foo ((Foo alloc) init))
                (assert_equal "hello" (foo hello))
                (assert_equal "goodbye" (foo goodbye))
                ;; now declare a protocol that includes only one of them
                (protocol DontSayGoodbye
                     (- (id) hello))
                (assert_equal 1 ((DontSayGoodbye methodDescriptions) count))
                ;; give the instance and protocol to a protocol checker
                (set bar ((NSProtocolChecker alloc) initWithTarget:foo protocol:DontSayGoodbye))
                ;; try the two methods; only the one in the protocol should be allowed
                (assert_equal "hello" (bar hello))
                (assert_throws "NuUnknownMessage" (bar goodbye))))))
