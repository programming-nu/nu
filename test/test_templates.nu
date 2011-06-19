;; test_templates.nu
;;  tests for Nu code templates.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(load "template")

(class TestTemplates is NuTestCase
     
     (- (id) testCodeSubstitution is
        (set template (NuTemplate codeForString:<<-END
this is <%= (- 2 1) %> of many (at least <%= (+ -2 3) %>) tests.END))
        (set goal <<-END
this is 1 of many (at least 1) tests.END)
        (assert_equal goal (eval template)))
     
     (- (id) testCountingSubstitution is
        (set template (NuTemplate codeForString:<<-END
<% (10 times: (do (i) %><%= i %>: <%= (- 10 i) %>
<% )) %>END))
        (set goal <<-END
0: 10
1: 9
2: 8
3: 7
4: 6
5: 5
6: 4
7: 3
8: 2
9: 1
END)
        (set result (eval template))
        (assert_equal goal result)))


