//
//  EventsInCoreData.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//

@import MapKit;
@class Event;

@interface EventsInCoreData : NSManagedObject {

    Event *event_;
}
@property (nonatomic, retain) Event *event;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)addEventsToCoreData:(NSArray *)events;
- (void)addEventToCoreData:(NSDictionary *)newEvent;
- (void)updateEventInCoreData:(NSDictionary *) newEvent;
- (void) listEvents;
- (NSArray *) arrayOfEvents;
- (NSArray *) arrayOfMapItems;
- (void)removeAllEventsFromCoreData;
- (void)removeEventsFromCoreData: (NSArray *) events;



@end