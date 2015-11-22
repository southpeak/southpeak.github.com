---
layout: post

title: "URL加载系统之三：NSURLConnection"

date: 2014-07-15 18:37:44 +0800

comments: true

categories: iOS 网络

---

NSURLConnection提供了简单的接口来创建和取消一个连接，并支持一个代理方法的集合来提供连接的响应，并对连接进行多方面的控制。这个类的方法可以分为5大类：URL加载、缓存管理、认证与证书、cookie存储、协议支持。

## 创建一个连接

NSURLConnection提供了三种方式来获取URL的内容：同步、异步使用完成处理器block、异步使用自定义的代理对象。

1. 使用同步请求时，一般是在后台线程中独占线程运行，我们可以调用sendSynchronousRequest:returningResponse:error: 方法来执行HTTP请求。当请求完成或返回错误时，该方法会返回。
2. 如果我们不需要监听请求的状态，而只是在数据完成返回时执行一些操作，则可以调用sendAsynchronousRequest:queue:completionHandler:方法来执行一个异步操作，其中需要传递一个block来处理结果。
3. 我们也可以创建一个代理对象来处理异步请求，此时我们需要实现以下方法：connection:didReceiveResponse:、connection:didReceiveData:、connection:didFailWithError:和connectionDidFinishLoading: 。这些方法在NSURLConnectionDelegate、NSURLConnectionDownloadDelegate和 NSURLConnectionDataDelegate协议中定义。


代码清单1以代理对象异步请求为例，初始化了一个URL连接并实现代理方法来处理连接响应

	@interface Conn : NSObject
	{
	    NSURLConnection *theConnection;
	    NSMutableData *receivedData;
	}
	
	@end
	
	@implementation Conn
	
	- (void)createConnection
	{
	    // 创建一个请求
	    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com/"]
	                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
	                                          timeoutInterval:60.0];
	    
	    // 创建NSMutableData来保存接收到的数据
	    receivedData = [NSMutableData dataWithCapacity: 0];
	    
	    // 使用theRequest创建一个连接并开始加载数据
	    // 调用initWithRequest:delegate后会立即开始传输
	    // 请求可以在connectionDidFinishLoading:或connection:didFailWithError:消息被发送前通过调用cancel来取消
	    theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	    
	    if (!theConnection) {
	        // 释放receivedData对象
	        receivedData = nil;
	        // 通知用户连接失败
	    }
	}
	
	// 当服务端提供了有效的数据来创建NSURLResponse对象时，代理会收到connection:didReceiveResponse:消息。
	// 这个代理方法会检查NSURLResponse对象并确认数据的content-type，MIME类型，文件 名和其它元数据。
	// 需要注意的是，对于单个连接，我们可能会接多次收到connection:didReceiveResponse:消息；这咱情况发生在
	// 响应是多重MIME编码的情况下。每次代理接收到connection:didReceiveResponse:时，应该重设进度标识
	// 并丢弃之前接收到的数据。
	- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
	{
	    [receivedData setLength:0];
	}
	
	// 代理会定期接收到connection:didReceiveData:消息，该消息用于接收服务端返回的数据实体。该方法负责存储数据。
	// 我们也可以用这个方法提供进度信息，这种情况下，我们需要在connection:didReceiveResponse:方法中
	// 调用响应对象的expectedContentLength方法来获取数据的总长度。
	- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
	{
	    [receivedData appendData:data];
	}
	
	// 如果数据传输的过程中出现了错误，代理会接收到connection:didFailWithError:消息。其中error参数给出了错误信息。
	// 在代理收到connection:didFailWithError:消息后，它不会再接收指定连接的代理消息。
	- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
	{
	    theConnection = nil;
	    receivedData = nil;
	
	    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	}
	
	// 如果成功获取服务端返回的所有数据，则代理会收到connectionDidFinishLoading:消息。
	- (void)connectionDidFinishLoading:(NSURLConnection *)connection
	{
	    NSLog(@"Succeeded! Receive %lu bytes of data(unsigned long)",[receivedData length]);
	
	    theConnection = nil;
	    receivedData = nil;
	}
	
	@end

## 发起一个POST请求

我们可以像发起其它URL请求一样，发起一个HTTP或HTTPS POST请求。主要的区别在于我们必须先配置好NSMutableURLRequest对象，并将其作为参数传递给initWithRequest:delegate:方法。

另外，我们还需要构造请求的body数据。可以以下面三种方式来处理

1. 对于上传短小的内存数据，我们需要对已存在的数据块进行URL编码
2. 如果是从磁盘中上传文件，则调用setHTTPBodyStream:方法来告诉NSMutableURLRequest从一个NSInputStream中读取并使用结果数据作为body的内容
3. 对于大块的数据，调用CFStreamCreateBoundPair来创建流对象对，然后调用setHTTPBodyStream:方法来告诉NSMutableURLRequest使用这些流对象中的一个作为body内容的源。通过将数据写入其它流，可以一次发送一小块数据。

如果要上传数据到一个兼容的服务器中，URL加载系统同样支持100（继续）状态码，这样允许一个上传操作在发生认证错误或其它失败时仍能继续。为了开启这个操作，可以设置请求对象的expect头为100-continue。

代码清单2展示了如何配置一个POST请求的NSMutableURLRequest对象

	- (void)setRequestForPost
	{
	    // 对于application/x-www-form-urlencoded类型的body数据，form域的参数由&号分开，
	    NSString *bodyData = @"name=Jane+Doe&address=123+Main+St";
	    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.apple.com"]];
	    
	    // 设置content-type为application/x-www-form-urlencoded
	    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	    
	    // 指定请求方法为POST
	    [postRequest setHTTPMethod:@"POST"];
	    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
	    
	    // Initialize the NSURLConnection and proceed as described in
	    // Retrieving the Contents of a URL
	    
	}

## 使用Block来接收数据

NSURLConnection类提供了类方法sendAsynchronousRequest:queue:completionHandler:，该方法可以以异常的方式向服务端发起请求，并在数据返回或发生错误/超时时调用block来处理。该方法需要一个请求对象，一个完成处理block，及block运行的队列。当请求完成或错误发生时，URL加载系统调用该block来处理结果数据或错误信息。

如果请求成功，则会传递一个NSData对象和一个NSURLResponse对象给block。如果失败，则传递一个NSError对象。

这个方法有两个限制

1. 对于需要认证的请求，只提供最小的支持。
2. 没有办法来修改响应缓存和服务端重定向的默认行为。


参考：
[URL Loading System Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html)
