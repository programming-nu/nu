;; test_strings.nu
;;  tests for Nu string literals.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestStrings is NuTestCase
     
     (- (id) testEscapedStrings is
        (assert_equal 10 ("\n" characterAtIndex:0))
        (assert_equal 13 ("\r" characterAtIndex:0))
        (assert_equal 12 ("\f" characterAtIndex:0))
        (assert_equal 9  ("\t" characterAtIndex:0))
        (assert_equal 8  ("\b" characterAtIndex:0))
        (assert_equal 7  ("\a" characterAtIndex:0))
        (assert_equal 27 ("\e" characterAtIndex:0))
        (assert_equal 32 ("\s" characterAtIndex:0))
        (assert_equal 34 ("\"" characterAtIndex:0))
        (assert_equal 92 ("\\" characterAtIndex:0)))
     
     (- (id) testInterpolation is
        (set x "")
        (assert_equal "" "#{x}")
        
        (set x "blueberry")
        (assert_equal "blueberry pancakes" "#{x} pancakes")
        
        (assert_equal "24" "#{(* 6 4)}"))
     
     (- (id) testOctalEscapedStrings is
        (assert_equal 0 ("\000" characterAtIndex:0))
        (assert_equal 1 ("\001" characterAtIndex:0))
        (assert_equal 255 ("\377" characterAtIndex:0)))
     
     (- (id) testHexEscapedStrings is
        (assert_equal 0 ("\x00" characterAtIndex:0))
        (assert_equal 1 ("\x01" characterAtIndex:0))
        (assert_equal 255 ("\xfF" characterAtIndex:0)))
     
     (- (id) testUnicodeEscapedStrings is
        (assert_equal 0 ("\u0000" characterAtIndex:0))
        (assert_equal 1 ("\u0001" characterAtIndex:0))
        (assert_equal 255 ("\u00ff" characterAtIndex:0))
        (assert_equal 65535 ("\uFfFf" characterAtIndex:0)))
     
     (- (id) testEscapedHereStrings is
        (set x <<+END
\n\r\f\t\b\a\e\s\"\\END) ;; " fix textmate! 
        (assert_equal 10 (x characterAtIndex:0))
        (assert_equal 13 (x characterAtIndex:1))
        (assert_equal 12 (x characterAtIndex:2))
        (assert_equal 9  (x characterAtIndex:3))
        (assert_equal 8  (x characterAtIndex:4))
        (assert_equal 7  (x characterAtIndex:5))
        (assert_equal 27 (x characterAtIndex:6))
        (assert_equal 32 (x characterAtIndex:7))
        (assert_equal 34 (x characterAtIndex:8))
        (assert_equal 92 (x characterAtIndex:9)))
     
     (- (id) testOctalEscapedHereStrings is
        (set x <<+END
\003\001\377END)
        (assert_equal 3 (x characterAtIndex:0))
        (assert_equal 1 (x characterAtIndex:1))
        (assert_equal 255 (x characterAtIndex:2)))
     
     (- (id) testHexEscapedHereStrings is
        (set x <<+END
\x03\x01\xffEND)
        (assert_equal 3 (x characterAtIndex:0))
        (assert_equal 1 (x characterAtIndex:1))
        (assert_equal 255 (x characterAtIndex:2)))
     
     (- (id) testUnicodeEscapedHereStrings is
        (set x <<+END
\u0000\u0001\u00ff\uFfFfEND)
        (assert_equal 0 (x characterAtIndex:0))
        (assert_equal 1 (x characterAtIndex:1))
        (assert_equal 255 (x characterAtIndex:2))
        (assert_equal 65535 (x characterAtIndex:3)))
     
     (- (id) testExplicitlyUnescapedStrings is
        (assert_equal 92 (-"\n" characterAtIndex:0))
        (assert_equal 92 (-"\s" characterAtIndex:0))
        (assert_equal 92 (-"\x20" characterAtIndex:0)))
     
     (- (id) testExplicitlyEscapedStrings is
        (assert_equal 10 (+"\n" characterAtIndex:0))
        (assert_equal 32 (+"\s" characterAtIndex:0))
        (assert_equal 32 (+"\x20" characterAtIndex:0)))
     
     (- (id) testExplicitlyUnescapedHereStrings is
        (set x <<-END
foo\nbarEND)
        (assert_equal 8 (x length))
        (assert_equal 92 (x characterAtIndex:3)))
     
     (- (id) testExplicitlyEscapedHereStrings is
        (set x <<+END
foo\nbarEND)
        (assert_equal 7 (x length))
        (assert_equal 10 (x characterAtIndex:3)))
     
     (- (id) testLineSplitting is
        (set x <<-END
Line 0
Line 1
Line 2
END)
        (set lines (x lines))
        (assert_equal 3 (lines count))
        (assert_equal "Line 1" (lines objectAtIndex:1)))
     
     (- (id) testEscapedRepresentations is
        ;; verify the named characters
        (assert_equal "(\"\\a\\b\\t\\n\\f\\r\\e\")" ('("\a\b\t\n\f\r\e") stringValue))
        ;; verify escaping of low-valued characters
        (assert_equal "\"\\x01\\x02\"" ("\x01\x02" escapedStringRepresentation))
        ;;verify that 0x1f is the highest character escaped, 0x20 is kept as-is
        (assert_equal "\"\\x1f \"" ("\x1f\x20" escapedStringRepresentation))
        ;; verify that 0x7e is not escaped but 0x7f is
        (assert_equal "\"~\\x7f\"" ("\x7e\x7f" escapedStringRepresentation))
        ;; verify escaping of higher-valued one-byte characters
        (assert_equal "\"\\xe0\\xf0\"" ("\xE0\xf0" escapedStringRepresentation))
        ;; verify escaping of unicode characters (\ufffe and \uffff are not valid characters)
        (assert_equal "\"\\u0100\\ufffd\"" ("\u0100\uffFD" escapedStringRepresentation)))
     
     (- (id) testStringEach is
        (set start "hello, world")
        (set finish "")
        (start each:(do (c) (finish appendCharacter:c)))
        (assert_equal start finish)
        ;; each with break
        (set finish "")
        (start each:(do (c) (if (eq c ',') (break)) (finish appendCharacter:c)))
        (assert_equal "hello" finish)
        ;; each with continue
        (set finish "")
        (start each:(do (c) (if (eq c ',') (continue)) (finish appendCharacter:c)))
        (assert_equal "hello world" finish))
     
     (- (id) testStringMap is
        (set start "hello, world")
        (set mapped
             (start map:
                    (do (c) (NSString stringWithCharacter:(if (and (>= c 'a') (<= c 'z'))
                                                              (then (- c (- 'a' 'A')))
                                                              (else c))))))
        (set finish (mapped componentsJoinedByString:""))
        (assert_equal "HELLO, WORLD" finish))
     
     (- (id) testAddingNilToStrings is
        (assert_equal "hello world" (+ "hello" nil " " nil "world"))))