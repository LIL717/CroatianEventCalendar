//
//  ParseOperation.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//
#import <Foundation/Foundation.h>

#define TABLE_FEED_TAGS  @"event", nil

#define EVENT_FEED_TAGS @"event", @"hour", @"minute", @"ampm", @"hour_end", @"minute_end", @"ampm_end", @"month", @"day", @"year", @"month_end", @"location", @"email", @"phone", @"link", @"link_name", @"description", @"html", nil


extern NSString *kAddFestivalNotif;
extern NSString *kFestivalResultsKey;

extern NSString *kFestivalErrorNotif;
extern NSString *kFestivalMsgErrorKey;

@class VersionController;

@interface ParseOperation : NSOperation {
    
    NSData *parseData;
    
    NSSet *tableItemNames;

    NSMutableDictionary *tableTagsDictionary;
    NSMutableDictionary *currentItemDictionary;
    NSString *currentTableName;
    NSString *currentElementName;
    NSMutableDictionary *parsedTablesDictionary;


@private
    
    // these variables are used during parsing
    VersionController *versionController;

    NSMutableArray *currentParseBatch;
    NSMutableString *currentParsedCharacterData;
    
    
    BOOL accumulatingParsedCharacterData;
    BOOL didAbortParsing;
    NSUInteger parsedRecordCounter;
}

@property (copy, readonly) NSData *parseData;
@property (nonatomic, retain) NSMutableDictionary *tableTagsDictionary;
@property (nonatomic, retain) NSMutableDictionary *currentItemDictionary;
@property (nonatomic, retain) NSMutableDictionary *parsedTablesDictionary;
@property (nonatomic, retain) NSString *currentElementName;
@property (nonatomic, retain) NSString *currentTableName;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithData:(NSData *)data;



@end
