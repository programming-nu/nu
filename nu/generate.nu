;; @file       generate.nu
;; @discussion Code generator for Objective-C classes.
;;             Generates instance variables, accessors, setters, and archiving functions.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Radtastical Inc.
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

(load "template")

(class NSString
     ;; Get the last character of a string.
     (- (int) lastCharacter is
          (self characterAtIndex:(- (self length) 1)))
     ;; Capitalize the first character of a string.
     (- (id) capitalizeFirstCharacter is
          (self stringByReplacingCharactersInRange:'(0 1)
                withString:((self substringWithRange:'(0 1)) capitalizedString)))
     ;; Remove the parentheses surrounding a string.
     (- (id) stripParens is
          (self substringWithRange:(list 1 (- (self length) 2)))))

;; @abstract A code generator for Objective-C classes.
;; @discussion Given a list of instance variables and their types,
;; NuGenerator generates code for Objective-C classes.  This
;; code includes variable declarations, accessors, and
;; encoding and decoding methods.  Much of this capability
;; is available in Objective-C 2.0 using properties,
;; but it is provided here to show how easy it is to
;; use Nu to take direct control of the process.
;;
(class NuGenerator is NSObject
     (ivars)
     
     ;; Initialize a generator with a list that describes a set of classes to be generated.
     (- (id) initWithDescription:(id) description is
          (super init)
          (set @description description)
          self)
     
     ;; Generate typedefs for enumerated types
     (- (id) generateEnumTypedefs is
          (set result ((NSMutableString alloc) init))
          (@description each:
               (do (declaration)
                   (if (eq (car declaration) 'enum)
                       (set enumType ((declaration second) stringValue))
                       (result appendString:<<-END
typedef enum {
END)
                       (((declaration cdr) cdr) each:
                        (do (enum)
                            (result appendString:<<-END
    #{enumType}#{enum},
END)))
                       (result appendString:<<-END
} #{enumType}Type;
	
END)               
                       
                       )))
          result)
     
     ;; Generate class forward declarations; usually these are placed in header files.
     (- (id) generateDeclarations is
          (set result ((NSMutableString alloc) init))
          
          (@description each:
               (do (declaration)
                   (if (eq (car declaration) 'class)
                       ;; open the class interface
                       (result appendString:<<-END
@class #{(declaration second)};
END))))
          result)
     
     ;; Generate class interface descriptions; usually these are placed in header files.
     (- (id) generateInterfaces is
          (set result ((NSMutableString alloc) init))
          
          (@description each:
               (do (declaration)
                   (if (eq (car declaration) 'class)
                       ;; open the class interface
                       (result appendString:<<-END
@interface #{(declaration second)} : #{(declaration fourth)} {
END)                 
                       (set cursor (cdr (cdr (cdr (cdr declaration)))))
                       (while cursor
                              (set group (cursor car))
                              (if (eq (group car) 'ivar)
                                  ((group cdr) eachPair:
                                   (do (type name)
                                       ;; declare each variable
                                       (result appendString:<<-END
	#{((type stringValue) stripParens)} #{name};									
END)									
                                       )))
                              (set cursor (cursor cdr)))
                       ;; close the instance variables section
                       (result appendString:<<-END
}							
END)                      
                       (set remainder (cdr (cdr (cdr (cdr declaration)))))
                       (remainder each:
                            (do (group)
                                (if (eq (group car) 'ivar)
                                    ((group cdr) eachPair:
                                     (do (type name)
                                         ;; declare each getter and setter
                                         (result appendString:<<-END
- #{type} #{name};
- (void) set#{((name stringValue) capitalizeFirstCharacter)}: #{type} #{name};	
END)
                                         
                                         )))))
                       ;; close the class interface
                       (result appendString:<<-END
@end

END)
                       )))
          result)
     
     ;; Generate class implementations; usually these are placed in source (.m) files.
     (- (id) generateImplementations is
          (set result ((NSMutableString alloc) init))
          
          (@description each:
               (do (declaration)
                   (if (eq (car declaration) 'class)
                       ;; open the class implementation
                       (result appendString:<<-END
@implementation #{(declaration second)}

END)
                       
                       (set remainder (cdr (cdr (cdr (cdr declaration)))))
                       (remainder each:
                            (do (group)
                                (if (eq (group car) 'ivar)
                                    ((group cdr) eachPair:
                                     (do (type name)
                                         ;; define each getter and setter
                                         (result appendString:<<-END
- #{type} #{name} {return #{name};}

- (void) set#{((name stringValue) capitalizeFirstCharacter)}:#{type} _#{name} {
END)
                                         (if (or (eq type '(id)) (eq (((type stringValue) stripParens) lastCharacter) 42))
                                             (result appendString:<<-END
    [_#{name} retain];
    [#{name} release];
END))
                                         (result appendString:<<-END
    #{name} = _#{name};
}

END))))))
                       
                       ;; define the archiving method
                       (result appendString:<<-END
- (void)encodeWithCoder:(NSCoder *)coder
{
END)
                       (set remainder (cdr (cdr (cdr (cdr declaration)))))
                       (remainder each:
                            (do (group)
                                (if (eq (group car) 'ivar)
                                    ((group cdr) eachPair:
                                     (do (type name)
                                         (result appendString: (self encodeVariable:name withType:type))
                                         (result appendString: (NSString carriageReturn))
                                         )))))
                       (result appendString:<<-END
}

END)
                       
                       ;; define the unarchiving method
                       (result appendString:<<-END
- (id) initWithCoder:(NSCoder *)coder
{
    [super init];
END)
                       (set remainder (cdr (cdr (cdr (cdr declaration)))))
                       (remainder each:
                            (do (group)
                                (if (eq (group car) 'ivar)
                                    ((group cdr) eachPair:
                                     (do (type name)
                                         (result appendString: (self decodeVariable:name withType:type))
                                         (result appendString: (NSString carriageReturn))
                                         )))))
                       (result appendString:<<-END
    return self;
}
                    
END)
                       ;; close the class implementation
                       (result appendString:<<-END
@end

END))))
          result)
     
     ;; Generate code to encode instance variables during archiving.
     (+ (id) encodeVariable:(id) name withType:(id) type is
          (set typeName ((type stringValue) stripParens))
          (cond ((eq typeName "int")
                 "    [coder encodeValueOfObjCType:@encode(int) at:&#{name}];")
                ((eq typeName "double")
                 "    [coder encodeValueOfObjCType:@encode(double) at:&#{name}];")
                ((eq typeName "bool")
                 "    [coder encodeValueOfObjCType:@encode(bool) at:&#{name}];")
                ((eq (typeName lastCharacter) 42)
                 "    [coder encodeObject:#{name}];")
                (t
                  "    [coder encodeValueOfObjCType:@encode(int) at:&#{name}];")))
     
     ;; Generate code to decode instance variables during unarchiving.
     (+ (id) decodeVariable:(id) name withType:(id) type is
          (set typeName ((type stringValue) stripParens))
          (cond ((eq typeName "int")
                 "    [coder decodeValueOfObjCType:@encode(int) at:&#{name}];")
                ((eq typeName "double")
                 "    [coder decodeValueOfObjCType:@encode(double) at:&#{name}];")
                ((eq typeName "bool")
                 "    [coder decodeValueOfObjCType:@encode(bool) at:&#{name}];")
                ((eq (typeName lastCharacter) 42)
                 "    #{name} = [[coder decodeObject] retain];")
                (t
                  "    [coder decodeValueOfObjCType:@encode(int) at:&#{name}];"))))
