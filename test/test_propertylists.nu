;; test_propertylists.nu
;;  tests for Nu property list support.
;;
;;  Copyright (c) 2008 Tim Burks, Radtastical Inc.

(class TestPropertyLists is NuTestCase
     
     (- (id) testSerialization is
        (if (eq (uname) "Darwin")
            (then (set object (array 2 2 3.3 (dict now:(NSDate date)) "five" (array 1 2 3 4 5))))
            ;; GNUstep is not properly serializing/deserializing dates
            (else (set object (array 2 2 3.3 (dict now:((NSDate date) timeIntervalSinceReferenceDate) "five" (array 1 2 3 4 5))))))
        (set plist (object XMLPropertyListRepresentation))
        (set object2 (plist propertyListValue))
        (assert_equal (object description) (object2 description))))
