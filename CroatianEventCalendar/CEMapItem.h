//
//  CEMapItem.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 4/11/14.
//  Copyright (c) 2014 Lori Hill. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CEMapItem : NSObject

@property (nonatomic, strong) NSNumber *eventId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *beginDate;
@property (nonatomic, strong) MKPlacemark *placemark;

@end
