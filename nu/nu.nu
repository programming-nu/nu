;; @file       nu.nu
;; @discussion Nu library definitions. Useful extensions to common classes.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(global first   (do (my-list) (car my-list)))
(global second  (do (my-list) (car (cdr my-list))))
(global third   (do (my-list) (car (cdr (cdr my-list)))))
(global fourth  (do (my-list) (car (cdr (cdr (cdr my-list))))))
(global fifth   (do (my-list) (car (cdr (cdr (cdr (cdr my-list)))))))
(global sixth   (do (my-list) (car (cdr (cdr (cdr (cdr (cdr my-list))))))))
(global seventh (do (my-list) (car (cdr (cdr (cdr (cdr (cdr (cdr my-list)))))))))
(global eighth  (do (my-list) (car (cdr (cdr (cdr (cdr (cdr (cdr (cdr my-list))))))))))
(global ninth   (do (my-list) (car (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr my-list)))))))))))
(global tenth   (do (my-list) (car (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr my-list))))))))))))

(global rand
        (do (maximum)
            (set r (NuMath random))
            (* maximum (- (/ r maximum) ((/ r maximum) intValue)))))

(global reverse 
        (do (my-list)
            (if my-list
                (then (append (reverse (cdr my-list)) (list (car my-list))))
                (else nil))))

;; returns an array of filenames matching a given pattern.
;; the pattern is a string that is converted into a regular expression.
(global filelist 
        (do (pattern)
            (set r (regex pattern))
            (set results ((NSMutableSet alloc) init))
            (let (enumerator ((NSFileManager defaultManager) enumeratorAtPath:"."))
                 (while (set filename (enumerator nextObject))
                        (if (r findInString:(filename stringValue))
                            (results addObject:filename))))
            ((results allObjects) sortedArrayUsingSelector:"compare:")))

;; parse operator; parses a string into Nu code objects
(global parse 
        (do (string)
            ((NuParser new) parse:string)))

;; create an array from a list of values
(global array (do (*args) (NSArray arrayWithList:*args)))

;; create a dictionary from a list of key-value pairs
(global dict (do (*args) (NSDictionary dictionaryWithList:*args)))

;; add enumeration to collection classes
(NSArray include: NuEnumerable)
(NSSet include: NuEnumerable)

(class NSObject
     
     ;; Concisely set key-value pairs from a property list.
     (imethod (id) set: (id) propertyList is
          (propertyList eachPair: (do (key value)
                                      (if (and (key isKindOfClass:NuSymbol)
                                               (key isLabel))
                                          (then (set label (key labelName)))
                                          (else (set label key)))
                                      (cond ((eq label "action") (self setAction:value))
                                            (else                (self setValue:value forKey:label)))))
          self))

(class NSArray
     
     ;; This default sort method sorts an array using its elements' compare: method.
     (imethod (id) sort is
          (self sortedArrayUsingSelector:"compare:"))
     
     ;; Convert an array into a list.
     (imethod (id) list is
          (self reduceLeft:(do (result item) (cons item result)) from: nil))
     
     ;; When an unknown message is received by an array, 
     ;; if it is an integer, treat it as a call to objectAtIndex:.
     (imethod (id) handleUnknownMessage:(id) method withContext:(id) context is
          (set m (method car))
          (set m (m evalWithContext: context))
          (if (m isKindOfClass:NSNumber)
              (then (if (and (< m (self count)) (>= m 0)) 
                        (then (self objectAtIndex:m))
                        (else nil)))
              (else (super handleUnknownMessage:method withContext:context))))
     
     ;; Convert a list into an array.
     (cmethod (id) arrayWithList: (id) list is
          (set a (NSMutableArray array))
          (list each:
                (do (object)
                    (a addObject:object)))
          a))

(class NSMutableArray
     
     ;; Concisely add objects to arrays using this method, which is equivalent to a call to addObject:.
     (imethod (void) << (id) object is (self addObject:object)))

