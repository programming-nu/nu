;; test_profiler.nu
;;  tests for Nu profiling helpers.
;;
;;  Copyright (c) 2009 Tim Burks, Radtastical Inc.


(function dosomething ()
     (1000 times:(do (i) (+ i i))))

(class TestProfiler is NuTestCase
     
     (- (id) testProfile is
        (set profiler (NuProfiler defaultProfiler))
        (profiler start:"top")
        (1 times:
           (do (i)
               (profiler start:"1")
               (dosomething)
               (profiler stop)))
        
        (2 times:
           (do (i)
               (profiler start:"2")
               (dosomething)
               (profiler stop)))
        
        (3 times:
           (do (i)
               (profiler start:"3")
               (dosomething)
               (profiler stop)))
        (profiler stop)
        
        (set results (profiler sections))
        ;(puts (results description))
        
        (assert_equal 2 ((results "2") count))
        (assert_equal 3 ((results "3") count))
        (set toptime ((results "top") time))
        (set onetime ((results "1") time))
        (set twotime ((results "2") time))
        (set threetime ((results "3") time))
        (assert_true (>= toptime (+ onetime twotime threetime)))))

