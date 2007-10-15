;; test_strings.nu
;;  tests for Nu string literals.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestStrings is NuTestCase
     
     (imethod (id) testEscapedStrings is
          (assert_equal 10 ("\n" characterAtIndex:0))
          (assert_equal 13 ("\r" characterAtIndex:0))
          (assert_equal 12 ("\f" characterAtIndex:0))
          (assert_equal 8  ("\b" characterAtIndex:0))
          (assert_equal 7  ("\a" characterAtIndex:0))
          (assert_equal 27 ("\e" characterAtIndex:0))
          (assert_equal 32 ("\s" characterAtIndex:0))
          (assert_equal 34 ("\"" characterAtIndex:0))
          (assert_equal 92 ("\\" characterAtIndex:0)))
     
     (imethod (id) testOctalEscapedStrings is 
          (assert_equal 0 ("\000" characterAtIndex:0))
          (assert_equal 1 ("\001" characterAtIndex:0))
          (assert_equal 255 ("\377" characterAtIndex:0)))
     
     (imethod (id) testHexEscapedStrings is
          (assert_equal 0 ("\x00" characterAtIndex:0))
          (assert_equal 1 ("\x01" characterAtIndex:0))
          (assert_equal 255 ("\xfF" characterAtIndex:0)))
     
     (imethod (id) testUnicodeEscapedStrings is
          (assert_equal 0 ("\u0000" characterAtIndex:0))
          (assert_equal 1 ("\u0001" characterAtIndex:0))
          (assert_equal 255 ("\u00ff" characterAtIndex:0))
          (assert_equal 65535 ("\uFfFf" characterAtIndex:0))))

