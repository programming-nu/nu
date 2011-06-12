# test_nu.rb
#  Nu sanity tests.  Requires Ruby, RubyObjC, and Test::Unit.
#
#  Copyright (c) 2007 Tim Burks, Radtastical Inc.
#  For more information about this file, visit http://programming.nu.

require 'test/unit'

unless defined? ObjC
  require 'rubygems'
  require 'objc'
end

ObjC::NSBundle.bundleWithPath_(File.dirname(__FILE__)+'/../Nu.framework').load

class ObjC::NuParser
  def eval(expr)
    value = parseEval_(expr)
    value ? value.to_s : nil
  end
end

class TestNu < Test::Unit::TestCase
  def setup
    @parser = ObjC::NuParser.alloc.init
  end

  def teardown
    @patterns.split("\n").each do |line|
      expression, value = line.split('===')
      expression = expression.strip
      value = value.chomp.strip if value
      value = nil if value == "nil"
      result = @parser.eval(expression)
      assert_equal(value, result, "error in the evaluation of #{expression}") if value
    end
  end

  def test_eval
    @patterns = <<-END
    (eval '(+ 2 2)) === 4
    END
  end
  
  def test_cadr
    @patterns = <<-END
    (set a '(1 2 3))        === (1 2 3)
    (set b '((1 2) 3))      === ((1 2) 3)
    (car a)                 === 1
    (car b)                 === (1 2)
    (car (car b))           === 1
    (cdr a)                 === (2 3)
    (cdr b)                 === (3)
    (car (cdr b))           === 3
    END
  end

  def test_atom
    @patterns = <<-END
    (atom '(1 2 3))         === ()
    (atom 1)                === t
    (atom 'a)               === t
    END
  end
  
  def test_cond
    @patterns = <<-END
    (cond (1 '1) (else '2))  === 1
    (cond (0 '1) (else '2))  === 2
    END
  end
  
  def test_cons
    @patterns = <<-END
    (cons 1 '(2 3))         === (1 2 3)
    (cons '(1 2) '(3))      === ((1 2) 3)
    (cons 1 2)              === (1 . 2)
    (cons 1)                === (1)
    (cons nil 1)            === (() . 1)
    ((cons 1 (cons 2 3)))   === (1 2 . 3)
    END
  end
  
  def test_positions
    @patterns = <<-END
    (set a '(1 2 3 4 5 6))
    (a first) === 1
    (a second) === 2
    (a third) === 3
    (a fourth) === 4
    (a fifth) === 5
    END
  end
  
  def test_set
    @patterns = <<-END
    (set a 1)               === 1
    (set b 2)               === 2
    a                       === 1
    b                       === 2
    (set c (set d 3))       === 3
    c                       === 3
    END
  end
  
  def test_do
    @patterns = <<-END
    (set a 0)                 === 0
    (set b 0)                 === 0
    (set c 3)                 === 3
    (def f (a b) (+ a b c))   === (do (a b) ((+ a b c)))
    (set c 4)                 === 4
    (f 1 2)                   === 6
    (f 3 4)                   === 10
    (def g (a b) (set c (+ a b))(* c c))
    (g 2 3)                   === 25
    c                         === 4
    END
  end
  
  def test_factorial
    @patterns = <<-END
    (def factorial (x)
      (cond ((eq x 0) 1)
             (else (* x (factorial (- x 1))))))
    (factorial 0)                === 1
    (factorial 1)                === 1
    (factorial 2)                === 2
    (factorial 10)               === 3628800
    END
  end
  
  def test_fibonacci
    @patterns = <<-END
    (def fib (x)
      (cond ((eq x 0) 1)
            ((eq x 1) 1)
            (else (+ (fib (- x 1)) (fib (- x 2))))))
    (fib 0) === 1
    (fib 1) === 1
    (fib 2) === 2
    (fib 3) === 3
    (fib 4) === 5
    (fib 5) === 8
    (fib 6) === 13
    (fib 7) === 21
    (fib 8) === 34
    (fib 9) === 55
    END
  end
  
  def test_times
    @patterns = <<-END
    (set a ((NSMutableArray alloc) init))
    (3 times: (do (i) 
      (3 times: (do (j) 
        (a addObject:  (+ (* i 3) j))
      ))
    ))
    (a count)                  === 9
    (a objectAtIndex: 4)       === 4
    (a objectAtIndex: 8)       === 8
    END
  end
  
  def test_messages
    @patterns = <<-END
    ((NuClass all) count) === #{ObjC::Class.to_a.length}
    END
  end
  
  def test_bridge
    @patterns = <<-END
    ("scheme" commonPrefixWithString:"school" options:0) === sch
    ("scheme" capitalizedString) === Scheme
    ((NSArray arrayWithObject:2) objectAtIndex:0) === 2
    END
  end
  
  def test_mutableset
    @patterns = <<-END
    (set s ((NSMutableSet alloc) init))
    (s addObject:1)
    (s addObject:"two")
    (s addObject:3.0)
    (s count)           === 3
    (s member:1)        === 1
    (s member:"two")    === two
    (s member:3.0)      === 3
    (s member:4)        === ()
    END
  end
  
  def test_select
    @patterns = <<-END
    (NSArray include: NuEnumerable)
    (set m (NSString classMethods))
    (((m select:(do (x) (eq (x name) "string"))) lastObject) name)   === string
    (set name-is (do (x) (do (y) (eq (y name) x))))
    (((m select:(name-is "string")) lastObject) name)                === string
    (((m select:(name-is "stringWithCString:")) lastObject) name)    === stringWithCString:
    ((m find:(name-is "stringWithCString:")) name)                   === stringWithCString:
    END
  end

  def test_add_instance_method
    @patterns = <<-END
    (NSObject addInstanceMethod:"beep" signature:"@@:" body:(do () ("beep!")))
    (set o ((NSObject alloc) init))
    (o beep)                                                        === beep!
    END
  end
  
  def test_simple_subclass
    @patterns = <<-END
    (NSObject createSubclassNamed:"MyChild")
    (MyChild addInstanceMethod:"show" signature:"@@:" body:(do () (self class)))
    (set o ((MyChild alloc) init))
    (o show)                                                        === MyChild
    END
  end
  
  def test_add_factorial_method
    @patterns = <<-END
    (NSNumber addInstanceMethod:"factorial" signature:"i@:" body:
      (do ()  
        (set x (self intValue))
        (cond ((eq x 0) 1)
              (else (* x ((- x 1) factorial))))))
     (5 factorial) === #{5*4*3*2}
    END
  end
  
  def test_addition_shocker
    @patterns = <<-END
    (NSNumber addInstanceMethod:"+" signature:"d@:d" body:(do (x) (+ x (self doubleValue))) )
    (1.2 + 3.4) === 4.6
    END
  end
  
  def test_add_class_method
    @patterns = <<-END
    (NSNumber addClassMethod:"three" signature:"@@:" body:(do () (+ 1 1 1)))
    (NSNumber three) === 3
    END
  end
  
  def test_add_ivar
    # try this for a few different classes.  NSWindow crashes. :-(
    @patterns = <<-END
    (NSWindowController createSubclassNamed: "Child")
    (Child addInstanceVariable: "one" signature: "i")
    (set c ((Child alloc) init))
    (c valueForKey: "one")                                   === 0
    (c setValue: 33 forKey: "one")
    (c valueForKey: "one")                                   === 33 
    END
    # trying to read a non-existent ivar crashes too:
    # (c valueForKey: "two") 
  end
  
  def test_add_ivar2
    @patterns = <<-END  
    (class Test is NSObject
        (ivar (int) x)
        (- (void) setX:(int) x is (set @x x))
        (- (int) x is @x))
    (set y ((Test alloc) init))
    (y setX:33)               
    (y x)                                                    === 33
    END
  end
  
  def test_auto_ivar
    @patterns = <<-END    
    (class Foo is NSObject
        (ivars)
        (- (id) incr is
            (cond (@y (set @y (+ @y 1)))
                  (else (set @y 1)))))
    (set f ((Foo alloc) init))
    (f setValue:2 forIvar:"x")
    (f valueForIvar:"x")            === 2
    (f incr)                        === 1
    (f incr)                        === 2
    (f incr)                        === 3
    END
  end
  
  def test_let
    @patterns = <<-END
    (let (abc 999) (+ 2 2) (+ 1 abc))                        === 1000
    (let ((a 1) (b 2)) (+ a b))                              === 3   
    END
  end
  
  def test_list
    @patterns = <<-END
    (list 1 2 3)                  === (1 2 3)
    (list (list 2 3 4) 2)         === ((2 3 4) 2)
    END
  end
  
  def test_counter_class
    @patterns = <<-END
    (class Counter is NSObject
  	  (ivar (id) c)
  	  (- (id) init is
  		  (super init)
  		  (set @c 0)
  		  self)
  	  (- (id) count is (@c))
  	  (- (void) step is (set @c (+ @c 1))))
    (set counter ((Counter alloc) init))
    (counter count)                         === 0
    (10 times: (do () (counter step)))
    (counter count)                         === 10
    END
  end
  
  def test_another_factorial
    @patterns = <<-END
    (class NSNumber
       (- (id) "!" is 
         (set n (self intValue))
         (cond ((eq n 0) 1)
               (else     (* n ((- n 1)!))))))
    (3 !) === 6
    (4 !) === 24
    (5 !) === 120
    END
  end

  def test_append
    @patterns = <<-END
      (append '(1 2 3) '() '(4 5 6) '(7) '(8 9)) === (1 2 3 4 5 6 7 8 9)  
    END
  end

  def test_extensions
	@patterns = <<-END
  	(NSArray include: NuEnumerable)
	  (class NSMutableDictionary
    	 (+ (id) dictionaryWithList: (id) list is
        	(let (d (self dictionary))
             	(list eachPair:
                   	(do (key value)
                       	(d setValue:value forKey:key)))
             			d)))
	  (class NSDictionary
    	 (- (id) list is
        	((self allKeys) reduce:
         		(do (result key)
             		(cons key (cons (self objectForKey: key) result)))
         			from: nil)))
	  (class NSMutableArray
    	 (+ (id) arrayWithList: (id) list is
        	(let (a (self array))
             (list each: (do (item) (a addObject: item)))
             a)))
	  (class NSArray
    	 (- (id) list is
        	(self reduceLeft:(do (result item) (cons item result)) from: nil))
		   (- (id) sum is
			    (self reduce:(do (result item) (+ item result)) from: 0)))
	  (set d (NSMutableDictionary dictionaryWithList: '("a" 1 "b" 2 "c" 3)))
	  (d count) 				        === 3
	  (d objectForKey:"a") 			=== 1
	  (d objectForKey:"b")      === 2
	  (d objectForKey:"c")      === 3
	  (set e (NSMutableDictionary dictionaryWithList: (d list)))
	  (e count) 				        === 3
	  (e objectForKey:"a") 			=== 1
	  (e objectForKey:"b")      === 2
	  (e objectForKey:"c")      === 3	  
	  (set a (NSMutableArray arrayWithList: '(1 2 3 4 5 6)))
	  (a count) 				        === 6
	  (a list) 				          === (1 2 3 4 5 6)
	  (a sum) 				          === 21
	  END
  end
  
  def test_super
    @patterns = <<-END
    (class Level1 is NSObject
        (- (int) depth is (1)))
    (class Level2 is Level1
        (- (int) depth is (+ 1 (super depth))))
    (class Level3 is Level2
        (- (int) depth is (+ 1 (super depth))))
    (class Level4 is Level3
        (- (int) depth is (+ 1 (super depth))))
    (((Level1 alloc) init) depth) === 1
    (((Level2 alloc) init) depth) === 2
    (((Level3 alloc) init) depth) === 3
    (((Level4 alloc) init) depth) === 4
    END
  end
  
  def test_method_replacement
    @patterns = <<-END
    (class NSObject (- (int) one is 1))
    (((NSObject alloc) init) one) === 1
    (class NSObject (- (int) one is 2))
    (((NSObject alloc) init) one) === 2
    END
    # this doesn't work, though:
    #(class NSObject (- (double) one is (1.1)))
    #(((NSObject alloc) init) one) === 1.1
    # it seems that we can't change the return type of a method
  end
  
  def test_case
    @patterns = <<-END
    (set x 1)
    (case x (2 y) (4 z) (11 2) (9 9 10 11) (x (set y 4) (* y x)) (2 (+ 1 1))) === 4
    END
  end
  
  def test_if_unless
    @patterns = <<-END
      (if (eq 1 1) 99)      === 99
      (if (eq 1 2) 99)      === ()
      (unless (eq 1 1) 99)  === ()
      (unless (eq 1 2) 99)  === 99
    END
  end
  
  def test_structs
    @patterns = <<-END
    (def reverse (n)
        (cond ((eq n nil) nil)
              (else (append (reverse (cdr n)) (list (car n))))))
    (class Structs is NSObject
      (+ (NSPoint) makePointX:(double)x y:(double)y is (list x y))
      (+ (NSSize) makeSizeW:(double)w h:(double)h is (list w h))
      (+ (NSRect) makeRectX:(double)x y:(double)y w:(double)w h:(double)h is (list x y w h))
      (+ (id) unpackPoint:(NSPoint) point is point)
      (+ (id) unpackSize:(NSSize) size is size)
      (+ (id) unpackRect:(NSRect) rect is rect)
      (+ (NSPoint) passPoint:(NSPoint) point is point)
      (+ (NSSize) passSize:(NSSize) size is size)
      (+ (NSRange) passRange:(NSRange) range is range)
      (+ (NSRect) passRect:(NSRect) rect is rect)
      (+ (NSRect) flipRect:(NSRect) rect is (reverse rect)))
    (Structs makePointX:3 y:5)              === (3 5)
    (Structs makeSizeW:9.9 h:110)           === (9.9 110)
    (Structs makeRectX:1 y:2.2 w:3.3 h:4.4) === (1 2.2 3.3 4.4)
    (Structs unpackPoint:'(2 3))            === (2 3)
    (Structs unpackSize:'(9 10))            === (9 10)
    (Structs unpackRect:'(5 6 7 8))         === (5 6 7 8)
    (Structs passPoint:'(1 2))              === (1 2)
    (Structs passSize:'(0 0))               === (0 0)
    (Structs passRange:'(10 20))            === (10 20)
    (Structs passRect:'(1 2 3 4))           === (1 2 3 4)
    (Structs flipRect:'(1 2 3 4))           === (4 3 2 1)
    END
  end
  
  def test_list_map
    @patterns = <<-END
    ('(1 2 3 4 5) map: (do (i) (* i i)))    === (1 4 9 16 25)
    END
  end
  
  def test_kind_of
    @patterns = <<-END
    (NSMutableArray isKindOfClass:NSArray)  === 1
    (NSMutableArray isKindOfClass:NSMutableArray) === 1
    (NSMutableArray isKindOfClass:NSString) === 0
    END
  end
end
