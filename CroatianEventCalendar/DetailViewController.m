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
#import <MapKit/MapKit.h>
#import "Reachability.h"
#import "MBProgressHUD.h"

@interface DetailViewController ()<UIActionSheetDelegate>

@property (nonatomic, strong) EKEventStore *eventStore; // EKEventStore instance associated with the current Calendar application
@property (nonatomic, strong) EKCalendar *defaultCalendar; // Default calendar associated with the above event store
@property (nonatomic, strong) EKEvent *calendarEvent;
@property(nonatomic, retain) NSMutableSet* visitedLinks;

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic, assign) BOOL networkIsReachable;
@property (nonatomic, strong) NSString *eventAddedMessage;

- (void)configureView;
@end

@implementation DetailViewController
/////////////////////////////////////////////////////////////////////////////
#pragma mark - Init/Dealloc
/////////////////////////////////////////////////////////////////////////////
int savedEndDateHeight;
int savedBeginDateToEndDateConstraint;
int savedLinkToDescriptionConstraint;
int savedLinkHeight;
int savedPhoneToLinkConstraint;
int savedPhoneHeight;
int savedEmailToPhoneConstraint;
int savedEmailHeight;
int savedEndDateToEmailConstraint;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.visitedLinks = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}
#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
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
//			self.calendarEvent.location = formattedLocationString;
			self.location.hidden = NO;
			if (self.networkIsReachable) {
				self.location.enabled = YES;
				self.location.imageView.hidden = NO;
			} else {
				self.location.enabled = NO;
				self.location.imageView.hidden = YES;
			}

			//autolayout is not doing this automatically so set height of button to match height of textLabel
			self.locationHeight.constant = self.location.titleLabel.frame.size.height;
			// for iPad, if the height is too small the pin gets compressed, so make it at least 50 pixels high
			if (self.locationHeight.constant < 50) {
				self.locationHeight.constant = 50;
				}
		} else {
			
			self.locationHeight.constant = 0;
		}
		
		if (self.mapViewHeight.constant > 100 && self.networkIsReachable) {
			[self displayMapWithLocation: self.location.titleLabel.text];
		} else {
			self.mapView.hidden = YES;
		}
		
		if ([[self.detailItem valueForKey:@"beginDate"] description]) {
			[self formatDates];
			self.iCalButton.hidden = NO;
			self.iCalButton.enabled = YES;
		}
			
		dataInItem = [self trimString:[[self.detailItem valueForKey:@"email"] description]];
		if (dataInItem) {
//			NSLog (@" email is %@",[[self.detailItem valueForKey:@"email"] description]);
			self.email.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"email"] description]];
			self.email.automaticallyAddLinksForType = NSTextCheckingTypeLink;
			self.email.delegate = self; // Delegate methods are called when the user taps on a link
			self.emailHeight.constant = savedEmailHeight;
			self.endDateToEmailConstraint.constant = savedEndDateToEmailConstraint;
		} else {
			self.email.text = @"";
			self.emailHeight.constant = 0;
			self.endDateToEmailConstraint.constant = 0;
		}
		
		dataInItem = [self trimString:[[self.detailItem valueForKey:@"phone"] description]];
		if (dataInItem) {
			self.phone.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"phone"] description]];
			self.phone.automaticallyAddLinksForType = NSTextCheckingTypePhoneNumber;
			self.phone.delegate = self; // Delegate methods are called when the user taps on a link
			self.phoneHeight.constant = savedPhoneHeight;
			self.emailToPhoneConstraint.constant = savedEmailToPhoneConstraint;
		} else {
			self.phone.text = @"";
			self.phoneHeight.constant = 0;
			self.emailToPhoneConstraint.constant = 0;
		}

		dataInItem = [self trimString:[[self.detailItem valueForKey:@"link"] description]];
		NSLog (@" link issssssssss %@", [self.detailItem valueForKey: @"link"]);
		if (dataInItem) {
			self.link.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"link"] description]];
			self.link.automaticallyAddLinksForType = NSTextCheckingTypeLink;
			self.link.delegate = self; // Delegate methods are called when the user taps on a link
			NSString *myURLString = [NSString stringWithFormat: @"http://%@", self.link.attributedText.string];
			NSURL *myURL = [NSURL URLWithString: myURLString];
			self.calendarEvent.URL = myURL;
			self.linkHeight.constant = savedLinkHeight;
			self.phoneToLinkConstraint.constant = savedPhoneToLinkConstraint;
		} else {
//			self.link.hidden = YES;
			self.link.text = @"";
			self.linkHeight.constant = 0;
			self.phoneToLinkConstraint.constant = 0;
		}

		dataInItem = [self trimString:[[self.detailItem valueForKey:@"desc"] description]];
		if (dataInItem) {
			//description is a textView because OHAttributedLabel can't handle more than one line of text
			self.desc.text = [[self.detailItem valueForKey:@"desc"] description];
			self.calendarEvent.notes = self.desc.text;
			self.linkToDescriptionConstraint.constant = savedPhoneToLinkConstraint;
			self.desc.hidden = NO;
		} else {
			self.desc.text = @"";
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
        paragraphStyle.textAlignment = kCTCenterTextAlignment;
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
	
	self.endDateHeight.constant = savedEndDateHeight;
	self.beginDateToEndDateConstraint.constant = savedBeginDateToEndDateConstraint;
	
	
	if ([theEndDate isEqualToString:@""]) {		//no end date
		if ([theEndTime isEqualToString:@""]) {  //no end date or time
			self.endDateHeight.constant = 0;
			self.beginDateToEndDateConstraint.constant = 0;
//			self.endDate.hidden = YES;
			self.beginDate.text = [NSString stringWithFormat: @"%@  %@", theBeginDate, theBeginTime];
		} else {									//no end date, but end time so ends same day
			self.beginDate.text = [NSString stringWithFormat: @"%@", theBeginDate];
			self.beginDateToEndDateConstraint.constant = 2;
			self.endDate.text = [NSString stringWithFormat:@"%@ - %@", theBeginTime, theEndTime];
		}
	} else {									 //different dates
//			self.endDate.hidden = NO;
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
	
//	NSLog (@"endDateHeight is %f, constraint is %f", self.endDateHeight.constant, self.beginDateToEndDateConstraint.constant);

}
- (void ) displayMapWithLocation: (NSString *) location {

		// Create and initialize a search request object.
		MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
		request.naturalLanguageQuery = self.location.titleLabel.text;
		request.region = self.mapView.region;
		[self.mapView setRegion:[self.mapView regionThatFits:request.region] animated:YES];
		 
		// Create and initialize a search object.
		MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
		 
		// Start the search and display the results as annotations on the map.
		[search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
		{
		   NSMutableArray *placemarks = [NSMutableArray array];
		   for (MKMapItem *item in response.mapItems) {
			  [placemarks addObject:item.placemark];
		   }
		   [self.mapView removeAnnotations:[self.mapView annotations]];
		   [self.mapView showAnnotations:placemarks animated:NO];
		   
		if (error) {
			self.mapView.hidden = YES;
		} else {
			self.mapView.hidden = NO;
		}
		}];
		
}
#pragma mark - View handling


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.navigationController.navigationBar.translucent = YES;
	
	// Initialize the event store for adding to Calendar
	self.eventStore = [[EKEventStore alloc] init];
	
	//set up the calendarEvent here, even if it doesn't get used, so that as the view is poplulated the event can be populated too
	self.calendarEvent = [EKEvent eventWithEventStore:self.eventStore];
		
	savedEndDateHeight = self.endDateHeight.constant;
	savedBeginDateToEndDateConstraint = self.beginDateToEndDateConstraint.constant;
	savedLinkToDescriptionConstraint = self.linkToDescriptionConstraint.constant;
	savedLinkHeight = self.linkHeight.constant;
	savedPhoneToLinkConstraint = self.phoneToLinkConstraint.constant;
	savedPhoneHeight = self.phoneHeight.constant;
	savedEmailToPhoneConstraint = self.emailToPhoneConstraint.constant;
	savedEmailHeight = self.emailHeight.constant;
	savedEndDateToEmailConstraint = self.endDateToEmailConstraint.constant;
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed: @"tileBackground.png"]];
	self.mapView.delegate = self;

     //Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
	//Check initial reachability
    NSString *remoteHostName = @"www.apple.com";
	self.hostReachability = [Reachability reachabilityWithHostname:remoteHostName];
	[self.hostReachability startNotifier];
	[self updateReachabilityFlag:self.hostReachability];
	
