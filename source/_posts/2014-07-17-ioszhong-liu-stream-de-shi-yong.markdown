---
layout: post

title: "iOS中流(Stream)的使用"

date: 2014-07-17 23:30:26 +0800

comments: true

categories: iOS 网络

---

流提供了一种简单的方式在不同和介质中交换数据，这种交换方式是与设备无关的。流是在通信路径中串行传输的连续的比特位序列。从编码的角度来看，流是单向的，因此流可以是输入流或输出流。除了基于文件的流外，其它形式的流都是不可查找的，这些流的数据一旦消耗完后，就无法从流对象中再次获取。

在Cocoa中包含三个与流相关的类：NSStream、NSInputStream和NSOutputStream。NSStream是一个抽象基类，定义了所有流对象的基础接口和属性。NSInputStream和NSOutputStream继承自NSStream，实现了输入流和输出流的默认行为。下图描述了流的应用场景：

![image](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Streams/Articles/Art/stream_src_dest.gif)

从图中看，NSInputStream可以从文件、socket和NSData对象中获取数据；NSOutputStream可以将数据写入文件、socket、内存缓存和NSData对象中。这三处类主要处理一些比较底层的任务。

流对象有一些相关的属性。大部分属性是用于处理网络安全和配置的，这些属性统称为SSL和SOCKS代理信息。两个比较重要的属性是：

1. NSStreamDataWrittenToMemoryStreamKey：允许输出流查询写入到内存的数据
2. NSStreamFileCurrentOffsetKey：允许操作基于文件的流的读写位置

可以给流对象指定一个代理对象。如果没有指定，则流对象作为自己的代理。流对象调用唯一的代理方法stream:handleEvent:来处理流相关的事件：

1. 对于输入流来说，是有可用的数据可读取事件。我们可以使用read:maxLength:方法从流中获取数据
2. 对于输出流来说，是准备好写入的数据事件。我们可以使用write:maxLength:方法将数据写入流

Cocoa中的流对象与Core Foundation中的流对象是对应的。我们可以通过toll-free桥接方法来进行相互转换。NSStream、NSInputStream和NSOutputStream分别对应CFStream、CFReadStream和CFWriteStream。但这两者间不是完全一样的。Core Foundation一般使用回调函数来处理数据。另外我们可以子类化NSStream、NSInputStream和NSOutputStream，来自定义一些属性和行为，而Core Foundation中的流对象则无法进行扩展。

上面主要介绍了iOS中流的一些基本概念，我们下面将介绍流的具体使用，首先看看如何从流中读取数据。


## 从输入流中读取数据


从一个NSInputStream流中读取数据主要包括以下几个步骤：

1. 从数据源中创建和初始化一个NSInputStream实例
2. 将流对象放入一个run loop中并打开流
3. 处理流对象发送到其代理的事件
4. 当没有更多数据可读取时，关闭并销毁流对象。

#### 准备流对象

要使用一个NSInputStream，必须要有数据源。数据源可以是文件、NSData对象和网络socket。创建好后，我们设置其代理对象，并将其放入到run loop中，然后打开流。代码清单1展示了这个准备过程.

###### 代理清单1

	- (void)setUpStreamForFile:(NSString *)path
	{
	    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
	    inputStream.delegate = self;
	    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	    
	    [inputStream open];
	}

在流对象放入run loop且有流事件(有可读数据)发生时，流对象会向代理对象发送stream:handleEvent:消息。在打开流之前，我们需要调用流对象的scheduleInRunLoop:forMode:方法，这样做可以避免在没有数据可读时阻塞代理对象的操作。我们需要确保的是流对象被放入正确的run loop中，即放入流事件发生的那个线程的run loop中。

#### 处理流事件

打开流后，我们可以使用streamStatus属性查看流的状态，用hasBytesAvailable属性检测是否有可读的数据，用streamError来查看流处理过程中产生的错误。

流一旦打开后，将会持续发送stream:handleEvent:消息给代理对象，直到流结束为止。这个消息接收一个NSStreamEvent常量作为参数，以标识事件的类型。对于NSInputStream对象，主要的事件类型包括NSStreamEventOpenCompleted、NSStreamEventHasBytesAvailable和NSStreamEventEndEncountered。通常我们会对NSStreamEventHasBytesAvailable更感兴趣。代理清单2演示了从流中获取数据的过程

###### 代理清单2
	- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
	{
	    switch (eventCode) {
	        case NSStreamEventHasBytesAvailable:
	        {
	            if (!data) {
	                data = [NSMutableData data];
	            }
	            
	            uint8_t buf[1024];
	            unsigned int len = 0;
	            len = [(NSInputStream *)aStream read:buf maxLength:1024];  // 读取数据
	            if (len) {
	                [data appendBytes:(const void *)buf length:len];
	            }
	        }
	            break;
	    }
	}

当NSInputStream在处理流的过程中出现错误时，它将停止流处理并产生一个NSStreamEventErrorOccurred事件给代理。我们同样的上面的代理方法中来处理这个事件。

#### 清理流对象
当NSInputStream读取到流的结尾时，会发送一个NSStreamEventEndEncountered事件给代理，代理对象应该销毁流对象，此过程应该与创建时相对应，代码清单3演示了关闭和释放流对象的过程。

