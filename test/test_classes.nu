;; test_classes.nu
;;  tests for Nu class manipulations.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestClasses is NuTestCase
     
     (- (id) testMetaVariables is
        (assert_equal TestClasses _class)
        (assert_equal "testMetaVariables" _method))
     
     (- (id) testAutomaticClassCreationFromNu is
        (class NuLittleCatZ is NSObject (- (id) takeOffYourHat is ("Voom!")))
        (set Alphabet "ZYXWVUTSRQPONMLKJIHGFEDCBA")
        (25 times:
            (do (i)
                (set superName "NuLittleCat#{(Alphabet letterAtIndex:i)}")
                (set className "NuLittleCat#{(Alphabet letterAtIndex:(+ i 1))}")
                (eval (list 'class (className symbolValue)
                           'is (superName symbolValue)))))
        (assert_equal "Voom!" ((NuLittleCatA new) takeOffYourHat)))
     
     (- (id) testAutomaticClassCreationFromObjC is ;; not really objc, but the same interface
        (class ObjCLittleCatZ is NSObject (- (id) takeOffYourHat is ("Voom!")))
        (set Alphabet "ZYXWVUTSRQPONMLKJIHGFEDCBA")
        (25 times:
            (do (i)
                (set superName "ObjCLittleCat#{(Alphabet letterAtIndex:i)}")
                (set className "ObjCLittleCat#{(Alphabet letterAtIndex:(+ i 1))}")
                ((NuClass classWithName:superName) createSubclassNamed:className)))
        (assert_equal "Voom!" ((ObjCLittleCatA new) takeOffYourHat)))
     
     (- testAddClassMethod is
        (NSNumber addClassMethod:"three" signature:"@@:" body:(do () (+ 1 1 1)))
        (assert_equal 3 (NSNumber three)))
     
     (- testAddInstanceMethod is
        (NSObject addInstanceMethod:"beep" signature:"@@:" body:(do () ("beep!")))
        (set o ((NSObject alloc) init))
        (assert_equal "beep!" (o beep))))

;; helper
(class NSString
     (- (id) letterAtIndex:(id) index is
        (self substringWithRange:(list index 1))))

(class TestClassMethodMissing is NuTestCase
     (- (id) testCustomSubclassClassMethodMissing is
        (assert_equal "Handling message (hello)" (MySampleClass hello) )
        (assert_equal "Handling message (nu: \"rocks\")" (MySampleClass nu:"rocks") ))
     
     (if (eq (uname) "Darwin")
         (- (id) testNSWorkspaceSingletonRemoval is
            ;; I'm almost positive that all Nubies on Macs will have Xcode installed.
            (assert_not_equal nil (NSWorkspace fullPathForApplication:"Xcode") )
            (assert_equal ((NSWorkspace sharedWorkspace) notificationCenter) (NSWorkspace notificationCenter))
            (assert_equal ((NSWorkspace sharedWorkspace) activeApplication) (NSWorkspace activeApplication)))
         
         (- (id) testNSFileManagerSingletonRemoval is
            (assert_not_equal (NSFileManager currentDirectoryPath) nil))
         
         (- (id) testNonexistentClassMethodsCanFail is
            (assert_throws "NuUnknownMessage" (do () (NSObject shouldFail:2))))
         
         (- (id) testInheritedClassMethodMissing is
            (assert_equal "Handling message (hello)" (YetAnotherClass hello)))
         
         (- (id) testTwoUnknownMessageHandlers is
            (set two (TwoHandle new))
            (assert_equal "Instance-based unknown message: (hello)" (two hello))
            (assert_equal "Class-based unknown message: (goodbye)" (TwoHandle goodbye)))
         
         (- (id) testOverridingClassBasedMethodMissing is
            (assert_equal "Overrode successfully with message (hello)" (Overrider hello)))))

;; helpers for method missing tests

(if (eq (uname) "Darwin")
    (class NSWorkspace
         (+ handleUnknownMessage:message withContext:context is
            ((NSWorkspace sharedWorkspace) sendMessage:message withContext:context))))

(class NSFileManager
     (+ handleUnknownMessage:message withContext:context is
        ((NSFileManager defaultManager) sendMessage:message withContext:context)))

(class MySampleClass is NSObject
     (+ handleUnknownMessage:message withContext:context is
        "Handling message #{message}"))

(class YetAnotherClass is MySampleClass)

(class TwoHandle is NSObject
     (+ handleUnknownMessage:message withContext:context is
        "Class-based unknown message: #{message}")
     
     (- handleUnknownMessage:message withContext:context is
        "Instance-based unknown message: #{message}"))

(class Overrider is MySampleClass
     (+ handleUnknownMessage:message withContext:context is
        "Overrode successfully with message #{message}"))
