;; @file       cocoa.nu
;; @discussion Global constants useful for programming in Cocoa.
;; Currently, these are manually set, but in the future,
;; they may be read from Mac OS 10.5's Bridge Support files.
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

(macro bridge (kind name signature)
     (case kind
           ('constant
                     `(global ,name (NuBridgedConstant constantWithName:(',name stringValue) signature:,signature)))
           ('function
                     `(global ,name (NuBridgedFunction functionWithName:(',name stringValue) signature:,signature)))
           (else
                `(NSLog "invalid argument to bridge: '#{,kind}'"))))

(bridge function NSLog "v@")
(bridge function NSApplicationMain "ii^*")
(bridge function NSRectFill "v{_NSRect}")

(bridge constant NSDefaultRunLoopMode "@")
(bridge constant NSForegroundColorAttributeName "@")
(bridge constant NSFontAttributeName "@")
(bridge constant NSSQLiteStoreType "@")
(bridge constant NSXMLStoreType "@")
(bridge constant NSBinaryStoreType "@")
(bridge constant NSInMemoryStoreType "@")

(global NSBorderlessWindowMask          0)
(global NSTitledWindowMask            	1)
(global NSClosableWindowMask          	2)
(global NSMiniaturizableWindowMask    	4)
(global NSResizableWindowMask         	8)
(global NSUtilityWindowMask				(<< 1 4))
(global NSBackingStoreBuffered        	2)
(global NSRoundedBezelStyle           	1)
(global NSCenterTextAlignment         	2)
(global NSMappedRead 					1)
(global NSUncachedRead 					2)
(global NSOKButton 						1)
(global NSCancelButton 					0)
(global NSTableViewLastColumnOnlyAutoresizingStyle 4)
(global NSTableColumnAutoresizingMask 	(<< 1 0))
(global NSTableColumnUserResizingMask 	(<< 1 1))
(global NSControlKeyMask              	(<< 1 18))
(global NSAlternateKeyMask            	(<< 1 19))
(global NSCommandKeyMask              	(<< 1 20))
(global NSASCIIStringEncoding			1)
(global NSUTF8StringEncoding			4)
(global NSKeyDown                     	10)
(global NSAnyEventMask					0xffffffff)
(global NSWarningAlertStyle           	0)
(global NSInformationalAlertStyle     	1)
(global NSCriticalAlertStyle          	2)
(global NSViewNotSizable     			0)
(global NSViewMinXMargin     			1)
(global NSViewWidthSizable   			2)
(global NSViewMaxXMargin     			4)
(global NSViewMinYMargin     			8)
(global NSViewHeightSizable  			16)
(global NSViewMaxYMargin     			32)
(global NSLeftTextAlignment      		0)
(global NSRightTextAlignment     		1)
(global NSCenterTextAlignment    		2)
(global NSJustifiedTextAlignment 		3)
(global NSNaturalTextAlignment   		4)
(global NSNumberFormatterScientificStyle 4)
(global NSNoBorder 						0)
(global NSTIFFFileType 					0)
(global NSBMPFileType 					1)
(global NSGIFFileType 					2)
(global NSJPEGFileType 					3)
(global NSPNGFileType 					4)
(global NSOrderedAscending 				-1)
(global NSOrderedSame       			0)
(global NSOrderedDescending 			1)

