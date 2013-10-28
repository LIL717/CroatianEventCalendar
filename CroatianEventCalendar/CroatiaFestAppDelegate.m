//
//  CroatiaFestAppDelegate.m
//  CroatiaFest
//
//  Created by Lori Hill on 6/10/11.
//  Copyright 2011 CroatiaFest. All rights reserved.
//

#import "CroatiaFestAppDelegate.h"
#import "ScheduleViewController.h"
#import "RootViewController.h"
#import "EventViewController.h"
#import "MarketplaceViewController.h"
#import "ParseOperation.h"
#import "Directory.h"
#import "Food.h"
#import "InsertEvents.h"
#import "Vendor.h"
#import "VersionController.h"


// this framework was imported so we could use the kCFURLErrorNotConnectedToInternet error code
#import <CFNetwork/CFNetwork.h>

//// customize navBar for pre iOS5 devices
//@implementation UINavigationBar (CustomImage)
//- (void)drawRect:(CGRect)rect
//{
//    UIImage *image = [UIImage imageNamed: @"navigationBarImageMuted.png"];
//    [image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
//}
//@end

#pragma mark CroatiaFestAppDelegate () 

// forward declarations
@interface CroatiaFestAppDelegate ()

@property (nonatomic, retain) NSURLConnection *webConnection;
@property (nonatomic, retain) NSMutableData *festivalData;    // the data returned from the NSURLConnection
@property (nonatomic, retain) NSOperationQueue *parseQueue;   // the queue that manages our NSOperation for parsing festival data
@property (nonatomic, assign) BOOL resetData;

- (void) setUpViewControllers;
- (void) setUpURLConnection;
- (void) distributeParsedData:(NSDictionary *) parsedData;
- (void) handleError:(NSError *)error;
@end

@implementation CroatiaFestAppDelegate

//NSString *kNotificationDestroyAllNSFetchedResultsControllers = @"NotificationDestroyAllNSFetchedResultsControllers";

@synthesize window;
@synthesize webConnection;
@synthesize festivalData;
@synthesize parseQueue;
@synthesize resetData;
@synthesize managedObjectContext = managedObjectContext_;
@synthesize managedObjectModel = managedObjectModel_;
@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize persistentStoreCoordinator = persistentStoreCoordinator_;




- (void)dealloc {

    LogMethod();
    [window release];  
    [webConnection cancel];
    [webConnection release];
    [festivalData release];
    [parseQueue release];
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [fetchedResultsController_ release];
    [persistentStoreCoordinator_ release];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAddFestivalNotif object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFestivalErrorNotif object:nil];
    [super dealloc];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    LogMethod ();
    // Override point for customization after application launch.
//    [TestFlight takeOff:@"edbbcf45a655f8286ea1810a5e350c09_OTE2NjEyMDEyLTA1LTE4IDE4OjE2OjEyLjMyODAxMA"];
//    
//#define TESTING 1
//#ifdef TESTING
//    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
//#endif
    
    [self setUpURLConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addParsedData:)
                                                 name:kAddFestivalNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(parsedDataError:)
                                                 name:kFestivalErrorNotif
                                               object:nil];

    self.resetData = YES; //use this bool to only reset core data once when new data is coming in
    self.festivalData = nil;
    [self setUpViewControllers];   
    [self.window makeKeyAndVisible];


    return YES;

}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    LogMethod ();

//#define TESTING 1
//#ifdef TESTING
//    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
//#endif
    
    [self setUpURLConnection];
    self.resetData = YES; //use this bool to only reset core data once when new data is coming in
    self.festivalData = nil;


}
- (void) setUpViewControllers {
    LogMethod ();

    //Create the tabBarController
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"tabbar-button-red.png"]];



    //Create view controllers
    RootViewController *rootViewController = [[RootViewController alloc] init];
    
    ScheduleViewController *scheduleViewController = [[ScheduleViewController alloc] init];
    scheduleViewController.managedObjectContext = self.managedObjectContext;
    
    EventViewController *eventViewController = [[EventViewController alloc] init];
    eventViewController.managedObjectContext = self.managedObjectContext;

    MarketplaceViewController *marketplaceViewController = [[MarketplaceViewController alloc] init];
    marketplaceViewController.managedObjectContext = self.managedObjectContext;


    //Create navigation controller
    UINavigationController *navController = [[UINavigationController alloc]
                                             initWithRootViewController:rootViewController];
    //Create navigation controller
    UINavigationController *navController2 = [[UINavigationController alloc]
                                              initWithRootViewController:scheduleViewController];

    //Create navigation controller
    UINavigationController *navController3 = [[UINavigationController alloc]
                                              initWithRootViewController:eventViewController];


    //Create navigation controller
    UINavigationController *navController4 = [[UINavigationController alloc]
                                              initWithRootViewController:marketplaceViewController];
    //Customize the look of the UINavBar for iOS5 devices
    if ([[UINavigationBar class]respondsToSelector:@selector(appearance)]) {

//        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigationBarPleter.png"] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"menubar-red.png"] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar  appearance]setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                 [UIFont fontWithName:@"Chalkduster" size:20.0f], UITextAttributeFont,
                                                 [UIColor whiteColor], UITextAttributeTextColor,
                                                 [UIColor grayColor], UITextAttributeTextShadowColor,
                                                 [NSValue valueWithUIOffset:UIOffsetMake(0.0f, 1.0f)], UITextAttributeTextShadowOffset,
                                                 nil]];
