//
//  EventsMapViewController.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 4/11/14.
//  Copyright (c) 2014 Lori Hill. All rights reserved.
//

#import "EventsMapViewController.h"
#import "EventsInCoreData.h"
#import "CEMapItem.h"
#import "CEAnnotation.h"
#import "DetailViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

@interface EventsMapViewController ()

@property (assign) BOOL eventsMapped;
@property (nonatomic, strong) NSArray *mapItemsArray;

@end

@implementation EventsMapViewController

@synthesize splitViewButton = _splitViewButton;
NSNumber *eventIdToFetch;

#pragma mark - Init and loading

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		if (self.masterPopoverController != nil) {
			[self.masterPopoverController dismissPopoverAnimated:YES];
		}
	}
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.appDelegate = (id) [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = [self.appDelegate managedObjectContext];
	[self.mapView setDelegate:self];
	

				
	EventsInCoreData *eventsInCoreData = [EventsInCoreData alloc];
	eventsInCoreData.managedObjectContext = self.managedObjectContext;
	self.mapItemsArray = [eventsInCoreData arrayOfMapItems];
	
	// Show progress window
	
	if ([self.mapItemsArray count] > 0) {
		self.eventsMapped = YES;
		[self addPinsToMap];
	} else {
		// Show progress window
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		hud.labelText = @"Loading Croatian Events";
	}
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(eventsFinishedLoading)
                                                 name:@"DoneLoadingLocations"
                                               object:nil];
}
- (void)dealloc {
    
//    LogMethod();
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneLoadingLocations" object:nil];

    
}
- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		if (!self.eventsMapped) {
			if ([self.mapItemsArray count] > 0) {
				[self addPinsToMap];
				self.eventsMapped = NO;
			}
		}
	}

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Mapping 

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    NSString * annotationIdentifier = nil;
    if ([annotation isKindOfClass:CEAnnotation.class]) {
        annotationIdentifier = @"eventIdentifier";
    }
    if (!annotation) {
        return nil;
    }
    MKPinAnnotationView * annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    if(annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        annotationView.canShowCallout = YES;
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//        annotationView.image = [UIImage imageNamed:@"MyAnnotationPin"];
        annotationView.centerOffset = CGPointMake(-10.0f, 0.0f);
    }
    annotationView.annotation = annotation;

    return annotationView;
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([view.annotation isKindOfClass:CEAnnotation.class]) {
		CEAnnotation *annotation = view.annotation;
		eventIdToFetch = annotation.eventId;
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			DetailViewController *newController = nil;

			newController = (DetailViewController *)[self.masterViewController chooseViewController: @"EventDetailViewController"];
			NSManagedObject *object = [self fetchSelectedEvent: eventIdToFetch];
			newController.detailItem = object;
			
			UIBarButtonItem *mapButton = [[UIBarButtonItem alloc]
								   initWithTitle:@"Map"
								   style:UIBarButtonItemStyleBordered 
								   target:self.masterViewController
								   action:@selector(mapView)];
			self.masterViewController.navigationItem.leftBarButtonItem = mapButton;
		} else {
			[self performSegueWithIdentifier: @"mapToEventDetail" sender: self];
		}
    }
}
- (void) eventsFinishedLoading {
	
		[self addPinsToMap];
}

/*
 On the background thread, retrieve the Array of Placemarks.
 On the main thread, add the annotations to the map.
 */
