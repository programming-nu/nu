;; @file       nibtools.nu
;; @discussion Nu helpers for manipulating Cocoa objects.  
;; These are especially useful for working with objects loaded from nib files.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class NSObject
     ;; Get the children of an object.  By default, NSObjects have no children.
     (imethod (id) children is nil)
     
     ;; Return a collection of objects from the object child-hierarchy rooted at the current object.
     ;; Objects must match criteria in the provided block.
     ;; For example, to return all the NSButton objects in a specified view, use:
     ;;
     ;;    <code>(myView allMatchingChildren: (do (v) (v isKindOfClass: NSButton)))</code>
     (imethod (id) allMatchingChildren: (id) block is
          (set matches ((NSMutableArray alloc) init))
          (if (block self)
              (matches addObject:self))
          (if (self children)
              ((self children) each: (do (child) (matches addObjectsFromArray: (child allMatchingChildren: block)))))
          matches)
     
     ;; Return one object from the object child-hierarchy rooted at the current object.
     ;; The object must match criteria in the provided block.
     ;; For example, to return the NSButton object in a specified view, use:
     ;;
     ;;    <code>(myView onlyMatchingChild: (do (v) (v isKindOfClass: NSButton)))</code>
     (imethod (id) onlyMatchingChild: (id) block is
          (set results (self allMatchingChildren: block))
          (results objectAtIndex:0)))

(class NSView
     ;; The children of a view are its subviews.
     (imethod (id) children is
          (append (super children) ((self subviews) list))))

(class NSTableView
     ;; The children of a table view are its table columns.
     (imethod (id) children is
          (append (super children) ((self tableColumns) list))))

(class NSWindow
     ;; The child of a window is its contentView.
     (imethod (id) children is
          (append (super children) (list (self contentView)))))

(class NSWindowController
     ;; The child of a window controller is its window.
     (imethod (id) children is
          (append (super children) (list (self window)))))

(class NSApplication
     ;; The children of an application are its menu and its windows.
     (imethod (id) children is
          (append (super children) (list (self mainMenu)) ((self windows) list))))

(class NSMenu
     ;; The children of a menu are its items.
     (imethod (id) children is
          (append (super children) ((self itemArray) list))))

(class NSMenuItem
     ;; The children of a menu item are its submenus.
     (imethod (id) children is
          (if (self submenu) 
              (then (append (super children) (list (self submenu))))
              (else (super children)))))
