//
//  CroatiaFestAppDelegate.h
//  CroatiaFest
//
//  Created by Lori Hill on 6/10/11.
//  Copyright 2011 CroatiaFest. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RootViewController.h"

extern NSString *kNotificationDestroyAllNSFetchedResultsControllers;

@interface CroatiaFestAppDelegate : NSObject <UIApplicationDelegate, NSXMLParserDelegate, NSFetchedResultsControllerDelegate> {
    
@private    
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;

    // for downloading the xml data
    NSURLConnection *webConnection;
    NSMutableData *festivalData;
    NSOperationQueue *parseQueue; 
    
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void) deletePersistentStore;

@end
