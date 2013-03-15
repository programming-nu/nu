;; test_markup.nu
;;  tests for Nu markup operators.
;;
;;  Copyright (c) 2012 Tim Burks, Radtastical Inc.

(class TestMarkup is NuTestCase
 
 (- testMarkup is
    (set markup (&html (&body (&h1 "Hello!")
                              (&p "This is a test")
                              (&p "This is a second paragraph"))))
    (set golden "<!DOCTYPE html><html><body><h1>Hello!</h1><p>This is a test</p><p>This is a second paragraph</p></body></html>")
    (assert_equal golden markup))
 
 (- testAttributes is
    (set markup (&magic attribute:123 "hello"))
    (set golden "<magic attribute=\"123\">hello</magic>")
    (assert_equal golden markup))
 
 (- testHTML is
    (set markup (&html))
    (set golden "<!DOCTYPE html><html></html>")
    (assert_equal golden markup))
 
 (- testBooleanAttributes is
    (set markup (&p foo:(eq 1 1)) bar:(eq 1 0))
    (set golden "<p foo></p>")
    (assert_equal golden markup))
 
 (- testVoidElements is
    (set voidElements (array "area"
                             "base"
                             "br"
                             "col"
                             "command"
                             "embed"
                             "hr"
                             "img"
                             "input"
                             "keygen"
                             "link"
                             "meta"
                             "param"
                             "source"
                             "track"
                             "wbr"))
    (voidElements each:
                  (do (element)
                      (set markup (eval (parse "(&#{element})")))
                      (set golden "<#{element}/>")
                      (assert_equal golden markup)))
    (set nonVoidElements (array "div"
                                "span"
                                "frame"
                                "strong"
                                "p"))
    (nonVoidElements each:
                     (do (element)
                         (set markup (eval (parse "(&#{element})")))
                         (set golden "<#{element}></#{element}>")
                         (assert_equal golden markup))))
 
 (- testEmbeddedClassAndIdProperties is
    (set markup (&div.class1.class2.class3))
    (set golden "<div class=\"class1\" class=\"class2\" class=\"class3\"></div>")
    (assert_equal golden markup)
    (set markup (&div#id1#id2#id3))
    (set golden "<div id=\"id1\" id=\"id2\" id=\"id3\"></div>")
    (assert_equal golden markup)
    (set markup (&div#myid.myclass))
    (set golden "<div id=\"myid\" class=\"myclass\"></div>")
    (assert_equal golden markup)))
