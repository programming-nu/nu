;; test_regex.nu
;;  tests for Nu regular expression support.
;;
;;  Copyright (c) 2007,2011 Tim Burks, Radtastical Inc.

(class TestRegex is NuTestCase
     
     (- (id) testRegexWithOperator is
        (set r (regex "a(.*)z"))
        (set match (r findInString:"abcdefghijklmnopqrstuvwxyz"))
        (assert_equal 24 ((match groupAtIndex:1) length)))
     
     (- (id) testScrapeWithOperator is
        (set s (NSString stringWithContentsOfFile:((NSBundle mainBundle) pathForResource:"test" ofType:"html")))
        (unless s
                (set s (NSString stringWithContentsOfFile:"test/test.html" encoding:NSUTF8StringEncoding error:nil)))
        (set r (regex <<-END
<a href="/search([^\"]*)"END))
        (set matches (r findAllInString:s))
        (assert_equal 10 (matches count))
        (assert_equal "?q=bicycle+pedal&amp;hl=en&amp;start=10&amp;sa=N" ((matches lastObject) groupAtIndex:1)))
     
     (- (id) testRegex is
        (set match (/a(.*)z/ findInString:"abcdefghijklmnopqrstuvwxyz"))
        (assert_equal 24 ((match groupAtIndex:1) length)))
     
     (- (id) testRegexScraping is
        (set s (NSString stringWithContentsOfFile:((NSBundle mainBundle) pathForResource:"test" ofType:"html")))
        (unless s
                (set s (NSString stringWithContentsOfFile:"test/test.html" encoding:NSUTF8StringEncoding error:nil)))
        (set r /<a href="\/search([^"]*)"/)
        (set matches (r findAllInString:s))
        (assert_equal 10 (matches count))
        (assert_equal "?q=bicycle+pedal&amp;hl=en&amp;start=10&amp;sa=N"
             ((matches lastObject) groupAtIndex:1)))
     
     (- (id) testExtendedRegex is
        (set r /foo  # comment
                   bar/x)
        (set match (r findInString:"foobar"))
        (assert_not_equal nil match))
     
     (- (id) testMultipleCaptures is
        (set match (/^ab(.*)def(.*)jklmn(.*)tuv(.*)z$/
                        findInString:"abcdefghijklmnopqrstuvwxyz"))
        (assert_equal "c"     (match groupAtIndex:1))
        (assert_equal "ghi"   (match groupAtIndex:2))
        (assert_equal "opqrs" (match groupAtIndex:3))
        (assert_equal "wxy"   (match groupAtIndex:4)))
     
     (- (id) testEquality is
        (assert_equal /hello/ /hello/)
        (assert_equal /extended/x /extended/x)
        (assert_equal /a(.*)z/ /a(.*)z/)
        (assert_not_equal /hello/ /goodbye/)
        (assert_not_equal /extended/x /extended/)
        (assert_not_equal /foo/ nil)
        (assert_not_equal /foo/ "foo")))