- (void) addPinsToMap{
    
	EventsInCoreData *eventsInCoreData = [EventsInCoreData alloc];
	eventsInCoreData.managedObjectContext = self.managedObjectContext;
	self.mapItemsArray = [eventsInCoreData arrayOfMapItems];
	
    __block NSArray *annotations;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        annotations = [self getEventLocations];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
    
			if ([annotations count] > 0) {
				[self.mapView showAnnotations:annotations animated:NO];

			} else {
				[self noEventsToMap];
			}
			// Remove progress window
			[MBProgressHUD hideHUDForView:self.view animated:YES];

        });
    });
}
- (void) noEventsToMap {

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"No Events to Map" message:@"View Event List" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];

}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			DetailViewController *newController = nil;

			newController = (DetailViewController *)[self.masterViewController chooseViewController:@"EventDetailViewController"];
			NSManagedObject *object = [self fetchSelectedEvent: eventIdToFetch];
			newController.detailItem = object;
			
			UIBarButtonItem *mapButton = [[UIBarButtonItem alloc]
								   initWithTitle:@"Map"
								   style:UIBarButtonItemStyleBordered 
								   target:self.masterViewController
								   action:@selector(mapView)];
			self.masterViewController.navigationItem.leftBarButtonItem = mapButton;
		} else {
				// segue to event list
			[self performSegueWithIdentifier: @"EventsCalendarSegue" sender: self];
		}
    }
}
//- (void ) displayMapWithLocation: (NSString *) location {
- (NSMutableArray *)getEventLocations{

    NSMutableArray *annotations = [[NSMutableArray alloc]init];

	// Create and initialize a search request object.
	MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];

	request.region = self.mapView.region;
	[self.mapView setRegion:[self.mapView regionThatFits:request.region] animated:YES];
	


	for (CEMapItem *item in self.mapItemsArray) {
		CEAnnotation *temp = [[CEAnnotation alloc]init];
		[temp setEventId: item.eventId];
        [temp setTitle: item.name];
        [temp setSubtitle: [self stringFromDate: item.beginDate]];
		// Process the placemark into coordinates
		 NSString *latDest1 = [NSString stringWithFormat:@"%.4f",item.placemark.location.coordinate.latitude];
		 NSString *lngDest1 = [NSString stringWithFormat:@"%.4f",item.placemark.location.coordinate.longitude];
		[temp setCoordinate:CLLocationCoordinate2DMake([latDest1 floatValue], [lngDest1 floatValue])];
        [temp setCoordinate:CLLocationCoordinate2DMake([latDest1 floatValue], [lngDest1 floatValue])];
		[annotations addObject: temp];
	}

	return annotations;
		
}
- (NSString *) stringFromDate: (NSDate *) beginDate {

	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateStyle: NSDateFormatterLongStyle];

	NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
	[timeFormat setDateFormat:@"h:mm a"];

	NSString *theDate = [dateFormat stringFromDate:beginDate];
	
	NSString *theTime = [timeFormat stringFromDate: beginDate];
	
	//if no time was entered display as blank
	unsigned unitFlags = NSCalendarUnitHour  | NSCalendarUnitMinute;
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:beginDate];
	
	if (comps.hour == 0 && comps.minute == 0) {
		theTime = @"";
	}
	
//	NSLog (@" date is %@  %@", theDate, theTime);
	return [NSString stringWithFormat: @"%@  %@", theDate, theTime];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"mapToEventDetail"]) {
        NSManagedObject *object = [self fetchSelectedEvent: eventIdToFetch];
        [[segue destinationViewController] setDetailItem:object];
    }
}

-(NSManagedObject *)fetchSelectedEvent:(NSNumber *)eventId {

    NSArray *fetchedObjects;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Event"  inManagedObjectContext: context];
    [fetch setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"eventId = %@", eventId];
	
	[fetch setPredicate:predicate];
	NSError * error = nil;
    fetchedObjects = [context executeFetchRequest:fetch error:&error];

    if([fetchedObjects count] == 1)
    return [fetchedObjects objectAtIndex:0];
    else
    return nil;  

}

#pragma mark - Split view

#pragma mark - Split View Handler
-(void) turnSplitViewButtonOn: (UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *) popoverController {
    barButtonItem.title = NSLocalizedString(@"All Events", @"All Events");
    _splitViewButton = barButtonItem;
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

-(void)turnSplitViewButtonOff {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    _splitViewButton = nil;
    self.masterPopoverController = nil;
    
}

-(void) setSplitViewButton:(UIBarButtonItem *)splitViewButton forPopoverController:(UIPopoverController *)popoverController {
    if (splitViewButton != _splitViewButton) {
        if (splitViewButton) {
            [self turnSplitViewButtonOn:splitViewButton forPopoverController:popoverController];
        } else {
            [self turnSplitViewButtonOff];
        }
    }
}
@end
