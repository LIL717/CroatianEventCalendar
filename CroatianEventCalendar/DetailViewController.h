//
//  DetailViewController.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/13.
//  Copyright (c) 2013 Lori Hill. All rights reserved.
//

@import MessageUI;
@import MapKit;
@import EventKit;

#import <OHAttributedLabel/OHAttributedLabel.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, OHAttributedLabelDelegate, MKMapViewDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIButton *location;
@property (weak, nonatomic) IBOutlet UILabel *beginDate;
@property (weak, nonatomic) IBOutlet UILabel *endDate;
@property (weak, nonatomic) IBOutlet OHAttributedLabel *email;
@property (weak, nonatomic) IBOutlet OHAttributedLabel *phone;
@property (weak, nonatomic) IBOutlet OHAttributedLabel *link;
@property (weak, nonatomic) IBOutlet UITextView *desc;
@property (weak, nonatomic) IBOutlet UIButton *iCalButton;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;


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
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *mapViewHeight;

- (IBAction)openMapWithAddress:(id)sender;
- (IBAction)handleMoreButton:(id)sender;
- (IBAction)addToiCal:(id)sender;

@end
