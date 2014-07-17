---
layout: post

title: "URL加载系统之四：认证与TLS链验证"

date: 2014-07-16 18:51:03 +0800

comments: true

categories: iOS 网络

---

一个NSURLRequest对象经常会遇到认证请求，或者需要从其所连接的服务端请求证书。当需要认证请求时，NSURLConnection、NSURLSession和NSURLDownload类会通知它们的代理对象，以便能正确地做处理。不过需要注意的是，URL加载系统只有在服务端响应包含WWW-Authenticate头时才会调用代理来处理认证请求，而类似于代理认证和TLS信任验证这样的认证类型则不需要这个头。

## 确定如何响应一个认证请求

如果一个NSURLRequest对象需要认证时，则认证请求方式取决于使用的对象的类型：

1. 如果请求是与NSURLSession对象关联，则所有认证请求都会传递给代理，而不考虑认证的类型。
2. 如果请求是与NSURLConnection或NSURLDownload对象，则对象的代理接收一个connection:canAuthenticateAgainstProtectionSpace: (或者 download:canAuthenticateAgainstProtectionSpace:) 消息。这允许代理对象在尝试再次认证前分析服务端的属性，包括协议和认证方法。如果我们的代理对象不准备认证服务端的受保护空间，则返回NO，且系统尝试使用用户的keychain的信息进行认证。
3. 如果NSURLConnection或NSURLDownload的代理对象没有实现connection:canAuthenticateAgainstProtectionSpace: (或者 download:canAuthenticateAgainstProtectionSpace:)方法，且保护空间使用客户端证书认证或服务端信任认证，则系统假设我们返回NO。而对象其它所有类型，系统都返回YES。

下一步，如果我们的代理对象同意处理认证，但是没有有效的证书（不管是作为请求URL的一部分或者在NSURLCredentialStorage中共享），则代理以收到以下消息：

1. URLSession:didReceiveChallenge:completionHandler:2. URLSession:task:didReceiveChallenge:completionHandler:3. connection:didReceiveAuthenticationChallenge:4. download:didReceiveAuthenticationChallenge:

为了让连接能够继续，则代理对象有三种选择：

1. 提供认证证书
2. 尝试在没有证书的情况下继续
3. 取消认证查询

为了确保操作的正确流程，传递给这些方法的NSURLAuthenticationChallenge实例会包含一些信息，包括是什么触发了认证查询、查询的尝试次数、任何先前尝试的证书、请求证书的NSURLProtectionSpace对象，及查询的发送者。

如果认证请求事先尝试认证且失败了(如用户在服务端修改了密码)，我们可以通过在认证请求调用proposedCredential来获取尝试凭据。代理可以使用这些证书来填充一个显示给用户的话框。

调用认证请求的previousFailureCount可以返回身份验证尝试次数，这些尝试包括不同认证协议的尝试请求。代理可以将这些方法提供给用户，以确定先前提供的证书是否失败，或限制最大认证尝试次数。

## 响应认证请求

前面说过三种响应我们响应connection:didReceiveAuthenticationChallenge:代理方法的方式，我们将逐一介绍：

#### 提供证书

为了进行认证，程序需要使用服务端期望的认证信息创建一个NSURLCredential对象。我们可以调用authenticationMethod来确定服务端的认证方法，这个认证方法是在提供的认证请求的保护空间中。NSURLCredential支持一些方法：

1. HTTP基本认证(NSURLAuthenticationMethodHTTPBasic)：需要用户名和密码。提示用户输入必要信息并使用credentialWithUser:password:persistence:方法创建一个NSURLCredential对象。
2. HTTP数字认证(NSURLAuthenticationMethodHTTPDigest):类似于基本认证，需要用户名和密码。提示用户输入必要信息并使用credentialWithUser:password:persistence:方法创建一个NSURLCredential对象。
3. 客户端证书认证(NSURLAuthenticationMethodClientCertificate): 需要系统标识和所有服务端认证所需要的证书。然后使用credentialWithIdentity:certificates:persistence:来创建一个NSURLCredential对象。
4. 服务端信任认证(NSURLAuthenticationMethodServerTrust)需要一个由认证请求的保护空间提供的信任。使用credentialForTrust:来创建一个NSURLCredential对象。

