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

- (void)addEventsToCoreData:(NSArray *)events forKey: (NSString *) eventType;


@end