//
//  DetailViewController.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/13.
//  Copyright (c) 2013 Lori Hill. All rights reserved.
//

#import "DetailViewController.h"
#import "OHAttributedLabel.h"
#import "WebViewController.h"
#import "UIAlertView+Commodity.h"
#import <OHAttributedLabel/NSAttributedString+Attributes.h>
#import <OHAttributedLabel/OHASBasicHTMLParser.h>
#import <OHAttributedLabel/OHASBasicMarkupParser.h>
#import <EventKit/EventKit.h>
//#import <EventKitUI/EventKitUI.h>

@interface DetailViewController ()<UIActionSheetDelegate>
// EKEventStore instance associated with the current Calendar application
@property (nonatomic, strong) EKEventStore *eventStore;

// Default calendar associated with the above event store
@property (nonatomic, strong) EKCalendar *defaultCalendar;
@property (nonatomic, strong) EKEvent *calendarEvent;
@property(nonatomic, retain) NSMutableSet* visitedLinks;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController
/////////////////////////////////////////////////////////////////////////////
#pragma mark - Init/Dealloc
/////////////////////////////////////////////////////////////////////////////


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.visitedLinks = [NSMutableSet set];
    }
    return self;
}
#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
//        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.navigationController.navigationBar.translucent = YES;
	
	// Initialize the event store for adding to Calendar
	self.eventStore = [[EKEventStore alloc] init];
	
	//set up the calendarEvent here, even if it doesn't get used, so that as the view is poplulated the event can be populated too
	self.calendarEvent = [EKEvent eventWithEventStore:self.eventStore];
	
    [self configureView];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)configureView
{
    // Update the user interface for the detail item.

	BOOL dataInItem;
    if (self.detailItem) {
        self.name.text = [[self.detailItem valueForKey:@"name"] description];
		self.calendarEvent.title = self.name.text;

		
		dataInItem = [self trimString:[[self.detailItem valueForKey:@"location"] description]];
		if (dataInItem) {
			//location is a label because OHAttributedLabel does not handle more than one line of text
			// and textView was not picking up enough of the address :(
			
			NSString *locationString = [[self.detailItem valueForKey:@"location"] description];
			NSString *formattedLocationString = locationString;
			BOOL foundHouseNumber = NO;
			BOOL probablyAStreetNumber = NO;
//			NSLog (@"%@", locationString);

			//look through the address, either find location of first number (street address) or first comma (and then make sure there is a second comma)
			NSRange rangeOfFirstDigit = [locationString rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
			if (rangeOfFirstDigit.location != NSNotFound) {
				//need to check if character 2 spaces in front is a Capital letter or a period in case the number is street number not a house number
				if (rangeOfFirstDigit.location > 1) {
//								NSLog (@"%C",[locationString characterAtIndex:rangeOfFirstDigit.location - 2]);

					if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember: [locationString characterAtIndex:rangeOfFirstDigit.location - 2]]
					|| [[NSCharacterSet characterSetWithCharactersInString: @"."] characterIsMember: [locationString characterAtIndex:rangeOfFirstDigit.location - 2]]) {
//						NSLog (@"this is probably a street number");
						foundHouseNumber = NO;
						probablyAStreetNumber = YES;
					}
				}
				if (!probablyAStreetNumber) {
					if (rangeOfFirstDigit.location > 0) {
					 formattedLocationString = [locationString stringByReplacingCharactersInRange: NSMakeRange (rangeOfFirstDigit.location - 1, 1) withString:@"\n"];
						foundHouseNumber = YES;
					}
				}
				
			}
			if (!foundHouseNumber) {
				//find first comma instead
				NSRange rangeOfFirstComma = [locationString rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @","]];
				if (rangeOfFirstComma.location != NSNotFound) {
					if (rangeOfFirstComma.location > 0) {
						//make sure this is not the comma between the city and state
						if (rangeOfFirstComma.location > 5) {
							if (rangeOfFirstComma.location < [locationString length] - 6) {
								formattedLocationString = [locationString stringByReplacingCharactersInRange: NSMakeRange (rangeOfFirstComma.location, 2) withString:@"\n"];
								}
						}
					}
				}
			}
//			NSLog (@"%@", formattedLocationString);
			[self.location setTitle: formattedLocationString forState:UIControlStateNormal];
			self.calendarEvent.location = formattedLocationString;



			//autolayout is not doing this automatically so set height of button to match height of textLabel
			self.locationHeight.constant = self.location.titleLabel.frame.size.height;
		} else {
			self.locationHeight.constant = 0;
			self.nameToLocationConstraint.constant = 0;
		}
		
		[self formatDates];
		
		dataInItem = [self trimString:[[self.detailItem valueForKey:@"email"] description]];
		if (dataInItem) {
//			NSLog (@" email is %@",[[self.detailItem valueForKey:@"email"] description]);
			self.email.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"email"] description]];
			self.email.automaticallyAddLinksForType = NSTextCheckingTypeLink;
			self.email.delegate = self; // Delegate methods are called when the user taps on a link
		} else {
			self.emailHeight.constant = 0;
			self.endDateToEmailConstraint.constant = 0;
		}
		
		dataInItem = [self trimString:[[self.detailItem valueForKey:@"phone"] description]];
		if (dataInItem) {
			self.phone.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"phone"] description]];
			self.phone.automaticallyAddLinksForType = NSTextCheckingTypePhoneNumber;
			self.phone.delegate = self; // Delegate methods are called when the user taps on a link
		} else {
			self.phoneHeight.constant = 0;
			self.emailToPhoneConstraint.constant = 0;
		}

		dataInItem = [self trimString:[[self.detailItem valueForKey:@"link"] description]];
		if (dataInItem) {
			self.link.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"link"] description]];
			self.link.automaticallyAddLinksForType = NSTextCheckingTypeLink;
			self.link.delegate = self; // Delegate methods are called when the user taps on a link
			NSString *myURLString = [NSString stringWithFormat: @"http://%@", self.link.attributedText.string];
			NSURL *myURL = [NSURL URLWithString: myURLString];
			self.calendarEvent.URL = myURL;
		} else {
			self.link.hidden = YES;
			self.linkHeight.constant = 0;
			self.phoneToLinkConstraint.constant = 0;
		}

		dataInItem = [self trimString:[[self.detailItem valueForKey:@"desc"] description]];
		if (dataInItem) {
			//description is a textView because OHAttributedLabel can't handle more than one line of text
			self.desc.text = [[self.detailItem valueForKey:@"desc"] description];
			self.calendarEvent.notes = self.desc.text;
		} else {
			self.desc.hidden = YES;
			self.linkToDescriptionConstraint.constant = 0;
		}

    }
}
- (BOOL) trimString: (NSString *) string {
		NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		if ([trimmed isEqualToString: @""]) {
			return NO;
		} else {
			return YES;
		}
}
- (NSAttributedString *) buildAttributedString: (NSString *) text {
	/**(1)** Build the NSAttributedString *******/
	NSMutableAttributedString* attrStr = [[[NSAttributedString alloc] initWithString: text] mutableCopy];

    NSRange selectedRange = NSMakeRange(0, text.length);

    [attrStr beginEditing];

    [attrStr addAttribute:NSFontAttributeName
                   value:[UIFont systemFontOfSize:16]
                   range:selectedRange];

    [attrStr endEditing];

    // Change the paragraph attributes, like textAlignment, lineBreakMode and paragraph spacing
    [attrStr modifyParagraphStylesWithBlock:^(OHParagraphStyle *paragraphStyle) {
//        paragraphStyle.textAlignment = kCTCenterTextAlignment;
        paragraphStyle.lineBreakMode = kCTLineBreakByWordWrapping;
        paragraphStyle.paragraphSpacing = 8.f;
        paragraphStyle.lineSpacing = 3.f;
//		paragraphStyle.lineHeightMultiple = 50.f;

    }];


//    [attrStr setFontFamily:@"helvetica" size:17 bold:NO italic:NO range:NSMakeRange(0, [text length])];
//	[attrStr setFont: [UIFont systemFontOfSize:17]];

  return attrStr;
}
- (void) formatDates {
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateStyle: NSDateFormatterLongStyle];

	NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
	[timeFormat setDateFormat:@"h:mm a"];

	NSString *theBeginDate = [dateFormat stringFromDate:[self.detailItem valueForKey:@"beginDate"]];
	NSString *theBeginTime = [timeFormat stringFromDate: [self.detailItem valueForKey:@"beginDate"]];

	//if no time was entered display as blank
	unsigned timeUnitFlags = NSCalendarUnitHour  | NSCalendarUnitMinute |NSCalendarUnitSecond;
	NSDateComponents *beginTimeComps = [[NSCalendar currentCalendar] components:timeUnitFlags fromDate:[self.detailItem valueForKey:@"beginDate"]];
	if (beginTimeComps.hour == 0 && beginTimeComps.minute == 0) {
		theBeginTime = @"";
		self.calendarEvent.allDay = YES;
	} else {
		self.calendarEvent.allDay = NO;
	}
	self.calendarEvent.startDate = [self.detailItem valueForKey:@"beginDate"]; //NSDate

	
	NSString *theEndDate = [dateFormat stringFromDate:[self.detailItem valueForKey:@"endDate"]];
	NSString *theEndTime = [timeFormat stringFromDate: [self.detailItem valueForKey:@"endDate"]];
		
	if ([theBeginDate isEqualToString: theEndDate]) {
		theEndDate = @"";
		if ([theBeginTime isEqualToString: theEndTime]) {
			theEndTime = @"";
		}
	}
	
	NSDateComponents *endTimeComps = [[NSCalendar currentCalendar] components:timeUnitFlags fromDate:[self.detailItem valueForKey:@"endDate"]];
		//there is a bug with the way Apple stores a zero date in core data -
	// stores as 0002-11-30 07:52:58 +0000
	if ((endTimeComps.hour == 0 && endTimeComps.minute == 0) || (endTimeComps.second != 0)) {
		theEndTime = @"";
	}
		
	self.calendarEvent.endDate = [self.detailItem valueForKey:@"endDate"];  //NSDate

	if ([theEndDate isEqualToString:@""]) {		//no end date
		if ([theEndTime isEqualToString:@""]) {  //no end date or time
			self.endDateHeight.constant = 0;
			self.beginDateToEndDateConstraint.constant = 0;
			self.endDate.hidden = YES;
			self.beginDate.text = [NSString stringWithFormat: @"%@  %@", theBeginDate, theBeginTime];
		} else {									//no end date, but end time so ends same day
			self.beginDate.text = [NSString stringWithFormat: @"%@", theBeginDate];
			self.beginDateToEndDateConstraint.constant = 2;
			self.endDate.text = [NSString stringWithFormat:@"%@ - %@", theBeginTime, theEndTime];
		}
	} else {									 //different dates
			self.endDate.hidden = NO;
			if ([theBeginTime isEqualToString: @""]) {     //different dates but no begin time
				self.beginDate.text = [NSString stringWithFormat: @"%@ -", theBeginDate];
			} else {										//different dates with a time
				self.beginDate.text = [NSString stringWithFormat: @"%@  %@ -", theBeginDate, theBeginTime];
			}
			if ([theEndTime isEqualToString: @""]) {		//different dates but no end time
				self.endDate.text = [NSString stringWithFormat: @"%@", theEndDate];
			} else {										//differnt dates and an end time
				self.endDate.text = [NSString stringWithFormat: @"%@  %@", theEndDate, theEndTime];
			}
	}

}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"WebViewSegue"]) {
		WebViewController *webViewController = segue.destinationViewController;
		NSString* launchUrl = [NSString stringWithFormat:@"http://%@",[[self.detailItem valueForKey:@"link"] description]];
        webViewController.urlObject = [NSURL URLWithString: launchUrl];
        
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}
/////////////////////////////////////////////////////////////////////////////
#pragma mark - Visited Links Managment
/////////////////////////////////////////////////////////////////////////////


