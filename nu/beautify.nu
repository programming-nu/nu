;; @file       beautify.nu
;; @discussion Code beautification for Nu.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Radtastical Inc.
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

(global LPAREN '(')
(global RPAREN ')')
(global SPACE  ' ')
(global COLON  ':')
(global TAB    '\x09')
(global DOUBLEQUOTE '"')

(class NSString
 ;; Make a string consisting of the specified number of spaces.
 (+ (id) spaces:(id) count is
    (unless $spaces (set $spaces (NSMutableDictionary dictionary)))
    (unless (set spaces ($spaces objectForKey:count))
            (set spaces "")
            (set c count)
            (unless c (set c 0))
            (while (> c 0)
                   (spaces appendString:" ")
                   (set c (- c 1)))
            ($spaces setObject:spaces forKey:count))
    (NSMutableString stringWithString:spaces))
 
 ;; Make a copy of a string with leading and trailing whitespace removed.
 (- (id) strip is
    (self stringByTrimmingCharactersInSet:(NSCharacterSet whitespaceCharacterSet)))
 
 ;; If a string begins with a label, return the position of the first colon in the string. If not, return 0.
 (- (id) labelColonPosition is
    (set i 0)
    (while (and (< i (self length))
                (ne (self characterAtIndex:i) LPAREN)
                (ne (self characterAtIndex:i) SPACE)
                (ne (self characterAtIndex:i) COLON))
           (set i (+ i 1)))
    (if (and (< i (self length))
             (eq (self characterAtIndex:i) COLON))
        (then i)
        (else 0))))

;; @abstract A Nu code beautifier.
;; @discussion This class is used by nubile, the standalone Nu code beautifier, to automatically indent Nu code.
(class NuBeautifier is NSObject
 
 ;; Beautify a string containing Nu source code. The method returns a string containing the beautified code.
 (+ (id) beautify:(id) text is
    (set b ((NuBeautifier alloc) init))
    (b beautify:text))
 
 ;; Beautify a string containing Nu source code. The method returns a string containing the beautified code.
 (- (id) beautify:(id) text is
    (set result "")
    
    ;; the indentation stack contains one or two values for each level of indentation
    ;; the first is always present and is the position of the leftmost non-whitespace character
    ;; the second is present when there is a label to match and is the position of the label colon
    (set indentation_stack ((NuStack alloc) init))
    (indentation_stack push:(list 0))
    
    ;; expressions that match these patterns get special (fixed-width) indentation
    (set fixed-indent-pattern /\(class /)
    
    (set nube-parser ((NuParser alloc) init))
    (set @olddepth 0)
    
    (set lines (text componentsSeparatedByString:"\n"))
    (lines eachWithIndex:
           (do (input-line line-number)
               ;; indent line to current level of indentation
               (if (or (eq (nube-parser state) 3) ;; parsing a herestring
                       (eq (nube-parser state) 4)) ;; parsing a regex
                   (then (set line input-line))
                   (else (set stripped-line (input-line strip))
                         (if (and ((indentation_stack top) cdr) ;; the previous line started with a label
                                  (set colon-position (stripped-line labelColonPosition)))
                             (then (set spaces (- ((indentation_stack top) second) colon-position)))
                             (else (set spaces ((indentation_stack top) first))))
                         (set line (NSString spaces:spaces))
                         (line appendString:stripped-line)))
               
               (if (eq line-number (- (lines count) 1))
                   (then (result appendString:line))
                   (else (result appendString:line) (result appendString:"\n")))
               
               (try
                   (nube-parser parse:line)
                   (catch (exception)
                          (result appendString:";; ")
                          (result appendString:(exception name))
                          (result appendString:":")
                          (result appendString:(exception reason))
                          (result appendString:"\n")))
               (nube-parser newline)
               
               ;; account for any changes in indentation
               (set indentation_change (- (nube-parser parens) @olddepth))
               (set @olddepth (nube-parser parens))
               (cond ((> indentation_change 0)
                      ;; Going down, compute new levels of indentation, beginning with each unmatched paren.
                      (set positions ((NSMutableArray alloc) init))
                      (set i (- ((nube-parser opens) depth) indentation_change))
                      (while (< i ((nube-parser opens) depth))
                             (positions addObject:((nube-parser opens) objectAtIndex:i))
                             (set i (+ i 1)))
                      ;; For each unmatched paren, find a good place to indent with respect to it.
                      ;; Push that on the indentation stack.
                      (positions each:
                                 (do (p)
                                     (if (fixed-indent-pattern findInString:line)
                                         (then (indentation_stack push:(list (+ p 0))))
                                         (else (set j p)
                                               (set finished nil)
                                               (while (and (< j (line length))
                                                           (not finished))
                                                      (case (line characterAtIndex:j)
                                                            (SPACE  (while (and (< j (line length))
                                                                                (eq (line characterAtIndex:j) SPACE))
                                                                           ;; we reached a space.
                                                                           ;; normally we would indent to the first non-space character after the space
                                                                           (set j (+ j 1)))
                                                                    ;; but if we have a label, we will try to align the colon
                                                                    (set k j)
                                                                    (while (and (< k (line length))
                                                                                (ne (line characterAtIndex:k) DOUBLEQUOTE) ;; ignore colons inside strings
                                                                                (ne (line characterAtIndex:k) SPACE)
                                                                                (ne (line characterAtIndex:k) COLON))
                                                                           (set k (+ k 1)))
                                                                    (if (and (< k (line length))
                                                                             (eq (line characterAtIndex:k) COLON))
                                                                        (then (indentation_stack push:(list j k)))
                                                                        (else (indentation_stack push:(list j))))
                                                                    (set finished YES))
                                                            (LPAREN (indentation_stack push:(list j))
                                                                    (set finished YES))
                                                            (COLON  ;; we're starting with a label. indent at the last paren, but also remember the colon positon
                                                                    (indentation_stack push:(list p j))
                                                                    (set finished YES))
                                                            (else   (set j (+ j 1)))))
                                               (if (and (eq j (line length)) (not finished))
                                                   (indentation_stack push:(list j))))))))
                     ((< indentation_change 0)
                      ;; Going up, pop indentation positions off the stack.
                      ((- 0 indentation_change) times:
                       (do (i) (indentation_stack pop))))
                     (else nil))))
    
    ;; if we have open s-exprs, close them.
    (if (set count (- (indentation_stack depth) 1))
        (count times:(do (i) (result appendString:")"))))
    
    result))
