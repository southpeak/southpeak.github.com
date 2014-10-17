---
layout: post

title: "OSAtomic原子操作"

date: 2014-10-17 10:56:00 +0800

comments: true

categories: iOS

---

并发编程一个主要问题就是如何同步数据。同步数据的方式有很多种，这里我们介绍一下libkern/OSAtomic.h。这个头文件包含是大量关于原子操作和同步操作的函数，如果要对数据进行同步操作，这里面的函数可以作为我们的首选项。不同平台这些函数的实现是自定义的。另外，它们是线程安全的。

需要注意的是，传递给这些函数的所有地址都必须是“自然对齐”的，例如int32_t * 指针必须是32位对齐的(地址的低位2个bit为0)，int64_t * 指针必须是64位对齐的(低3位为0)。

这些原子函数的一些版本整合了内存屏障(memory barriers)，而另一些则没有。在诸如PPC这样的弱有序(weakly-ordered)架构中，Barriers严格限制了内存访问顺序。所有出现在barriers之前的加载和存储操作完成后，才会运行barriers之后的加载和存储操作。

在单处理器系统中，barriers操作通常是一个空操作。在多处理器系统中，barriers在某些平台上可能是相当昂贵的操作，如PPC。

大多数代码都应该使用barrier函数来确保在线程间共享的内存是正确同步的。例如，如果我们想要初始化一个共享的数据结构，然后自动增加某个变量值来标识初始化操作完成，则我们必须使用OSAtomicIncrement32Barrier来确保数据结构的存储操作在变量自动增加前完成。

同样的，该数据结构的消费者也必须使用OSAtomicIncrement32Barrier，以确保在自动递增变量值之后再去加载这些数据。另一方面，如果我们只是简单地递增一个全局计数器，那么使用OSAtomicIncrement32会更安全且可能更快。

如果不能确保我们使用的是哪个版本，则使用barrier变量以保证是安全的。

另外，自旋锁和队列操作总是包含一个barrier。

这个头文件中的函数主要可以分为以下几类

## 内存屏障(Memory barriers)

内存屏障的概念如上所述，它是一种屏障和指令类，可以让CPU或编译器强制将barrier之前和之后的内存操作分开。CPU采用了一些可能导致乱序执行的性能优化。在单个线程的执行中，内存操作的顺序一般是悄无声息的，但是在并发编程和设备驱动程序中就可能出现一些不可预知的行为，除非我们小心地去控制。排序约束的特性是依赖于硬件的，并由架构的内存顺序模型来定义。一些架构定义了多种barrier来执行不同的顺序约束。

OSMemoryBarrier()函数就是用来设置内存屏障，它即可以用于读操作，也可以用于写操作。

示例代码：

	// 代码来自ReactiveCocoa:RACDisposable类
	
	- (id)initWithBlock:(void (^)(void))block {
	    NSCParameterAssert(block != nil);
	    
	    self = [super init];
	    if (self == nil) return nil;
	    
	    _disposeBlock = (void *)CFBridgingRetain([block copy]);
	    OSMemoryBarrier();
	    
	    return self;
	}

## 自旋锁(Spinlocks)

自旋锁是在多处理器系统(SMP)上为保护一段关键代码的执行或者关键数据的一种保护机制，是实现synchronization的一种手段。

libkern/OSAtomic.h中包含了三个关于自旋锁的函数：OSSpinLockLock, OSSpinLockTry, OSSpinLockUnlock

示例代码：

	// 代码来自ReactiveCocoa:RACCompoundDisposable类
	
	- (void)dispose {
	#if RACCompoundDisposableInlineCount
	    RACDisposable *inlineCopy[RACCompoundDisposableInlineCount];
	#endif
	    
	    CFArrayRef remainingDisposables = NULL;
	    
	    OSSpinLockLock(&_spinLock);
	    {
	        _disposed = YES;
	        
	#if RACCompoundDisposableInlineCount
	        for (unsigned i = 0; i < RACCompoundDisposableInlineCount; i++) {
	            inlineCopy[i] = _inlineDisposables[i];
	            _inlineDisposables[i] = nil;
	        }
	#endif
	        
	        remainingDisposables = _disposables;
	        _disposables = NULL;
	    }
	    OSSpinLockUnlock(&_spinLock);
	    
	#if RACCompoundDisposableInlineCount
	    // Dispose outside of the lock in case the compound disposable is used
	    // recursively.
	    for (unsigned i = 0; i < RACCompoundDisposableInlineCount; i++) {
	        [inlineCopy[i] dispose];
	    }
	#endif
	    
	    if (remainingDisposables == NULL) return;
	    
	    CFIndex count = CFArrayGetCount(remainingDisposables);
	    CFArrayApplyFunction(remainingDisposables, CFRangeMake(0, count), &disposeEach, NULL);
	    CFRelease(remainingDisposables);
	}
	
