;; test_xml.nu
;;  tests for Nu usage of NSXMLDocument.
;;
;;  Copyright (c) 2011 Tim Burks, Radtastical Inc.

(unless (eq (uname) "iOS")
        
        (class TestXML is NuTestCase
             
             (- (id) testNoCrash is
                (set xmlText "<sample><one/><two/><three/></sample>")
                (set xmlData (xmlText dataUsingEncoding:NSUTF8StringEncoding))
                (set doc ((NSXMLDocument alloc) initWithData:xmlData options:0 error:nil)))))
