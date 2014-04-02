//
//  DetailViewController.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/13.
//  Copyright (c) 2013 Lori Hill. All rights reserved.
//

@import UIKit;
@import MessageUI;
@import MapKit;

#import <OHAttributedLabel/OHAttributedLabel.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, OHAttributedLabelDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *name;
//@property (strong, nonatomic) IBOutlet OHAttributedLabel *location;
@property (strong, nonatomic) IBOutlet UIButton *location;
@property (strong, nonatomic) IBOutlet UILabel *beginDate;
@property (strong, nonatomic) IBOutlet UILabel *endDate;
@property (strong, nonatomic) IBOutlet OHAttributedLabel *email;
@property (strong, nonatomic) IBOutlet OHAttributedLabel *phone;
@property (strong, nonatomic) IBOutlet OHAttributedLabel *link;
@property (strong, nonatomic) IBOutlet UITextView *desc;


@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nameToLocationConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *locationToBeginDateConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beginDateToEndDateConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *endDateToEmailConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emailToPhoneConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *phoneToLinkConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *linkToDescriptionConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *locationHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *endDateHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emailHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *phoneHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *linkHeight;

- (IBAction)openMapWithAddress:(id)sender;

@end