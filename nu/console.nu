;; @file       console.nu
;; @discussion An interactive Nu console in a Cocoa NSTextView.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
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

(load "nibtools")	;; dependency, needed to insert menu item

(function make-scrollview (frame block)
     (let (v ((NSScrollView alloc) initWithFrame: frame))
          (v set: (autoresizingMask: 18 hasHorizontalScroller: YES hasVerticalScroller: YES borderType: 2))
          (block v)
          v))

(class NSTextStorage
     
     ;; Search back from a closing paren to find its match.
     (imethod (int) findOpeningParenForParenAt:(int) position backTo:(int) startOfInput is
          (let ((count 0)
                (index position)
                (found NO)
                (c nil))
               (while (and (>= index startOfInput) (eq found NO))
                      (set c ((self string) characterAtIndex:index))
                      (case c
                            (LPAREN	(set count (- count 1)))
                            (RPAREN (set count (+ count 1)))
                            (else   nil))
                      (if (eq count 0)
                          (then (set found YES))
                          (else (set index (- index 1)))))
               (if found (then index) (else -1))))
     
     ;; Search forward from an opening paren to find its match.
     (imethod (int) findClosingParenForParenAt:(int) position is
          (let ((count 0)
                (index position)
                (maxindex (self length))
                (found NO)
                (c nil))
               (while (and (< index maxindex) (eq found NO))
                      (set c ((self string) characterAtIndex:index))
                      (case c
                            (LPAREN	(set count (- count 1)))
                            (RPAREN (set count (+ count 1)))
                            (else   nil))
                      (if (eq count 0)
                          (then (set found YES))
                          (else (set index (+ index 1)))))
               (if found (then index) (else -1)))))

;; @abstract Value transformer class for binding to menu item.
;; @discussion This class is part of the Nu console implementation.
;; An instance of this class provides text to a menu item that toggles the display of the Nu console window.
(class NuConsoleShowHideTransformer is NSValueTransformer
     
     ;; Get the class of the transformed value (NSString).
     (cmethod (Class) transformedValueClass is NSString)
     
     ;; Return NO because this transformer does not allow reverse transformation.
     (cmethod (BOOL) allowsReverseTransformation is NO)
     
     ;; Convert a boolean value into an appropriate string for the menu item.
     (imethod (id) transformedValue:(id) v is (if v (then "Hide Nu Console") (else "Show Nu Console"))))

(NSValueTransformer setValueTransformer: ((NuConsoleShowHideTransformer alloc) init)
     forName:"NuConsoleShowHideTransformer")