//        [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:-10.0f forBarMetrics:(UIBarMetrics)UIBarMetricsDefault];
        UIImage *backButton = [[UIImage imageNamed:@"back-red.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 4)];
                                  
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButton forState:UIControlStateNormal 
                                    barMetrics:UIBarMetricsDefault];
//        [[UIBarButtonItem appearance] setTintColor:[UIColor redColor]];
    }


    //Make an array containing the two view controllers
    NSArray *viewControllers = [NSArray arrayWithObjects: navController, navController2, navController3, navController4, nil];

    //The viewControllers array retains them so we can release our ownership of them in this method
    [rootViewController release];
    [scheduleViewController release];
    [eventViewController release];
    [marketplaceViewController release];


    //Attach them to the tab bar controller
    [tabBarController setViewControllers:viewControllers];

    //Set tabBar Controller as rootViewController of window
    //    [self.window setRootViewController:tabBarController];
    self.window.rootViewController = tabBarController;

    [tabBarController release];

    [navController release];
    [navController2 release];
    [navController3 release];
    [navController4 release];
}
- (void) setUpURLConnection { 
    LogMethod ();

    // Use NSURLConnection to asynchronously download the data. This means the main thread will not
    // be blocked - the application will remain responsive to the user. 
    //
    // IMPORTANT! The main thread of the application should never be blocked!
    // Also, avoid synchronous network access on any thread.
    //
    static NSString *feedURLString = @"http://www.croatiafest.org/croatia4_tables.xml";
    NSURLRequest *festivalURLRequest =
    [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString] cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 60.0];

    self.webConnection = [[[NSURLConnection alloc] initWithRequest:festivalURLRequest delegate:self] autorelease];
    
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
    NSLog (@"httpResponse is %d", httpResponse.statusCode);
    NSLog (@"response.MIMEType is %@", response.MIMEType);

    if ((([httpResponse statusCode]/100) == 2) && [[response MIMEType] isEqual:@"text/xml"]) {

        self.festivalData = [NSMutableData data];
//        self.festivalData = [[[NSMutableData alloc] init] autorelease];

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
    
    [festivalData appendData:data];
//        the following statement just shows binary data    
//        NSLog (@"(festivalData is %@", festivalData);
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


    ParseOperation *parseOperation = [[ParseOperation alloc] initWithData: self.festivalData];
    //need to pass managedObjectContext because ParseOperation calls core data to check version number
    parseOperation.managedObjectContext = self.managedObjectContext;

    [self.parseQueue addOperation:parseOperation];
    [parseOperation release];   // once added to the NSOperationQueue it's retained, we don't need it anymore
    //    [model release];
    
    // festivalData will be retained by the NSOperation until it has finished executing,
    // so we no longer need a reference to it in the main thread.
    self.festivalData = nil;
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
    [alertView release];
}

// Our NSNotification callback from the running NSOperation to add the parsed data
//
- (void)addParsedData:(NSNotification *)notif {
    LogMethod();
    
    assert([NSThread isMainThread]);
    
    [self distributeParsedData:[[notif userInfo] valueForKey:kFestivalResultsKey]];
    
}

// Our NSNotification callback from the running NSOperation when a parsing error has occurred
//
- (void)parsedDataError:(NSNotification *)notif {
    LogMethod();
    
    assert([NSThread isMainThread]);
    
    [self handleError:[[notif userInfo] valueForKey:kFestivalMsgErrorKey]];
}

// The NSOperation "ParseOperation" calls addParsedData: via NSNotification, on the main thread
// which in turn calls this method, with batches of parsed objects.
// The batch size is set via the kSizeOfParsedBatch constant.
//

