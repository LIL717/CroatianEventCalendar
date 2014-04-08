//
//  AppDelegate.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/13.
//  Copyright (c) 2013 Lori Hill. All rights reserved.
//

@import UIKit;
@import Foundation;
@import CoreData;

//extern NSString *kNotificationDestroyAllNSFetchedResultsControllers;

@interface AppDelegate : NSObject <UIApplicationDelegate, NSXMLParserDelegate, NSFetchedResultsControllerDelegate> {
    
@private
    NSManagedObjectContext *managedObjectContext_;
    
    // for downloading the xml data
    NSURLConnection *webConnection;
    NSMutableData *eventData;
    NSOperationQueue *parseQueue;
    
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
