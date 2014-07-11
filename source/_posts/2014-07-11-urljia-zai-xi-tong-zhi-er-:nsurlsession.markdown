---

layout: post

title: "URL加载系统之二：NSURLSession"

date: 2014-07-11 22:48:27 +0800

comments: true

categories: iOS 网络

---

NSURLSession及相关的类提供通过HTTP协议下载数据的API。该类提供了大量代理方法来支持认证和后台下载(程序未运行或挂起时)功能。

为了使用NSURLSession，我们的应用会创建一系列的会话，每个会话负责协调一组相关数据的传输任务。在每个会话中，我们的应用添加一系列的任务，每个任务都表示一个对指定URL的请求。与大多数网络API一样，NSURLSession  API是异步的。如果我们使用系统提供的代理，我们必须提供一个请求完成处理block，以便在请求成功或失败时返回数据给我们的应用。如果我们提供自定义的代理对象，则任务对象调用这些代理方法，并回传从服务端获取的数据（如果是文件下载，则当传输完成时调用）。

NSURLSession提供了status和progress属性，并作为额外的信息传递给代理。同时它支持取消、恢复、挂起操作，并支持断点续传功能。

要掌握NSURLSession的使用，我们需要了解下URL会话的一些内容

## URL会话

在一个会话中的任务的行为取决于三个方面：

1. session的类型（由创建会话时的配置对象确定）
2. 任务的类型
3. 当任务创建时应用是否在前台

NSURLSession支持以下三种会话类型：

1. 默认会话：行为与其它下载URL的Foundation方法类似。使用基于磁盘的缓存策略，并在用户keychain中存储证书。
3. 短暂会话(Ephemeral sessions)：不存储任何数据在磁盘中；所有的缓存，证书存储等都保存在RAM中并与会话绑定。这样，当应用结束会话时，它们被自动释放。
3. 后台会话(Background sessions)：类似于默认会话，除了有一个独立的进程来处理所有的数据传输。

在一个会话中，NSURLSession支持三种任务类型

1. 数据任务：使用NSData对象来发送和接收数据。数据任务可以分片返回数据，也可以通过完成处理器一次性返回数据。由于数据任务不存储数据到文件，所以不支持后台会话.
2. 下载任务：以文件的形式接收数据，当程序不运行时支持后台下载
3. 上传任务：通常以文件的形式发送数据，支持后台上传。

NSURLSession支持在程序挂起时在后台传输数据。后台传输只由使用后台会话配置对象创建的会话提供。使用后台会话时，由于实际传输是在一个独立的进程中传输，且重启应用进程相当损耗资源，只有少量特性可以使用，所以有以下限制：

1. 会话必须提供事件分发的代理。
2. 只支持HTTP和HTTPS协议
3. 只支持上传和下载任务
4. 总是伴随着重定义操作
5. 如果当应用在后台时初始化的后台传输，则配置对象的discretionary属性为true

在iOS中，当我们的应用不再运行时，如果后台下载任务完成或者需要证书，则系统会在后台自动重启我们的应用，同时调用UIApplicationDelegate对象的application:handlerEventsForBackgroundURLSession:completionHandler:方法。这个调用会提供启动的应用的session的标识。我们的应用应该存储完成处理器，使用相同的标识来创建后台配置对象，然后使用配置对象来创建会话。新的会话会与运行的后台activity关联。当会话完成后台下载任务时，会给会话代理发送一个URLSessioinDidFinishEventsForBackgroundURLSession:消息。我们的代理对象然后调用存储的完成处理器。

如果在程序挂起时有任何任务完成，则会调用URLSession:downloadTask:didFinishDownloadingToURL:方法。同样的，如果任务需要证书，则NSURLSession对象会在适当的时候调用URLSession:task:didReceiveChallenge:completionHandler: 和URLSession:didReceiveChallenge:completionHandler:方法。

这里需要注意的是必须为每个标识创建一个会话，共享相同标识的多个会话的行为是未定义的。

会话和任务对象实现了NSCopying协议：

1. 当应用拷贝一个会话或任务对象时，会获取相同对象的指针
2. 当应用拷贝一个配置对象时，会获取一个可单独修改的新的对象

## 创建并配置NSURLSession

我们下面举个简单的实例来说明一个NSURLSession与服务端的数据交互。

###### 代码清单1：声明三种类型会话对象

	@interface URLSession : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>
	
	@property (nonatomic, strong) NSURLSession *backgroundSession;
	@property (nonatomic, strong) NSURLSession *defaultSession;
	@property (nonatomic, strong) NSURLSession *ephemeralSession;
	@property (nonatomic, strong) NSMutableDictionary *completionHandlerDictionary;
	
	- (void)addCompletionHandler:(CompletionHandlerType)handler forSession:(NSString *)identifier;
	
	- (void)callCompletionHandlerForSession:(NSString *)identifier;
	
	@end


NSURLSession提供了大量的配置选项，包括：

