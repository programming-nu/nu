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
            (let ((r (NuMath random)))
                 (* maximum (- (/ r maximum) ((/ r maximum) intValue))))))

(global reverse
        (do (my-list)
            (if my-list
                (then (append (reverse (cdr my-list)) (list (car my-list))))
                (else nil))))

;; returns an array of filenames matching a given pattern.
;; the pattern is a string that is converted into a regular expression.
(global filelist
        (do (pattern)
            (let ((r (regex pattern))
                  (results ((NSMutableSet alloc) init))
                  (enumerator ((NSFileManager defaultManager) enumeratorAtPath:"."))
                  (filename nil))
                 (while (set filename (enumerator nextObject))
                        (if (r findInString:(filename stringValue))
                            (results addObject:filename)))
                 ((results allObjects) sortedArrayUsingSelector:"compare:"))))

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
                                      (let ((label (if (and (key isKindOfClass:NuSymbol) (key isLabel))
                                                       (then (key labelName))
                                                       (else key))))
                                           (if (eq label "action")
                                               (then (self setAction:value))
                                               (else (self setValue:value forKey:label))))))
          self)
     
     ;; A C-style ternary operator. Deprecated, because unlike the C operator, all of its arguments are evaluated.
     (imethod (id) ? (id) a : (id) b is
          (unless $ternary_deprecation_warning_already
                  ;; The problem is that because it is a message,
                  ;; all its arguments are evaluated
                  (NSLog "The ternary operator is deprecated. Please don't use it.")
                  (set $ternary_deprecation_warning_already t))
          (if self (then a) (else b))))

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
          (let ((m ((method car) evalWithContext:context)))
               (if (m isKindOfClass:NSNumber)
                   (then (if (and (< m (self count)) (>= m 0))
                             (then (self objectAtIndex:m))
                             (else nil)))
                   (else (super handleUnknownMessage:method withContext:context)))))
     
     ;; Convert a list into an array.
     (cmethod (id) arrayWithList: (id) list is
          (let ((a (NSMutableArray array)))
               (list each:(do (object) (a addObject:object)))
               a)))

(class NSMutableArray
     
     ;; Concisely add objects to arrays using this method, which is equivalent to a call to addObject:.
     (imethod (void) << (id) object is (self addObject:object)))

(class NSSet
     
     ;; Convert a list into a set.
     (cmethod (id) setWithList:(id) list is
          (let ((s (NSMutableSet set)))
               (list each:(do (object) (s addObject:object)))
               s)))

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
              (then (self objectForKey:((method car) evalWithContext: context)))
              (else (super handleUnknownMessage:method withContext:context))))
     
     ;; Look up an object by key, return the specified default if no object is found.
     (imethod (id) objectForKey:(id)key withDefault:(id)default is
          (cond ((self objectForKey:key))
                (else default)))
     
     ;; Iterate over the key-object pairs in a dictionary. Pass it a block with two arguments: (key object).
     (imethod (id) each:(id) block is
          ((self allKeys) each:
           (do (key) (block key (self objectForKey:key))))))


(class NSString
     
     ;; Convert a string into a symbol.
     (imethod (id) symbolValue is ((NuSymbolTable sharedSymbolTable) symbolWithString:self))
     
     ;; Split a string into lines.
     (imethod (id) lines is
          (let ((a (self componentsSeparatedByString:(NSString carriageReturn))))
               (if (eq (a lastObject) "")
                   (then (a subarrayWithRange:(list 0 (- (a count) 1))))
                   (else a))))
     
     ;; Replace a substring with another.
     (imethod (id) replaceString:(id) target withString:(id) replacement is
          (let ((s (NSMutableString stringWithString:self)))
               (s replaceOccurrencesOfString:target withString:replacement options:nil range:(list 0 (self length)))
               s)))

(class NuCell
     
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
                              ;; ivar name is the first (only) token of the message
                              (self valueForIvar:((message first) stringValue))
                              (catch (error)
                                     (super handleUnknownMessage:message withContext:context))))
                        (2
                          ;; try to automatically set an ivar
                          (if (eq (((message first) stringValue) substringWithRange:'(0 3)) "set")
                              (then
                                   (try
                                       (let ((firstArgument ((message first) stringValue)))
                                            (let ((variableName0 ((firstArgument substringWithRange:'(3 1)) lowercaseString))
                                                  (variableName1 ((firstArgument substringWithRange:
                                                                       (list 4 (- (firstArgument length) 5))))))
                                                 (self setValue:((message second) evalWithContext:context)
                                                       forIvar: "#{variableName0}#{variableName1}")))
                                       (catch (error)
                                              (super handleUnknownMessage:message withContext:context))))
                              (else (super handleUnknownMessage:message withContext:context))))
                        (else (super handleUnknownMessage:message withContext:context))))))

;; use this to create and extend protocols
(global protocol
        (macro _
             (set __signatureForIdentifier (NuBridgedFunction functionWithName:"signature_for_identifier" signature:"@@@"))
             (function __parse_signature (typeSpecifier)
                  (__signatureForIdentifier typeSpecifier (NuSymbolTable sharedSymbolTable)))
             
             (set __name ((margs car) stringValue))
             (unless (set __protocol (Protocol protocolNamed: __name))
                     (set __protocol ((Protocol alloc) initWithName: __name)))
             (eval (list 'set (margs car) __protocol))
             (set __rest (margs cdr))
             (while __rest
                    (set __method (__rest car))
                    (set __returnType (__parse_signature ((__method cdr) car)))
                    (set __signature __returnType)
                    (__signature appendString:"@:")
                    (set __name "#{(((__method cdr) cdr) car)}")
                    (set __argumentCursor (((__method cdr) cdr) cdr))
                    (while __argumentCursor ;; argument type
                           (__signature appendString:(__parse_signature (__argumentCursor car)))
                           (set __argumentCursor (__argumentCursor cdr))
                           (if __argumentCursor ;; variable name
                               (set __argumentCursor (__argumentCursor cdr)))
                           (if __argumentCursor ;; selector
                               (__name appendString:((__argumentCursor car) stringValue))
                               (set __argumentCursor (__argumentCursor cdr))))
                    (cond ((or (eq (__method car) '-) (eq (__method car) 'imethod))
                           (__protocol addInstanceMethod:__name withSignature:__signature))
                          ((or (eq (__method car) '+) (eq (__method car) 'cmethod))
                           (__protocol addClassMethod:__name withSignature:__signature))
                          (else nil))
                    (set __rest (__rest cdr)))))