id objectForLinkInfo(NSTextCheckingResult* linkInfo)
{
	// Return the first non-nil property
	return (id)linkInfo.URL ?: (id)linkInfo.phoneNumber ?: (id)linkInfo.addressComponents ?: (id)linkInfo.date ?: (id)[linkInfo description];
}

-(UIColor*)attributedLabel:(OHAttributedLabel*)attrLabel colorForLink:(NSTextCheckingResult*)link underlineStyle:(int32_t*)pUnderline
{
	if ([self.visitedLinks containsObject:objectForLinkInfo(link)]) {
		// Visited link
		*pUnderline = kCTUnderlineStyleSingle|kCTUnderlinePatternDot;
		return [UIColor purpleColor];
	} else {
		*pUnderline = attrLabel.linkUnderlineStyle; // use default value
		return attrLabel.linkColor; // use default value
	}
}

-(BOOL)attributedLabel:(OHAttributedLabel *)attributedLabel shouldFollowLink:(NSTextCheckingResult *)linkInfo
{
	[self.visitedLinks addObject:objectForLinkInfo(linkInfo)];
	[attributedLabel setNeedsRecomputeLinksInText];
	
	if (linkInfo.resultType ==NSTextCheckingTypePhoneNumber ) {
				[[[UIActionSheet alloc] initWithTitle: linkInfo.phoneNumber
								  delegate:self
						 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
					destructiveButtonTitle:nil
						 otherButtonTitles:NSLocalizedString(@"Call", nil), nil]
						        showInView:self.view];
				return NO;
//                [UIAlertView showWithTitle:@"Phone Number" message:linkInfo.phoneNumber];
	} else if ([[UIApplication sharedApplication] canOpenURL:linkInfo.extendedURL])
		{
        // use default behavior
        return YES;
		} else
			{
				switch (linkInfo.resultType) {
				case NSTextCheckingTypeAddress:
					[UIAlertView showWithTitle:@"Address" message:[linkInfo.addressComponents description]];
					break;
				case NSTextCheckingTypeDate:
					[UIAlertView showWithTitle:@"Date" message:[linkInfo.date description]];
					break;
				default: {
					NSString* message = [NSString stringWithFormat:@"Unknown link type (NSTextCheckingType %lld)",linkInfo.resultType];
					[UIAlertView showWithTitle:@"Unknown link type" message:message];
					break;
				}

			}
			return NO;
    }

}
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
					clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
	// phone interface
	NSString *formattedPhoneNumber = [@"tel:" stringByAppendingString:actionSheet.title];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:formattedPhoneNumber]];
}

	//make the font larger for the title (phone number)
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView *_currentView in actionSheet.subviews) {
        if ([_currentView isKindOfClass:[UILabel class]]) {
            UILabel *l = [[UILabel alloc] initWithFrame:_currentView.frame];
            l.text = [(UILabel *)_currentView text];
            [l setFont:[UIFont fontWithName:@"Arial-BoldMT" size:20]];
            l.textColor = [UIColor darkGrayColor];
            l.backgroundColor = [UIColor clearColor];
            [l sizeToFit];
            [l setCenter:CGPointMake(actionSheet.center.x, 25)];
            [l setFrame:CGRectIntegral(l.frame)];
            [actionSheet addSubview:l];
            _currentView.hidden = YES;
            break;
        }
    }
}
- (IBAction)openMapWithAddress:(id)sender {

	UIButton *button = (UIButton *)sender;
	NSString *addressString = button.currentTitle;

	NSString *escapedAddress = [addressString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *addressUrl = [NSString stringWithFormat: @"http://maps.apple.com/?q=%@", escapedAddress];
	
//	NSLog(@"Maps String: %@", addressUrl);
	
    NSURL *map_url = [NSURL URLWithString:addressUrl];
		
	UIApplication *application = [UIApplication sharedApplication];
	[application openURL:map_url];
}

- (IBAction)handleMoreButton:(id)sender {
	
	
	NSString *myURLString = [NSString stringWithFormat: @"http://%@", self.link.attributedText.string];
	NSURL *myURL = [NSURL URLWithString: myURLString];
	NSArray *activityItems = [[NSArray alloc] initWithObjects: self.name.text, self.beginDate.text, self.location.titleLabel.text,[NSString stringWithFormat:@"%@", myURL], nil];
		
	NSArray * applicationActivities = nil;
//	NSArray * excludeActivities = @[UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeMessage];

	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
//	[activityViewController excludeActivityTypes: excludeActivities];
	[activityViewController setValue: self.name.text forKey:@"subject"];
	
	[self presentViewController:activityViewController animated:YES completion:nil];

}
- (IBAction)addToiCal:(id)sender {

	    // Check whether we are authorized to access Calendar
    [self checkEventStoreAccessForCalendar];
		if (self.calendarEvent.endDate) {
		self.calendarEvent.endDate = [self.detailItem valueForKey:@"endDate"];  //NSDate
	} else {
		self.calendarEvent.endDate = [self.detailItem valueForKey:@"beginDate"];  //if no endDate was entered, use begin Date for end date
	}
	[self.calendarEvent setCalendar: self.defaultCalendar];
	NSError *err = nil;
	[self.eventStore saveEvent:self.calendarEvent span:EKSpanThisEvent commit:YES error:&err];
	
	NSString *eventTitle = self.calendarEvent.title;
	NSString *eventAddedMessage;
	if (err) {
		eventAddedMessage = [NSString stringWithFormat: @"Unable to add event to calendar - code %@", err];
	} else {
		eventAddedMessage = @"Event successfully added to calendar";
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:eventTitle message:eventAddedMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
	[alert show];

}
#pragma mark -
#pragma mark Access Calendar

// Check the authorization status of our application for Calendar 
-(void)checkEventStoreAccessForCalendar
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];    
 
    switch (status)
    {
        // Update our UI if the user has granted access to their Calendar
        case EKAuthorizationStatusAuthorized: [self accessGrantedForCalendar];
            break;
        // Prompt the user for access to Calendar if there is no definitive answer
        case EKAuthorizationStatusNotDetermined: [self requestCalendarAccess];
            break;
        // Display a message if the user has denied or restricted access to Calendar
        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning" message:@"Permission was not granted for Calendar"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;
        default:
            break;
    }
}


// Prompt the user for access to their Calendar
-(void)requestCalendarAccess
{
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
    {
         if (granted)
         {
             DetailViewController * __weak weakSelf = self;
             // Let's ensure that our code will be executed from the main queue
             dispatch_async(dispatch_get_main_queue(), ^{
             // The user has granted access to their Calendar; let's populate our UI with all events occuring in the next 24 hours.
                 [weakSelf accessGrantedForCalendar];
             });
         }
     }];
}


// This method is called when the user has granted permission to Calendar
-(void)accessGrantedForCalendar
{
    // Let's get the default calendar associated with our event store
    self.defaultCalendar = self.eventStore.defaultCalendarForNewEvents;

}

@end
