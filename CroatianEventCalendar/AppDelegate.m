//
//  AppDelegate.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/13.
//  Copyright (c) 2013 Lori Hill. All rights reserved.
//

#import "AppDelegate.h"
#import "ParseOperation.h"
#import "EventsInCoreData.h"
#import "Event.h"
#import "SparkInspector.h"
#import "MasterViewcontroller.h"
#import "TestFlight.h"
#import "Flurry.h"


// this framework was imported so we could use the kCFURLErrorNotConnectedToInternet error code
#import <CFNetwork/CFNetwork.h>

#pragma mark CroatiaFestAppDelegate ()

// forward declarations
@interface AppDelegate ()

@property (nonatomic, retain) NSURLConnection *webConnection;
@property (nonatomic, retain) NSMutableData *eventData;    // the data returned from the NSURLConnection
@property (nonatomic, retain) NSOperationQueue *parseQueue;   // the queue that manages our NSOperation for parsing event data
@property (nonatomic, assign) BOOL firstTimeThru;
@property (nonatomic, assign) BOOL doneParsing;
@property (nonatomic, retain) NSMutableArray *arrayOfCoreDataEvents;

- (void) setUpURLConnection;
- (void) distributeParsedData:(NSArray *) parsedData;
- (void) handleError:(NSError *)error;
@end

@implementation AppDelegate

@synthesize window;
@synthesize webConnection;
@synthesize eventData;
@synthesize parseQueue;
@synthesize firstTimeThru;
@synthesize doneParsing;
@synthesize arrayOfCoreDataEvents;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

static NSString * const kEvents = @"events";

- (void)dealloc {
    
    LogMethod();
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAddEventNotif object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kEventErrorNotif object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kDoneParsingNotif object:nil];

}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    LogMethod ();
	
	NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);

	[[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                       [UIColor colorWithRed:252.0 green:0.0 blue:0.0 alpha:1.0], NSForegroundColorAttributeName,
                                                       shadow, NSShadowAttributeName,
                                                       [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:25.0], NSFontAttributeName, nil]];
				
    // Override point for customization after application launch.
	
	//Override point for customization after application launch.
//    [TestFlight takeOff:@"28a6b2db-af02-4d35-a1de-46f4c6a84386"];
     //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
     [Flurry setCrashReportingEnabled:YES];
     
    // Replace YOUR_API_KEY with the api key in the downloaded package
    [Flurry startSession:@"YZJXTYRRX5VJMBJZHM29"];
    [self setUpURLConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addParsedData:)
                                                 name:kAddEventNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(parsedDataError:)
                                                 name:kEventErrorNotif
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(parsingComplete:)
                                                 name:kDoneParsingNotif
                                               object:nil];
    
    self.firstTimeThru = YES; //use this bool to get array of what is in core data once when new data is coming in
	self.doneParsing = NO; //gets set when the last batch of data is passed
    self.eventData = nil;
    
    
    return YES;
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    LogMethod ();
    
    //#define TESTING 1
    //#ifdef TESTING
    //    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    //#endif
    
//    [self setUpURLConnection];
//    self.firstTimeThru = YES; //use this bool to only reset core data once when new data is coming in
//	self.doneParsing = NO;
//    self.eventData = nil;
    
    
}

- (void) setUpURLConnection {
    LogMethod ();
    
    // Use NSURLConnection to asynchronously download the data. This means the main thread will not
    // be blocked - the application will remain responsive to the user.
    //
    // IMPORTANT! The main thread of the application should never be blocked!
    // Also, avoid synchronous network access on any thread.
    //
    static NSString *feedURLString = @"http://www.croatiafest.org/xml/event.xml";

    NSURLRequest *eventURLRequest =
    [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString] cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 60.0];
    
    self.webConnection = [[NSURLConnection alloc] initWithRequest:eventURLRequest delegate:self];
    
    // Test the validity of the connection object. The most likely reason for the connection object
    // to be nil is a malformed URL, which is a programmatic error easily detected during development.
    // If the URL is more dynamic, then you should implement a more flexible validation technique,
    // and be able to both recover from errors and communicate problems to the user in an
    // unobtrusive manner.
    NSAssert(self.webConnection != nil, @"Failure to create URL connection.");
    
    // Start the status bar network activity indicator. We'll turn it off when the connection
    // finishes or experiences an error.
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    parseQueue = [NSOperationQueue new];
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    LogMethod();
    
    NSError *error = nil;
    if (managedObjectContext_ != nil) {
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error])
            [self saveContext];
        //        //remove this code after testing
        //            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //            abort();
        
    }
}


