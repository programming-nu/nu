;; maildemo.nu
;; MailDemo in Nu.
;;
;; Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class Mailbox is NSObject
     (ivar (id) title (id) icon (id) emails)     
     (- init is
        (super init)
        (set @title "New Mailbox")
        (set @icon (NSImage imageNamed:"Folder"))
        (set @emails (NSMutableArray array))
        self))

(class Email is NSObject
     (ivar (id) address (id) subject (id) date (id) body)
     (- init is
        (super init)
        (set @address "test@test.com")
        (set @subject "Subject")
        (set @date (NSDate date))
        (set @body "")
        self))

(class MailController is NSWindowController
     ;; all these outlets are set in the nib file
     (ivar (id) mailboxTable (id) emailTable (id) previewPane (id) emailStatusLine (id) mailboxStatusLine
           (id) addMailboxButton (id) deleteMailboxButton (id) addEmailButton (id) deleteEmailButton
           (id) controllerAlias (id) mailboxController (id) emailController)
     ;; this is for the application data
     (ivar (id) mailboxes)
     
     (- init is
        (super initWithWindowNibName:"MailDemo")
        ((self window) makeKeyAndOrderFront:self)
        (@previewPane setEditable:NO)
        (set @mailboxes ((NSMutableArray alloc) init))
        (self makeBindings)
        self)
     
     ;; if you prefer, you can do this in Interface Builder, but I think explicit bindings are easier to get right.
     (- makeBindings is
        (set @controllerAlias ((NSObjectController alloc) init))
        (@controllerAlias setContent:self)
        
        (set @mailboxController ((NSArrayController alloc) init))	    
        (@mailboxController bind:"contentArray" toObject:@controllerAlias withKeyPath:"selection.mailboxes" options:nil)
        (@mailboxController setObjectClass:Mailbox)
        (@addMailboxButton set:(target:@mailboxController action:"add:"))
        (@deleteMailboxButton set:(target:@mailboxController action:"remove:"))
        ((@mailboxTable tableColumnWithIdentifier:"title") 
         bind:"value" toObject:@mailboxController withKeyPath:"arrangedObjects.title" options:nil)
        (@mailboxStatusLine 
             bind:"displayPatternValue1" toObject:@mailboxController withKeyPath:"arrangedObjects.@count" 
             options:(NSMutableDictionary dictionaryWithList:(NSDisplayPattern: "%{value1}@ Mailboxes")))
        
        (set @emailController ((NSArrayController alloc) init))
        (@emailController bind:"contentArray" toObject:@mailboxController withKeyPath:"selection.emails" options:nil)
        (@emailController setObjectClass:Email)
        (@addEmailButton set: (target:@emailController action:"add:"))
        (@deleteEmailButton set: (target:@emailController action:"remove:"))
        
        ((list "address" "subject" "date") each: 
         (do (item)
             ((@emailTable tableColumnWithIdentifier:item) 
              bind:"value" toObject:@emailController withKeyPath:"arrangedObjects.#{item}" options:nil)))
        (@emailStatusLine 
             bind:"displayPatternValue1" toObject:@emailController withKeyPath:"arrangedObjects.@count" 
             options:(NSMutableDictionary dictionaryWithList:(NSDisplayPattern: "%{value1}@ Emails")))
        (@previewPane bind:"data" toObject:@emailController withKeyPath:"selection.body" options:nil)))

;; you could do this in the nib file too, but look how clearly our menu is specified here:
(set maildemo-application-menu
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
                  ("Close" action:"performClose:" key:"w"))
            (menu "Window"
                  ("Minimize" action:"performMiniaturize:" key:"m")
                  (separator)
                  ("Bring All to Front" action:"arrangeInFront:"))))