###### 代理清单3
	- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
	{
	    switch (eventCode) {
	        case NSStreamEventEndEncountered:
	        {
	            [aStream close];
	            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	            aStream = nil;
	        }
	            break;
	    }
	}

## 写入数据到输出流
类似于从输入流读取数据，写入数据到输出流时，需要下面几个步骤：

1. 使用要写入的数据创建和初始化一个NSOutputStream实例，并设置代理对象
2. 将流对象放到run loop中并打开流
3. 处理流对象发送到代理对象中的事件
4. 如果流对象写入数据到内存，则通过请求NSStreamDataWrittenToMemoryStreamKey属性来获取数据
5. 当没有更多数据可供写入时，处理流对象

基本流程与输入流的读取差不多，我们主要介绍不同的地方

1. 数据可写入的位置包括文件、C缓存、程序内存和网络socket。
2. hasSpaceAvailable属性表示是否有空间来写入数据
3. 在stream:handleEvent:中主要处理NSStreamEventHasSpaceAvailable事件，并调用流的write:maxLength方法写数据。代码清单4演示了这一过程。
4. 如果NSOutputStream对象的目标是应用的内存时，在NSStreamEventEndEncountered事件中可能需要从内存中获取流中的数据。我们将调用NSOutputStream对象的propertyForKey:的属性，并指定key为NSStreamDataWrittenToMemoryStreamKey来获取这些数据。


###### 代理清单4

	- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
	{
	    switch (eventCode) {
	        case NSStreamEventHasSpaceAvailable:
	        {
	            uint8_t *readBytes = (uint8_t *)[data mutableBytes];
	            readBytes += byteIndex;
	            int data_len = [data length];
	            unsigned int len = (data_len - byteIndex >= 1024) ? 1024 : (data_len - byteIndex);
	            uint8_t buf[len];
	            
	            (void)memcpy(buf, readBytes, len);
	            
	            len = [aStream write:(const uint_8 *)buf maxLength:len];
	            byteIndex += len;
	            break;
	        }
	    }
	}

这里需要注意的是：当代理接收到NSStreamEventHasSpaceAvailable事件而没有写入任何数据到流时，代理将不再从run loop中接收该事件，直到NSOutputStream对象接收到更多数据，这时run loop会重启NSStreamEventHasSpaceAvailable事件。


## 流的轮循处理

在流的处理过程中，除了将流放入run loop来处理流事件外，还可以对流进行轮循处理。我们将流处理数据的过程放到一个循环中，并在循环中不断地去询问流是否有可用的数据供读取(hasBytesAvailable)或可用的空间供写入(hasSpaceAvailable)。当处理到流的结尾时，我们跳出循环结束流的操作。

具体的过程如代码清单5所示

代码清单5

	- (void)createNewFile {	    NSOutputStream *oStream = [[NSOutputStream alloc] initToMemory];	    [oStream open];	   	    ￼￼￼uint8_t *readBytes = (uint8_t *)[data mutableBytes];	    uint8_t buf[1024];	    int len = 1024;
	    	    while (1) {	        if (len == 0) break;
	        	        if ([oStream hasSpaceAvailable])
	        {	            (void)strncpy(buf, readBytes, len);	            readBytes += len;	            if ([oStream write:(const uint8_t *)buf maxLength:len] == -1)
	            {	                [self handleError:[oStream streamError]];	                break;
	            }	            [bytesWritten setIntValue:[bytesWritten intValue]+len];	            len = (([data length] - [bytesWritten intValue] >= 1024) ? 1024 : [data length] - [bytesWritten intValue]);	        }	    }	    NSData *newData = [oStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
	    	    if (!newData) {	        NSLog(@"No data written to memory!");	    } else {	        [self processData:newData];	    }
	    	    [oStream close];	    [oStream release];	    oStream = nil;	}

这种处理方法的问题在于它会阻塞当前线程，直到流处理结束为止，才继续进行后面的操作。而这种问题在处理网络socket流时尤为严重，我们必须等待服务端数据回来后才能继续操作。因此，通常情况下，建议使用run loop方式来处理流事件。

## 错误处理

当流出现错误时，会停止对流数据的处理。一个流对象在出现错误时，不能再用于读或写操作，虽然在关闭前可以查询它的状态。

NSStream和NSOutputStream类会以几种方式来告知错误的发生：

1. 如果流被放到run loop中，对象会发送一个NSStreamEventErrorOccurred事件到代理对象的stream:handleEvent:方法中
2. 任何时候，可以调用streamStatus属性来查看是否发生错误(返回NSStreamStatusError)
3. 如果在通过调用write:maxLength:写入数据到NSOutputStream对象时返回-1，则发生一个写错误。

一旦确定产生错误时，我们可以调用流对象的streamError属性来查看错误的详细信息。在此我们不再举例。


## 设置Socket流

在iOS中，NSStream类不支持连接到远程主机，幸运的是CFStream支持。前面已经说过这两者可以通过toll-free桥接来相互转换。使用CFStream时，我们可以调用CFStreamCreatePairWithSocketToHost函数并传递主机名和端口号，来获取一个CFReadStreamRef和一个CFWriteStreamRef来进行通信，然后我们可以将它们转换为NSInputStream和NSOutputStream对象来处理。

具体的处理流程我们会在后期详细讨论。

参考

[Stream Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Streams/Streams.html)
