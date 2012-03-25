;; test_interface.nu
;;  tests for the Nu public interface.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestInterface is NuTestCase
     
     ;; all of these calls could be made from Objective-C
     ;; using methods that are declared in Nu/Nu.h
     (- (id) testParser is
        ;; create a parser
        (set parser (Nu parser))
        ;; set a variable in the top-level context using KVC
        (parser setValue:2 forKey:"x")
        ;; parse text into an evaluatable object
        (set code (parser parse:"(set x (+ x x))"))
        ;; evaluate the parsed code
        (set result (parser eval:code))
        (assert_equal 4 result)
        ;; parsed code objects can be evaluated any number of times
        (set result (parser eval:code))
        (assert_equal 8 result)
        ;; KVC is broadly interpreted to allow any Nu expression as a key
        (assert_equal 16 (parser valueForKey:"(+ x x)"))
        ;; But for setting, the key must be a symbol name
        (parser setValue:"hello" forKey:"y")
        ;; Symbol values can also be looked up using parse: and eval:
        (assert_equal "hello" (parser eval:(parser parse:"y")))))

