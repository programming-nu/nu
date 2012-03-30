;; @file       test.nu
;; @discussion Nu testing framework.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Radtastical Inc.
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
;; &nbsp;&nbsp;(- (id) testPlus is<br/>
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
     
     ;; By overriding this method, we detect each time a class is defined in Nu that inherits from this class.
     (+ (id) inheritedByClass:(id) testClass is
        (unless $testClasses (set $testClasses (NSMutableSet set)))
        ;; we need to check for the existence of testClass because reloading
        ;; a file with a class definition will call this again but with nil
        (if testClass
            ($testClasses addObject:testClass)))
     
     ;; The setup method is called before each test case is executed.
     ;; The default implementation does nothing.
     (- (id) setup is nil)
     
     ;; The teardown method is called after each test case is executed.
     ;; The default implementation does nothing.
     (- (id) teardown is nil)
     
     ;; Loop over all subclasses of NuTestCase and run all test cases defined in each class.
     (+ (id) runAllTests is
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
        (NSLog "All: completed #{$tests} tests/#{$assertions} assertions/#{$failures} failures/#{$errors} errors")
        (puts "")
        (if (or $failures $errors)
            (then (NSLog "FAILURE (#{$failures} failures, #{$errors} errors)"))
            (else (NSLog "SUCCESS (0 failures, 0 errors)")))
        (+ $failures $errors))
     
     ;; Run all the test cases for a particular instance of NuTestCase.
     (- (id) run is
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

(macro assert_equal (reference actual)
     (set __code actual)
     `(progn
            (set @assertions (+ @assertions 1))
            (set __reference ,reference)
            (set __actual ,actual)
            (unless (eq __reference __actual)
                    (puts "failure: #{__code} expected '#{__reference}' got '#{__actual}'")
                    (set @failures (+ @failures 1)))
            nil))

(macro assert_not_equal (reference actual)
     (set __code actual)
     `(progn
            (set @assertions (+ @assertions 1))
            (set __reference ,reference)
            (set __actual ,actual)
            (unless (!= __reference __actual)
                    (puts "failure: #{__code} expected '#{__actual} != '#{__reference}'")
                    (set @failures (+ @failures 1)))
            nil))

(macro assert_greater_than (reference actual)
     (set __code actual)
     `(progn
            (set @assertions (+ @assertions 1))
            (set __reference ,reference)
            (set __actual ,actual)
            (unless (> __actual __reference)
                    (puts "failure: #{__code} expected '#{__actual} > '#{__reference}'")
                    (set @failures (+ @failures 1)))
            nil))

(macro assert_less_than (reference actual)
     (set __code actual)
     `(progn
            (set @assertions (+ @assertions 1))
            (set __reference ,reference)
            (set __actual ,actual)
            (unless (< __actual __reference)
                    (puts "failure: #{__code} expected '#{__actual} < '#{__reference}'")
                    (set @failures (+ @failures 1)))
            nil))

(if (eq (uname) "Darwin")
    (then
         (macro assert_throws (desired *block)
              `(progn
                     (set @assertions (+ @assertions 1))
                     (set __desired ,desired)
                     (set __exception nil)
                     (try
                         (eval ,*block)
                         (catch (exception) (set __exception exception)))
                     (if __exception
                         (then
                              (unless (eq (__exception name) __desired)
                                      (puts "failure: expected exception #{__desired} to be thrown, got #{(__exception name)}")
                                      (set @failures (+ @failures 1))))
                         (else
                              (puts "failure: exception #{__desired} was not thrown")
                              (set @failures (+ @failures 1))))
                     nil)))
    (else ;; unfortunately, we can only throw exceptions with the Darwin runtime
          (macro assert_throws (desired *block) nil)))

(macro assert_in_delta (reference actual delta)
     (set __code actual)
     `(progn
            (set @assertions (+ @assertions 1))
            (set __reference ,reference)
            (set __actual ,actual)
            (set __delta ,delta)
            (set __difference (NuMath abs:(- __reference __actual)))
            (if (> __difference __delta)
                (puts "failure: #{__code} expected #{__reference} got #{__actual} which is outside margin #{__delta}")
                (set @failures (+ @failures 1)))
            nil))

(macro assert_true (actual)
     (set __code actual)
     `(progn
            (set @assertions (+ @assertions 1))
            (set __actual ,actual)
            (unless __actual
                    (puts "failure: #{__code} expected true value, got '#{__actual}'")
                    (set @failures (+ @failures 1)))
            nil))

(macro assert_false (actual)
     (set __code actual)
     `(progn
            (set @assertions (+ @assertions 1))
            (set __actual ,actual)
            (if __actual
                (puts "failure: #{__code} expected false value, got '#{__actual}'")
                (set @failures (+ @failures 1)))
            nil))

