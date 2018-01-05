//
//  WZRunLoopObserver.m
//  WZRunLoopObserver
//
//  Created by WonkeyZ on 2017/11/10.
//  Copyright © 2017年 WZ. All rights reserved.
//

#import "WZRunLoopObserver.h"

#define kRunLoopChainLockBlock(param, ...) \
__weak typeof(&*self) weakSelf = self; \
return ^id(param){ \
__strong typeof(&*weakSelf) self = weakSelf; \
dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__ \
dispatch_semaphore_signal(_lock); \
return self; \
};

static const NSInteger kRunLoopRemoveTaskDelay = 100;

@interface WZRunLoopObserver () {
    dispatch_semaphore_t _lock;
    NSUInteger _limitCount;
    NSUInteger _delay;
    BOOL _isCache;
}

@property (nonatomic, strong) WZRunLoopObserver *main;

@property (nonatomic, strong) NSMutableDictionary *observers; // 存储自定义队列

@property (nonatomic, copy) NSString *queueName;              // 自定义队列名
@property (nonatomic, copy) dispatch_block_t removeTask;      // 移除observer的task

@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) NSMutableArray *caches;

@end

@implementation WZRunLoopObserver

#pragma mark - Life cycle
+ (instancetype)manager {
    static WZRunLoopObserver *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WZRunLoopObserver alloc] init];
    });
    return manager;
}

- (instancetype)initWithQueueName:(NSString *)queueName {
    self = [super init];
    if (self) {
        self.queueName = queueName;
        _lock = dispatch_semaphore_create(1);
        _limitCount = INT_MAX;
        _isCache = NO;
    }
    return self;
}

#pragma mark - Public Methods
+ (WZRunLoopObserver *)main {
    WZRunLoopObserver *observer = WZRunLoopObserver.manager.main;
    if (!observer) {
        observer = [[WZRunLoopObserver alloc] initWithQueueName:@"com.wonkeyz.main"];
        [observer addObserverWithRunLoop:CFRunLoopGetMain()];
        WZRunLoopObserver.manager.main = observer;
    }
    return observer;
}

+ (WZRunLoopObserver *(^)(NSString *))queue {
    return ^id(NSString *queueName){
        NSAssert(queueName != nil, @"queueName should not be nil");
        
        WZRunLoopObserver *observer = [WZRunLoopObserver.manager.observers objectForKey:queueName];
        if (!observer) {
            observer = [[WZRunLoopObserver alloc] initWithQueueName:queueName];
            [observer addObserverWithRunLoop:CFRunLoopGetCurrent()];
            [WZRunLoopObserver.manager.observers setObject:observer forKey:queueName];
        }
        return observer;
    };
}

- (WZRunLoopObserver *(^)(dispatch_block_t))add {
    kRunLoopChainLockBlock(dispatch_block_t task, {
        if (task) {
            if (self.tasks.count > _limitCount) {
                if (_isCache) {
                    [self.caches addObject:task];
                }else {
                    [self.tasks removeObjectAtIndex:0];
                    [self.tasks addObject:task];
                }
            }else {
                [self.tasks addObject:task];
            }
        }
    });
}

- (WZRunLoopObserver *(^)(NSUInteger))limit {
    kRunLoopChainLockBlock(NSUInteger limit, {
        self->_limitCount = limit;
    });
}

- (WZRunLoopObserver *(^)(BOOL))cache {
    kRunLoopChainLockBlock(BOOL cache, {
        self->_isCache = cache;
    });
}

- (WZRunLoopObserver *(^)(NSUInteger))delay {
    kRunLoopChainLockBlock(NSUInteger delay, {
        self->_delay = delay;
    });
}

- (WZRunLoopObserver *(^)(dispatch_block_t))cancel {
    kRunLoopChainLockBlock(dispatch_block_t task, {
        if ([self.tasks containsObject:task]) {
            [self.tasks removeObject:task];
        }else if ([self.caches containsObject:task]) {
            [self.caches removeObject:task];
        }
    });
}

#pragma mark - Private Methods
- (void)addObserverWithRunLoop:(CFRunLoopRef)runloop {
    __weak typeof(&*self) weakSelf = self;
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        
        __strong typeof(&*weakSelf) self = weakSelf;
        
        if (self.tasks.count == 0) return;
        
        if (self->_delay > 0) {
            self->_delay--;
            return;
        }
        
        dispatch_block_t task = self.tasks.firstObject;
        task();
        [self.tasks removeObject:task];
        
        if (_isCache && self.caches.count) {
            id cacheTask = self.caches.firstObject;
            [self.tasks addObject:cacheTask];
            [self.caches removeObject:cacheTask];
        }
        
        [self removeObserver:observer];
        
    });
    
    CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
    CFRelease(observer);
}

- (void)removeObserver:(CFRunLoopObserverRef)observer {
    if (self.tasks.count == 0) {
        __weak typeof(&*self) weakSelf = self;
        if ([WZRunLoopObserver.manager.observers objectForKey:self.queueName]) {
            self.removeTask = ^{
                CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopCommonModes);
                [WZRunLoopObserver.manager.observers removeObjectForKey:weakSelf.queueName];
            };
            
            WZRunLoopObserver.main.delay(kRunLoopRemoveTaskDelay).limit(1).
            add(self.removeTask);
        }
    }else {
        if (self.removeTask) {
            WZRunLoopObserver.main.cancel(self.removeTask);
            self.removeTask = nil;
        }
    }
}

#pragma mark - Getter Methods
- (NSMutableDictionary *)observers {
    if (!_observers) {
        _observers = [NSMutableDictionary dictionary];
    }
    return _observers;
}

- (NSMutableArray *)tasks {
    if (!_tasks) {
        _tasks = [NSMutableArray array];
    }
    return _tasks;
}

- (NSMutableArray *)caches {
    if (!_caches) {
        _caches = [NSMutableArray array];
    }
    return _caches;
}

@end
