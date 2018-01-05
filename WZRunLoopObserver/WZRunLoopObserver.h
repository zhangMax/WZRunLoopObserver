//
//  WZRunLoopObserver.h
//  WZRunLoopObserver
//
//  Created by WonkeyZ on 2017/11/10.
//  Copyright © 2017年 WZ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZRunLoopObserver : NSObject


/**
 主任务队列, observer不会移除
 
 WZRunLoopObserver.main;
 */
+ (WZRunLoopObserver *)main;


/**
 自定义队列, 当任务数为0时, 会在当前RunLoop循环n次后移除observer, n默认值为100
 
 WZRunLoopObserver.queue(@"com.wonkeyz.queue");
 */
+ (WZRunLoopObserver *(^)(NSString *))queue;

/**
 添加任务
 
 WZRunLoopObserver.main.add(dispatch_block_t task).add(...);
 */
- (WZRunLoopObserver *(^)(dispatch_block_t))add;

/**
 取消任务
 
 WZRunLoopObserver.main.cancel(dispatch_block_t task)
 */
- (WZRunLoopObserver *(^)(dispatch_block_t))cancel;

/**
 限制任务个数, 默认不限制, 超出后会移除先添加的任务
 
 WZRunLoopObserver.main.limit(n).add(...);
 */
- (WZRunLoopObserver *(^)(NSUInteger))limit;

/**
 缓存超出限制的任务, 当任务队列不再超限时将缓存的任务添加到任务队列中, 默认关闭
 
 WZRunLoopObserver.main.limit(10).cache.add(...);
 */
- (WZRunLoopObserver *(^)(BOOL))cache;

/**
 延迟调用任务, 在当前RunLoop循环n次后执行任务
 
 WZRunLoopObserver.main.delay(n).add(...);
 */
- (WZRunLoopObserver *(^)(NSUInteger))delay;

@end
