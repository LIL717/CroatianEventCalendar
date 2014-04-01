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
#import "InsertEvents.h"
#import "Event.h"


@interface MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation MasterViewController
@synthesize fetchedResultsController = _fetchedResultsController;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.appDelegate = (id) [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = [self.appDelegate managedObjectContext];

	// Do any additional setup after loading the view, typically from a nib.

    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
	
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CalendarBackgroundImage.png"]];
	
//	InsertEvents *insertEvents = [InsertEvents alloc];
//	insertEvents.managedObjectContext = self.managedObjectContext;
//	
//	[insertEvents listEvents];

    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
	
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
	
//	NSLog (@"textLabel %@, detailLabel %@", cell.textLabel.text, cell.detailTextLabel.text);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        self.detailViewController.detailItem = object;
    }
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
 
    NSFetchedResultsController *theFetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
            managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil
            cacheName:@"Root"];
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
@end
