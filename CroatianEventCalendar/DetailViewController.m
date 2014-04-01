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




@interface DetailViewController ()<UIActionSheetDelegate>
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

    if (self.detailItem) {
        self.name.text = [[self.detailItem valueForKey:@"name"] description];
		
		if ([[self.detailItem valueForKey:@"location"] description]) {
			//location is a label because OHAttributedLabel does not handle more than one line of text
			// and textView was not picking up enough of the address :(
			
			[self.location setTitle: [[self.detailItem valueForKey:@"location"] description] forState:UIControlStateNormal];
			CGSize labelSize = [self.location sizeThatFits:CGSizeMake(self.location.frame.size.width, FLT_MAX)];
			self.locationHeight.constant = labelSize.height;
			
//			NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeAddress error:nil];
//
//			[detector enumerateMatchesInString:self.location.text
//                         options:0 
//                           range:NSMakeRange(0, [self.location.text length])
//                      usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//
//            
//                NSDictionary *address = [result addressComponents];
//                NSLog(@"addressComponents  %@",address);
//            
//
//                      }];
			

		} else {
			self.locationHeight.constant = 0;
			self.nameToLocationConstraint.constant = 0;
		}
		
		[self formatDates];

		if ([[self.detailItem valueForKey:@"email"] description]) {
			self.email.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"email"] description]];
			self.email.automaticallyAddLinksForType = NSTextCheckingTypeLink;
			self.email.delegate = self; // Delegate methods are called when the user taps on a link
		} else {
			self.emailHeight.constant = 0;
			self.endDateToEmailConstraint.constant = 0;
		}
		
		if ([[self.detailItem valueForKey:@"phone"] description]) {
			self.phone.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"phone"] description]];
			self.phone.automaticallyAddLinksForType = NSTextCheckingTypePhoneNumber;
			self.phone.delegate = self; // Delegate methods are called when the user taps on a link
		} else {
			self.phoneHeight.constant = 0;
			self.emailToPhoneConstraint.constant = 0;
		}


		if ([[self.detailItem valueForKey:@"link"] description]) {
			self.link.attributedText = [self buildAttributedString: [[self.detailItem valueForKey:@"link"] description]];
			self.link.automaticallyAddLinksForType = NSTextCheckingTypeLink;
			self.link.delegate = self; // Delegate methods are called when the user taps on a link
		} else {
			self.link.hidden = YES;
			self.linkHeight.constant = 0;
			self.phoneToLinkConstraint.constant = 0;
		}

		if ([[self.detailItem valueForKey:@"desc"] description]) {
			//description is a textView because OHAttributedLabel can't handle more than one line of text
			self.desc.text = [[self.detailItem valueForKey:@"desc"] description];
		} else {
			self.desc.hidden = YES;
			self.linkToDescriptionConstraint.constant = 0;
		}

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
	unsigned timeUnitFlags = NSCalendarUnitHour  | NSCalendarUnitMinute;
	NSDateComponents *beginTimeComps = [[NSCalendar currentCalendar] components:timeUnitFlags fromDate:[self.detailItem valueForKey:@"beginDate"]];
	if (beginTimeComps.hour == 0 && beginTimeComps.minute == 0) {
		theBeginTime = @"";
	}
	
	
	NSString *theEndDate = [dateFormat stringFromDate:[self.detailItem valueForKey:@"endDate"]];
	NSString *theEndTime = [timeFormat stringFromDate: [self.detailItem valueForKey:@"endDate"]];
		
		//if no time was entered display as blank
	unsigned dateUnitFlags = NSCalendarUnitMonth  | NSCalendarUnitDay | NSCalendarUnitYear;
	NSDateComponents *endDateComps = [[NSCalendar currentCalendar] components:dateUnitFlags fromDate:[self.detailItem valueForKey:@"endDate"]];
	//there is a bug with the way Apple stores a zero date in core data -
	// stores as 0002-11-30 07:52:58 +0000
	if ((endDateComps.month == 0 && endDateComps.day == 0 && endDateComps.year == 0) || (endDateComps.year < 2000)) {
		theEndDate = @"";
	}
	
	NSDateComponents *endTimeComps = [[NSCalendar currentCalendar] components:timeUnitFlags fromDate:[self.detailItem valueForKey:@"endDate"]];
		//there is a bug with the way Apple stores a zero date in core data -
	// stores as 0002-11-30 07:52:58 +0000
	if ((endTimeComps.hour == 0 && endTimeComps.minute == 0) || (endTimeComps.second != 0)) {
		theEndTime = @"";
	}
	
	if ([theEndDate isEqualToString:@""]) {
		self.endDateHeight.constant = 0;
		self.beginDateToEndDateConstraint.constant = 0;
		if ([theEndTime isEqualToString: @""]) {
			self.beginDate.text = [NSString stringWithFormat: @"%@  %@", theBeginDate, theBeginTime];
		} else {
			self.beginDate.text = [NSString stringWithFormat: @"%@  %@ - %@", theBeginDate, theBeginTime, theEndTime];
		}
	} else {
		self.endDate.hidden = NO;
		self.beginDate.text = [NSString stringWithFormat: @"%@  %@ -", theBeginDate, theBeginTime];
		self.endDate.text = [NSString stringWithFormat: @"%@  %@", theEndDate, theEndTime];
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
- (IBAction) openMapViewForAddress: (NSString *) addressString {



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
	
	NSLog(@"Maps String: %@", addressUrl);
	
    NSURL *map_url = [NSURL URLWithString:addressUrl];
		
	UIApplication *application = [UIApplication sharedApplication];
	[application openURL:map_url];
}
@end