#pragma mark -
#pragma mark NSURLConnection delegate methods

// The following are delegate methods for NSURLConnection. Similar to callback functions, this is
// how the connection object, which is working in the background, can asynchronously communicate back
// to its delegate on the thread from which it was started - in this case, the main thread.
//
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // check for HTTP status code for proxy authentication failures
    // anything in the 200 to 299 range is considered successful,
    // also make sure the MIMEType is correct:
    //
    LogMethod();
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSLog (@"httpResponse is %ld", (long)httpResponse.statusCode);
    NSLog (@"response.MIMEType is %@", response.MIMEType);
    
    if ((([httpResponse statusCode]/100) == 2) && [[response MIMEType] isEqual:@"text/xml"]) {
        
        self.eventData = [NSMutableData data];
        //        self.eventData = [[[NSMutableData alloc] init] autorelease];
        
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
                                  NSLocalizedString(@"HTTP Error",
                                                    @"Connection Error.")
                                                             forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"HTTP" code:[httpResponse statusCode] userInfo:userInfo];
        [self handleError:error];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //    LogMethod();
    
    [eventData appendData:data];
    //        the following statement just shows binary data
    //        NSLog (@"(eventData is %@", eventData);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    LogMethod();
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if ([error code] == kCFURLErrorNotConnectedToInternet) {
        // if we can identify the error, we can present a more precise message to the user.
        NSDictionary *userInfo =
        [NSDictionary dictionaryWithObject:
         NSLocalizedString(@"Connection Error",
                           @"Not connected to the Internet.")
                                    forKey:NSLocalizedDescriptionKey];
        NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                         code:kCFURLErrorNotConnectedToInternet
                                                     userInfo:userInfo];
        [self handleError:noConnectionError];
    } else {
        // otherwise handle the error generically
        [self handleError:error];
    }
    self.webConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    LogMethod();
    
    self.webConnection = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // Spawn an NSOperation to parse the data so that the UI is not blocked while the
    // application parses the XML data.
    //
    // IMPORTANT! - Don't access or affect UIKit objects on secondary threads.
    //
    //    DataModel *model = [[DataModel alloc] init];
    
    
    ParseOperation *parseOperation = [[ParseOperation alloc] initWithData: self.eventData];
//don't think I need this
    //need to pass managedObjectContext because ParseOperation calls core data to check version number
//    parseOperation.managedObjectContext = self.managedObjectContext;
    
    [self.parseQueue addOperation:parseOperation];
    
    // eventData will be retained by the NSOperation until it has finished executing,
    // so we no longer need a reference to it in the main thread.
    self.eventData = nil;
}
#pragma mark -
#pragma mark handle data coming from URL

//
- (void)handleError:(NSError *)error {
    LogMethod();
    
    NSString *errorMessage = [error localizedDescription];
    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:
     NSLocalizedString(@"Connection Error",
                       @"App will display previously loaded data")
                               message:errorMessage
                              delegate:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil];
    [alertView show];
}

// Our NSNotification callback from the running NSOperation to add the parsed data
//
- (void)addParsedData:(NSNotification *)notif {
    LogMethod();
    
    assert([NSThread isMainThread]);
    [self distributeParsedData:[[notif userInfo] valueForKey:kEventResultsKey]];
    
}

// Our NSNotification callback from the running NSOperation when a parsing error has occurred
//
- (void)parsedDataError:(NSNotification *)notif {
    LogMethod();
    
    assert([NSThread isMainThread]);
    
    [self handleError:[[notif userInfo] valueForKey:kEventMsgErrorKey]];
}

