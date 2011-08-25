;; test_forwarding.nu
;;  tests for message forwarding in Nu
;;
;;  Copyright (c) 2011 Brian Chapados

(class RealThingBase is NSObject
     
     (- (id)baseName is "RealThingBase"))


(class RealThing is RealThingBase
     
     (- (id)realName is "RealThing"))

;; Standard Message forwarding:
;;   override -forwardInvocation:, -respondsToSelector:, -methodSignatureForSelector:
(class MyRegularProxy is NSObject
     
     (- (id)initWithObject:(id)delegate is
        (self init)
        (set @delegate delegate)
        self)
     
     (- (id)proxyName is "ARegularProxy")
     
     (- (void) forwardInvocation:(id) invocation is
        (set selector (invocation selector))
        (if (@delegate respondsToSelector:selector)
            (then
                 (invocation retainArguments)
                 (invocation invokeWithTarget:@delegate))
            (else
                 (self doesNotRecognizeSelector:selector))))
     
     (- (BOOL) respondsToSelector:(SEL) selector is
        (set mySuperClass (RealThing class))
        (set result (mySuperClass instancesRespondToSelector:selector))
        (if (eq NO result)
            (set result (@delegate respondsToSelector:selector)))
        result)
     
     (- (id)methodSignatureForSelector:(SEL) selector is
        (@delegate methodSignatureForSelector:selector)))

;; Fast-forwarding path:
;;  implement -forwardingTargetForSelector:
(class MyFastProxy is NSObject
     
     (- (id)initWithObject:(id)delegate is
        (self init)
        (set @delegate delegate)
        self)
     
     (- (id)proxyName is "AFastForwardingProxy")
     
     (- (id)forwardingTargetForSelector:(SEL)selector is
        (if (@delegate respondsToSelector:selector)
            (then @delegate)
            (else nil))))

(class TestForwarding is NuTestCase
     
     (- testNormalForwarding is
        (set real ((RealThing alloc) init))
        (set proxy ((MyRegularProxy alloc) initWithObject:real))
        (assert_equal "RealThing" (real realName))
        (assert_equal "ARegularProxy" (proxy proxyName))
        (assert_equal "RealThing" (proxy realName))
        (assert_equal "RealThingBase" (proxy baseName)))
     
     (- testFastForwarding is
        (set real ((RealThing alloc) init))
        (set proxy ((MyFastProxy alloc) initWithObject:real))
        (assert_equal "RealThing" (real realName))
        (assert_equal "AFastForwardingProxy" (proxy proxyName))
        (assert_equal "RealThing" (proxy realName))
        (assert_equal "RealThingBase" (proxy baseName))))