(class NSSet
     
     ;; Convert a list into a set.
     (cmethod (id) setWithList:(id) list is
          (set s (NSMutableSet set))
          (list each: 
                (do (object)
                    (s addObject:object)))
          s))

(class NSMutableSet
     
     ;; Concisely add objects to sets using this method, which is equivalent to a call to addObject:.
     (imethod (void) << (id) object is (self addObject:object)))

(class NSDictionary
     
     ;; Convert a list of key-value pairs into a dictionary.
     (cmethod (id) dictionaryWithList: (id) list is
          (let (d (NSMutableDictionary dictionary))
               (list eachPair:
                     (do (key value)                        
                         (if (and (key isKindOfClass:NuSymbol)
                                  (key isLabel))
                             (then (d setValue:value forKey:(key labelName)))
                             (else (d setValue:value forKey:key)))))
               d))
     
     ;; When an unknown message is received by a dictionary, 
     ;; treat it as a call to objectForKey:.
     (imethod (id) handleUnknownMessage:(id) method withContext:(id) context is
          (if (eq (method length) 1)
              (then (set m ((method car) evalWithContext: context))
                    (self objectForKey:m))              
              (else (super handleUnknownMessage:method withContext:context)))))


(class NSString
     
     ;; Convert a string into a symbol.
     (imethod (id) symbolValue is ((NuSymbolTable sharedSymbolTable) symbolWithString:self))
     
     ;; Split a string into lines.
     (imethod (id) lines is
          (set array (self componentsSeparatedByString:(NSString carriageReturn)))
          (if (eq (array lastObject) "")
              (then (array subarrayWithRange:(list 0 (- (array count) 1))))
              (else array))))

(class NuCell
     ;; Test another list for equality.
     (imethod (BOOL) isEqual:(id) other is
          (try 
               (and ((self car) isEqual:(other car))
                    ((self cdr) isEqual:(other cdr)))
               (catch (exception) nil)))
     
     ;; Convert a list into an NSRect. The list must have at least four elements.
     (imethod (NSRect) rectValue is (list (self first) (self second) (self third) (self fourth)))
     
     ;; Convert a list into an NSPoint.  The list must have at least two elements.
     (imethod (NSPoint) pointValue is (list (self first) (self second)))
     
     ;; Convert a list into an NSSize.  The list must have at least two elements.
     (imethod (NSSize) sizeValue is (list (self first) (self second)))
     
     ;; Convert a list into an NSRange.  The list must have at least two elements.
     (imethod (NSRange) rangeValue is (list (self first) (self second))))

;; Call this macro in a class declaration to give a class automatic accessors for its instance variables.
;; Watch out for conflicts with other uses of handleUnknownMessage:withContext:.
;; The odd-looking use of the global operator is to define the macro globally.
;; We just use an "_" for the macro name argument because its local name is unimportant.
(global ivar-accessors 
        (macro _
             (imethod (id) handleUnknownMessage:(id) message withContext:(id) context is
                  (case (message length)
                        (1 
                           ;; try to automatically get an ivar  
                           (try 
                                (set variableName ((message first) stringValue))               
                                (self valueForIvar: variableName)
                                (catch (error)
                                       (super handleUnknownMessage:message withContext:context))))
                        (2
                          ;; try to automatically set an ivar  
                          (try 
                               (set firstArgument ((message first) stringValue))
                               (set variableName0 ((firstArgument substringWithRange:'(3 1)) lowercaseString))
                               (set variableName1 ((firstArgument substringWithRange:(list 4 (- (firstArgument length) 5)))))
                               (set variableName "#{variableName0}#{variableName1}")
                               (self setValue:((message second) evalWithContext:context) forIvar: variableName)
                               (catch (error)
                                      (super handleUnknownMessage:message withContext:context))))
                        (t (super handleUnknownMessage:message withContext:context))))))
