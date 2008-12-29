;; test_regex.nu
;;  tests for Nu regular expression support.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestRegex is NuTestCase
     
     (imethod (id) testRegexWithOperator is
          (set r (regex "a(.*)z"))
          (set match (r findInString:"abcdefghijklmnopqrstuvwxyz"))
          (assert_equal 24 ((match groupAtIndex:1) length)))
     
     (if (eq (uname) "Darwin") ;; requires UTF-8
         (imethod (id) testScrapeWithOperator is
              (set s (NSString stringWithContentsOfFile:"test/test.html" encoding:NSUTF8StringEncoding error:nil))
              (set r (regex <<-END
<a href="/search([^\"]*)"END))
              (set matches (r findAllInString:s))
              (assert_equal 10 (matches count))
              (assert_equal "?q=bicycle+pedal&amp;hl=en&amp;start=10&amp;sa=N" ((matches lastObject) groupAtIndex:1))))
     
     (imethod (id) testRegex is
          (set match (/a(.*)z/ findInString:"abcdefghijklmnopqrstuvwxyz"))
          (assert_equal 24 ((match groupAtIndex:1) length)))
     
     (if (eq (uname) "Darwin") ;; requires UTF-8
         (imethod (id) testRegexScraping is
              (set s (NSString stringWithContentsOfFile:"test/test.html" encoding:NSUTF8StringEncoding error:nil))
              (set r /<a href="\/search([^"]*)"/)
              (set matches (r findAllInString:s))
              (assert_equal 10 (matches count))
              (assert_equal "?q=bicycle+pedal&amp;hl=en&amp;start=10&amp;sa=N"
                   ((matches lastObject) groupAtIndex:1))))
     
     (imethod (id) testExtendedRegex is
          (set r /foo  # comment
                   bar/x)
          (set match (r findInString:"foobar"))
          (assert_not_equal nil match))
     
     (imethod (id) testMultipleCaptures is
          (set match (/^ab(.*)def(.*)jklmn(.*)tuv(.*)z$/
                          findInString:"abcdefghijklmnopqrstuvwxyz"))
          (assert_equal "c"     (match groupAtIndex:1))
          (assert_equal "ghi"   (match groupAtIndex:2))
          (assert_equal "opqrs" (match groupAtIndex:3))
          (assert_equal "wxy"   (match groupAtIndex:4)))
    
    (imethod (id) testEquality is
        (assert_equal /hello/ /hello/)
        (assert_equal /extended/x /extended/x)
        (assert_equal /a(.*)z/ /a(.*)z/)
        (assert_not_equal /hello/ /goodbye/)
        (assert_not_equal /extended/x /extended/)))



