//
//  ParseOperation.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//
#import <Foundation/Foundation.h>

#define EVENT_FEED_TAGS @"id", @"name", @"hour", @"minute", @"ampm", @"hour_end", @"minute_end", @"ampm_end", @"month", @"day", @"year", @"month_end", @"location", @"email", @"phone", @"link", @"link_name", @"description", @"html", nil


extern NSString *kAddEventNotif;
extern NSString *kEventResultsKey;
extern NSString *kDoneParsingNotif;

extern NSString *kEventErrorNotif;
extern NSString *kEventMsgErrorKey;

//@class VersionController;

@interface ParseOperation : NSOperation {
    
    NSData *parseData;
    NSSet *tableItemNames;

    NSMutableDictionary *tableTagsDictionary;
    NSMutableDictionary *currentItemDictionary;
    NSString *currentTableName;
    NSString *currentElementName;

@private
    
    // these variables are used during parsing
    NSMutableArray *currentParseBatch;
    NSMutableString *currentParsedCharacterData;
    
    BOOL accumulatingParsedCharacterData;
    BOOL didAbortParsing;
    NSUInteger parsedRecordCounter;
}

@property (copy, readonly) NSData *parseData;
@property (nonatomic, retain) NSMutableDictionary *tableTagsDictionary;
@property (nonatomic, retain) NSMutableDictionary *currentItemDictionary;
@property (nonatomic, retain) NSMutableDictionary *parsedFinalDictionary;
@property (nonatomic, retain) NSString *currentElementName;
@property (nonatomic, retain) NSString *currentTableName;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSSet *eventItemNames;

- (id)initWithData:(NSData *)data;



@end