在创建NSURLCredential对象后

1. 对于NSURLSession，使用提供的完成处理block将该对象传递给认证请求发送者
2. 对于NSURLConnection和NSURLDownload，使用useCredential:forAuthenticationChallenge:方法将对象传递给认证请求发送者。

#### 尝试在没有证书的情况下继续

如果代理选择不提供证书，可以尝试继续操作：

1. 对于NSURLSession，传递下面的值给完成处理block:
	NSURLSessionAuthChallengePerformDefaultHandling:处理请求。尽管代理没有提供代理方法来处理认证请求
	NSURLSessionAuthChallengeRejectProtectionSpace:拒绝请求。依赖于服务端响应允许的认证类型，URL加载类可能多次调用这个代理方法。
2. 对于NSURLConnection和NSURLDownload，在[challenge sender]中调用continueWithoutCredentialsForAuthenticationChallenge:。

依赖于协议的实现，这种处理方法可能会导致连接失败而以送connectionDidFailWithError:消息，或者返回可选的不需要认证的URL内容。

#### 取消连接

代理可以选择取消认证请求

1. 对于NSURLSession，传递NSURLSessionAuthChallengeCancelAuthenticationChallenge给完成处理block
2. 对于NSURLConnection和NSURLDownload，在[challenge sender]中调用cancelAuthenticationChallenge:。代理接收connection:didCancelAuthenticationChallenge:消息，以提供用户反馈的机会。


下面的代码演示了使用用户名和密码创建NSURLCredential对象来响应认证请求

	-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
		{
	    if ([challenge previousFailureCount] == 0)

	    {
	    	        NSURLCredential *newCredential;
	        newCredential = [NSURLCredential credentialWithUser:[self preferencesName] password:[self preferencesPassword] persistence:NSURLCredentialPersistenceNone];
	        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
	    }

	    else

	    {	        [[challenge sender] cancelAuthenticationChallenge:challenge];	        // inform the user that the user name and password	        // in the preferences are incorrect	        [self showPreferencesCredentialsAreIncorrectPanel:self];	    }

	}

如果代理没有实现connection:didReceiveAuthenticationChallenge:，而请求需要认证，则有效的证书必须位于URL证书存储中或作为请求URL的一部分。如果证书无效或者认证失败，则底层实现会发送一个continueWithoutCredentialForAuthenticationChallenge:消息。


## 执行自定义TLS链验证

在NSURL系统的AIP中，TLS链验证由应用的认证代理方法来处理，但它不是提供证书给服务端以验证用户，而是在TLS握手的过程中校验服务端提供的证书，然后再告诉URL加载系统是否应该接受还是拒绝这些证书。

如果需要以非标准的方法(如接收一个指定的自标识的证书用于测试)来执行链验证，则应用必须如下处理：

1. 对于NSURLSession，实现URLSession:didReceiveChallenge:completionHandler:和URLSession:task:didReceiveChallenge:completionHandler:代理方法。如果实现了两者，由会话级别的方法负责处理认证。
2. 对于NSURLConnection和NSURLDownload，实现connection:canAuthenticateAgainstProtectionSpace:和download:canAuthenticateAgainstProtectionSpace:方法，如果保护空间有一个NSURLAuthenticationMethodServerTrust类型的认证，则返回YES。然后，实现connection:didReceiveAuthenticationChallenge:或download:didReceiveAuthenticationChallenge:方法来处理认证。

在认证处理代理方法中，我们需要确认认证保护空间是否有NSURLAuthenticationMethodServerTrust类型的认证，如果有，则从保护空间获取serverTrust信息。