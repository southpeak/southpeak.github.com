---
layout: post
title: "App Transport Security(ATS)"
date: 2015-09-14 19:47:32 +0800
comments: true
categories: iOS
---

最近下载iOS 9 GM版，然后跑了下我们的应用，发现有些网络请求失效了。先前在WWDC 2015上了解到iOS 9将要求网络请求使用HTTPS协议，但一直没有在iOS 9 beta版上跑过。现在这个问题突显出来了，所以搜了一些博文研究了一下。

我们知道，Apple在安全及用户隐私方面做了很多工作，包括沙盒机制、代码签名、禁用私有API等。而在今年6月份的WWDC 2015上，Apple又提出了App Transport Security(ATS)的概念。这一特性的主要意图是为我们的App与服务器之间提供一种安全的通信方式，以防止中间人窃听、篡改传输的数据。这一特性在iOS 9+和OS X 10.11+中是默认的支持项。这一概念的提出，也将意味着Apple将会慢慢转向支持HTTPS，而可能放弃HTTP。

## App Transport Security技术要求

我们先来看看ATS的技术要求（参考[App Transport Security Technote](https://developer.apple.com/library/prerelease/ios/technotes/App-Transport-Security-Technote/)）：

- The server must support at least Transport Layer Security (TLS) protocol version 1.2.
- Connection ciphers are limited to those that provide forward secrecy (see the list of ciphers below.)
- Certificates must be signed using a SHA256 or better signature hash algorithm, with either a 2048 bit or greater RSA key or a 256 bit or greater Elliptic-Curve (ECC) key.

可以看到服务端必须支持TLS 1.2或以上版本；必须使用支持前向保密的密码；证书必须使用SHA-256或者更好的签名hash算法来签名，如果证书无效，则会导致连接失败。

Apple认为这是目前保证通信安全性的最佳实践，特别是使用TLS 1.2和前向保密。当然，相信Apple也会与时俱进，不断的修正ATS，以保证网络通信的安全性。

## 默认配置

在iOS 9+和OS X 10.11+中，如果我们的App使用了`NSURLConnection`、`CFURL` 或者`NSURLSession`相关的API来进行数据通信的话，则默认是通过ATS的方式来传输数据。在此配置下，如果我们使用HTTP来进行通信，则会导致请求失败，并报以下错误：

``` 
The resource could not be loaded because the App Transport Security policy requires the use of a secure connection.
```

这样意味着如果使用ATS，将无法支持HTTP协议（我们测试了一下，由于我们的登录服务是使用HTTP协议，目前在iOS 9下已无法正常登录）。相信目前还有大量的应用是通过HTTP协议来访问服务器的。而要让所有的应用都转向支持HTTPS，显然是一件费时费力的事（与今年年头所有应用必须支持64位ARM不同，那次只是在客户端层面，而ATS涉及到服务端，影响面更大）。所以苹果提供了一种兼容方案，下面我们就来看看如何处理。

## 自定义配置

考虑到现实因素，我们可能并不想使用默认配置，或者至少需要一个过渡时期。为此，Apple允许我们在Info.plist文件中来自行配置以修改默认设置(Exceptions)，下表是一些键值及对应的类型和说明：

| 键                                        | 类型         | 说明                                       | 
| ---------------------------------------- | ---------- | ---------------------------------------- | 
| NSAppTransportSecurity                   | Dictionary | 配置ATS的顶层键值                               | 
| NSAllowsArbitraryLoads                   | Boolean    | 这是一个开关键，设置不在NSExceptionDomains列表中的其它域ATS特性。默认值是NO，如果设置为YES，则会关闭其它域的ATS特性。 | 
| NSExceptionDomains                       | Dictionary | 特定域列表                                    | 
| <domain-name-for-exception-as-string>    | Dictionary | 需要自定义配置的域名，键是对应的域名，如www.apple.com        | 
| NSExceptionMinimumTLSVersion             | String     | 指定域所需要的TLS的最低版本。有效值包括：TLSv1.0、TLSv1.1、TLSv1.2。默认值是TLSv1.2 | 
| NSExceptionRequiresForwardSecrecy        | Boolean    | 指定域是否需要支持前向保密。默认值是YES                    | 
| NSExceptionAllowsInsecureHTTPLoads       | Boolean    | 指定域的请求是否允许使用不安全的HTTP。使用这个键来访问没有证书，或者证书是自签名、过期或主机名不匹配的证书。默认值为NO，表示需要使用HTTPS。 | 
| NSIncludesSubdomains                     | Boolean    | 指定自定义的值是否应用到域的所有子域中。默认值是NO               | 
| NSThirdPartyExceptionMinimumTLSVersion   | String     | 类似于NSExceptionMinimumTLSVersion键，只不过指定的是应用本身无法控制的第三方组件的域所需要的TLS的最低版本。 | 
| NSThirdPartyExceptionRequiresForwardSecrecy | Boolean    | 同上。指定第三方组件的域是否需要支持前向保密                   | 
| NSThirdPartyExceptionAllowsInsecureHTTPLoads | Boolean    | 同上。指定第三方组件的域的请求是否使用HTTPS                 | 

通过设置上面的这些值，就可以精确的配置应用中访问的不同域的ATS特性。如下是[WORKING WITH APPLE’S APP TRANSPORT SECURITY](http://www.neglectedpotential.com/2015/06/working-with-apples-application-transport-security/)中给出的一个配置示例：

![image](http://neglectedpotential.com/wp-content/uploads/ATSInfoplist.png)

另外，在这篇文章中，也为我们例举了几种常见的配置，我们一起来看一下：

### Example A：所有请求均使用ATS

这当然是默认配置，只需要我们使用NSURLSession, NSURLConnection或者CFURL来做网络请求。当然只有iOS 9.0+以及OS X 10.11+才支持这一特性。

### Example B：配置部分域不使用ATS

如果我们希望部分域的请求不使用ATS，则我们可以将这些域放在NSExceptionDomains列表中来进行配置，以修改这些域的ATS默认配置。如果我们希望指定域及其所有子域都禁用ATS，则设置`NSExceptionAllowsInsecureHTTPLoads`为YES并将`NSIncludesSubdomains`设置为YES，如下配置：

![image](http://www.neglectedpotential.com/wp-content/uploads/ExampleB.png)

那当然，如果我们不想在指定域完全禁用ATS，则可以设置 `NSExceptionRequiresForwardSecrecy` 和`NSExceptionMinimumTLSVersion` 来指定更多的规则。

### Example C：禁用ATS，但部分域使用ATS

如果我们想要在应用中禁用ATS特性，则可以设置`NSAllowsArbitraryLoads`的值为YES，这样所有的请求将不会使用ATS。而如果我们希望部分域使用ATS，则如同Example B中那样来设置指定域的 `NSExceptionAllowsInsecureHTTPLoads` 的值为NO，这样就要求指定域必须使用ATS来进行数据传输。如下配置：

![image](http://www.neglectedpotential.com/wp-content/uploads/ExampleC.png)

### Example D：降级ATS

在一些情况下，我们可能需要使用ATS，但可能现实情况并不完全能够支持ATS的最佳实践。比如我们的服务端支持TLS 1.2，但却不支持前向保密。这种情况下，我们可以让指定域支持ATS，但同时禁用前向保密，这种情况下就可以设置`NSExceptionRequiresForwardSecrecy`为NO。同样，如果我们希望使用前向保密，但可以TLS的版本只是1.1，则我们可以设置 `NSExceptionMinimumTLSVersion` 的值为TSLv1.1，如下配置：

![image](http://www.neglectedpotential.com/wp-content/uploads/ExampleD.png)

### Example E：完全禁用ATS的更友好的方式

如果想完全禁用ATS，我们可以在Info.plist中简单的设置`NSAllowsArbitraryLoads`为YES，如下配置：

![image](http://www.neglectedpotential.com/wp-content/uploads/ExampleE.png)



以上几种情况基本上囊括了自定义ATS特性的所有情况。大家可以根据需要来自定义配置。

## Certificate Transparency

对于ATS，大部分安全特性都是默认可用的，不过Certificate Transparency是必须配置的。Certificate Transparency的概念在wiki中的解释是：

``` 
Certificate Transparency (CT) is an experimental IETF open standard and open source framework for monitoring and auditing digital certificates. Through a system of certificate logs, monitors, and auditors, certificate transparency allows website users and domain owners to identify mistakenly or maliciously issued certificates and to identify certificate authorities (CAs) that have gone rogue.
```

它主要是让web站点的用户和域所有者可以识别出错误的或恶意的证书，以及识别出无效的证书颁发机构。

如果我们的证书支持certificate transparency，那么我们可以设置`NSRequiresCertificateTransparency`键来启用这一功能。而不如证书不支持certificate transparency，则该功能默认总是关闭的。

## 小结

Apple提出App Transport Security这一特性，是为了保证用户数据的安全传输。安全因素始终是网络开发中一个重要的因素，相信会有越来越多的站点会转向HTTPS。而Apple作为业内技术的一个风向标，也会带动这一趋势的发展。所以，还不支持HTTPS的筒子们可以行为起来了。

这篇文章更多的是对App开发文档[App Transport Security Technote](https://developer.apple.com/library/prerelease/ios/technotes/App-Transport-Security-Technote/)和[WORKING WITH APPLE’S APP TRANSPORT SECURITY](http://www.neglectedpotential.com/2015/06/working-with-apples-application-transport-security/)两篇文章的整理。[iOS程序犭袁](http://weibo.com/luohanchenyilong/)在他的[iOS9AdaptationTips](https://github.com/ChenYilong/iOS9AdaptationTips)一文中有更多有意思的内容，大家可以参考。

### 参考

1. [App Transport Security Technote](https://developer.apple.com/library/prerelease/ios/technotes/App-Transport-Security-Technote/)
2. [WORKING WITH APPLE’S APP TRANSPORT SECURITY](http://www.neglectedpotential.com/2015/06/working-with-apples-application-transport-security/)
3. [WWDC 2015视频：Networking with NSURLSession](https://developer.apple.com/videos/wwdc/2015/?id=711)
4. [App Transport Security](http://willowtreeapps.com/blog/app-transport-security/)
5. [iOS9AdaptationTips](https://github.com/ChenYilong/iOS9AdaptationTips)



------

Hi，我是南峰子，最近开通了微信公众号：iOS知识小集，将会分享工作学习中的一些总结、心得。另外也会分享一些旅行户外的小知识，求关注ing。

![image](https://github.com/southpeak/Blog-images/blob/master/weimin_header.jpg?raw=true)

