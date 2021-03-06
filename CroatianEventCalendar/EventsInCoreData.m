//
//  EventsInCoreData.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//

#import "EventsInCoreData.h"
#import "Event.h"
#import <MapKit/MapKit.h>
#import "CEMapItem.h"

@implementation EventsInCoreData

@synthesize event = event_;
@synthesize managedObjectContext = managedObjectContext_;
int beginHour;
int requestsMadeCount = 0;
int requestsReturnedCount = 0;


- (void)dealloc {
    
}    
- (void)addEventsToCoreData:(NSArray *) events {
    //LogMethod();
    //this is an array of dictionaries
    
    // insert the events into Core Data
    for (id newEvent in events) {
		[self addEventToCoreData: newEvent];
    }

}
- (void)addEventToCoreData:(NSDictionary *) newEvent {
    //LogMethod();
    
    NSError *error = nil;
    // insert the events into Core Data

	NSDate *date = [self processBeginDate: newEvent];

	NSDate *endDate = [self processEndDate: newEvent];
	//if event is older than yesterday, don't add it
	if ([self dateIsOlderThanYesterday: endDate]) {
		return;
	}
	
	Event *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
	
	//add date separately because it's already been formatted for addEvent
	event.beginDate = date;
	[self formatEvent: event withNewEvent: newEvent];
	
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
	
	//add date separately because it's already been formatted for addEvent and needs to be formatted for updateEvent, also needs to be done before endDate because blank endDate is set to beginDate
	event.beginDate = [self processBeginDate: newEvent];
	[self formatEvent: event withNewEvent: newEvent];

	if (![self.managedObjectContext save:&error]) {
		NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
	}
        
}
- (void) formatEvent: (Event *) event withNewEvent: (NSDictionary *) newEvent {
	
	event.eventId = [NSNumber numberWithInteger:[[newEvent valueForKey: @"id"] intValue]];
	event.name = [newEvent valueForKey: @"name"];
	
	event.endDate = [self processEndDate: newEvent];
	
//		NSLog(@" --------------> endDate is %@", event.endDate);
	
	event.location = [newEvent valueForKey: @"location"];
	[self getMapItemForLocation: [newEvent valueForKey: @"location"] forEvent: event];
	event.email = [newEvent valueForKey: @"email"];
	event.phone = [newEvent valueForKey: @"phone"];
	event.link = [newEvent valueForKey: @"link"];
	
	if ([[newEvent valueForKey: @"link"] length] > 0) {
	NSRange range = [[newEvent valueForKey: @"link"] rangeOfString:@"http://"];
		if (range.length > 0) {
			event.link = [[[newEvent valueForKey: @"link"] substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		}
	}

//	event.link_name = [newEvent valueForKey: @"link_name"];
	event.desc = [newEvent valueForKey: @"description"];
}
-(void) getMapItemForLocation: (NSString *) location forEvent: (Event *) event {

		// Create and initialize a search request object.
		MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
		request.naturalLanguageQuery = location;
//		request.region = self.mapView.region;
//		[self.mapView setRegion:[self.mapView regionThatFits:request.region] animated:YES];
		requestsMadeCount++;
		// Create and initialize a search object.
		MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
		 
		// Start the search and display the results as annotations on the map.
		[search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
		{
			MKMapItem *newMapItem = [response.mapItems firstObject];
			CEMapItem *myMapItem = [CEMapItem alloc];
			myMapItem.eventId = event.eventId;
			myMapItem.name = event.name;
			myMapItem.beginDate = event.beginDate;
			myMapItem.placemark = newMapItem.placemark;
			event.mapItem = [NSKeyedArchiver archivedDataWithRootObject: (CEMapItem *) myMapItem];
			requestsReturnedCount++;
			
			if (requestsReturnedCount == requestsMadeCount) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"DoneLoadingLocations"
                                                        object:self];
			}
			
			if (![self.managedObjectContext save:&error]) {
				NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
			}
			if (error) {
				NSLog (@"error getting mapItem");
			}

	}];
}
- (NSDate*) processBeginDate: (NSDictionary*) newEvent {

	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setYear:[[newEvent valueForKey: @"year"] intValue]];
	[comps setMonth:[[newEvent valueForKey: @"month"] intValue]];
	[comps setDay:[[newEvent valueForKey: @"day"] intValue]];
	
	beginHour = [[newEvent valueForKey: @"hour"] intValue];
	if ([[newEvent valueForKey: @"ampm"] isEqualToString: @"PM"]) {
		if (beginHour != 12) {
			beginHour += 12;
		}
	}
	[comps setHour: beginHour];
	
	[comps setMinute:[[newEvent valueForKey: @"minute"] intValue]];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}
- (NSDate*) processEndDate: (NSDictionary*) newEvent {
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setYear:[[newEvent valueForKey: @"year_end"] intValue]];
	[comps setMonth:[[newEvent valueForKey: @"month_end"] intValue]];
	[comps setDay:[[newEvent valueForKey: @"day_end"] intValue]];
	
//		NSLog (@"incoming end date values %i %i %i", [[newEvent valueForKey: @"year_end"] intValue], [[newEvent valueForKey: @"month_end"] intValue], [[newEvent valueForKey: @"day_end"] intValue]);
	
	int endHour = [[newEvent valueForKey: @"hour_end"] intValue];
	if ([[newEvent valueForKey: @"ampm_end"] isEqualToString: @"PM"]) {
		if (endHour != 12) {
			endHour += 12;
		}
	}
	[comps setHour: endHour];
	[comps setMinute:[[newEvent valueForKey: @"minute_end"] intValue]];
		//if there is no end date, set the end date to the begin date
	if (comps.day == 0) {
		[comps setYear:[[newEvent valueForKey: @"year"] intValue]];
		[comps setMonth:[[newEvent valueForKey: @"month"] intValue]];
		[comps setDay:[[newEvent valueForKey: @"day"] intValue]];
		if (comps.hour == 0 && comps.minute == 0) {
			[comps setHour: beginHour];
			[comps setMinute:[[newEvent valueForKey: @"minute"] intValue]];
		}
	}

	return [[NSCalendar currentCalendar] dateFromComponents:comps];
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
			CEMapItem *mapItem = [NSKeyedUnarchiver unarchiveObjectWithData:event.mapItem];
			NSLog (@"Event %@ %@ %@ %@ %@ %@", event.eventId, event.name, event.beginDate, event.endDate, mapItem.name, mapItem.eventId);
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
- (NSArray *) arrayOfMapItems {
//	LogMethod();
//        NSLog(@"***************listEvents**********");

		NSError *error = nil;

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" 
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
				
//		[fetchRequest setSortDescriptors: @[ [[NSSortDescriptor alloc] initWithKey: @"eventId" ascending:YES] ]];
    
		NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		
		NSMutableArray *mapItemsArray = [[NSMutableArray alloc] initWithCapacity: [fetchedObjects count]];
		for (Event *event in fetchedObjects) {
			CEMapItem *mapItem = [NSKeyedUnarchiver unarchiveObjectWithData:event.mapItem];
			if (mapItem) {
				[mapItemsArray addObject: mapItem];
			}
    }
		
		return mapItemsArray;

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
