;; test_macros.nu
;;  tests for Nu macros.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestMacros is NuTestCase
     
     (- (id) testFactorialFunction is
        (function fact (x)
             (if (== x 0)
                 (then 1)
                 (else (* (fact (- x 1)) x))))
        (assert_equal 24 (fact 4)))
     
     ;; recursive macro test case done wrong.
     ;; because x is not a gensym it keeps getting redefined in the recursive descent
     (- (id) testBrokenFactorialMacro is
        (macro mfact (n)
             `(progn
                    (set x ,n)
                    (if (== x 0)
                        (then 1)
                        (else (* (mfact (- x 1)) x)))))
        (assert_equal 0 (mfact 4)))
     
     ;; recursive macro test case done right.
     ;; names prefixed with the "__" sigil are gensyms.
     (- (id) testFactorialMacro is
        (macro mfact (n)
             `(progn
                    (set __x ,n)
                    (if (== __x 0)
                        (then 1)
                        (else (* (mfact (- __x 1)) __x)))))
        (assert_equal 24 (mfact 4)))
     
     ;; test string interpolation of gensyms
     (- (id) testGensymInterpolation is
        (macro interpolateGensym ()
             (set __x 123)
             (set __y 456)
             "you got #{__x} and #{__y}")
        (assert_equal "you got 123 and 456" (interpolateGensym)))
     
     ;; test some macro implementation details
     (- (id) testMacroImplementation is
        (set s (NuSymbolTable sharedSymbolTable))
        (macro forty () (set __x 22) (set __y (+ __x 18)))
        (set newBody (send forty body:(send forty body) withGensymPrefix:"g999" symbolTable:s))
        (assert_equal "((set g999__x 22) (set g999__y (+ g999__x 18)))" (newBody stringValue)))
     
     ;; test a macro that adds an ivar with a getter and setter
     (- (id) testIvarAccessorMacro is
        (function make-setter-name (oldName)
             (set newName "set")
             (newName appendString:((oldName substringToIndex:1) capitalizedString))
             (newName appendString:((oldName substringFromIndex:1)))
             (newName appendString:":")
             newName)
        
        (macro reader (name)
             `(progn
                    (set __name (',name stringValue))
                    (_class addInstanceVariable:__name
                            signature:"@")
                    (_class addInstanceMethod:__name
                            signature:"@@:"
                            body:(do () (self valueForIvar:__name)))))
        
        (macro writer (name)
             `(progn
                    (set __name (',name stringValue))
                    (_class addInstanceVariable:__name
                            signature:"@")
                    (_class addInstanceMethod:(make-setter-name __name)
                            signature:"v@:@"
                            body:(do (new) (self setValue:new forIvar:__name)))))
        
        (macro accessor (name)
             `(progn
                    (set __name (',name stringValue))
                    (_class addInstanceVariable:__name
                            signature:"@")
                    (_class addInstanceMethod:__name
                            signature:"@@:"
                            body:(do () (self valueForIvar:__name)))
                    (_class addInstanceMethod:(make-setter-name __name)
                            signature:"v@:@"
                            body:(do (new) (self setValue:new forIvar:__name)))))
        
        (class SomeObject is NSObject
             (accessor greeting)
             (- init is
                (super init)
                (set @greeting "Hello, there!")
                self))
        
        (set tester ((SomeObject alloc) init))
        (assert_equal "Hello, there!" (tester greeting))
        (tester setGreeting:"Howdy!")
        (assert_equal "Howdy!" (tester greeting)))
     
     (- (id) testExceptionInMacro is
        # template contains an undefined symbol, watch the exceptions thrown by each macro call
        (set string "<%= (+ 2 x) %>")
        (load "template")
        (assert_throws "NuUndefinedSymbol"
             (macro-1 undefined1 (string) `(eval (NuTemplate codeForString:,string)))
             (undefined1 string))))