## 原子队列操作

队列操作主要包含两类：

1. 不加锁的FIFO入队和出队原子操作，包含OSAtomicFifoDequeue和OSAtomicFifoEnqueue两个函数
2. 不加锁的LIFO入队和出队原子操作，包含OSAtomicDequeue和OSAtomicEnqueue两个函数。这两个函数是线程安全的，对有潜在精确要求的代码来说，这会是强大的构建方式。

## 比较和交换

这组函数可以细分为三组函数：

1. OSAtomicCompareAndSwap**\[Barrier](type \_\_oldValue, type \_\_newValue, volatile type \*\_\_theValue)：这组函数用于比较\_\_oldValue是否与\_\_theValue指针指向的内存位置的值匹配，如果匹配，则将\_\_newValue的值存储到\_\_theValue指向的内存位置。可以根据需要使用barrier版本。
2. OSAtomicTestAndClear/OSAtomicTestAndClearBarrier( uint32_t \_\_n, volatile void *\_\_theAddress )：这组函数用于测试\_\_theAddress指向的值中由\_\_n指定的bit位，如果该位未被清除，则清除它。需要注意的是最低bit位应该是1，而不是0。对于一个64-bit的值来说，如果要清除最高位的值，则\_\_n应该是64。
3. OSAtomicTestAndSet/OSAtomicTestAndSetBarrier(uint32_t \_\_n, volatile void *\_\_theAddress)：与OSAtomicTestAndClear相反，这组函数测试值后，如果指定位没有设置，则设置它。

示例代码：

	void * sharedBuffer(void)
	{
	    static void * buffer;
	    if (buffer == NULL) {
	        void * newBuffer = calloc(1, 1024);
	        if (!OSAtomicCompareAndSwapPtrBarrier(NULL, newBuffer, &buffer)) {
	            free(newBuffer);
	        }
	    }
	    return buffer;
	}

上述代码的作用是如果没有缓冲区，我们将创建一个newBuffer，然后将其写到buffer中。

## 布尔操作(AND, OR, XOR)

这组函数可根据以下两个规则来分类：

1. 是否使用Barrier
2. 返回值是原始值还是操作完成后的值

以And为例，有4个函数：OSAtomicAnd32, OSAtomicAnd32Barrier, OSAtomicAnd32Orig, OSAtomicAnd32OrigBarrier。每个函数均带有两个参数：\_\_theMask(uint32_t)和\_\_theValue(volatile uint32_t *)。函数将\_\_theMask与\_\_theValue指向的值做AND操作。

类似，还有OR操作和XOR操作。

## 数学操作

这组函数主要包括：

1. 加操作：OSAtomicAdd**, OSAtomicAdd\*\*Barrier
2. 递减操作：OSAtomicDecrement**, OSAtomicDecrement\*\*Barrier
3. 递增操作：OSAtomicIncrement**, OSAtomicIncrement\*\*Barrier

示例代码：

	// 代码摘自ReactiveCocoa:RACDynamicSequence
	
	- (void)dealloc {
		static volatile int32_t directDeallocCount = 0;
	
		if (OSAtomicIncrement32(&directDeallocCount) >= DEALLOC_OVERFLOW_GUARD) {
			OSAtomicAdd32(-DEALLOC_OVERFLOW_GUARD, &directDeallocCount);
	
			// Put this sequence's tail onto the autorelease pool so we stop
			// recursing.
			__autoreleasing RACSequence *tail __attribute__((unused)) = _tail;
		}
		
		_tail = nil;
	}
	
## 小结

相较于@synchronized，OSAtomic原子操作更趋于数据的底层，从更深层次来对单例进行保护。同时，它没有阻断其它线程对函数的访问。

## 参考

1. [OSAtomic.h User-Space Reference](https://developer.apple.com/library/mac/documentation/System/Reference/OSAtomic_header_reference/Reference/reference.html)
2. [Memory barrier](http://blog.csdn.net/wzb56_earl/article/details/6634622)
3. [Objc的底层并发API](http://www.cocoachina.com/industry/20130821/6842.html)
4. [OSATOMIC与synchronized加锁的对比](http://blog.csdn.net/tuxiangqi/article/details/8076972)