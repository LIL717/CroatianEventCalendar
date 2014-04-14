//
//  CEMapItem.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 4/11/14.
//  Copyright (c) 2014 Lori Hill. All rights reserved.
//

#import "CEMapItem.h"

@implementation CEMapItem

- (void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:self.eventId forKey:@"EVENTID"];
    [aCoder encodeObject:self.name forKey:@"NAME"];
	[aCoder encodeObject:self.beginDate forKey:@"BEGINDATE"];
	[aCoder encodeObject:self.placemark forKey:@"PLACEMARK"];


}

-(id)initWithCoder:(NSCoder *)aDecoder{
  if(self = [super init]){
	self.eventId = [aDecoder decodeObjectForKey:@"EVENTID"];
	self.name = [aDecoder decodeObjectForKey:@"NAME"];
	self.beginDate = [aDecoder decodeObjectForKey: @"BEGINDATE"];
    self.placemark = [aDecoder decodeObjectForKey:@"PLACEMARK"];

  }
  return self;
}
@end
