//
//  NSObject+Notifications.m
//  Wrike
//
//  Created by Yarik Smirnov on 13/04/16.
//  Copyright (c) 2016 Wrike, Inc. All rights reserved.
//
#import <objc/runtime.h>
#import "NSObject+Notifications.h"

#if TARGET_OS_IPHONE
@import UIKit;
#endif

static void * const WRKNotificationsObserversKey = @"NotificationsObserversKey";

@implementation NSObject (Notifications)

- (void)ys_subscribe:(NSString *)name withAction:(SEL)action
{
    [self ys_subscribe:name withAction:action object:nil];
}

- (void)ys_subscribe:(NSString *)name withAction:(SEL)action object:(id)object
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:action name:name object:object];
}

- (void)ys_subscribe:(NSString *)name withBlock:(void (^)(NSNotification *notification))block
{
    NSMutableDictionary *dict = objc_getAssociatedObject(self, WRKNotificationsObserversKey);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, WRKNotificationsObserversKey, dict, OBJC_ASSOCIATION_RETAIN);
    }
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                                    object:nil
                                                                     queue:[NSOperationQueue currentQueue]
                                                                usingBlock:block];
    dict[name] = observer;
}

- (void)ys_postNotificationWithName:(NSString *)notificationName
{
    [self ys_postNotificationWithName:notificationName object:nil];
}

- (void)ys_postNotificationWithName:(NSString *)notificationName object:(id)object
{
    NSNotification *notification = [NSNotification notificationWithName:notificationName object:object];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)ys_unsubscribe:(NSString *)name
{
    NSMutableDictionary *dict = objc_getAssociatedObject(self, WRKNotificationsObserversKey);
    if (dict) {
        id observer = dict[name];
        if (observer) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            [dict removeObjectForKey:name];
        }
        if ([dict count] == 0)
            objc_setAssociatedObject(self, WRKNotificationsObserversKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:name object:nil];
}

#if TARGET_OS_IPHONE
- (void)ys_unsubscribeFromKeyboardNotifications
{
    [self ys_unsubscribe:UIKeyboardWillShowNotification];
    [self ys_unsubscribe:UIKeyboardDidShowNotification];
    [self ys_unsubscribe:UIKeyboardWillHideNotification];
    [self ys_unsubscribe:UIKeyboardDidHideNotification];
}
#endif

- (void)ys_unsubscribeFromAll
{
    NSMutableDictionary *dict = objc_getAssociatedObject(self, WRKNotificationsObserversKey);
    if (dict) {
        for (id observer in dict.allValues) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
        [dict removeAllObjects];
        objc_setAssociatedObject(self, WRKNotificationsObserversKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

- (void)ys_postNotification:(NSNotification *)notification
{
    if ([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        });
    }
}

@end
