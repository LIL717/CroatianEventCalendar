//
//  MasterViewController.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/13.
//  Copyright (c) 2013 Lori Hill. All rights reserved.
//

@import MessageUI;

@class AppDelegate;

@interface MasterViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate,MFMailComposeViewControllerDelegate, UISplitViewControllerDelegate>

@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong)   AppDelegate *appDelegate;

- (IBAction)addEventViaEmail:(id)sender;
- (UIViewController *) chooseViewController: (NSString *) viewControllerIdentifier;


@end
