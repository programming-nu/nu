;; growl.nu
;;  Use Growl from Nu.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

;; This example requires Growl and the Growl SDK.
;; Install and start Growl, then get Growl.framework
;; from the SDK.
;; You can put Growl.framework in a shared place:
(try
    (load "/Library/Frameworks/Growl")
    (catch (exception)
           (NSLog "Growler: Please install Growl to run this example.  See growl.nu for details.")
           ((NSApplication sharedApplication) terminate:0)))
;; or you can put Growl.framework in your application bundle in
;; the Contents/Frameworks directory and load it like this:
;(set path (((NSBundle mainBundle) privateFrameworksPath) 
;           stringByAppendingPathComponent:"Growl.framework"))
;(set bundle (NSBundle bundleWithPath:path))
;(bundle load)

;; @class NuGrowlDelegate
;; @discussion Growl requires a delegate object to control its interaction with
;; an application. This is an example.  See each method's comments for details.
;; Method comments were taken from the Growl SDK documentation.
(class NuGrowlDelegate is NSObject   
     (ivar (id) registrationDictionary)
     
     ; The returned dictionary gives Growl the complete list of notifications this application will ever send,
     ; and it also specifies which notifications should be enabled by default. 
     ; For most applications, these two arrays can be the same 
     ; (if all sent notifications should be displayed by default). 
     ; The NSString objects in these arrays are notification names, 
     ; and thus will correspond to the notificationName: 
     ; parameter passed into the 
     ;   +[GrowlApplicationBridge notifyWithTitle::::::::] calls.
     ;
     ; The dictionary should have at least 2 key object pairs:
     ;   GROWL_NOTIFICATIONS_ALL ("AllNotifications"): An NSArray of all possible names of notifications.
     ;   GROWL_NOTIFICATIONS_DEFAULT ("DefaultNotifications"): An NSArray of notifications enabled by default 
     ;   (either by name, or by index into the GROWL_NOTIFICATIONS_ALL array).
     ; All of the keys for registration dictionaries are defined in GrowlDefines.h.
     (imethod (id) registrationDictionaryForGrowl is
          (unless @registrationDictionary
                  (set @registrationDictionary
                       (NSMutableDictionary dictionaryWithList:
                            (list "AllNotifications" (NSArray arrayWithObject:"NuGrowl")
                                  "DefaultNotifications" (NSArray arrayWithObject:0)))))
          @registrationDictionary)
     
     ; The name of your application. 
     ; This name is used both for user display and for internal bookkeeping, 
     ; so it should clearly identify your application 
     ; (but it should not be your bundle identifier, because it will be displayed to the user) 
     ; and it should not change between versions and incarnations 
     ; (so don't include a version number or "Lite", "Pro", etc.). 
     ; If this method is not implemented, the executable name specified by 
     ; your application's Info.plist will be used.
     ; It is recommended that you implement this method.
     (imethod (id) applicationNameForGrowl is "Nu")
     
     ; The delegate may return an NSData object to use as the application icon;
     ; if this is not implemented or returns nil, the application's own icon is used. 
     ; This method is not generally needed.
     ;(imethod (id) applicationIconDataForGrowl is (NSData data))
     
     ; Informs the delegate that Growl (specifically, the GrowlHelperApp) 
     ; was launched successfully. The application can then take actions with 
     ; the knowledge that Growl is installed and functional.
     (imethod (void) growlIsReady is (puts "Growl: ready"))
     
     ; Informs the delegate that a Growl notification was clicked. 
     ; It is only sent for notifications sent with a non-nil clickContext, 
     ; so if you want to receive a message when a notification is clicked, 
     ; clickContext must not be nil when posting the notification. 
     ; clickContext must be a property list: it must be a dictionary, 
     ; array, string, data, or number object. Not all displays support click feedback.
     (imethod (void) growlNotificationWasClicked:(id) clickContext is 
          (puts "Growl: notification '#{clickContext}' was clicked"))
     
     ; Informs the delegate that a Growl notification timed out. 
     ; It is only sent for notifications sent with a non-nil clickContext, 
     ; so if you want to receive a message when a notification timed out, 
     ; clickContext must not be nil when posting the notification. 
     ; clickContext must be a property list: it must be a dictionary, 
     ; array, string, data, or number object. This selector was added in Growl 0.7.
     (imethod (void) growlNotificationTimedOut:(id)clickContext is 
          (puts "Growl: notification '#{clickContext}' timed out")))

(GrowlApplicationBridge setGrowlDelegate:(set $gd ((NuGrowlDelegate alloc) init)))

(function growl (message)
     (GrowlApplicationBridge notifyWithTitle:"Nu" 
          description:(message stringValue)
          notificationName:"NuGrowl" 
          iconData:(NSData data)
          priority:0
          isSticky:NO
          clickContext:(message stringValue)))

