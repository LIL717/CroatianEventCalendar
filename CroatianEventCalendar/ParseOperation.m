//
//  ParseOperation.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 10/28/2013.
//  Copyright 2013 CroatianEventCalendar. All rights reserved.
//

#import "ParseOperation.h"
#import "Event.h"

// NSNotification name for sending event data back to the app delegate
NSString *kAddEventNotif = @"AddEventNotif";

// NSNotification userInfo key for obtaining the event data
NSString *kEventResultsKey = @"EventResultsKey";

// NSNotification name for notifying app delegate when parsing has ended
NSString *kDoneParsingNotif = @"DoneParsingNotif";

// NSNotification name for reporting errors
NSString *kEventErrorNotif = @"EventErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kEventMsgErrorKey = @"EventMsgErrorKey";


@interface ParseOperation () <NSXMLParserDelegate>
@property (nonatomic, retain) NSMutableArray *currentParseBatch;
@property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@end

@implementation ParseOperation

@synthesize parseData;
@synthesize currentParsedCharacterData;
@synthesize currentParseBatch;

@synthesize eventItemNames;
@synthesize tableTagsDictionary;
@synthesize currentItemDictionary;
@synthesize currentTableName;
@synthesize currentElementName;
@synthesize managedObjectContext = __managedObjectContext;

- (id)initWithData:(NSData *)data

{
//    LogMethod();

    if ((self = [super init])) {   

		//i think there is only one key = event and an array of dictionaries of events
//        self.parsedFinalDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];

		self.eventItemNames = [[NSSet alloc] initWithObjects:EVENT_FEED_TAGS];

        parseData = [data copy];

    }
    return self;
}
- (void)dealloc {
//    LogMethod();

}
//- (void)distributeParsedData:(NSDictionary *)parsedData {
- (void)distributeParsedData:(NSArray *)parsedData {


//    LogMethod();
    assert([NSThread isMainThread]);
//    NSLog (@" parsedData %@", parsedData);
//    NSLog (@"userInfo is %@", [NSDictionary dictionaryWithObject:parsedData
//                                                        forKey:kEventResultsKey]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddEventNotif
                                                        object:self
                                                        userInfo:[NSDictionary dictionaryWithObject:parsedData
                                                        forKey:kEventResultsKey]];

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
        [self performSelectorOnMainThread:@selector(distributeParsedData:)
//                               withObject:self.parsedFinalDictionary
                               withObject:self.currentParseBatch
                            waitUntilDone:YES];
							
    }
    self.currentParsedCharacterData = nil;
    
}

#pragma mark -
#pragma mark Parser constants

// Limit the number of parsed records 
//
static const NSUInteger kMaximumNumberOfRecordsToParse = 150;

// When an parsed object has been fully constructed, it must be passed to the main thread and
// loaded into Core Data.   It is not efficient to do
// this for every event object - the overhead in communicating between the threads and reloading
// the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the
// constant below. In your application, the optimal batch size will vary 
// depending on the amount of data in the object and other factors, as appropriate.
//
static NSUInteger const kSizeOfParsedBatch = 40;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kFileName = @"xml";
static NSString * const kEventName = @"event";

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
	
	if ([elementName isEqualToString: kFileName]) {
	return;
	}
//    NSLog (@"elementName is %@", elementName);
//    NSLog (@"attributeDict is %@", attributeDict);
			
//	NSLog (@" parsedTablesDictionary is %@", self.parsedFinalDictionary);

	   
	if ([elementName isEqualToString:kEventName]) {
		self.currentItemDictionary = [[NSMutableDictionary alloc] initWithCapacity: [eventItemNames count]];

    } else {

        self.currentElementName  = elementName;
        if ([self.eventItemNames containsObject:self.currentElementName]) {

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

//    NSLog (@" parsed string %@", self.currentParsedCharacterData);
//    NSLog(@"end element %@", elementName);

    if (![elementName isEqualToString:kEventName]) {
//        NSLog(@"currentElementName is %@", self.currentElementName);
//        NSLog(@"currentParsedCharacterData is %@", self.currentParsedCharacterData);
        [self.currentItemDictionary setValue:currentParsedCharacterData forKey:self.currentElementName];
        currentParsedCharacterData = nil;
//        NSLog (@"currentItemDictionary is %@", self.currentItemDictionary);

    }
    else if ([elementName isEqualToString:kEventName]) {
//        NSLog (@" currentItemDictionary is %@", self.currentItemDictionary);

        [self.currentParseBatch addObject:self.currentItemDictionary];

//        NSLog (@" currentParseBatch is %@", self.currentParseBatch);
        
        parsedRecordCounter++;
		
		if ([self.currentParseBatch count] >= kSizeOfParsedBatch) {
			//pass the dictionary
			[self performSelectorOnMainThread:@selector(distributeParsedData:)
										withObject:self.currentParseBatch
                                        waitUntilDone:YES];
										
			[self.currentParseBatch removeAllObjects];
		}
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
		//put the array in the dictionary with the type of table for the key

//		if ([self.currentParseBatch count] >= kSizeOfParsedBatch) {
//			//pass the dictionary
			[[NSNotificationCenter defaultCenter] postNotificationName:kDoneParsingNotif
                                                        object:self
                                                        ];
			[self performSelectorOnMainThread:@selector(distributeParsedData:)
										withObject:self.currentParseBatch
                                        waitUntilDone:YES];
										
			[self.currentParseBatch removeAllObjects];
			

//		}
}

// an error occurred while parsing the Performer data,
// post the error as an NSNotification to our app delegate.
// 
- (void)handleParsedDataError:(NSError *)parseError {
//    LogMethod();

    [[NSNotificationCenter defaultCenter] postNotificationName:kEventErrorNotif
                                                        object:self
                                                      userInfo:[NSDictionary 
                                            dictionaryWithObject:parseError
                                                        forKey:kEventMsgErrorKey]];
}

// an error occurred while parsing the Performer data,
// pass the error to the main thread for handling.
// (note: don't report an error if we aborted the parse due to a max limit of Performer)
//
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
//    LogMethod();

    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !didAbortParsing)
    {
        [self performSelectorOnMainThread:@selector(handleParsedDataError:)
                               withObject:parseError
                            waitUntilDone:NO];
    }
}

@end