- (void)distributeParsedData:(NSDictionary *) parsedData {
    LogMethod();
//    NSLog (@"parsedData dictionary is %@", parsedData);

    if (self.resetData) {
        [self deletePersistentStore];
        self.resetData = NO;  //only reset Core Data the first time that data is coming in here in case it comes back in multiple batches
        // moc is deleted and re-created so need to re-setup view controllers
        [self setUpViewControllers]; 
    }
// read through dictionary, for each key, call method for that type of table with the dictionary of parsed data
    NSEnumerator *enumerator = [parsedData keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        /* code that uses the returned key */
        NSLog (@"key is %@", key);
        NSArray* passedArray = [[[NSArray alloc] initWithArray:[parsedData objectForKey:key]] autorelease];

        if ([key isEqualToString: @"appControl"]) {
            VersionController *versionController = [[VersionController alloc] autorelease];
            versionController.managedObjectContext = self.managedObjectContext;

            [versionController insertVersion: passedArray];
        }
        if ([key isEqualToString: @"cookingDemos"]) {
            InsertEvents *insertEvents = [[InsertEvents alloc] autorelease];
            insertEvents.managedObjectContext = self.managedObjectContext;
            [insertEvents addEventsToCoreData:passedArray forKey: @"Cooking Demos"];
        }
        if ([key isEqualToString: @"directory"]) {
            Directory *directory = [[Directory alloc] autorelease];
            directory.managedObjectContext = self.managedObjectContext;
            [directory addDirectoryToCoreData:passedArray];
        }
        if ([key isEqualToString: @"exhibits"]) {
            InsertEvents *insertEvents = [[InsertEvents alloc] autorelease];
            insertEvents.managedObjectContext = self.managedObjectContext;
            [insertEvents addEventsToCoreData:passedArray forKey: @"Exhibits"];
        }
        if ([key isEqualToString: @"festivalActivities"]) {
            InsertEvents *insertEvents = [[InsertEvents alloc] autorelease];
            insertEvents.managedObjectContext = self.managedObjectContext;

            [insertEvents addEventsToCoreData:passedArray forKey: @"Activities"];
        }
        if ([key isEqualToString: @"food"]) {
            Food *food = [[Food alloc] autorelease];
            food.managedObjectContext = self.managedObjectContext;
            [food addFoodToCoreData:passedArray];
        }
        if ([key isEqualToString: @"performers"]) {
            InsertEvents *insertEvents = [[InsertEvents alloc] autorelease];
            insertEvents.managedObjectContext = self.managedObjectContext;
            [insertEvents addEventsToCoreData:passedArray forKey: @"Performers"];
        }
        if ([key isEqualToString: @"vendors"]) {
            Vendor *vendor = [[Vendor alloc] autorelease];
            vendor.managedObjectContext = self.managedObjectContext;
            [vendor addVendorsToCoreData:passedArray];
        }
        if ([key isEqualToString: @"workshops"]) {
            InsertEvents *insertEvents = [[InsertEvents alloc] autorelease];
            insertEvents.managedObjectContext = self.managedObjectContext;
            [insertEvents addEventsToCoreData:passedArray forKey: @"Workshops"];
        }
    }
}
- (void) deletePersistentStore {
    LogMethod();
    //     retrieve the store URL
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores lastObject];
    NSError *error = nil;
    NSURL *storeURL = store.URL;
    [self.persistentStoreCoordinator removePersistentStore:store error:&error];

    // Release CoreData chain
    [managedObjectContext_ release];
    managedObjectContext_ = nil;
    [persistentStoreCoordinator_ release];
    persistentStoreCoordinator_ = nil;

//    // Delete the sqlite file
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
    }
   
    //NSLog(@"Data Reset");
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
            [alertView release];
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext_ != nil)
    {
        return managedObjectContext_;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel_ != nil)
    {
        return managedObjectModel_;
    }
//    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"CroatiaFest" ofType:@"momd"];
//    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CroatiaFest" withExtension:@"momd"];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator_ != nil)
    {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CroatiaFest.sqlite"];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        UIAlertView* alertView =
        [[UIAlertView alloc] initWithTitle:@"Pazi!! Data Management Error with Persistent Store Coordinator" 
                                   message:@"Press the Home button to quit this application." 
                                  delegate:self 
                         cancelButtonTitle:@"OK" 
                         otherButtonTitles: nil];
        [alertView show];
        [alertView release];
        
    }    
    
    return persistentStoreCoordinator_;
}
#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
 