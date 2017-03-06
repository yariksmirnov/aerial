//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//


#define LOG_LEVEL_DEF ddLogLevel
@import CocoaLumberjack;
static DDLogLevel ddLogLevel = DDLogLevelVerbose;


#import "NSObject+KVOBlock.h"
#import "NSObject+Notifications.h"