;; @abstract Console window controller.
;; @discussion This class is part of the Nu console implementation.
;; This class controls a window that contains an interactive Nu console.
(class NuConsoleWindowController is NSWindowController
     (ivar (id) parser (id) showConsole (id) alert (id) console (int) exitWhenClosed)
     
     ;; Setter to use to control the display of the console with bindings.
     (imethod (void) setMyShowConsole:(id) showConsole is (self setValue:showConsole forKey:"showConsole"))
     
     ;; Toggle the console display.
     (imethod (void) toggleConsole:(id) sender is
          (if @showConsole
              (then (self setMyShowConsole:NO)  ((self window) close))
              (else (self setMyShowConsole:YES) ((self window) makeKeyAndOrderFront:self))))
     
     ;; Add a menu item to toggle the console's display.
     (imethod (void) addMenuItem is
          (let (m ((NSMenuItem alloc) initWithTitle:"Toggle Nu Console" action:"toggleConsole:" keyEquivalent:"l"))
               (m setTarget: self)
               (m bind:"title" toObject:self withKeyPath:"showConsole"
                  options:(NSMutableDictionary dictionaryWithList:'("NSValueTransformerName" "NuConsoleShowHideTransformer")))
               (let (windowMenu (((NSApplication sharedApplication) mainMenu) onlyMatchingChild:
                                 (do (x) (and (eq (x className) "NSMenu") (eq (x title) "Window")))))
                    (if windowMenu (windowMenu insertItem:m atIndex:0)))))
     
     ;; Initialize a console.
     (imethod (id) init is
          (self initWithWindow:((NSPanel alloc) initWithContentRect:'(0 0 600 200)
                                styleMask:(+ NSTitledWindowMask NSClosableWindowMask NSMiniaturizableWindowMask NSResizableWindowMask NSUtilityWindowMask)
                                backing:NSBackingStoreBuffered
                                defer:NO))
          (set @console ((NuConsoleViewController alloc) initWithFrame: (list 0 0 (- (third ((self window) frame)) 17) (fourth ((self window) frame)))))
          (self setMyShowConsole:NO)
          (self addMenuItem)
          (set @exitWhenClosed NO)
          (let (w (self window))
               (w setContentView: (make-scrollview ((self window) frame)
                                       (do (sv) (sv setDocumentView: (@console valueForKey:"textview")))))
               (w center)
               (w set: (title:"Nu Console" delegate:self opaque:NO hidesOnDeactivate:NO
                        frameOrigin: (NSValue valueWithPoint: (list (first ((self window) frame)) 80))
                        minSize:     (NSValue valueWithSize:  '(600 100))))
               (if @showConsole
                   (w makeKeyAndOrderFront:self)))
          
          (@console setFonts) ;; apparently this must be done AFTER the window is brought onscreen
          self)
     
     ;; When a window resizes, move the cursor to the end of the input.
     (imethod (void) windowDidResize: (id) notification is
          (@console moveToEndOfInput))
     
     ;; On window close, optionally terminate the application.
     (imethod (void) windowWillClose: (id) notification is
          (if (eq @exitWhenClosed YES) ((NSApplication sharedApplication) terminate:self))
          (self setMyShowConsole:NO))
     
     ;; When a window is to be closed, optionally threaten to terminate the application.
     (imethod (BOOL) windowShouldClose: (id) sender is
          (case @exitWhenClosed
                (NO  YES)
                (YES (set @alert ((NSAlert alloc) init))
                     (let (a @alert)
                          (a setMessageText:"Do you really want to close this console? Your application will exit.")
                          (a setAlertStyle:NSCriticalAlertStyle)
                          (a addButtonWithTitle:"OK")
                          (a addButtonWithTitle:"Cancel")
                          (a beginSheetModalForWindow:(self window)
                             modalDelegate:self
                             didEndSelector:"alertDidEnd:returnCode:contextInfo:"
                             contextInfo:nil))
                     NO)))
     
     ;; Helper for window close alert.
     (imethod (void) alertDidEnd:(id) alert returnCode:(int) code contextInfo:(void *) contextInfo is
          (if (eq code 1000)
              ((self window) close))))

;; @abstract An NSTextView customization for Nu console display.
;; @discussion This class is part of the Nu console implementation.
;; This class provides special handling of key presses in the console.
(class NuConsoleView is NSTextView
     
     ;; Intercept key presses to capture control key sequences that enhance command line editing.
     (imethod (void) keyDown: (id) event is
          (cond ((eq 0  (& (event modifierFlags) NSControlKeyMask)) nil)       ;; do nothing if control key is not pressed
                ((eq 0  (event keyCode)) ((self delegate) moveToStartOfInput)) ;; ctrl-a
                ((eq 14 (event keyCode)) ((self delegate) moveToEndOfInput))   ;; ctrl-e
                (else nil))
          (super keyDown: event)))

;; @abstract A controller for a text view containing a Nu console.
;; @discussion This class is part of the Nu console implementation.
;; It controls a Cocoa text view containing an interactive Nu console.
(class NuConsoleViewController is NSObject
     (ivar (id) textview (id) startOfInput (id) insertionPoint (id) parser (id) history (id) index (id) count (id) chunk)
     
     ;; Initialize a controller with a specified frame.
     (imethod (id) initWithFrame:(NSRect) frame is
          (super init)
          (set @textview ((NuConsoleView alloc) initWithFrame: frame))
          (@textview setAutoresizingMask: (+ NSViewHeightSizable NSViewWidthSizable))
          (@textview set:
               (backgroundColor: (NSColor colorWithDeviceRed:0.8 green:0.8 blue:1.0 alpha:0.9)
                textColor: (NSColor blackColor)
                insertionPointColor: (NSColor blackColor)
                delegate: self))
          (set @startOfInput 0)
          (set @insertionPoint 0)
          (set @parser _parser) ;; _parser is a magic variable, automatically set in the context
          (set $$console self)
          (set @chunk 10)
          (set @count 0)
          (self prompt)
          (set @history ((NSMutableArray alloc) init))
          (set @index -1)
          self)
     
     ;; Get the number of lines to output between handling application events.
     (imethod (id) chunk is @chunk)
     
     ;; Set the number of lines to output between handling application events.
     ;; Setting this higher causes output to display faster, but more erratically.
     (imethod (void) setChunk:(id) chunk is (set @chunk chunk))
     
     ;; Set the console font
     (imethod (void) setFonts is
          (@textview setFont: (NSFont fontWithName:"Monaco" size: 14)))
     
     ;; Get the console prompt.
     (imethod (void) prompt is
          ;; In general, writes move both the insertionPoint and the startOfInput forward,
          ;; but we don't want to do this when we write the prompt.
          (let ((savedInsertionPoint @insertionPoint))
               (if (@parser incomplete)
                   (then (set @insertionPoint @startOfInput)
                         (self write: "- "))
                   (else (self write: "> ")))
               (set @insertionPoint savedInsertionPoint)))
     
     ;; Write text to the console.
     (imethod (void) write: (id) string is
          ((@textview textStorage) replaceCharactersInRange:(list @insertionPoint 0) withString:string)
          (set @insertionPoint (+ @insertionPoint (string length)))
          (set @startOfInput (+ @startOfInput (string length)))
          (@textview scrollRangeToVisible:(list (self lengthOfTextView) 0))
          
          (unless (NuMath integerMod:(set @count (+ @count 1)) by:@chunk)
                  ((NSRunLoop currentRunLoop) runUntilDate:(NSDate date)))
          (self moveToEndOfInput))
     
     ;; Move the console display to a specified point.
     (imethod (void) moveAndScrollToIndex: (id) index is
          (@textview scrollRangeToVisible:(list index 0))
          (@textview setSelectedRange:(list index 0)))
     
     ;; Move the console display and cursor to the beginning of the input area.
     (imethod (void) moveToStartOfInput is
          (self moveAndScrollToIndex:@startOfInput))
     
     ;; Move the console display and cursor to the end of the input area.
     (imethod (void) moveToEndOfInput is
          (self moveAndScrollToIndex:(self lengthOfTextView)))
     
     ;; Get the length of the text view containing the console.
     (imethod (id) lengthOfTextView is
          (((@textview textStorage) mutableString) length))
     
     ;; Get the current line of input to the console.
     (imethod (id) currentLine is
          (let (text ((@textview textStorage) mutableString))
               (text substringWithRange:(list @startOfInput (- (text length) @startOfInput)))))
     
     ;; Replace the current line of input with a line from the input history.
     (imethod (void) replaceLineWithPrevious is
          (cond ((eq @index 0) nil)
                ((eq @index -1) nil)
                (else
                     (set @index (- @index 1))
                     ((@textview textStorage)
                      replaceCharactersInRange:(list @startOfInput (- (self lengthOfTextView) @startOfInput))
                      withString:(@history objectAtIndex: @index))
                     (@textview scrollRangeToVisible:(list (self lengthOfTextView) 0)))))
     
     ;; Replace the current line of input with a line from the input history.
     (imethod (void) replaceLineWithNext is
          (cond ((eq @index (- (@history count) 0)) nil)
                ((eq @index (- (@history count) 1))
                 (set @index (+ @index 1))
                 ((@textview textStorage)
                  replaceCharactersInRange:(list @startOfInput (- (self lengthOfTextView) @startOfInput))
                  withString:"")
                 (@textview scrollRangeToVisible:(list (self lengthOfTextView) 0)))
                (else
                     (set @index (+ @index 1))
                     ((@textview textStorage)
                      replaceCharactersInRange:(list @startOfInput (- (self lengthOfTextView) @startOfInput))
                      withString:(@history objectAtIndex: @index))
                     (@textview scrollRangeToVisible:(list (self lengthOfTextView) 0)))))
     
     ;; Delegate methods to handle text changes.
     (imethod (BOOL) textView:(id) textview shouldChangeTextInRange:(NSRange) range replacementString:(id) replacement is
          ((@textview layoutManager) removeTemporaryAttribute:"NSColor" forCharacterRange:(list 0 (self lengthOfTextView)))
          ((@textview layoutManager) removeTemporaryAttribute:"NSBackgroundColor" forCharacterRange:(list 0 (self lengthOfTextView)))
          ((@textview layoutManager) removeTemporaryAttribute:"NSFont" forCharacterRange:(list 0 (self lengthOfTextView)))
          (cond ((< (first range) @startOfInput) nil)               ;; no edits are allowed before the prompt
                ((and (> (replacement length) 0) (eq (replacement characterAtIndex:(- (replacement length) 1)) RPAREN))
                 ;; add the paren to the view
                 ((@textview textStorage) replaceCharactersInRange:range withString:replacement)
                 ;; look back for the opening paren so the pair can be highlighted.
                 (set match ((@textview textStorage)
                             findOpeningParenForParenAt:(first range)
                             backTo:(if (@parser incomplete) (then 0) (else @startOfInput))))
                 (cond ((and (eq match -1) (eq (@parser incomplete) 0))
                        ;; let's try inserting a paren at the start of the line
                        ((@textview textStorage) replaceCharactersInRange:(list @startOfInput 0) withString:"(")
                        (set highlight (NSMutableDictionary dictionaryWithList:
                                            (list "NSColor"           (NSColor colorWithDeviceRed:0.0 green:0.0 blue:0 alpha:1)
                                                  "NSBackgroundColor" (NSColor colorWithDeviceRed:0.9 green:0.9 blue:0 alpha:1))))
                        ((@textview layoutManager) setTemporaryAttributes:highlight forCharacterRange:(list @startOfInput 1))
                        ((@textview layoutManager) setTemporaryAttributes:highlight forCharacterRange:(list (+ (first range) 1) 1)))
                       ; this code just highlights the unmatched paren in red without trying to fix anything
                       ;(set highlight (NSMutableDictionary dictionaryWithList:
                       ;                    (list "NSColor" ((NSColor redColor) colorWithAlphaComponent:1.0))))
                       ;((@textview layoutManager) setTemporaryAttributes:highlight forCharacterRange:(list (first range) 1)))
                       (else
                            (set highlight (NSMutableDictionary dictionaryWithList:
                                                (list "NSColor"           (NSColor colorWithDeviceRed:0.0 green:0.0 blue:0 alpha:1)
                                                      "NSBackgroundColor" (NSColor colorWithDeviceRed:0.9 green:0.9 blue:0 alpha:1))))
                            ((@textview layoutManager) setTemporaryAttributes:highlight forCharacterRange:(list (first range) 1))
                            ((@textview layoutManager) setTemporaryAttributes:highlight forCharacterRange:(list match 1)))))
                
                ((and (> (replacement length) 0) (eq (replacement characterAtIndex:(- (replacement length) 1)) LPAREN))
                 ;; add the paren to the view
                 ((@textview textStorage) replaceCharactersInRange:range withString:replacement)
                 ;; look back for the opening paren so the pair can be highlighted.
                 (set match ((@textview textStorage) findClosingParenForParenAt:(first range)))
                 (unless (eq match -1)
                         (set highlight (NSMutableDictionary dictionaryWithList:
                                             (list "NSColor"           (NSColor colorWithDeviceRed:0.0 green:0.0 blue:0 alpha:1)
                                                   "NSBackgroundColor" (NSColor colorWithDeviceRed:0.9 green:0.9 blue:0 alpha:1))))
                         ((@textview layoutManager) setTemporaryAttributes:highlight forCharacterRange:(list (first range) 1))
                         ((@textview layoutManager) setTemporaryAttributes:highlight forCharacterRange:(list match 1))))
                
                ((and (> (replacement length) 0) (eq (replacement characterAtIndex:(- (replacement length) 1)) 10))
                 ((@textview textStorage) replaceCharactersInRange:(list (self lengthOfTextView) 0) withString:replacement)
                 (@textview setNeedsDisplay:1)
                 (set stringToEvaluate (self currentLine))
                 (set @startOfInput (self lengthOfTextView))
                 (if (> (stringToEvaluate length) 1)
                     (then
                          (@history addObject:(stringToEvaluate substringToIndex:(- (stringToEvaluate length) 1)))
                          (set @index (@history count))
                          (try
                              (set code (@parser parse: stringToEvaluate))
                              (unless (@parser incomplete)
                                      (set @insertionPoint @startOfInput)
                                      (set result (@parser eval: code))
                                      (if (send result respondsToSelector:"escapedStringRepresentation")
                                          (then (set stringToDisplay (send result escapedStringRepresentation)))
                                          (else (set stringToDisplay (send result stringValue))))
                                      (self write:stringToDisplay)
                                      (self write:"\n"))
                              (catch (exception)
                                     ;; don't use string interpolation here, it calls the parser again
                                     (self write:(exception name))
                                     (self write:": ")
                                     (self write:(exception reason))
                                     (self write:("\n"))
                                     (@parser reset)
                                     (set @insertionPoint @startOfInput))))
                     (else
                          (set @insertionPoint @startOfInput)))
                 (self prompt)
                 nil)       ;; don't insert replacement text because we've already inserted it
                (else YES)))  ;; in the general case, the caller should insert replacement text
     
     ;; Delegate method to approve text changes.
     (imethod (NSRange) textView:(id) textview
          willChangeSelectionFromCharacterRange:(NSRange) oldRange
          toCharacterRange:(NSRange) newRange is
          (if (and (eq (second newRange) 0)
                   (< (first newRange) @startOfInput))
              (then oldRange)
              (else newRange)))
     
     ;; Delegate method to perform actions.
     (imethod (int) textView:(id) textview doCommandBySelector:(SEL) selector is
          (case selector
                ("moveUp:"    (self replaceLineWithPrevious))
                ("moveDown:"  (self replaceLineWithNext))
                (else         nil))))