//	[self configureView];  initial configureView is now called in updateReachabiityFlag:
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"All Events", @"All Events");
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
#pragma mark - Leaving this App

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"WebViewSegue"]) {
		WebViewController *webViewController = segue.destinationViewController;
		NSString* launchUrl = [NSString stringWithFormat:@"http://%@",[[self.detailItem valueForKey:@"link"] description]];
        webViewController.urlObject = [NSURL URLWithString: launchUrl];
        
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
	
	NSString *myURLString;
	if ([self.link.attributedText.string length] > 0) {
		myURLString = [NSString stringWithFormat: @"http://%@", self.link.attributedText.string];
	} else {
		myURLString = @"";
	}
	NSURL *myURL = [NSURL URLWithString: myURLString];
	
	NSArray *activityItems = [[NSArray alloc] initWithObjects: self.name.text, self.beginDate.text, self.endDate.text, self.location.titleLabel.text, [NSString stringWithFormat:@"%@", myURL], nil];
		
	NSArray * applicationActivities = nil;
//	NSArray * excludeActivities = @[UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeMessage];

	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
//	[activityViewController excludeActivityTypes: excludeActivities];
	[activityViewController setValue: self.name.text forKey:@"subject"];
	
	[self presentViewController:activityViewController animated:YES completion:nil];

}
#pragma mark -
#pragma mark Access Calendar
- (IBAction)addToiCal:(id)sender {

	    // Check whether we are authorized to access Calendar

	[self setEvent: self.calendarEvent
			withResecheduling:NO completion:^{
			NSLog (@"done adding event");
	}];
//											// Remove progress window
//					[MBProgressHUD hideHUDForView:self.view animated:YES];
}

