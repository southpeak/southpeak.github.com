---

layout: post

title: "URL加载系统之一：基本结构"

date: 2014-07-11 19:10:29 +0800

comments: true

categories: iOS 网络

---

URL加载系统是一组类和协议的集合，它允许我们的App访问URL指定的内容的。

URL加载系统的核心类是NSURL，该类提供了大量方法让我们操作URLs和它指向的资源。另外它还提供了一系列的类来加载URL的内容，上传数据到服务器，管理Cookie存储，控制响应缓存，处理认证存储和授权信息，及自定义协议扩展。

URL Loading System可支持以下协议

1. ftp://
2. http://
3. https://
4. file://
5. data://

另外它还支持代理服务和网关处理。

URL加载系统定义了用于加载URL的类，另外还定义了一些辅助类来修改加载类的行为。这些辅助类可以分为五大类：

1. 协议支持
2. 授权与认证
3. Cookie存储
4. 配置管理 
5. 缓存管理

整个URL加载系统的结构如下图所示：

![image](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/Art/nsobject_hierarchy_2x.png)

下面对这张图做个简单的介绍

## URL Loading

在这张图中，我们用得最多的就是URL Loading中的这几个类。这些类允许我们从URL指定的源获取内容。根据不同的需求，我们可以使用不同的类，这主要依赖于我们应用所支持的系统版本，以及我们希望内容是以文件的形式获取还是以数据块的方式获取。对于系统的版本，主要有以下几点作为参考：

1. 在iOS7及后续版本中，推荐使用NSURLSession。
2. 对于iOS7以前的版本，可以使用NSURLConnection来获取数据并加载到本地内存中。如果要保存数据，可以再将数据写入磁盘。

而对于获取数据，主要看我们是获取数据到内存中还是下载文件并保存。如果只是获取数据到内存中，则有两种方法：

1. 对于简单的请求，可以使用NSURLSession
2. 对于复杂的请求（如上传数据请求），提供了NSURLRequest对象来与NSURLSession和NSURLConnection一起使用。

不管使用哪种方法，我们都可以获取到响应数据，为此，我们可以如下处理响应

1. 提供一个响应处理block。当URL Loading类完成从服务端接收数据时调用该block.
2. 提供自定义有delegate。URL Loading类间断性地调用我们的代理方法来获取数据。在需要的情况下，我们的程序负责收集这些数据。

另外，URL Loading提供了一个返回对象来封装与请求相关的元数据，如MIME类型等。

而如果我们需要下载文件，则有两个基本方法来处理：

1. 对于简单请求，可以使用NSURLSession
2. 对于复杂请求，提供了NSURLRequest对象来与NSURLSession和NSURLDownload一起使用。

相较于NSURLDownload，NSURLSession有两个明显的优势：NSURLSession可用于iOS系统，而NSURLDownload在iOS中不被支持；当应用挂起、终止或异常退出时，下载可以在后台继续进行。

URL Loading中还提供了两个类用于处理元数据，一个用于表示客户端请求(NSURLRequest)，一个用于表示服务端响应(NSURLResponse)。我们分别介绍一下这两个类。

#### NSURLRequest

NSURLRequest对象封装了URL和协议指定的属性，及依赖于协议的行为。同时也指定了本地缓存策略及连接超时时间。一些协议支持协议指定的属性，如HTTP协议可以添加返回HTTP请求体，请求报头和传输方法到NSURLRequest中。

这里需要注意的是，当我们使用NSURLRequest的子类NSMutableURLRequest初始化一个连接或下载时，将会对NSMutableURLRequest实例进行深拷贝。因此在初始的请求上做修改时不会影响到连接和下载对象。

#### NSURLResponse

一个响应可以分为两个部分：描述内容的元数据和内容数据本身。而NSURLResponse类封装了大部分协议的响应元数据，这些元数据包括MIME类型，期望的Content-Length，编码格式，及提供响应的URL。NSURLResponse的一些子类提供了与协议相关的额外元数据。如NSHTTPURLResponse存储了web服务器返回的响应头和状态码。

需要注意的是NSURLResponse对象只存储响应的元数据，而不存储响应数据本身。响应数据由URL Loading通过响应处理block和对象的代理来接收并处理。

## 认证和证书

针对认证和证书，URL加载系统提供了以下几个类：

1. NSURLCredential：封装了由认证信息和持久化行为组成的证书。
2. NSURLProtectionSpace：表示需要特定证书的区域。一个保护区域可以限制到单独的URL，拥有web服务器的区域，或引用一个代理。
3. NSURLCredientialStorage：一般是一个共享实例，用于管理证书存储和提供NSURLCredential对象到NSURLProductionSpace对象的映射。
4. NSURLAuthenticationChallenge：封装了认证一个请求的的NSURLProtocol实现所需要的信息：一个建议的证书、保护空间、错误信息或者协议用于确定所需要认证的响应、以及认证尝试次数等。初始对象（即请求发送者）必须实现NSURLAuthenticationChallengeSender协议。NSURLAuthenticationChallenge实例被用于NSURLProtocol的子类来告诉URL加载系统需要认证。他们同样为NSURLConnection和NSURLDownload的代理方法提供了便利的自定义认证处理。

## 缓存管理

URL加载系统提供基于磁盘和内存的缓存，允许程序减少对网络连接的依赖，并提供对缓存响应的快速访问。缓存存储在每个app的缓存文件夹下。NSURLConnection会根据缓存策略（初始化NSURLRequest对象中指定的）来查询缓存。

NSURLCache提供了配置缓存大小和磁盘存储位置的方法。同时提供了包含缓存响应的NSCacheURLResponse对象集合的方法。NSCacheURLResponse对象封装了NSURLResponse对象和URL数据，同时提供用户信息字典，这些信息可以用于缓存任何用户数据。

不是所有的协议实现都支持响应缓存。当前只有http和https请求可被缓存。

一个NSURLConnection对象可以通过connection:willCacheResponse:代理访求来控制是否缓存响应，响应是否只应该存储在内存中。

## Cookie存储

由于HTTP协议是无状态的，所以客户端通常使用cookie来保存URL请求的数据。URL加载系统提供了接口来创建和管理cookie，将cookie作为HTTP请求的一部分来发送，及解析web服务端响应数据时接收cookie.

iOS提供了NSHTTPCookieStorage类来管理一个NSHTTPCookie对象的集合。

## 协议支持

URL加载系统默认支持http, https, file, ftp, data协议。另外，URL加载系统也允许我们注册自己的类来支持额外的系统层级的网络协议。我们也可以添加指定协议的属性到URL请求和URL响应对象
