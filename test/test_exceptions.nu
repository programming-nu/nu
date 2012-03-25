;; test_exceptions.nu
;;  tests for Nu exception handling.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestExceptions is NuTestCase
     
     (if (eq (uname) "Darwin") ;; broken for iOS simulator-only
         (- (id) testRangeException is
            (set name nil)
            (set before nil)
            (set after nil)
            (set z nil)
            (try
                (set before "this should always be set")
                ((NSArray array) objectAtIndex:1)
                (set after "this should never be set")
                (catch (exception) (set name (exception name)))
                (finally (set z 99)))
            (assert_equal "this should always be set" before)
            (assert_equal nil after)
            (assert_equal "NSRangeException" name)
            (assert_equal 99 z)))
     
     (if (eq (uname) "Darwin") ;; broken for iOS simulator-only
         (- (id) testUserRaisedException is
            (set name nil)
            (set before nil)
            (set after nil)
            (set z nil)
            (try
                (set before "this should always be set")
                (((NSException alloc) initWithName:"UserException" reason:"" userInfo:nil) raise)
                (set after "this should never be set")
                (catch (exception) (set name (exception name)))
                (finally (set z 99)))
            (assert_equal "this should always be set" before)
            (assert_equal nil after)
            (assert_equal "UserException" name)
            (assert_equal 99 z)))
     
     (- (id) testUserThrownException is
        (set name nil)
        (set before nil)
        (set after nil)
        (set z nil)
        (try
            (set before "this should always be set")
            (throw ((NSException alloc) initWithName:"UserException" reason:"" userInfo:nil))
            (set after "this should never be set")
            (catch (exception) (set name (exception name)))
            (finally (set z 99)))
        (assert_equal "this should always be set" before)
        (assert_equal nil after)
        (assert_equal "UserException" name)
        (assert_equal 99 z))
     
     (- (id) testUserThrownObject is
        (set object nil)
        (set before nil)
        (set after nil)
        (set z nil)
        (try
            (set before "this should always be set")
            (throw 99)
            (catch (thrown) (set object thrown))
            (finally (set z 99)))
        (assert_equal "this should always be set" before)
        (assert_equal nil after)
        (assert_equal 99 object)
        (assert_equal 99 z))
     
     (- (id) testAssertThrown is
        (assert_throws "UserException"
             (do () (throw ((NSException alloc) initWithName:"UserException" reason:"" userInfo:nil))))))

