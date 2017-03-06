//
//  NSObject+KVOBlock.m
//
//  Created by Yarik Smirnov on 13/04/16.
//  Copyright (c) 2016 YarikSmirnov, Inc. All rights reserved.
//

@import Foundation;
#import <objc/runtime.h>
#import <stdatomic.h>
#import "NSObject+KVOBlock.h"

static void * const YSObserverMapKey = @"WRKObserverMapKey";
static dispatch_queue_t YSObserverMutationQueue = NULL;

static dispatch_queue_t YSObserverMutationQueueCreatingIfNecessary()
{
    static dispatch_once_t queueCreationPredicate = 0;
    dispatch_once(&queueCreationPredicate, ^{
        YSObserverMutationQueue = dispatch_queue_create("yariksmirnov.observerMutationQueue", 0);
    });
    return YSObserverMutationQueue;
}

@interface YSObserverTrampoline : NSObject
{
    __weak id _observee; // Hold strong reference to observee object.
    NSString *_keyPath;
    YSBlockObserver _block;
    volatile atomic_int_fast32_t _cancellationPredicate;
    NSKeyValueObservingOptions _options;
}
@property (nonatomic, strong) NSString *keyPath;
@property (readonly) id token;

- (YSObserverTrampoline *)initObservingObject:(id)obj
                                       keyPath:(NSString *)keyPath
                                       options:(NSKeyValueObservingOptions)options
                                         block:(YSBlockObserver)block;

- (void)startObserving;

@end

@implementation YSObserverTrampoline
@synthesize keyPath = _keyPath;

static void * const YSObserverTrampolineContext = @"YSObserverTrampolineContext";

- (void)dealloc
{
    [self cancelObservationOfObject:_observee];
}

- (YSObserverTrampoline *)initObservingObject:(id)obj
                                       keyPath:(NSString *)keyPath
                                       options:(NSKeyValueObservingOptions)options
                                         block:(YSBlockObserver)block
{
    self = [super init];
    if (!self)
        return nil;

    _block = [block copy];
    _keyPath = [keyPath copy];
    _options = options;
    _observee = obj;
    return self;
}

- (void)startObserving
{
    [_observee addObserver:self
                forKeyPath:_keyPath
                   options:_options
                   context:YSObserverTrampolineContext];
}

- (id)token
{
    return [NSValue valueWithPointer:&_block];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == YSObserverTrampolineContext && !_cancellationPredicate) {
        _block(object, change, self.token);
    }
}

- (void)cancelObservationOfObject:(id)observee
{
    // Make sure we don't remove ourself before addObserver: completes
    [observee removeObserver:self forKeyPath:_keyPath context:YSObserverTrampolineContext];
    _observee = nil;
}

@end



@implementation NSObject (KVOBlock)

- (id)ys_addObseversForKeyPaths:(NSArray *)keyPaths
                        options:(NSKeyValueObservingOptions)options
                      withBlock:(YSBlockCollectionObserver)block
{
    for (NSString *path in keyPaths) {
        [self ys_addObserverForKeyPath:path
                               options:options 
                             withBlock:^(id obj,
                                         NSDictionary<NSString *,NSObject *> *change, 
                                         id observer)
         {
             if (block) {
                 block(obj, change, path);
             }
         }];
    }
    return nil;
}

- (id)ys_addObserverForKeyPath:(NSString *)keyPath
                        options:(NSKeyValueObservingOptions)options
                      withBlock:(YSBlockObserver)block
{
    __block id token = nil;

    __block YSObserverTrampoline *trampoline = nil;
    
    if (options == 0) {
        options = NSKeyValueObservingOptionNew;
    }

    dispatch_sync(YSObserverMutationQueueCreatingIfNecessary(), ^{
        NSMutableDictionary *dict = objc_getAssociatedObject(self, YSObserverMapKey);
        if (!dict) {
            dict = [[NSMutableDictionary alloc] init];
            objc_setAssociatedObject(self, YSObserverMapKey, dict, OBJC_ASSOCIATION_RETAIN);
        }
        trampoline = [[YSObserverTrampoline alloc] initObservingObject:self
                                                               keyPath:keyPath 
                                                               options:(NSKeyValueObservingOptions)options
                                                                 block:block];
        token = trampoline.token;
        dict[token] = trampoline;
    });

    // To avoid deadlocks when using wrk_removeObserverWithBlockToken from within the dispatch_sync
    // (for a one-shot with NSKeyValueObservingOptionInitial), start observing outside of the sync.
    [trampoline startObserving];
    return token;
}

- (void)ys_removeObserver:(id)token
{
    dispatch_sync(YSObserverMutationQueueCreatingIfNecessary(), ^{
        NSMutableDictionary *observationDictionary = objc_getAssociatedObject(self, YSObserverMapKey);
        YSObserverTrampoline *trampoline = observationDictionary[token];
        NSAssert(trampoline,@"Ignoring attempt to remove non-existent observer on %@ for token %@.", self, token);
        [trampoline cancelObservationOfObject:self];
        [observationDictionary removeObjectForKey:token];

        // Due to a bug in the obj-c runtime, this dictionary does not get cleaned up on release when running without GC.
        // (FWIW, I believe this was fixed in Snow Leopard.)
        if ([observationDictionary count] == 0)
            objc_setAssociatedObject(self, YSObserverMapKey, nil, OBJC_ASSOCIATION_RETAIN);
    });
}

- (void)ys_removeAllObservers
{
    dispatch_sync(YSObserverMutationQueueCreatingIfNecessary(), ^{
        NSMutableDictionary *observationDictionary = objc_getAssociatedObject(self, YSObserverMapKey);
        for (YSObserverTrampoline *trampoline in observationDictionary.allValues) {
            [trampoline cancelObservationOfObject:self];
        }
        [observationDictionary removeAllObjects];
        // Due to a bug in the obj-c runtime, this dictionary does not get cleaned up on release when running without GC.
        // (FWIW, I believe this was fixed in Snow Leopard.)
        if ([observationDictionary count] == 0)
            objc_setAssociatedObject(self, YSObserverMapKey, nil, OBJC_ASSOCIATION_RETAIN);
    });
}

- (void)ys_removeObserverForKeyPath:(NSString *)keyPath
{
    dispatch_sync(YSObserverMutationQueueCreatingIfNecessary(), ^{
        NSMutableDictionary *observationDictionary = objc_getAssociatedObject(self, YSObserverMapKey);
        NSArray *allTrampolines = observationDictionary.allValues.copy;
        for (YSObserverTrampoline *trampoline in allTrampolines) {
            if ([trampoline.keyPath isEqualToString:keyPath]) {
                [trampoline cancelObservationOfObject:self];
                [observationDictionary removeObjectForKey:allTrampolines];
            }
        }
        // Due to a bug in the obj-c runtime, this dictionary does not get cleaned up on release when running without GC.
        // (FWIW, I believe this was fixed in Snow Leopard.)
        if ([observationDictionary count] == 0)
            objc_setAssociatedObject(self, YSObserverMapKey, nil, OBJC_ASSOCIATION_RETAIN);
    });
}

@end
