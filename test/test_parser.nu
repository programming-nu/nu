;; test_parser.nu
;;  tests for the Nu parser.  Mainly used to test incremental parsing.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestParser is NuTestCase
     
     (- (id) testParseHereStrings is
        (set parser ((NuParser alloc) init))
        (parser parse:"(set x <<-END")
        (assert_equal YES (parser incomplete))
        (parser parse:"hello")
        (assert_equal YES (parser incomplete))
        (set script (parser parse:"worldEND)"))
        (assert_equal NO (parser incomplete))
        (eval script)
        (assert_equal <<-END
hello
worldEND x))
     
     (- (id) testParseMultilineRegularExpressions is
        (set parser ((NuParser alloc) init))
        (parser parse:"(set x /foo")
        (assert_equal YES (parser incomplete))
        (set script (parser parse:"bar/x)"))
        (assert_equal NO (parser incomplete))
        (eval script)
        (assert_not_equal nil (x findInString:"foobar"))
        (parser parse:"(set y /foo")
        (assert_equal YES (parser incomplete))
        (set script (parser parse:"bar/)"))
        (assert_equal NO (parser incomplete))
        (eval script)
        (assert_not_equal nil (y findInString:"foo\nbar"))))

