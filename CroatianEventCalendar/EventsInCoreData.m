//
//  EventsInCoreData.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//

#import "EventsInCoreData.h"
#import "Event.h"

@implementation EventsInCoreData

@synthesize event = event_;
@synthesize managedObjectContext = managedObjectContext_;


- (void)dealloc {
    
}    
- (void)addEventsToCoreData:(NSArray *) events {
    //LogMethod();
    //this is an array of dictionaries
    
    NSError *error = nil;
    // insert the events into Core Data
    for (id newEvent in events) {

//if event is older than yesterday, don't add it
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
		
		if ([self dateIsOlderThanYesterday: date]) {
			continue;
		}
		
        Event *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.managedObjectContext];

		event.eventId = [NSNumber numberWithInteger:[[newEvent valueForKey: @"id"] intValue]];
        event.name = [newEvent valueForKey: @"name"];
        
		event.beginDate = date;

        comps = [[NSDateComponents alloc] init];
        [comps setYear:[[newEvent valueForKey: @"year_end"] intValue]];
        [comps setMonth:[[newEvent valueForKey: @"month_end"] intValue]];
        [comps setDay:[[newEvent valueForKey: @"day_end"] intValue]];
        
//		NSLog (@"incoming end date values %i %i %i", [[newEvent valueForKey: @"year_end"] intValue], [[newEvent valueForKey: @"month_end"] intValue], [[newEvent valueForKey: @"day_end"] intValue]);
		
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
		
//		NSLog(@" --------------> endDate is %@", event.endDate);
        
        event.location = [newEvent valueForKey: @"location"];
        event.email = [newEvent valueForKey: @"email"];
        event.phone = [newEvent valueForKey: @"phone"];
        event.link = [newEvent valueForKey: @"link"];
        event.link_name = [newEvent valueForKey: @"link_name"];
        event.desc = [newEvent valueForKey: @"description"];
        
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
        }
        
    }

}
- (void)addEventToCoreData:(NSDictionary *) newEvent {
    //LogMethod();
    
    NSError *error = nil;
    // insert the events into Core Data

//if event is older than yesterday, don't add it
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
	
	if ([self dateIsOlderThanYesterday: date]) {
		return;
	}
	
	Event *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.managedObjectContext];

	event.eventId = [NSNumber numberWithInteger:[[newEvent valueForKey: @"id"] intValue]];
	event.name = [newEvent valueForKey: @"name"];
	
	event.beginDate = date;

	comps = [[NSDateComponents alloc] init];
	[comps setYear:[[newEvent valueForKey: @"year_end"] intValue]];
	[comps setMonth:[[newEvent valueForKey: @"month_end"] intValue]];
	[comps setDay:[[newEvent valueForKey: @"day_end"] intValue]];
	
//		NSLog (@"incoming end date values %i %i %i", [[newEvent valueForKey: @"year_end"] intValue], [[newEvent valueForKey: @"month_end"] intValue], [[newEvent valueForKey: @"day_end"] intValue]);
	
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
	
//		NSLog(@" --------------> endDate is %@", event.endDate);
	
	event.location = [newEvent valueForKey: @"location"];
	event.email = [newEvent valueForKey: @"email"];
	event.phone = [newEvent valueForKey: @"phone"];
	event.link = [newEvent valueForKey: @"link"];
	event.link_name = [newEvent valueForKey: @"link_name"];
	event.desc = [newEvent valueForKey: @"description"];
	
	if (![self.managedObjectContext save:&error]) {
		NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
	}
        

}
- (void)updateEventInCoreData:(NSDictionary *) newEvent {
    //LogMethod();
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext]];
    NSError *error = nil;
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"eventId == %@", [NSNumber numberWithInteger:[[newEvent valueForKey: @"id"] intValue]]];
	[fetchRequest setPredicate:predicate];
	NSArray *arrayWithEvent = [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
	
	Event *event = [arrayWithEvent firstObject];
	
	// Now we have the object that we're looking for, we can update it
//	[[response firstObject] setValue:@"Entry" forKey:@"Type"];

    // insert the events into Core Data

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
	
//		NSLog (@"incoming end date values %i %i %i", [[newEvent valueForKey: @"year_end"] intValue], [[newEvent valueForKey: @"month_end"] intValue], [[newEvent valueForKey: @"day_end"] intValue]);
	
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
	
//		NSLog(@" --------------> endDate is %@", event.endDate);
	
	event.location = [newEvent valueForKey: @"location"];
	event.email = [newEvent valueForKey: @"email"];
	event.phone = [newEvent valueForKey: @"phone"];
	event.link = [newEvent valueForKey: @"link"];
	event.link_name = [newEvent valueForKey: @"link_name"];
	event.desc = [newEvent valueForKey: @"description"];
	
	if (![self.managedObjectContext save:&error]) {
		NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
	}
        

}

- (BOOL) dateIsOlderThanYesterday:(NSDate *)checkEventDate
{
    NSDate* enddate = checkEventDate;
    NSDate* yesterday = [NSDate dateWithTimeIntervalSinceNow:(-86400)];
    NSTimeInterval distanceBetweenDates = [enddate timeIntervalSinceDate:yesterday];
    double secondsInMinute = 60;
    NSInteger secondsBetweenDates = distanceBetweenDates / secondsInMinute;

    if (secondsBetweenDates == 0)
        return YES;
    else if (secondsBetweenDates < 0)
        return YES;
    else
        return NO;
}

- (void) listEvents {
//	LogMethod();
//        NSLog(@"***************listEvents**********");

		NSError *error = nil;


        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" 
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

        for (Event *event in fetchedObjects) {

			NSLog (@"Event %@ %@ %@", event.eventId, event.name, event.beginDate);
    }
}
- (NSArray *) arrayOfEvents {
//	LogMethod();
//        NSLog(@"***************listEvents**********");

		NSError *error = nil;

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" 
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
		
			// Make sure the results are sorted by eventId.
		
		[fetchRequest setSortDescriptors: @[ [[NSSortDescriptor alloc] initWithKey: @"eventId" ascending:YES] ]];
    
		NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		
		return fetchedObjects;

}

- (void)removeAllEventsFromCoreData {
//    LogMethod();
    
//select all objects in the Events table
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext]];
    
    NSError * error = nil;
    NSArray * itemsToDelete = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    //error handling goes here
    for (NSManagedObject * item in itemsToDelete) {
        [self.managedObjectContext deleteObject:item];
    }
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
	
}
- (void)removeEventsFromCoreData: (NSArray *) events {
//    LogMethod();
    
//select all objects in the Events table
//    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
//    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext]];
    
//    NSError * error = nil;
//    NSArray * itemsToDelete = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    //error handling goes here
    for (NSManagedObject * item in events) {
        [self.managedObjectContext deleteObject:item];
    }
    NSError *error = nil;
    [self.managedObjectContext save:&error];
	
}

@end
