//
//  Event.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//

@class Schedule;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * event;
@property (nonatomic, retain) NSString * beginDate;
@property (nonatomic, retain) NSString * endDate;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * link_name;
@property (nonatomic, retain) NSString * description;
@property (nonatomic, retain) NSString * html;
@end

@interface Event (CoreDataGeneratedAccessors)

//- (void)addEventTimeObject:(Schedule *)value;
//- (void)removeEventTimeObject:(Schedule *)value;
//- (void)addEventTime:(NSSet *)values;
//- (void)removeEventTime:(NSSet *)values;
@end
