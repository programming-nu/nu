;; test_regex.nu
;;  tests for Nu regular expression support.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestRegex is NuTestCase
     
     (imethod (id) testRegex is
          (set r (regex "a(.*)z"))
          (set match (r findInString:"abcdefghijklmnopqrstuvwxyz"))
          (assert_equal 24 ((match groupAtIndex:1) length)))
     
     (imethod (id) testScrape is
          (set s (NSString stringWithContentsOfFile:"test/test.html" encoding:NSUTF8StringEncoding error:nil))
          (set r (regex <<-END
<a href="/search([^\"]*)"END))
          (set matches (r findAllInString:s))
          (assert_equal 10 (matches count))
          (assert_equal "?q=bicycle+pedal&amp;hl=en&amp;start=10&amp;sa=N" ((matches lastObject) groupAtIndex:1))))