//
//  InsertEvents.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//

#import "InsertEvents.h"
#import "Event.h"

@implementation InsertEvents

@synthesize event = event_;
@synthesize managedObjectContext = managedObjectContext_;


- (void)dealloc {
    


}    
- (void)addEventsToCoreData:(NSArray *)events forKey: (NSString *) eventType {
    //LogMethod();
    //this is an array of dictionaries
    
    NSError *error = nil;
    // insert the events into Core Data
    for (id newEvent in events) {

        Event *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
        event.event = [newEvent valueForKey: @"event"];
        event.beginDate = [newEvent valueForKey: @"beginDate"];
        event.endDate =[newEvent valueForKey: @"endDate"];
        event.location = [newEvent valueForKey: @"location"];
        event.email = [newEvent valueForKey: @"email"];
        event.phone = [newEvent valueForKey: @"phone"];
        event.link = [newEvent valueForKey: @"link"];
        event.link_name = [newEvent valueForKey: @"link_name"];
        event.description = [newEvent valueForKey: @"description"];
        event.html = [newEvent valueForKey: @"html"];
        
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
        }
        
    }
    
}
//// Test listing all Events from the store
//    if ([eventType isEqualToString:@"Exhibits"]) {
//        NSLog(@"***************insertEvents**********");
//        NSSet *set=[self.event eventTimes];
//
//        NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
//        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" 
//                                                  inManagedObjectContext:self.managedObjectContext];
//        [fetchRequest setEntity:entity];
//        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
////        for (Performer *performer in fetchedObjects) {
//        for (Event *event in fetchedObjects) {
//
//            NSLog(@"Name: %@", event.name);
//            NSLog(@" %@", event.desc1);
//            //        NSArray *timesArray = [performer.performanceTimes allObjects];
//            for (Schedule *schedule in set) {
//                NSLog(@"Begin Time: %@", schedule.beginTime);
//            }
//        } 
//    }
//// end test 

//        // Test listing all Schedule from the store
////        NSManagedObjectContext *context = self.managedObjectContext;
////        NSError *error = nil;
//        
//        NSFetchRequest *fetchRequest2 = [[[NSFetchRequest alloc] init] autorelease];
//        NSEntityDescription *entity2 = [NSEntityDescription entityForName:@"Schedule" 
//                                                  inManagedObjectContext:context];
//        [fetchRequest2 setEntity:entity2];
//        NSArray *fetchedObjects2 = [context executeFetchRequest:fetchRequest2 error:&error];
//        for (Schedule *schedule in fetchedObjects2) {
//            NSLog(@"Begin Time: %@", schedule.beginTime);
//            Performer *performer = schedule.performer;
//            NSLog(@"Performer name: %@", performer.name);
//        }        
//        // end test 
@end
