;; @file       test.nu
;; @discussion Nu testing framework.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

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
     (ivar (id) failures (id) assertions (id) errors)
     
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
          (set $errors 0)
          (set $assertions 0)
          (set $failures 0)
          (set $tests 0)
          (if $testClasses
              ((($testClasses allObjects) sort) each:
               (do (testClass)
                   (((testClass alloc) init) run))))
          
          (puts "")
          (puts "All: completed #{$tests} tests/#{$assertions} assertions/#{$failures} failures/#{$errors} errors")
          (puts "")
          (if (or $failures $errors)
              (then (puts "FAILURE (#{$failures} failures, #{$errors} errors)"))
              (else (puts "SUCCESS (0 failures, 0 errors)")))
          (+ $failures $errors))
     
     ;; Run all the test cases for a particular instance of NuTestCase.
     (imethod (id) run is
          (set @failures 0)
          (set @errors 0)
          (set @assertions 0)
          (set pattern /^test(.*)$/)
          (set testcases (((self instanceMethods) sort) select: (do (method) ((pattern findInString:(method name))))))
          (puts "")
          (puts "#{((self class) name)}: running")
          (testcases each:
               (do (test)
                   (set $tests (+ $tests 1))
                   (print "--- #{(test name)}")
                   (self setup)
                   (set command (list self (((NuSymbolTable sharedSymbolTable) symbolWithString:(test name)))))
                   (try
                       (eval command)
                       (catch (exception)
                              (print " FAILED: Unhandled #{(exception name)} exception caught in #{(test name)}: #{(exception reason)}")
                              (set @errors (+ @errors 1))))
                   (self teardown)
                   (puts "")))
          (set $errors (+ $errors @errors))
          (set $failures (+ $failures @failures))
          (set $assertions (+ $assertions @assertions))
          (puts "#{((self class) name)}: completed #{(testcases count)} tests/#{@assertions} assertions/#{@failures} failures/#{@errors} errors")))

(macro assert_equal
     (set @assertions (+ @assertions 1))
     (set __reference (eval (car margs)))
     (set __actual (eval (car (cdr margs))))
     (unless (eq __reference __actual)
             (puts "failure: #{(car (cdr margs))} expected '#{__reference}' got '#{__actual}'")
             (set @failures (+ @failures 1)))
     nil)

(macro assert_not_equal
     (set @assertions (+ @assertions 1))
     (set __reference (eval (car margs)))
     (set __actual (eval (car (cdr margs))))
     (unless (!= __reference __actual)
             (puts "failure: #{(car (cdr margs))} expected '#{__actual} != '#{__reference}'")
             (set @failures (+ @failures 1)))
     nil)

(macro assert_greater_than
     (set @assertions (+ @assertions 1))
     (set __reference (eval (car margs)))
     (set __actual (eval (car (cdr margs))))
     (unless (> __actual __reference)
             (puts "failure: #{(car (cdr margs))} expected '#{__actual} > '#{__reference}'")
             (set @failures (+ @failures 1)))
     nil)

(macro assert_less_than
     (set @assertions (+ @assertions 1))
     (set __reference (eval (car margs)))
     (set __actual (eval (car (cdr margs))))
     (unless (< __actual __reference)
             (puts "failure: #{(car (cdr margs))} expected '#{__actual} < '#{__reference}'")
             (set @failures (+ @failures 1)))
     nil)

(macro assert_throws
     (set @assertions (+ @assertions 1))
     (set __desired (eval (car margs)))
     (set __block (cdr margs))
     (set __exception nil)
     (try
         (eval __block)
         (catch (exception) (set __exception exception)))
     (if __exception
         (then
              (unless (eq (__exception name) __desired)
                      (puts "failure: expected exception #{__desired} to be thrown, got #{(__exception name)}")
                      (set @failures (+ @failures 1))))
         (else
              (puts "failure: exception #{__desired} was not thrown")
              (set @failures (+ @failures 1))))
     nil)

(macro assert_in_delta
     (set @assertions (+ @assertions 1))
     (set __reference (eval (car margs)))
     (set __actual (eval (car (cdr (margs)))))
     (set __delta (eval (car (cdr (cdr (margs))))))
     (set __difference (NuMath abs:(- __reference __actual)))
     (if (> __difference __delta)
         (puts "failure: #{(car (cdr margs))} expected #{__reference} got #{__actual} which is outside margin #{__delta}")
         (set @failures (+ @failures 1)))
     nil)

(macro assert_true
     (set @assertions (+ @assertions 1))
     (set __actual (eval (car margs)))
     (unless __actual
             (puts "failure: #{(car margs)} expected true value, got '#{__actual}'")
             (set @failures (+ @failures 1)))
     nil)

(macro assert_false
     (set @assertions (+ @assertions 1))
     (set __actual (eval (car margs)))
     (if __actual
         (puts "failure: #{(car margs)} expected false value, got '#{__actual}'")
         (set @failures (+ @failures 1)))
     nil)

