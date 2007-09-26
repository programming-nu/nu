;; @file       test.nu
;; @discussion Nu testing framework.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

;; @class NuTestCase
;; @abstract Base class for Nu test cases.  
;; @discussion NuTestCase is an abstract base class for Nu test cases.
;; To create new tests, create a class derived from this class
;; and give your test methods names beginning with "test".
;; As with Ruby's Test::Unit, you can also define methods
;; named "setup" and "teardown" to be run before and after
;; each test method.  
;;
;; Here's an example test:
;;
;; <div style="margin-left:2em"><code>
;; (class MyTestClass is NuTestCase<br/>
;; &nbsp;&nbsp;(imethod (id) testPlus is<br/>
;; &nbsp;&nbsp;&nbsp;&nbsp;(assert_equal 4 (+ 2 2))))
;; </code></div>
;;
;; To run your tests, use the "nutest" standalone program. 
;; The following invocation runs all of the Nu unit tests
;; from a console (Terminal.app):
;;
;; <code>% nutest test/test_*.nu</code>
;; 
(class NuTestCase is NSObject
     (ivar (id) failures (id) assertions)
     
     ;; By overriding this method, we detect each time a class is defined in Nu that inherits from this class.
     (cmethod (id) inheritedByClass:(id) testClass is 
          (unless $testClasses (set $testClasses (NSMutableSet set)))
          ($testClasses addObject:testClass))     
     
     ;; The setup method is called before each test case is executed.  
     ;; The default implementation does nothing.
     (imethod (id) setup is nil)
     
     ;; The teardown method is called after each test case is executed.  
     ;; The default implementation does nothing.
     (imethod (id) teardown is nil)
     
     ;; Loop over all subclasses of NuTestCase and run all test cases defined in each class.
     (cmethod (id) runAllTests is
          ;; class variables would be nice here
          (set $assertions 0)
          (set $failures 0)
          (set $tests 0)
          (if $testClasses
              ((($testClasses allObjects) sort) each: 
               (do (testClass)
                   (((testClass alloc) init) run))))
          
          (puts "")
          (puts "All: completed #{$tests} tests/#{$assertions} assertions/#{$failures} failures")
          (puts "")
          (if $failures 
              (then (puts "FAILURE (#{$failures} failures)")) 
              (else (puts "SUCCESS (0 failures)")))
          $failures)
     
     ;; Run all the test cases for a particular instance of NuTestCase.
     (imethod (id) run is
          (set @failures 0)
          (set @assertions 0)
          (set pattern (regex "^test(.*)$"))
          (set testcases (((self instanceMethods) sort) select: (do (method) ((pattern findInString:(method name))))))
          (puts "")
          (puts "#{((self class) name)}: running")
          (testcases each: 
               (do (test)
                   (set $tests (+ $tests 1))
                   (puts "--- #{(test name)}")
                   (self setup)
                   (set command (list self (((NuSymbolTable sharedSymbolTable) symbolWithString:(test name)))))
                   (eval command)
                   (self teardown)))     
          (set $failures (+ $failures @failures))
          (set $assertions (+ $assertions @assertions))  
          (puts "#{((self class) name)}: completed #{(testcases count)} tests/#{@assertions} assertions/#{@failures} failures")))          

(macro assert_equal
     (set @assertions (+ @assertions 1))
     (set golden (eval (car margs)))
     (set actual (eval (car (cdr margs))))
     (unless (eq golden actual)
             (puts "failure: #{(car (cdr margs))} expected '#{golden}' got '#{actual}'")
             (set @failures (+ @failures 1)))
     nil)

(macro assert_in_delta 
     (set @assertions (+ @assertions 1))
     (set golden (eval (car margs)))
     (set actual (eval (car (cdr (margs)))))
     (set delta (eval (car (cdr (cdr (margs))))))
     (set difference (NuMath abs:(- golden actual)))
     (if (> difference delta)
         (puts "failure: #{(car (cdr margs))} expected #{golden} got #{actual} which is outside margin #{delta}")
         (set @failures (+ @failures 1)))
     nil)



