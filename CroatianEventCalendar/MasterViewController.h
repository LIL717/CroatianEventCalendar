//
//  MasterViewController.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/13.
//  Copyright (c) 2013 Lori Hill. All rights reserved.
//

@import UIKit;

@class AppDelegate;
@class DetailViewController;

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong)   AppDelegate *appDelegate;


@end