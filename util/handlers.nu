;; Use this script to generate precompiled configurable method handlers.
;; Copyright 2008, Tim Burks, Neon Design Technology, Inc.
;; Released under the Apache License, 2.0.

(load "template")

(function generate-handlers-for-type (type count)
     (set lower (type lowercaseString))
     (eval (NuTemplate codeForString:<<-END
struct handler_description nu_handlers_returning_<%= lower %>[<%= count %>];
<% (count times:(do (i) %>
static <%= type %> nu_handler_returning_<%= lower %>_<%= i %> (id receiver, SEL selector, ...) 
{ 
    va_list ap; 
    va_start(ap, selector); 
    <% (if (!= type "void") %><%= type %> result;<% ) %>
    nu_handler(<% (if (!= type "void") then %>&result<% else %>0<% ) %>, &nu_handlers_returning_<%= lower %>[<%= i %>], receiver, ap); 
    <% (if (!= type "void") %>return result;<% ) %>
}
<% )) %>
void nu_init_handlers_returning_<%= lower %>() {<% (count times:(do (i) %>
    nu_handlers_returning_<%= lower %>[<%= i %>].handler = (IMP) nu_handler_returning_<%= lower %>_<%= i %>;<% )) %>
}
END)))

(function generate-handlers (class-name handlers)
     (eval (NuTemplate codeForString:<<-END
#ifdef IPHONE
#import "handler.h"  
#import <CoreGraphics/CoreGraphics.h>

<% (handlers each:(do (group) %> 
<%= (generate-handlers-for-type (group 0) (group 2)) %>
<% )) %>

@interface <%= class-name %> : NSObject { }
@end
@implementation <%= class-name %>
+ (void) load {
<% (handlers each:(do (group) %>
    nu_init_handlers_returning_<%= ((group 0) lowercaseString) %> ();
    [NuHandlerWarehouse registerHandlers:nu_handlers_returning_<%= ((group 0) lowercaseString) %> withCount:<%= (group 2) %> forReturnType:@"<%= (group 1) %>"];
<% )) %>
}
@end
#endif
END)))

(set source
     (generate-handlers "NuHandlerWarehouseLoader"
          '(("void" "v" 400)
            ("id" "@" 400)
            ("int" "i" 400)
            ("float" "f" 100)
            ("double" "d" 100)
            ("CGRect" "{_CGRect={_CGPoint=ff}{_CGSize=ff}}" 20)
            ("CGPoint" "{_CGPoint=ff}" 20)
            ("CGSize" "{_CGSize=ff}" 20)
            ("NSRange" "{_NSRange=II}" 20))))

(source writeToFile:"handlers.m" atomically:NO)


