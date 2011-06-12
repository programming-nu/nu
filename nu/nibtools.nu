;; @file       nibtools.nu
;; @discussion Nu helpers for manipulating Cocoa objects.
;; These are especially useful for working with objects loaded from nib files.
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

(class NSObject
     ;; Get the children of an object.  By default, NSObjects have no children.
     (- (id) children is nil)
     
     ;; Return a collection of objects from the object child-hierarchy rooted at the current object.
     ;; Objects must match criteria in the provided block.
     ;; For example, to return all the NSButton objects in a specified view, use:
     ;;
     ;;    <code>(myView allMatchingChildren: (do (v) (v isKindOfClass: NSButton)))</code>
     (- (id) allMatchingChildren: (id) block is
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
     (- (id) onlyMatchingChild: (id) block is
          (set results (self allMatchingChildren: block))
          (results objectAtIndex:0)))

(class NSView
     ;; The children of a view are its subviews.
     (- (id) children is
          (append (super children) ((self subviews) list))))

(class NSTableView
     ;; The children of a table view are its table columns.
     (- (id) children is
          (append (super children) ((self tableColumns) list))))

(class NSWindow
     ;; The child of a window is its contentView.
     (- (id) children is
          (append (super children) (list (self contentView)))))

(class NSWindowController
     ;; The child of a window controller is its window.
     (- (id) children is
          (append (super children) (list (self window)))))

(class NSApplication
     ;; The children of an application are its menu and its windows.
     (- (id) children is
          (append (super children) (list (self mainMenu)) ((self windows) list))))

(class NSMenu
     ;; The children of a menu are its items.
     (- (id) children is
          (append (super children) ((self itemArray) list))))

(class NSMenuItem
     ;; The children of a menu item are its submenus.
     (- (id) children is
          (if (self submenu)
              (then (append (super children) (list (self submenu))))
              (else (super children)))))
