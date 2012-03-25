;; @file benwanu.nu
;; @discussion Multithreaded visualizer for the Mandelbrot set.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Radtastical Inc.

;; These are a few simple helper functions.
(function min (x y) (if (< x y) (then x) (else y)))
(function max (x y) (if (> x y) (then x) (else y)))
(function NSMaxX (rect) (max (rect first) (+ (rect first) (rect third))))
(function NSMaxY (rect) (max (rect second) (+ (rect second) (rect fourth))))

;; This is the selection region when the program starts.
(set INITIAL '(-0.75 -1.2 3 2.4))

(class NuCell
     ;; For a list representing a point, get the x coordinate.
     (imethod (id) x is (self first))
     ;; For a list representing a point, get the y coordinate.
     (imethod (id) y is (self second))
     ;; For a list representing a size, get the width.
     (imethod (id) width is (self first))
     ;; For a list representing a size, get the height.
     (imethod (id) height is (self second))
     ;; For a list representing a rectangle, get the x coordinate of the origin.
     (imethod (id) origin.x is (self first))
     ;; For a list representing a rectangle, get the y coordinate of the origin.
     (imethod (id) origin.y is (self second))
     ;; For a list representing a rectangle, get the width of the rectangle.
     (imethod (id) size.width is (self third))
     ;; For a list representing a rectangle, get the height of the rectangle.
     (imethod (id) size.height is (self fourth)))

(class NSProgressIndicator 
     ;; Set a progress indicator's value with an NSNumber. Callable using performSelectorOnMainThread:withObject:waitUntilDone:.
     (imethod (void) setObjectValue:(id) value is
          (self setDoubleValue:value)))

(class NSBox
     ;; Set a box's hidden property with an NSNumber. Callable using performSelector:withObject:afterDelay:.
     (imethod (void) setHiddenWithObject:(id) object is
          (self setHidden:object)))

(global SCALE 4) ;; scale factor for zooming in and out

;; @class MandelbrotView
;; @discussion Draws the Mandelbrot set in a user-controllable region.
(class MandelbrotView is NSView
     (ivar (id) progressTextField 
           (id) refreshButton) ;; explicitly declare outlets needed for NIB file
     (ivars)
     (ivar-accessors)
     
     ;; Initialize the view with a specified frame.
     (imethod (id) initWithFrame:(NSRect) frameRect is
          (super initWithFrame:frameRect)
          (set @imageRep nil)        
          (set $view self) ;; this allows us to easily use the console to inspect and reconfigure the view          
          (set @selections ((NuStack alloc) init)) 
          (self setRegion:INITIAL) ;; Start with a nice high-level view of the set
          
          (set @scientificFormatter ((NSNumberFormatter alloc) init))
          (@scientificFormatter setNumberStyle:NSNumberFormatterScientificStyle)
          (@scientificFormatter setMaximumFractionDigits:2)
          (set @twoDigitFormatter ((NSNumberFormatter alloc) init))
          (@twoDigitFormatter set: (format: "#.##"))
          
          self)
     
     ;; Set the selected region for drawing.
     (imethod (void) setRegion:(id) region is
          (set @region region)
          (@selections push:region))
     
     ;; Set the number of threads to use when computing images.  Each server runs in a separate thread.
     (imethod (void) setThreadCount:(id) serverCount is
          (if (eq @serverCount @serversThatAreDone)
              (set @serverCount serverCount)
              (set @serversThatAreDone serverCount)
              (set @servers ((NSMutableArray alloc) init))
              (self makeProgressBox)
              (@serverCount times: 
                   (do (i) 
                       (@servers addObject:((MandelbrotRenderer alloc) 
                                            initWithView:self 
                                            progressBar:(@progressBars objectAtIndex:i)))))
              (self updateTitle)
              (self setNeedsDisplay:YES)))
     
     ;; Update the title bar of the window that contains the view.
     (imethod (void) updateTitle is
          ((self window) setTitle:"#{@serverCount}-way Benwanu origin:#{(self originString)} size:#{(self sizeString)}"))
     
     ;; Construct the progress box used to display server status.
     (imethod (void) makeProgressBox is
          (set HEIGHT 15)
          (set SPACING 5)
          (set BARS @serverCount)
          (set INSET 100)
          (set PADDING 30)
          (set height (+ (* HEIGHT BARS) (* SPACING (- BARS 1)) PADDING)) ;; Q. why add PADDING?? A. there seems to be some padding at the top of the box.
          (set width (- ((self frame) size.width) (* 2 INSET)))
          (set @progressBox ((NSBox alloc) initWithFrame:
                             (list INSET
                                   (* 0.5 (- ((self frame) size.height) height)) 
                                   width
                                   height)))
          (@progressBox set: (autoresizingMask:(+ NSViewMinXMargin NSViewMaxXMargin NSViewMinYMargin NSViewMaxYMargin)
                              borderType:NSNoBorder
                              title:""
                              contentViewMargins:(NSValue valueWithSize:'(0 0))
                              hidden:YES))
          (self setNeedsDisplay:YES)
          (self addSubview:@progressBox)
          (set @progressBars (NSMutableArray array))
          (BARS times: 
                (do (i)
                    (set bar ((NSProgressIndicator alloc) initWithFrame:
                              (list 
                                    0
                                    (- height (+ PADDING HEIGHT (* i (+ HEIGHT SPACING))))
                                    width
                                    HEIGHT)))
                    (bar setIndeterminate:NO)
                    (@progressBars << bar)
                    (@progressBox addSubview: bar)))
          nil)
     
     ;; Draw the Mandelbrot set image.
     (imethod (void) drawRect: (NSRect) rect is 
          ((NSColor whiteColor) set)
          (NSBezierPath fillRect:(self bounds))
          (if (eq @serversThatAreDone @serverCount)
              (then
                   (self drawImageProportionally:@imageRep)
                   (if @dragging 
                       ((NSColor redColor) set)
                       (NSBezierPath strokeRect:(self selectedRect))))
              (else
                   (if @oldImageRep (self drawImageProportionally:@oldImageRep)))))
     
     ;; This helper for drawRect: positions the image so that it is draw with equal scaling in the X and Y directions.
     (imethod (void) drawImageProportionally:(id) image is
          ;; resquare region to current view size
          ;; this is to keep the x and y scales the same
          (set viewAspectRatio 
               (/ ((self bounds) size.width) ((self bounds) size.height)))
          (set imageAspectRatio
               (/ ((image size) width) ((image size) height)))   
          (cond
               ((> viewAspectRatio imageAspectRatio) ;; view is too wide, reduce view width
                (set vw (* ((self bounds) size.height) imageAspectRatio))
                (set vx (+ ((self bounds) origin.x) (* 0.5 (- ((self bounds) size.width) vw))))
                (image drawInRect: (list vx
                                         ((self bounds) origin.y)
                                         vw
                                         ((self bounds) size.height))))                  
               ((< viewAspectRatio imageAspectRatio) ;; view is too tall, reduce view height
                (set vh (/ ((self bounds) size.width) imageAspectRatio))
                (set vy (+ ((self bounds) origin.y) (* 0.5 (- ((self bounds) size.height) vh))))
                (image drawInRect: (list ((self bounds) origin.x)
                                         vy
                                         ((self bounds) size.width)
                                         vh)))
               (else (image drawInRect:(self bounds)))))
     
     ;; Override the default and accept the first mouse click in the view.
     (imethod (BOOL) acceptsFirstMouse:(id) event is YES)
     
     ;; Override the defautl and accept key clicks in the view.
     (imethod (BOOL) acceptsFirstResponder is YES)
     
     ;; Handle mouse down events.  A mouse down indicates the start of a selection for zooming.
     (imethod (void) mouseDown:(id) event is          
          (if (eq @serversThatAreDone @serverCount) ;; Ignore drags while servers are working
              (set @dragging YES)
              (self setDownPoint:(self convertPoint:(event locationInWindow) fromView:nil))
              (self setCurrentPoint:@downPoint)))
     
     ;; Handle mouse dragged events.  Updates the selection rectangle and triggers a redraw.
     (imethod (void) mouseDragged:(id) event is     
          (if @dragging
              (self setCurrentPoint:(self convertPoint:(event locationInWindow) fromView:nil))
              (self setNeedsDisplay:YES)))
     
     ;; Handle mouse up events.  If the selection region is large enough, zoom the view.
     (imethod (void) mouseUp:(id) event is
          (if @dragging
              (set @dragging NO)
              (self setCurrentPoint:(self convertPoint:(event locationInWindow) fromView:nil))
              (set bounds    (self bounds))
              (set selection (self selectedRect))        
              (set original  (self region))
              ;; Calculate scaled region as if in the unit square
              (set scaled (list (/ (selection origin.x) (bounds size.width))
                                (/ (selection origin.y) (bounds size.height))
                                (/ (selection size.width) (bounds size.width))
                                (/ (selection size.height) (bounds size.height))))
              
              ;; rescale if the new region is big enough
              (if (and (> (scaled size.width) 0.005)
                       (> (scaled size.height) 0.005))
                  (then 
                        ;; Compute new region, scaling to region's size
                        (self setRegion: (list (+ (original origin.x)  (* (original size.width) (scaled origin.x)))
                                               (+ (original origin.y) (* (original size.height) (scaled origin.y)))
                                               (* (original size.width)  (scaled size.width))
                                               (* (original size.height) (scaled size.height))))              
                        (self refreshImage:self))
                  (else
                       (self setCurrentPoint:nil)
                       (self setDownPoint:nil)
                       (self setNeedsDisplay:YES)))))
     
     ;; Handle key down events that mainly control the selection to be displayed.
     (imethod (void) keyDown:(id) event is
          (if (eq @serversThatAreDone @serverCount) ;; Ignore movement keypresses while servers are working
              (case (event keyCode) ;; is there a comprehensive list of these somewhere? I haven't found it yet.
                    (31 ;; "o" is for out
                        (set original (self region))
                        (self setRegion:
                              (list (- (original origin.x) (* (- SCALE 1) (original size.width) 0.5))
                                    (- (original origin.y) (* (- SCALE 1) (original size.height) 0.5))
                                    (* SCALE (original size.width))
                                    (* SCALE (original size.height))))
                        (self refreshImage:self))
                    (34 ;; "i" is for in
                        (set original (self region))
                        (self setRegion:
                              (list (+ (original origin.x) (* (- SCALE 1) (original size.width) 0.5 (/ 1 SCALE)))
                                    (+ (original origin.y) (* (- SCALE 1) (original size.height) 0.5 (/ 1 SCALE)))
                                    (/ (original size.width) SCALE)
                                    (/ (original size.height) SCALE)))
                        (self refreshImage:self))                
                    (32 ;; "u" is for undo
                        (set prior (@selections pop))
                        (if (@selections depth) 
                            (then (self setRegion: (@selections pop))
                                  (self refreshImage:self))
                            (else (@selections push:prior))))
                    (123 ;; left arrow
                         (set original (self region))
                         (self setRegion:
                               (list (- (original origin.x) (* 0.25 (original size.width)))
                                     (original origin.y)
                                     (original size.width)
                                     (original size.height)))
                         (self refreshImage:self))
                    (124 ;; right arrow
                         (set original (self region))
                         (self setRegion:
                               (list (+ (original origin.x) (* 0.25 (original size.width)))
                                     (original origin.y)
                                     (original size.width)
                                     (original size.height)))
                         (self refreshImage:self))
                    (125 ;; down arrow
                         (set original (self region))
                         (self setRegion:
                               (list (original origin.x)
                                     (- (original origin.y) (* 0.25 (original size.height)))
                                     (original size.width)
                                     (original size.height)))
                         (self refreshImage:self))
                    (126 ;; up arrow
                         (set original (self region))
                         (self setRegion:
                               (list (original origin.x)
                                     (+ (original origin.y) (* 0.25 (original size.height)))
                                     (original size.width)
                                     (original size.height)))
                         (self refreshImage:self))
                    (3 ;; "f" is for "fit"
                       (self setRegion:INITIAL)
                       (self refreshImage:self))
                    (else 
                          (puts "key: #{(event keyCode)}")
                          nil))))
     
     (imethod recenter is
          (self setRegion:INITIAL)
          (self refreshImage:self))
     
     
     ;; Get the currently selected rectangle, valid while a user is dragging a rectangle.
     (imethod (NSRect) selectedRect is
          (set downPoint @downPoint)
          (set currentPoint @currentPoint)
          (set minX (min (downPoint x) (currentPoint x)))
          (set maxX (max (downPoint x) (currentPoint x)))
          (set minY (min (downPoint y) (currentPoint y)))
          (set maxY (max (downPoint y) (currentPoint y)))
          (list minX minY (- maxX minX) (- maxY minY)))
     
     ;; Each server thread should call this method (using performSelectorOnMainThread:withObject:waitUntilDone:) when it completes.
     (imethod (void) serverIsDone:(id) sender is
          (set @serversThatAreDone (+ 1 @serversThatAreDone))		
          (@progressTextField setStringValue:"#{@serversThatAreDone} servers are done")
          (if (eq @serversThatAreDone @serverCount) 
              (set duration ((NSDate date) timeIntervalSinceDate:@startTime))        
              (@progressTextField setStringValue:<<-END
Computation complete (#{(@twoDigitFormatter stringFromNumber:duration)}s)
View origin is #{(self originString)} and size is #{(self sizeString)}.END)
              (@refreshButton setEnabled:YES)
              (@progressBox performSelector:"setHiddenWithObject:" withObject:YES afterDelay:1)
              (self setNeedsDisplay:YES)))
     
     ;; Get a string that represents the origin of the view rectangle in the Mandelbrot Set coordinate space.
     (imethod (id) originString is
          "(#{(@twoDigitFormatter stringFromNumber:(@region origin.x))}, #{(@twoDigitFormatter stringFromNumber:(@region origin.y))})")
     
     ;; Get a string that represents the size of the view rectangle in the Mandelbrot Set coordinate space.
     (imethod (id) sizeString is
          "#{(@scientificFormatter stringFromNumber:(@region size.width))}x#{(@scientificFormatter stringFromNumber:(@region size.height))}")
     
     ;; Begin recalculating the image using multiple server threads.
     (imethod (void) refreshImage:(id) sender is         
          (@progressTextField setStringValue:@"Computation starting")
          (@refreshButton setEnabled:NO)
          (@progressBars each: (do (b) (b setDoubleValue:0)))
          (@progressBox setHidden:NO)
          (set @oldImageRep @imageRep) ;; draw the old image while the new one is being computed
          (self setNeedsDisplay:YES)
          
          (set @startTime (NSDate date))
          (set @serversThatAreDone 0)
          (set bounds (self bounds))
          (set pixelsHigh (bounds size.height))
          (set pixelsWide (bounds size.width))
          
          ;; resquare region to current view size
          ;; this is to keep the x and y scales the same
          (set viewAspectRatio 
               (/ ((self frame) size.width) ((self frame) size.height)))
          (set regionAspectRatio
               (/ (@region size.width) (@region size.height)))     
          (cond
               ((> viewAspectRatio regionAspectRatio) ;; view is too wide, expand region width
                (set rw (* (@region size.height) viewAspectRatio))
                (set rx (- (@region origin.x) (* 0.5 (- rw (@region size.width)))))
                (set @region (list rx
                                   (@region origin.y)
                                   rw
                                   (@region size.height))))
               
               ((< viewAspectRatio regionAspectRatio) ;; view is too tall, expand region height
                (set rh (/ (@region size.width) viewAspectRatio))
                (set ry (- (@region origin.y) (* 0.5 (- rh (@region size.height)))))
                (set @region (list (@region origin.x)
                                   ry
                                   (@region size.width)
                                   rh)))
               (else nil))
          
          (self updateTitle)
          ;; The image may be a few pixels shorter than the view.
          ;; Benefit:  all servers draw the same number of rows.
          (set remainder (NuMath integerMod:pixelsHigh by: @serverCount))
          (set pixelsHigh (- pixelsHigh remainder))
          (set rowsPerServer (NuMath integerDivide:pixelsHigh by:@serverCount))
          
          ;; Create the image rep the servers will draw on
          (set @imageRep ((NSBitmapImageRep alloc)
                          initWithBitmapDataPlanes:nil
                          pixelsWide:pixelsWide
                          pixelsHigh:pixelsHigh
                          bitsPerSample:8
                          samplesPerPixel:3
                          hasAlpha:NO
                          isPlanar:NO
                          colorSpaceName:"NSDeviceRGBColorSpace"
                          bytesPerRow:(* pixelsWide 3)
                          bitsPerPixel:0))
          
          (set maxY (NSMaxY @region))
          (set maxX (NSMaxX @region))
          (set deltaY (/ (@region size.height) @serverCount))
          
          ;; Ask each server to draw a set of rows.
          (@serverCount times:
               (do (i)
                   (set iMaxY (- maxY (* i deltaY)))
                   ;; Assign a region to the server
                   ((@servers objectAtIndex:i) set: (imageRep: @imageRep
                                                     offset: i
                                                     minX: (@region origin.x)
                                                     minY: (- iMaxY deltaY)
                                                     maxX: maxX
                                                     maxY: iMaxY
                                                     width: pixelsWide
                                                     height: rowsPerServer))
                   ;; Run the server in a separate thread.
                   (NSThread detachNewThreadSelector:"fillRegion:"
                        toTarget:(@servers objectAtIndex:i) 
                        withObject:self)))
          (@progressTextField setStringValue:"Computation started"))
     
     ;; Open a save panel to save the image to a file.
     (imethod (void) saveImage:(id) sender is
          (set panel (NSSavePanel savePanel))
          (panel setRequiredFileType:"png")
          (panel beginSheetForDirectory:nil
                 file:nil
                 modalForWindow:(self window)
                 modalDelegate:self
                 didEndSelector:"didEnd:returnCode:contextInfo:"
                 contextInfo:nil))     
     
     ;; This callback method is called when the saveImage: panel is closed.
     ;; If a file was specified, it writes the image to that file.
     (imethod (void) didEnd:(id) sheet returnCode:(int) code contextInfo:(void *) info is
          (if (eq code NSOKButton)
              ((@imageRep representationUsingType:NSPNGFileType properties:nil)
               writeToFile:(sheet filename) atomically:NO))))


;; import C helper function.  It could be an imethod of MandelbrotRenderer, but this is more fun to demonstrate.
(set fillRegion	(NuBridgedFunction functionWithName:"fillRegion" signature:"v@iddddii@"))

;; @class MandelbrotRenderer
;; @discussion Calculate a section of the selected image region in a separate thread.
(class MandelbrotRenderer is NSObject
     (ivar (id) view 
           (id) progressBar
           (id) imageRep
           (int) offset
           (double) minX
           (double) minY 
           (double) maxX 
           (double) maxY 
           (int) width 
           (int) height) ;; explicitly declaring these allows KV setting (above)
     
     ;; Initialize the server with a specific view and progress bar.
     ;; The view and progress bar will receive messages from the server
     ;; as it proceeds.
     (imethod (id) initWithView:(id) view progressBar:(id) progressBar is
          (super init)
          (set @view view)
          (set @progressBar progressBar)
          self)
     
     ;; Helper method that sets the progress indicator to a specified value.
     ;; This method is called from the C function that calculates the point values in the Mandelbrot Set.
     (imethod (void) setProgress:(id) progress is
          (@progressBar performSelectorOnMainThread:"setObjectValue:" withObject:progress waitUntilDone:NO))
     
     ;; Calculate the Mandelbrot Set points according to the current server configuration.
     ;; The server is configured using KV setters for its instance variables.
     ;; This method calls a helper function written in C.  When it finishes,
     ;; it sends a message to the main thread using performSelectorOnMainThread:withObject:waitUntilDone:.
     (imethod (void) fillRegion:(id) sender is
          (fillRegion @imageRep @offset @minX @minY @maxX @maxY @width @height self)
          (self setProgress:100)
          (@view performSelectorOnMainThread:"serverIsDone:" withObject:self waitUntilDone:NO)))

;; @class MandelbrotWindowController
;; @discussion Controller for the Mandelbrot set viewer.
(class MandelbrotWindowController is NSWindowController
     (ivars)
     (ivar-accessors)
     
     ;; Initialize a controller by creating its window and all of the window's contents.
     ;; This method could load a window from a nib file, but in this case, all interface
     ;; elements are created directly within Nu.
     (imethod (id) init is
          (set mainFrame (list 0 0 640 560))
          (set styleMask (+ NSTitledWindowMask NSClosableWindowMask NSMiniaturizableWindowMask NSResizableWindowMask))
          (self initWithWindow:((NSWindow alloc) initWithContentRect:mainFrame styleMask:styleMask backing:NSBackingStoreBuffered defer:NO))
          (set @exitWhenClosed NO)
          (let (w (self window))
               (w center)
               (w set: (title:"Benwanu" delegate:self opaque:NO hidesOnDeactivate:NO
                        frameOrigin: (NSValue valueWithPoint: (list 200 (- (((w screen) frame) size.height) 
                                                                           (+ 200 ((w frame) size.height)))))
                        minSize:     (NSValue valueWithSize:  '(640 582))
                        contentView: ((NSView alloc) initWithFrame:mainFrame)))
               
               (set @view ((MandelbrotView alloc) initWithFrame:'(20 60 600 480)))
               ((w contentView) addSubview:@view)
               (@view setAutoresizingMask:(+ NSViewWidthSizable NSViewHeightSizable))
               
               (set tf ((NSTextField alloc) initWithFrame:'(14 11 420 44)))
               (tf set: (bordered:NO editable:NO drawsBackground:NO 
                         alignment:NSLeftTextAlignment autoresizingMask:NSViewMaxXMargin))
               ((w contentView) addSubview:tf)
               
               (set b ((NSButton alloc) initWithFrame:'(469 12 157 32)))
               (b set: (title:"Refresh Image" bezelStyle:NSRoundedBezelStyle action:"refreshImage:" target:@view autoresizingMask:NSViewMinXMargin))
               ((w contentView) addSubview:b)
               
               (@view setProgressTextField:tf)
               (@view setRefreshButton:b)
               (@view setThreadCount:8)
               (@view refreshImage:self)
               
               (w makeKeyAndOrderFront:self))
          self))

;; This list describes the application menu.  It is used in the application delegate's 
;; applicationDidFinishLaunching: method to construct the application menus.  You
;; could also load your menu from a nib file, but IB is so slow... :-)
(set benwanu-application-menu
     '(menu "Main"
            (menu "Application"
                  ("About #{appname}" action:"orderFrontStandardAboutPanel:")
                  (separator)
                  (menu "Services")
                  (separator)
                  ("Hide #{appname}" action:"hide:" key:"h")
                  ("Hide Others" action:"hideOtherApplications:" key:"h" modifier:(+ NSAlternateKeyMask NSCommandKeyMask))
                  ("Show All" action:"unhideAllApplications:")
                  (separator)
                  ("Quit #{appname}" action:"terminate:" key:"q"))
            (menu "File"
                  ("New" action:"newView:" target:$delegate key:"n")
                  ("Save" action:"saveView:" target:$delegate key:"s")
                  ("Close" action:"performClose:" key:"w"))
            (menu "Threads"
                  ("1" action:"setThreadCountFromMenuItem:" target:$delegate key:"1")
                  ("2" action:"setThreadCountFromMenuItem:" target:$delegate key:"2")
                  ("3" action:"setThreadCountFromMenuItem:" target:$delegate key:"3")
                  ("4" action:"setThreadCountFromMenuItem:" target:$delegate key:"4")
                  ("5" action:"setThreadCountFromMenuItem:" target:$delegate key:"5")
                  ("6" action:"setThreadCountFromMenuItem:" target:$delegate key:"6")
                  ("7" action:"setThreadCountFromMenuItem:" target:$delegate key:"7")
                  ("8" action:"setThreadCountFromMenuItem:" target:$delegate key:"8"))
            (menu "Window"
                  ("Minimize" action:"performMiniaturize:" key:"m")
                  (separator)
                  ("Bring All to Front" action:"arrangeInFront:"))
            (menu "Help"
                  ("#{appname} Help" action:"showHelp:" key:"?"))))

