;; test_classes.nu
;;  tests for Nu class manipulations.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestClasses is NuTestCase
     
     (imethod (id) testAutomaticClassCreationFromNu is
          (class NuLittleCatZ is NSObject (imethod (id) takeOffYourHat is ("Voom!")))        
          (set Alphabet "ZYXWVUTSRQPONMLKJIHGFEDCBA")
          (25 times: 
              (do (i)        
                  (set superName "NuLittleCat#{(Alphabet letterAtIndex:i)}")        
                  (set className "NuLittleCat#{(Alphabet letterAtIndex:(+ i 1))}")
                  (puts "#{className} is #{superName}")
                  (eval (list 'class (className symbolValue) 
                             'is (superName symbolValue)))))                            
          (assert_equal "Voom!" ((NuLittleCatA new) takeOffYourHat)))
     
     (imethod (id) testAutomaticClassCreationFromObjC is ;; not really objc, but the same interface
          (class ObjCLittleCatZ is NSObject (imethod (id) takeOffYourHat is ("Voom!")))        
          (set Alphabet "ZYXWVUTSRQPONMLKJIHGFEDCBA")
          (25 times: 
              (do (i)        
                  (set superName "ObjCLittleCat#{(Alphabet letterAtIndex:i)}")        
                  (set className "ObjCLittleCat#{(Alphabet letterAtIndex:(+ i 1))}")
                  (puts "#{className} is #{superName}")
                  ((NuClass classWithName:superName) createSubclassNamed:className)))          
          (assert_equal "Voom!" ((ObjCLittleCatA new) takeOffYourHat))))

;; helper
(class NSString 
     (imethod (id) letterAtIndex:(id) index is
          (self substringWithRange:(list index 1))))