// The NSOperation "ParseOperation" calls addParsedData: via NSNotification, on the main thread
// which in turn calls this method, with batches of parsed objects.
// The batch size is set via the kSizeOfParsedBatch constant.
//
// Our NSNotification callback from the running NSOperation to add the parsed data
//
- (void)parsingComplete:(NSNotification *)notif {
    LogMethod();
    
    doneParsing = YES;
    
}
- (void)distributeParsedData:(NSArray *) parsedData {

    LogMethod();
	
	EventsInCoreData *eventsInCoreData = [EventsInCoreData alloc];
	eventsInCoreData.managedObjectContext = self.managedObjectContext;
	
    if (self.firstTimeThru) {
		self.arrayOfCoreDataEvents = [[NSMutableArray alloc] initWithArray: [eventsInCoreData arrayOfEvents]];
		for (Event *event in arrayOfCoreDataEvents) {

			NSLog (@"Event %@ %@ %@", event.eventId, event.name, event.beginDate);
		}
        self.firstTimeThru = NO;
    }
	// check if core data is empty, just add all events at once
	if ([arrayOfCoreDataEvents count] == 0) {
		// add the whole array of dictionaries to core data because its the first time
		[eventsInCoreData addEventsToCoreData:parsedData];
		return;
	}
	
	// Sort the array of dictionaries in eventID order
	NSArray *incomingEventsArray;
	incomingEventsArray = [parsedData sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *event1, NSDictionary *event2) {
		NSNumber *first = [NSNumber numberWithInt:[[event1 valueForKey: @"id"] intValue]];
		NSNumber *second = [NSNumber numberWithInt:[[event2 valueForKey: @"id"] intValue]];
		return [first compare:second];
	}];

	//index i is for array of incoming events (incomingEventsArray 
	//index j is for array of events currently in CoreData (arrayOfCoreDataEvents)
	int i, j;
	for (i = 0,j = 0; i < [incomingEventsArray count]; i++) {
	
		int incomingId = [[[incomingEventsArray objectAtIndex: i] valueForKey: @"id"]intValue];
		int coreDataId;

		//if there aren't any events left to check in the arrayOfCoreDataEvents then just add the incoming event
		if ([arrayOfCoreDataEvents count] > j) {
			coreDataId = [[(Event *) [arrayOfCoreDataEvents objectAtIndex: j] eventId] intValue];
		} else {
			[eventsInCoreData addEventToCoreData: [incomingEventsArray objectAtIndex: i]];
			break;
		}


//		NSLog (@"incomingEventId is %@", incomingId);
//		NSLog (@"coreDataEventId is %@", coreDataId);
		
		while (incomingId > coreDataId) {

				//if there are more objects in the arrayOfCoreDataEvents then bump up
				if ((j + 1) < [arrayOfCoreDataEvents count]) {
					j++;
					coreDataId = [[(Event *) [arrayOfCoreDataEvents objectAtIndex: j] eventId] intValue];

				} else {
					//entry is not already in core data so add it - this is a new id higher than any in core data
					[eventsInCoreData addEventToCoreData: [incomingEventsArray objectAtIndex: i]];
					break;
				}

		}
		//if event ids match then insert the new event
		if (incomingId < coreDataId) {
			//entry is not already in core data so add it
			[eventsInCoreData addEventToCoreData: [incomingEventsArray objectAtIndex: i]];
		} else if (incomingId == coreDataId) {
			[eventsInCoreData updateEventInCoreData: [incomingEventsArray objectAtIndex: i]];
			[arrayOfCoreDataEvents removeObjectAtIndex: j];
			//don't increment j, it should stay where it is because next object becomes current
		}
	}

	
	if (doneParsing) {
	//delete the events that are in core data that were not present in incomingEvents (what is left in array)
		[eventsInCoreData removeEventsFromCoreData: arrayOfCoreDataEvents];

	}
	
	[eventsInCoreData listEvents];
}

#pragma mark -
#pragma mark save context method
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            UIAlertView* alertView =
            [[UIAlertView alloc] initWithTitle:@"Pazi!! Data Management Error - saving context"
                                       message:@"Press the Home button to quit this application."
                                      delegate:self
                             cancelButtonTitle:@"OK"
                             otherButtonTitles: nil];
            [alertView show];
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CroatianEventCalendar" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CroatianEventCalendar.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end

