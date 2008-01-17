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
          (assert_equal "Voom!" ((ObjCLittleCatA new) takeOffYourHat))))

;; helper
(class NSString
     (- (id) letterAtIndex:(id) index is
          (self substringWithRange:(list index 1))))

(class TestClassMethodMissing is NuTestCase
     
     (- (id) testNSWorkspaceSingletonRemoval is
          (assert_not_equal (NSWorkspace fullPathForApplication:"TextMate") nil)
          (assert_equal ((NSWorkspace sharedWorkspace) notificationCenter) (NSWorkspace notificationCenter))
          (assert_equal ((NSWorkspace sharedWorkspace) activeApplication) (NSWorkspace activeApplication)))
     
     (- (id) testCustomSubclassClassMethodMissing is
          (assert_equal (MySampleClass hello) "Handling message (hello)")
          (assert_equal (MySampleClass nu:"rocks") "Handling message (nu: rocks)"))
     
     (- (id) testNSFileManagerSingletonRemoval is
          (assert_not_equal (NSFileManager currentDirectoryPath) nil))
     
     (- (id) testNonexistentClassMethodsCanFail is
          (assert_throws "NuUnknownMessage" (do () (NSObject shouldFail:2))))
     
     (- (id) testInheritedClassMethodMissing is
          (assert_equal (YetAnotherClass hello) "Handling message (hello)"))
     
     (- (id) testTwoUnknownMessageHandlers is
          (set two (TwoHandle new))
          (assert_equal (two hello) "Instance-based unknown message: (hello)")
          (assert_equal (TwoHandle goodbye) "Class-based unknown message: (goodbye)"))
     
     (- (id) testOverridingClassBasedMethodMissing is
          (assert_equal (Overrider hello) "Overrode successfully with message (hello)")))

;; helpers for method missing tests

(class NSWorkspace
     (+ handleUnknownMessage:message withContext:context is
        ((NSWorkspace sharedWorkspace) sendMessage:message withContext:context)))

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
