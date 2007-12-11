;; @file       bridgesupport.nu
;; @discussion Optionally read constants, enums, and functions from Apple's BridgeSupport files.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(global BridgeSupport (dict frameworks:(dict)	;; remember the frameworks we've read
                            constants:(dict)	;; for each constant, remember its type signature
                            enums:(dict)		;; for each enum, remember its value
                            functions:(dict)))	;; for each function, remember its signature

(macro import 
     (set __framework ((margs car) stringValue))
     (unless ((BridgeSupport valueForKey:"frameworks") valueForKey:__framework)
             (set __path (if (margs cdr) (then (eval ((margs cdr) car))) (else nil)))
             ((BridgeSupport valueForKey:"frameworks") setValue:(load-bridge-support __framework __path) forKey:__framework))
     t)

(function load-bridge-support (framework path)
     (if path 
         (then (set path "#{path}/Resources/BridgeSupport/#{framework}.bridgesupport"))
         (else (set path "/System/Library/Frameworks/#{framework}.framework/Resources/BridgeSupport/#{framework}.bridgesupport")))
     
     (NSLog "importing #{framework} from #{path}")
     
     (set xmlFile (NSString stringWithContentsOfFile:path))
     (if xmlFile 
         (then (set xmlDocument ((NSXMLDocument alloc) initWithXMLString:xmlFile options:0 error:nil))
               
               (((xmlDocument rootElement) nodesForXPath:"depends_on" error:nil) each:
                (do (dependency)
                    (set fileName ((dependency attributeForName:"path") stringValue))
                    (set frameworkName (((fileName lastPathComponent) componentsSeparatedByString:".") objectAtIndex:0))
                    (eval (list 'import frameworkName fileName))))
               
               (set constants (BridgeSupport valueForKey:"constants"))
               (((xmlDocument rootElement) nodesForXPath:"constant" error:nil) each: 
                (do (node) 
                    (constants setValue:((node attributeForName:"type") stringValue)
                         forKey:((node attributeForName:"name") stringValue))))
               
               (set enums (BridgeSupport valueForKey:"enums"))
               (((xmlDocument rootElement) nodesForXPath:"enum" error:nil) each:
                (do (node)
                    (enums setValue:(((node attributeForName:"value") stringValue) intValue)
                           forKey:((node attributeForName:"name") stringValue))))
               
               (set functions (BridgeSupport valueForKey:"functions"))
               (((xmlDocument rootElement) nodesForXPath:"function" error:nil) each:
                (do (node)
                    (set name ((node attributeForName:"name") stringValue))
                    (set argumentTypes "")
                    (set returnType "v")
                    ((node children) each: 
                     (do (child)          
                         (case (child name)
                               ("arg" 
                                      (if (set typeModifier (child attributeForName:"type_modifier"))
                                          (argumentTypes appendString:(typeModifier stringValue)))
                                      (argumentTypes appendString:((child attributeForName:"type") stringValue)))
                               ("retval" (set returnType ((child attributeForName:"type") stringValue)))
                               (else (NSLog "unrecognized type #{(child XMLString)}")))))
                    (set signature "#{returnType}#{argumentTypes}")
                    (functions setValue:signature forKey:name)))
               
               t)
         
         (else t)))
