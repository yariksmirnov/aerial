//
//  NSObject+KVOBlock.h
//
//  Created by Yarik Smirnov on 13/04/16.
//  Copyright (c) 2016 YarikSmirnov, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^YSBlockCollectionObserver)(id obj, NSDictionary<NSString *, NSObject *> *change, NSString *keyPath);
typedef void (^YSBlockObserver)(id obj, NSDictionary<NSString *, NSObject *> *change, id observer);

@interface NSObject (KVOBlock)

- (id)ys_addObseversForKeyPaths:(NSArray *)keyPaths
                        options:(NSKeyValueObservingOptions)options
                      withBlock:(YSBlockCollectionObserver)block;

/// Add a block-based observer. Returns a token for use with removeObserverWithBlockToken:.
- (id)ys_addObserverForKeyPath:(NSString *)keyPath
                        options:(NSKeyValueObservingOptions)options
                      withBlock:(YSBlockObserver)block;
/**
 *  Remove observer of object.
 *
 *  @param observer token returned in sf_addObserver
 */
- (void)ys_removeObserver:(id)observer;
/**
 *  Remove observer by specific keyPath;
 *
 *  @param keyPath keyPath of observer.
 */
- (void)ys_removeObserverForKeyPath:(NSString *)keyPath;
/**
 *  Removes all observing of self.
 */
- (void)ys_removeAllObservers;

@end
