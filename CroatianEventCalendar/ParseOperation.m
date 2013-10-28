//
//  ParseOperation.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//

#import "ParseOperation.h"

// NSNotification name for sending Festival data back to the app delegate
NSString *kAddFestivalNotif = @"AddFestivalNotif";

// NSNotification userInfo key for obtaining the Festival data
NSString *kFestivalResultsKey = @"FestivalResultsKey";

// NSNotification name for reporting errors
NSString *kFestivalErrorNotif = @"FestivalErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kFestivalMsgErrorKey = @"FestivalMsgErrorKey";


@interface ParseOperation () <NSXMLParserDelegate>
@property (nonatomic, retain) VersionController *versionController;
@property (nonatomic, retain) NSMutableArray *currentParseBatch;
@property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@end

@implementation ParseOperation

@synthesize parseData;
@synthesize versionController;
@synthesize currentParsedCharacterData;
@synthesize currentParseBatch;

@synthesize tableTagsDictionary;
@synthesize currentItemDictionary;
@synthesize parsedTablesDictionary;
@synthesize currentTableName;
@synthesize currentElementName;
@synthesize managedObjectContext = __managedObjectContext;



- (id)initWithData:(NSData *)data

{
    LogMethod();

    if ((self = [super init])) {   
        tableItemNames = [[NSSet alloc] initWithObjects:TABLE_FEED_TAGS]; 
        self.tableTagsDictionary = [[NSMutableDictionary alloc] initWithCapacity: [tableItemNames count]];
        self.parsedTablesDictionary = [[NSMutableDictionary alloc] initWithCapacity:[tableItemNames count]];

        [self.tableTagsDictionary setValue:[[NSSet alloc] initWithObjects:EVENT_FEED_TAGS] forKey:@"event"];

        parseData = [data copy];

    }
    return self;
}
- (void)dealloc {
    LogMethod();

}
- (void)distributeParsedData:(NSDictionary *)parsedData {

//    LogMethod();
    assert([NSThread isMainThread]);
//    NSLog (@" parsedData %@", parsedData);
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddFestivalNotif
                                                        object:self
                                                        userInfo:[NSDictionary dictionaryWithObject:parsedData
                                                        forKey:kFestivalResultsKey]]; 
}

// the main function for this NSOperation, to start the parsing
- (void)main {
//    LogMethod();
    self.currentParseBatch = [NSMutableArray array];
    self.currentParsedCharacterData = [NSMutableString string];
    self.currentItemDictionary = [[NSMutableDictionary alloc] initWithCapacity: [tableItemNames count]];

    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
    // not desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
//    NSLog (@"parseData %@", self.parseData);
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.parseData];
    [parser setDelegate:self];
    [parser parse];
    
    // depending on the total number of reocrds parsed, the last batch might not have been a
    // "full" batch, and thus not been part of the regular batch transfer. So, we check the count of
    // the array and, if necessary, send it to the main thread.
    //
    if ([self.currentParseBatch count] > 0) {
        [self.parsedTablesDictionary setValue:self.currentParseBatch forKey:self.currentTableName];
        [self performSelectorOnMainThread:@selector(distributeParsedData:)
                               withObject:self.parsedTablesDictionary
                            waitUntilDone:NO];
    }
    self.currentParsedCharacterData = nil;
    self.currentParseBatch = nil;
    
}

#pragma mark -
#pragma mark Parser constants

// Limit the number of parsed records 
//
static const NSUInteger kMaximumNumberOfRecordsToParse = 150;

// When an parsed object has been fully constructed, it must be passed to the main thread and
// loaded into Core Data.   It is not efficient to do
// this for every festival object - the overhead in communicating between the threads and reloading
// the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the
// constant below. In your application, the optimal batch size will vary 
// depending on the amount of data in the object and other factors, as appropriate.
//
static NSUInteger const kSizeOfParsedBatch = 80;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kTableName = @"table";
static NSString * const kColumnName = @"column";

#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
    self.currentItemDictionary = nil;
	self.currentElementName = nil;
	self.currentParsedCharacterData = nil;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
//    LogMethod();

//    NSLog(@"start element ************%@", elementName);

    // If the number of parsed records is greater than
    // kMaximumNumberOfRecordsToParse, abort the parse.
    //
    if (parsedRecordCounter >= kMaximumNumberOfRecordsToParse) {
        // Use the flag didAbortParsing to distinguish between this deliberate stop
        // and other parser errors.
        //
        didAbortParsing = YES;
        [parser abortParsing];
    }
