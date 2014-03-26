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
- (void)addEventToCoreData:(Event *)newEvent {
    //LogMethod();
    //this is an array of dictionaries
    
    NSError *error = nil;
    // insert the events into Core Data
//    for (id newEvent in events) {

        Event *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.managedObjectContext];

		event.eventId = [NSNumber numberWithInteger:[[newEvent valueForKey: @"id"] intValue]];
        event.name = [newEvent valueForKey: @"name"];
        
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setYear:[[newEvent valueForKey: @"year"] intValue]];
        [comps setMonth:[[newEvent valueForKey: @"month"] intValue]];
        [comps setDay:[[newEvent valueForKey: @"day"] intValue]];
        
        int hour = [[newEvent valueForKey: @"hour"] intValue];
        if ([[newEvent valueForKey: @"ampm"] isEqualToString: @"PM"]) {
            if (hour != 12) {
                hour += 12;
            }
        }
        [comps setHour: hour];
        
        [comps setMinute:[[newEvent valueForKey: @"minute"] intValue]];
        NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
        event.beginDate = date;
        
        comps = [[NSDateComponents alloc] init];
        [comps setYear:[[newEvent valueForKey: @"year_end"] intValue]];
        [comps setMonth:[[newEvent valueForKey: @"month_end"] intValue]];
        [comps setDay:[[newEvent valueForKey: @"day_end"] intValue]];
        
        hour = [[newEvent valueForKey: @"hour_end"] intValue];
        if ([[newEvent valueForKey: @"ampm_end"] isEqualToString: @"PM"]) {
            if (hour != 12) {
                hour += 12;
            }
        }
        [comps setHour: hour];
        
        [comps setMinute:[[newEvent valueForKey: @"minute_end"] intValue]];
        
        date = [[NSCalendar currentCalendar] dateFromComponents:comps];
        event.endDate = date;
        
        event.location = [newEvent valueForKey: @"location"];
        event.email = [newEvent valueForKey: @"email"];
        event.phone = [newEvent valueForKey: @"phone"];
        event.link = [newEvent valueForKey: @"link"];
        event.link_name = [newEvent valueForKey: @"link_name"];
        event.desc = [newEvent valueForKey: @"description"];
        
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
        }
        
//    }
    

}
- (void) listEvents {
// Test listing all Events from the store
	LogMethod();
//        NSLog(@"***************listEvents**********");
//        NSSet *set=[self.event eventTimes];

		NSError *error = nil;


        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" 
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

        for (Event *event in fetchedObjects) {

			NSLog (@"Event ID %@", event.eventId);
            NSLog(@"Name: %@", event.name);
            NSLog(@" desc %@", event.desc);
            NSLog(@" beginDate %@", event.beginDate);
            //        NSArray *timesArray = [performer.performanceTimes allObjects];
//            for (Schedule *schedule in set) {
//                NSLog(@"Begin Time: %@", schedule.beginTime);
//            }
    }
// end test
}

- (void)removeExpiredEventsFromCoreData {
//    LogMethod();
    
//select all objects in the Events table
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext]];
//    [itemsToDelete setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	// Set up predicate here
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"beginDate < %@", [NSDate dateWithTimeIntervalSinceNow:(-86400)]];

	[fetchRequest setPredicate:predicate];
    
    NSError * error = nil;
    NSArray * itemsToDelete = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    //error handling goes here
    for (NSManagedObject * item in itemsToDelete) {
        [self.managedObjectContext deleteObject:item];
    }
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
	
}

@end
