;; test_markup.nu
;;  tests for Nu markup operators.
;;
;;  Copyright (c) 2012 Tim Burks, Radtastical Inc.

(class TestMarkup is NuTestCase
     
     (- testMarkup is
        (set markup (&html (&body (&h1 "Hello!")
                                  (&p "This is a test")
                                  (&p "This is a second paragraph"))))
        (set golden "<html><body><h1>Hello!</h1><p>This is a test</p><p>This is a second paragraph</p></body></html>")
        (assert_equal golden markup))
     
     (- testAttributes is
        (set markup (&magic attribute:123 "hello"))
        (set golden "<magic attribute=\"123\">hello</magic>")
        (assert_equal golden markup)))