//    NSLog (@"elementName is %@", elementName);
//    NSLog (@"attributeDict is %@", attributeDict);

    if ([elementName isEqualToString:kTableName]) {
        
        if ([[attributeDict valueForKey:@"name"] isEqualToString: self.currentTableName] || self.currentTableName == nil) {
                
            } else {
                //if the table is a different type from the previous one, need put previous table's data into passing dictionary and init
                //put the array in the dictionary with the type of table for the key
                [self.parsedTablesDictionary setValue:self.currentParseBatch forKey:self.currentTableName];
//                NSLog (@" parsedTablesDictionary is %@", self.parsedTablesDictionary);
                
                if ([self.currentParseBatch count] >= kSizeOfParsedBatch) {
                    //pass the dictionary
                    [self performSelectorOnMainThread:@selector(distributeParsedData:)
                                           withObject:self.parsedTablesDictionary
//                                        waitUntilDone:NO];
                                          waitUntilDone:YES];

                    self.currentParseBatch = [NSMutableArray array];
                    self.parsedTablesDictionary = [[NSMutableDictionary alloc] initWithCapacity:[tableItemNames count]];


                }
                self.currentParseBatch = [NSMutableArray array];
            }
        self.currentTableName = [[NSString alloc] initWithString:[attributeDict valueForKey:@"name"]];

        if ([tableItemNames containsObject:self.currentTableName ]) {
            NSSet *itemNames = [[NSSet alloc] initWithSet:[self.tableTagsDictionary valueForKey:self.currentTableName]];
            self.currentItemDictionary = [[NSMutableDictionary alloc] initWithCapacity: [itemNames count]];
        } else self.currentTableName = nil;
    } 
    if ([elementName isEqualToString:kColumnName]) {
        self.currentElementName  = [[NSString alloc] initWithString:[attributeDict valueForKey:@"name"]];

        if ([[self.tableTagsDictionary valueForKey:self.currentTableName] containsObject:self.currentElementName]) {

                // The mutable string needs to be reset to empty.
                currentParsedCharacterData = [[NSMutableString alloc] init];

                // For the 'column' element begin accumulating parsed character data.
                // The contents are collected in parser:foundCharacters:.
                accumulatingParsedCharacterData = YES;
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName 
{   
//    LogMethod();

//    NSLog (@" here is the data that is in the parsed string %@", self.currentParsedCharacterData);
//    NSLog(@"end element %@", elementName);

    if ([elementName isEqualToString:kColumnName]) {
//        NSLog(@"currentElementName is %@", self.currentElementName);
//        NSLog(@"currentParsedCharacterData is %@", self.currentParsedCharacterData);
        [self.currentItemDictionary setValue:currentParsedCharacterData forKey:self.currentElementName];
        currentParsedCharacterData = nil;
//        NSLog (@"currentItemDictionary is %@", self.currentItemDictionary);

    }
    else if ([elementName isEqualToString:kTableName]) {
//        NSLog (@" currentItemDictionary is %@", self.currentItemDictionary);

        [self.currentParseBatch addObject:self.currentItemDictionary];

//        NSLog (@" currentParseBatch is %@", self.currentParseBatch);
                
        parsedRecordCounter++;
        
    }
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    accumulatingParsedCharacterData = NO;
}

// This method is called by the parser when it finds parsed character data ("PCDATA") in an element.
// The parser is not guaranteed to deliver all of the parsed character data for an element in a single
// invocation, so it is necessary to accumulate character data until the end of the element is reached.
//
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {

    if (accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}
- (void)parserDidEndDocument:(NSXMLParser *)parser {
//    LogMethod();
}

// an error occurred while parsing the Performer data,
// post the error as an NSNotification to our app delegate.
// 
- (void)handleParsedDataError:(NSError *)parseError {
    LogMethod();

    [[NSNotificationCenter defaultCenter] postNotificationName:kFestivalErrorNotif
                                                        object:self
                                                      userInfo:[NSDictionary 
                                            dictionaryWithObject:parseError
                                                        forKey:kFestivalMsgErrorKey]];
}

// an error occurred while parsing the Performer data,
// pass the error to the main thread for handling.
// (note: don't report an error if we aborted the parse due to a max limit of Performer)
//
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    LogMethod();

    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !didAbortParsing)
    {
        [self performSelectorOnMainThread:@selector(handleParsedDataError:)
                               withObject:parseError
                            waitUntilDone:NO];
    }
}

@end
