;; test!
;; HelloWorldClassic in Nu
;;  a sample iPhone application ported to Nu
;;
;; Copyright 2008, Tim Burks http://blog.neontology.com
;; Released under the Creative Commons Attribution-Share Alike 3.0 license
;; http://creativecommons.org/license/results-one?license_code=by-sa

;; These constants are defined in the UIKit framework headers.
(global UIControlStateNormal 0)
(global UIControlContentHorizontalAlignmentCenter 0)
(global UIControlContentVerticalAlignmentCenter 0)
(global UIControlEventTouchUpInside (<< 1 6))
(global UITextFieldBorderStyleRounded 3)
(global UIKeyboardTypeAlphabet 1)
(global UITextAlignmentCenter 1)
(global UIButtonTypeRoundedRect 1)

(set TEXT_FIELD_FONT_SIZE 15.0)
(set BUTTON_FONT_SIZE 16.0)
(set TEXT_LABEL_FONT_SIZE 30.0)
(set TEXT_FIELD_HEIGHT_MULTIPLIER 2.0)

(class AppDelegate is NSObject
     (ivar (id) window (id) contentView (id) textField (id) label)

     (- (void)addControlsToContentView:(id)aContentView is
        (set contentFrame (aContentView frame))

        ;; Create a button 
        (set buttonFrame (list 0.0 0.0 200 40))
        (set button (UIButton buttonWithType:UIButtonTypeRoundedRect))
        (button setFrame:buttonFrame)
        (button setTitle:"Hello" forStates:UIControlStateNormal)
        (button setFont:(UIFont boldSystemFontOfSize:BUTTON_FONT_SIZE))

        ;; Center the text on the button, considering the button's shadow
        (button setContentHorizontalAlignment:
                UIControlContentHorizontalAlignmentCenter)
        (button setContentVerticalAlignment:
                UIControlContentVerticalAlignmentCenter)

        ;; hello: is sent when the button is touched
        (button addTarget:self action:"hello:" 
                forControlEvents:UIControlEventTouchUpInside)

        ;; Position the button centered horizontally in the contentView
        (button setCenter: (list ((aContentView center) first)
                                 (- ((aContentView center) second) 52)))
        (aContentView addSubview:button)

        ;; Create a text field to type into
        (set textFieldWidth (* (contentFrame third) 0.72))
        ;; and set the origin based on centering the view
        (set textFieldOriginX (/ (- (contentFrame third) textFieldWidth) 2.0))
        (set leftMargin 220.0)
        (set textFieldFrame
             (list textFieldOriginX leftMargin textFieldWidth
                   (* TEXT_FIELD_FONT_SIZE TEXT_FIELD_HEIGHT_MULTIPLIER)))
        (set aTextField ((UITextField alloc) initWithFrame:textFieldFrame))
        (aTextField setBorderStyle: UITextFieldBorderStyleRounded)
        (aTextField setFont:(UIFont systemFontOfSize:TEXT_FIELD_FONT_SIZE))
        (aTextField setContentVerticalAlignment:
             UIControlContentVerticalAlignmentCenter)
        (aTextField setPlaceholder:"Touch here and enter your name.")
        (aTextField setKeyboardType: UIKeyboardTypeAlphabet)
        (set @textField aTextField)

        (aContentView addSubview:@textField)

        ;; Create a label for greeting output.
        ;; Dimensions are based on the input field sizing
        (set leftMargin 90.0)
        (set labelFrame
             (list textFieldOriginX leftMargin textFieldWidth
                   (* TEXT_LABEL_FONT_SIZE TEXT_FIELD_HEIGHT_MULTIPLIER)))
        (set aLabel ((UILabel alloc) initWithFrame:labelFrame))
        (aLabel setFont:(UIFont systemFontOfSize:TEXT_LABEL_FONT_SIZE))
 	    (aLabel setBackgroundColor:(UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0))
        ;; Create a slightly muted green color
        (aLabel setTextColor:
                (UIColor colorWithRed:0.22 green:0.54 blue:0.41 alpha:1.0))
        (aLabel setTextAlignment:UITextAlignmentCenter)
		((aLabel layer) setMasksToBounds:YES)
		((aLabel layer) setCornerRadius:10)
        (set @label aLabel)
        (aContentView addSubview:@label))

     ;; This method is invoked when the Hello button is touched
     (- (void)hello:(id)sender is
        (@textField resignFirstResponder)
        (set nameString (@textField text))
        (if (eq (nameString length) 0)
            (set nameString "Nubie"))
        (@label setText:(+ "Hello, " nameString "!")))

     (- (void)applicationDidFinishLaunching:(id)application is
        ;; Set up the window and content view
        (set screenRect ((UIScreen mainScreen) bounds))
        (set @window ((UIWindow alloc) initWithFrame:screenRect))

		(set @contentView ((UIView alloc) initWithFrame:screenRect))
		(@contentView setBackgroundColor:(UIColor scrollViewTexturedBackgroundColor))

        (@window addSubview:@contentView)
        (self addControlsToContentView:@contentView)

        ;; Show the window
        (@window makeKeyAndVisible)))
