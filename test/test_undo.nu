;; test_undo.nu
;;  tests for Nu support for invocation-based undo.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class Toddler is NSObject
     ;(ivar-accessors)
     
     (- init is
        (super init)
        (set @shoes "untied")
        (set @giggles 0)
        self)
     
     (- tieShoes is
        (set @shoes "tied"))
     
     (- untieShoes is
        (set @shoes "untied"))
     
     (- (void) tickle:(int) times is
        (set @giggles (+ @giggles times))
        (if (>= @giggles 5) (self untieShoes))))

(class TestUndo is NuTestCase
    
     (- testUndo is
        (set u (NSUndoManager new))
        (u setGroupsByEvent:NO) ;; we will manage our own undo groups
        (u setLevelsOfUndo:0) ;; we will use an unlimited undo stack
        
        ;; create our test subject
        (set shannon (Toddler new))
        
        ;; verify initial conditions
        (assert_equal "untied" (shannon shoes))
        (assert_equal 0 (shannon giggles))
        (assert_equal 0 (u canUndo))
        
        ;; now let's push some "undo" actions on the stack.
        ;; these actions are last-in-first-out.
        
        ;; tie Shannon's shoes.
        (u beginUndoGrouping)
        ;; Beginning with Mac OS 10.6, prepareWithInvocationTarget returns a proxy object
        (set p (u prepareWithInvocationTarget:shannon))
        (p tieShoes)
        (u endUndoGrouping)
        
        ;; tickle her again.
        (u beginUndoGrouping)
        (set p (u prepareWithInvocationTarget:shannon))
        (p tickle:3)
        (u endUndoGrouping)
        
        ;; tickle her.
        (u beginUndoGrouping)
        (set p (u prepareWithInvocationTarget:shannon))
        (set one 1)
        (p tickle:(+ one one one))
        (u endUndoGrouping)
        
        ;; first, tie Shannon's shoes.
        (u beginUndoGrouping)
        (set p (u prepareWithInvocationTarget:shannon))
        (p tieShoes)
        (u endUndoGrouping)
        
        (assert_equal 1 (u canUndo))
        
        ;; now let's "undo" everything.
        
        (u undo)
        (assert_equal "tied" (shannon shoes))
        (assert_equal 0 (shannon giggles))
        (assert_equal 1 (u canUndo))
        
        (u undo)
        (assert_equal "tied" (shannon shoes))
        (assert_equal 3 (shannon giggles))
        (assert_equal 1 (u canUndo))
        
        (u undo)
        (assert_equal "untied" (shannon shoes))
        (assert_equal 6 (shannon giggles))
        (assert_equal 1 (u canUndo))
        
        (u undo)
        (assert_equal "tied" (shannon shoes))
        (assert_equal 6 (shannon giggles))
        (assert_equal 0 (u canUndo))))