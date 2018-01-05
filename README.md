# WZRunLoopObserver
一个利用RunLoop解决渲染卡顿的链式语法库

## 原理
当界面需要大量渲染操作时会阻塞主线程，造成卡顿，比如tableView加载多张大图时。`WZRunLoopObserver`将耗费性能的任务分成若干子任务，并利用RunLoop的空闲时`kRunLoopBeforeWaiting`依次执行，从而大大降低了性能的消耗。

## 使用方法
类似`Masonry`的链式调用语法，一目了然~

### 添加任务
```objc
WZRunLoopObserver.main.add(dispatch_block_t task).add(...);
```

### 取消任务
```objc
WZRunLoopObserver.main.cancel(dispatch_block_t task)
```

### 限制任务个数, 默认不限制, 超出后会移除先添加的任务
```objc 
WZRunLoopObserver.main.limit(n).add(...);
```

### 缓存超出限制的任务, 当任务队列不再超限时将缓存的任务添加到任务队列中, 默认关闭
```objc
WZRunLoopObserver.main.limit(10).cache.add(...);
```

### 延迟调用任务, 在当前RunLoop循环n次后执行任务
```objc 
WZRunLoopObserver.main.delay(n).add(...);
```

详细请见demo~