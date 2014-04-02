//
//  InsertEvents.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//

@class Event;

@interface InsertEvents : NSManagedObject {

    Event *event_;
}
@property (nonatomic, retain) Event *event;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)addEventsToCoreData:(NSArray *)events;
- (void)addEventToCoreData:(NSDictionary *)newEvent;
- (void)updateEventInCoreData:(NSDictionary *) newEvent;
- (void) listEvents;
- (NSArray *) arrayOfEvents;
- (void)removeAllEventsFromCoreData;
- (void)removeEventsFromCoreData: (NSArray *) events;



@end