-(void)setEvent:(EKEvent *) buildEvent withResecheduling:(BOOL)rescheduling completion:(void (^)(void))completionBlock
{
	
    EKEventStore* store = [[EKEventStore alloc] init];

    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted)
        {
			NSLog (@"Not granted");
			dispatch_async(dispatch_get_main_queue(), ^{
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Calendar Error" message:@"Unable to add event to calendar - change calendar access in privacy settings" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
			});
            return;
        }
                dispatch_async(dispatch_get_main_queue(), ^{
                    EKEvent *event = [EKEvent eventWithEventStore:store];
                    event.title = buildEvent.title;
                    event.startDate = buildEvent.startDate;
                    event.endDate = buildEvent.endDate;
					event.location = buildEvent.location;
					event.URL = buildEvent.URL;
					event.notes = buildEvent.notes;
					event.allDay = buildEvent.allDay;
                    [event setCalendar:[store defaultCalendarForNewEvents]];
                    NSError *err = nil;
                    [store saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
                    if (!rescheduling) {

                        NSString* alertTitle;
                        NSString* msg;
                        if (err) {
							alertTitle = @"Calendar Error";
							msg = [NSString stringWithFormat: @"Unable to add event to calendar. %@", err.localizedDescription];
                        } else {
                            alertTitle = buildEvent.title;
                            msg = @"Event successfully added to calendar.";
                        }
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:alertTitle message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
                    }

        });


    }];

}

#pragma mark -
#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	[self updateReachabilityFlag:curReach];
}


- (void)updateReachabilityFlag:(Reachability *)reachability
{
	NetworkStatus netStatus = [reachability currentReachabilityStatus];

    if (netStatus == NotReachable) {
		self.networkIsReachable = NO;
	} else {
		self.networkIsReachable = YES;
	}
	NSLog (@"NNNNNNNNNNNNNNNNNNNNNNNNNNetwork status bool is %hhd, status is %i", self.networkIsReachable, netStatus);
	[self configureView];
}
@end