1. 支持缓存、cookie，认证及协议的私有存储
2. 认证
3. 上传下载文件
4. 每个主机的配置最大数
5. 超时时间
6. 支持的TLS最小最小版本
7. 自定义代理字典
8. 控制cookie策略
9. 控制HTTP管道行为

由于大部分设置都包含在一个独立的配置对象中，所以我们可以重用这些配置。当我们初始一个会话对象时，我们指定了如下内容

1. 一个配置对象，用于管理其中的会话和任务的行为
2. 一个代理对象，用于在收到数据时处理输入数据，及会话和任务中的其它事件，如服务端认证、确定一个资源加载请求是否应该转换成下载等。这个对象是可选的。但如果我们需要执行后台传输，则必须提供自定义代理。

在实例一个会话对象后，我们不能改变改变配置或代理。

###### 代码清单2演示了如何创建一个会话

	NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
	        
	// 配置会话的缓存
	NSString *cachePath = @"/MyCacheDirectory";
	        
	NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = [pathList objectAtIndex:0];
	        
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	        
	NSString *fullCachePath = [[path stringByAppendingPathComponent:bundleIdentifier] stringByAppendingPathComponent:cachePath];
	        
	NSLog(@"Cache path: %@", fullCachePath);
	        
	NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:16384 diskCapacity:268435456 diskPath:cachePath];
	defaultConfigObject.URLCache = cache;
	defaultConfigObject.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
	        
	self.defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];

除了后台配置对象外，我们可以重用会话的配置对象来创建新的会话，正如上面所讲的，拷贝一个配置对象会生成一个新的独立的配置对象。我们可以在任何时候安全的修改配置对象。当创建一个会话时，会话会对配置对象进行深拷贝，所以修改只会影响到新的会话。代理清单3演示了创建一个新的会话，这个会话使用重用的配置对象。

###### 代码清单3：重用会话对象

	self.ephemeralSession = [NSURLSession sessionWithConfiguration:ephemeralConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
	        
	ephemeralConfigObject.allowsCellularAccess = YES;
	        
	// ...
	NSURLSession *ephemeralSessionWifiOnly = [NSURLSession sessionWithConfiguration:ephemeralConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];


使用NSURLSession获取数据基本就是两步：

1. 创建一个配置对象及基于这个对象的会话
2. 定义一个请求完成处理器来处理获取到的数据。

如果使用系统提供的代理，只需要代码清单4这几行代码即可搞定

###### 代码清单4：使用系统提供代理

	NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
	[delegateFreeSession dataTaskWithRequest:@"http://www.sina.com"
	                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {    
	                                   NSLog(@"Got response %@", response);
	                               }];


只是系统提供的代理只提供有限的网络行为。如果应用需要更多的处理，如自定义认证或后台下载等，则需要使用自定义的代理。使用自定义代理来获取数据时，代理必须实现以下方法：

1. URLSession:dataTask:didReceiveData: 从请求提供数据给我们的任务，一次一个数据块
2. URLSession:task:didCompleteWithError: 表示任务已经接受了所有的数据。

如果我们在URLSession:dataTask:didReceiveData:方法返回后使用数据，则需要将数据存储在某个地方。

###### 代码清单5：演示了一个数据访问实例：

	NSURL *url = [NSURL URLWithString:@"http://www.sina.com"];
	NSURLSessionDataTask *dataTask = [self.defaultSession dataTaskWithURL:url];
	[dataTask resume];

如果远程服务器返回的状态表示需要一个认证，且认证需要连接级别的处理时，NSURLSession将调用认证相关代理方法。这个具体我们后面文章将详细讨论。

## 处理iOS后台Activity

在iOS中使用NSURLSession时，当一个下载完成时，会自动启动我们的应用。应用的代理方法application:handleEventsForBackgroundURLSession:completionHandler: 负责创建一个合适的会话，存储请求完成处理器，并在会话调用会话代理的URLSessionDidFinishEventsForBackgroundURLSession: 方法时调用这个处理器。代码清单6与代码清单7演示了这个处理流程

###### 代码清单6：iOS后台下载的会话代理方法

	- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
	{
	    NSLog(@"background url session %@", session);
	    
	    if (session.configuration.identifier)
	    {
	        [self callCompletionHandlerForSession:session.configuration.identifier];
	    }
	}
	
	- (void)callCompletionHandlerForSession:(NSString *)identifier
	{
	    CompletionHandlerType handler = [self.completionHandlerDictionary objectForKey:identifier];
	    
	    if (handler) {
	        [self.completionHandlerDictionary removeObjectForKey:identifier];
	        
	        handler();
	    }
	}


###### 代码清单7：iOS后台下载的App 代理方法

	- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
	{
	    NSURLSessionConfiguration *backgroundConfigObject = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
	    
	    URLSession *sessionDelegate = [[URLSession alloc] init];
	    
	    NSURLSession *backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfigObject
	                                                                    delegate:sessionDelegate
	                                                               delegateQueue:[NSOperationQueue mainQueue]];
	    
	    [sessionDelegate addCompletionHandler:completionHandler forSession:identifier];
	}

参考：

1. [URL Loading System Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html)
