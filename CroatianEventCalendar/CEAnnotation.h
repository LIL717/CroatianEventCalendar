//
//  CEAnnotation.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 4/11/14.
//  Copyright (c) 2014 Lori Hill. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CEAnnotation : NSObject <MKAnnotation>{
    
	NSNumber *eventId;
    NSString *title;
    NSString *subtitle;
    CLLocationCoordinate2D coordinate;
}

@property (nonatomic, copy) NSNumber * eventId;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * subtitle;
@property (nonatomic, assign)CLLocationCoordinate2D coordinate;

@end