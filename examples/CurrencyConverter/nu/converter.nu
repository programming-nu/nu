;; converter.nu
;;  Ubiquitous Cocoa currency converter example ported to Nu.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class ConverterController is NSObject
     (ivar (id) window (id) form)
     
     (imethod (id) init is
          (super init)
          
          (set @window ((NSWindow alloc)
                        initWithContentRect:'(125 513 383 175)
                        styleMask:(+ NSTitledWindowMask NSClosableWindowMask NSMiniaturizableWindowMask)
                        backing:NSBackingStoreBuffered
                        defer:0))
          (@window setTitle:"Currency Converter")
          
          (let (form ((NSForm alloc) initWithFrame:'(15 70 348 85)))
               
               ('("Exchange Rate per $1" "Dollars to Convert" "Amount in Other Currency") each:
                 (do (text) (form addEntry:text)))
               
               (form set: (interlineSpacing:9 autosizesCells:1 target:self action:"convert:"))
               
               ((@window contentView) addSubview:form)
               (set @form form))
          
          ((@window contentView) addSubview:((NSBox alloc) initWithFrame:'(15 59 353 2)))
          
          (let (button ((NSButton alloc) initWithFrame:'(247 15 90 30)))
               (button set: (bezelStyle:NSRoundedBezelStyle title:"Convert" keyEquivalent:"\r" target:self action:"convert:"))
               ((@window contentView) addSubview:button))
          
          (@window orderFront:nil)
          self)
     
     (imethod (void) convert: (id) sender is
          ((@form cellAtIndex:2) setStringValue: ((* ((@form cellAtIndex:0) floatValue)
                                                     ((@form cellAtIndex:1) floatValue))
                                                  stringValue))))
