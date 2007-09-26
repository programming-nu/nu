;; test_dictionary.nu
;;  tests for Nu dictionary extensions.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestDictionary is NuTestCase
     
     (imethod (id) testSet is          
          (set d (NSMutableDictionary dictionary))
          (d set: ( one:1
                    "two" 2
                    three:"three"))
          (assert_equal 3 (d count))
          (assert_equal 2 (d valueForKey:"two"))
          (assert_equal "three" (d valueForKey:"three")))
     
     (imethod (id) testCreate is
          (set d (NSMutableDictionary dictionaryWithList:( one: 1 
                                                           "two" 2 
                                                           three: "three")))
          (assert_equal 3 (d count))
          (assert_equal 2 (d valueForKey:"two"))
          (assert_equal "three" (d valueForKey:"three"))))           


