//
//  MasterViewController.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/13.
//  Copyright (c) 2013 Lori Hill. All rights reserved.
//

#import "MasterViewController.h"

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "EventsMapViewController.h"
#import "EventsInCoreData.h"
#import "Event.h"



@interface MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation MasterViewController
@synthesize fetchedResultsController = _fetchedResultsController;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		EventsMapViewController *eventsMapViewController = nil;
		eventsMapViewController = (EventsMapViewController *)[self chooseViewController:@"EventsMapViewController"];
		eventsMapViewController.masterViewController = self;
		[self.splitViewController setDelegate:self];
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	//stupid ios 7 bug that won't deselect on back gesture - needs the following line
	self.clearsSelectionOnViewWillAppear = NO;

	
	self.appDelegate = (id) [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = [self.appDelegate managedObjectContext];

	// Do any additional setup after loading the view, typically from a nib.
	
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tileBackground"]];
//	}
	EventsInCoreData *eventsInCoreData = [EventsInCoreData alloc];
	eventsInCoreData.managedObjectContext = self.managedObjectContext;
	[eventsInCoreData listEvents];

    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
	
}
- (void)viewDidAppear:(BOOL)animated
{
	LogMethod();
    [super viewDidAppear:animated];

    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated: animated];
}
- (void)dealloc {
    
    LogMethod();
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo =
	[[_fetchedResultsController sections] objectAtIndex:section];
//	NSLog (@"row in section %lu", (unsigned long) [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Event *event = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [event valueForKey:@"name"];
	
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateStyle: NSDateFormatterLongStyle];

	NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
	[timeFormat setDateFormat:@"h:mm a"];

	NSString *theDate = [dateFormat stringFromDate:[event valueForKey:@"beginDate"]];
	
	NSString *theTime = [timeFormat stringFromDate: [event valueForKey:@"beginDate"]];
	
	//if no time was entered display as blank
	unsigned unitFlags = NSCalendarUnitHour  | NSCalendarUnitMinute;
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:[event valueForKey: @"beginDate"]];
	if (comps.hour == 0 && comps.minute == 0) {
		theTime = @"";
	}
	
	cell.detailTextLabel.text = [NSString stringWithFormat: @"%@  %@", theDate, theTime];
	cell.backgroundColor = [UIColor clearColor];
//	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.textLabel.highlightedTextColor = [UIColor blueColor];
	cell.detailTextLabel.highlightedTextColor = [UIColor blueColor];
	
//	NSLog (@"textLabel %@, detailLabel %@", cell.textLabel.text, cell.detailTextLabel.text);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
		// set the alpha to half on the selected row so that the background shows through
		UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
		cell.selectedBackgroundView.alpha = 0.5;
		

	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		DetailViewController *newController = nil;

		newController = (DetailViewController *)[self chooseViewController:@"EventDetailViewController"];
		NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
		newController.detailItem = object;
		
		UIBarButtonItem *mapButton = [[UIBarButtonItem alloc]
                               initWithTitle:@"Map"
                               style:UIBarButtonItemStyleBordered 
                               target:self 
                               action:@selector(mapView)];
		self.navigationItem.leftBarButtonItem = mapButton;
	}

}
- (void) mapView {

		EventsMapViewController *newController = nil;
		newController = (EventsMapViewController *)[self chooseViewController:@"EventsMapViewController"];
		newController.masterViewController = self;
		self.navigationItem.leftBarButtonItem = nil;
		//get rid of highlighted cell
		[self.tableView reloadData];

}
- (UIViewController *) chooseViewController: (NSString *) viewControllerIdentifier {

        UIStoryboard *storyboard = [self storyboard];
        DetailViewController *newController = nil;

		newController = [storyboard instantiateViewControllerWithIdentifier:viewControllerIdentifier];

        // now set this to the navigation controller
        UINavigationController *navController = [[[self splitViewController ] viewControllers ] lastObject ];
        DetailViewController *oldController = [[navController viewControllers] firstObject];
        
        NSArray *newStack = [NSArray arrayWithObjects:newController, nil ];
        [navController setViewControllers:newStack];
        
        UIBarButtonItem *splitViewButton = [[oldController navigationItem] leftBarButtonItem];
        UIPopoverController *popoverController = [oldController masterPopoverController];
        [newController setSplitViewButton:splitViewButton forPopoverController:popoverController];
        
        // see if we should be hidden
        if (!UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
            // we are in portrait mode so go away
            [popoverController dismissPopoverAnimated:YES];
            
        }
		
		return newController;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:object];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
 
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
 
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
        entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
 
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
        initWithKey:@"beginDate" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
 
    [fetchRequest setFetchBatchSize:20];
	
	//only show events that are from yesterday on (so that an ongoing event still appears)
	NSDate *yesterdaysDate = [NSDate dateWithTimeIntervalSinceNow: -86400];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"beginDate > %@", yesterdaysDate];
	
	[fetchRequest setPredicate:predicate];
 
    NSFetchedResultsController *theFetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
            managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil
            cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
 
    return _fetchedResultsController;
 
}



- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}
 
 
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
 
    UITableView *tableView = self.tableView;
 
    switch(type) {
 
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
 
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
 
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
 
        case NSFetchedResultsChangeMove:
           [tableView deleteRowsAtIndexPaths:[NSArray
arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
           [tableView insertRowsAtIndexPaths:[NSArray
arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
           break;
    }
}
 
 
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
 
    switch(type) {
 
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
 
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}
 
 
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}
- (IBAction)addEventViaEmail:(id)sender {

        if ([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            [controller setSubject:@"Croatian Calendar Request"];
            [controller setMessageBody:@"Please add the following event to the Croatian Event Calendar.<br /><br />Event Name:<br />Location: <br />Begin Date and Time: <br /> End Date and Time: <br />Email: <br />Phone: <br />Website: <br />Description:  " isHTML:YES];
            [controller setToRecipients:[NSArray arrayWithObjects:@"calendar@croatiafest.org",nil]];
			[self presentViewController:controller animated:YES completion:nil];        }
        else{
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"alrt" message:nil delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil] ;
            [alert show];
        }

    }

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError*)error;
{
  if (result == MFMailComposeResultSent) {
    NSLog(@"Request sent");
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - Split View Delegate
- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    UINavigationController *navController = [[[self splitViewController ] viewControllers ] lastObject ];
    DetailViewController *vc = [[navController viewControllers] firstObject];
    
    [vc setSplitViewButton:barButtonItem forPopoverController:popoverController];
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    UINavigationController *navController = [[[self splitViewController ] viewControllers ] lastObject ];
    DetailViewController *vc = [[navController viewControllers] firstObject];
    
    [vc setSplitViewButton:nil forPopoverController:nil];
}
@end
