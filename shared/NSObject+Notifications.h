//
//  NSObject+Notifications.h
//  Wrike
//
//  Created by Yarik Smirnov on 13/04/16.
//  Copyright (c) 2016 Wrike, Inc. All rights reserved.
//

///------------------------------------------
/// @name NSObject
///------------------------------------------

@import Foundation;

@interface NSObject (Notifications)


- (void)ys_subscribe:(NSString *)name withBlock:(void (^)(NSNotification *notification))block;

- (void)ys_subscribe:(NSString *)name withAction:(SEL)action object:(id)object;

- (void)ys_unsubscribe:(NSString *)name;

#if TARGET_OS_IPHONE
- (void)ys_unsubscribeFromKeyboardNotifications;
#endif

- (void)ys_unsubscribeFromAll;

- (void)ys_postNotification:(NSNotification *)notification;

- (void)ys_postNotificationWithName:(NSString *)notificationName;

- (void)ys_postNotificationWithName:(NSString *)notificationName object:(id)object;


@end
