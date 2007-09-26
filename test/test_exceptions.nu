;; test_exceptions.nu
;;  tests for Nu exception handling.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestExceptions is NuTestCase
     
     (imethod (id) testRangeException is
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
          (assert_equal before "this should always be set")
          (assert_equal after nil)
          (assert_equal name "NSRangeException")
          (assert_equal z 99))
     
     (imethod (id) testUserRaisedException is
          (set name nil)
          (set before nil)
          (set after nil)
          (set z nil)
          (try 
               (set before "this should always be set")
               (((NSException alloc) initWithName:"UserException" reason:"" userInfo:NULL) raise)
               (set after "this should never be set")
               (catch (exception) (set name (exception name)))
               (finally (set z 99)))
          (assert_equal before "this should always be set")
          (assert_equal after nil)
          (assert_equal name "UserException")
          (assert_equal z 99))
     
     (imethod (id) testUserThrownException is
          (set name nil)
          (set before nil)
          (set after nil)
          (set z nil)
          (try 
               (set before "this should always be set")
               (throw ((NSException alloc) initWithName:"UserException" reason:"" userInfo:NULL))
               (set after "this should never be set")
               (catch (exception) (set name (exception name)))
               (finally (set z 99)))
          (assert_equal before "this should always be set")
          (assert_equal after nil)
          (assert_equal name "UserException")
          (assert_equal z 99))
     
     (imethod (id) testUserThrownObject is
          (set object nil)
          (set before nil)
          (set after nil)
          (set z nil)
          (try 
               (set before "this should always be set")
               (throw 99)
               (catch (thrown) (set object thrown))
               (finally (set z 99)))
          (assert_equal before "this should always be set")
          (assert_equal after nil)
          (assert_equal object 99) 
          (assert_equal z 99)))		


