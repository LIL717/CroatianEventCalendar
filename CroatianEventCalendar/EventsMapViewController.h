//
//  EventsMapViewController.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 4/11/14.
//  Copyright (c) 2014 Lori Hill. All rights reserved.
//

#import "SplitViewButtonHandler.h"
#import "MasterViewController.h"

@import MapKit;
@class AppDelegate;

@interface EventsMapViewController : UIViewController <MKMapViewDelegate, SplitViewButtonHandler>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@property (strong, nonatomic) MasterViewController *masterViewController;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong)  AppDelegate *appDelegate;


@end
