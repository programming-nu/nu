;; test_propertylists.nu
;;  tests for Nu property list support.
;;
;;  Copyright (c) 2008 Tim Burks, Neon Design Technology, Inc.

(class TestPropertyLists is NuTestCase
       
     (- (id) testSerialization is
        (set PLISTFILE "/tmp/TEMPORARY.plist")
        (set object (array 1 2 3.3 (dict now:(NSDate date)) "five" (array 1 2 3 4 5)))
        (object writeToPropertyList:PLISTFILE)
        (set object2 (NSObject readFromPropertyList:PLISTFILE))
        (assert_equal (object description) (object2 description))
        (system (+ "rm " PLISTFILE))))
