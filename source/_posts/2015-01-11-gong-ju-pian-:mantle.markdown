---

layout: post

title: "工具篇：Mantle"

date: 2015-01-11 21:55:03 +0800

comments: true

categories: iOS

---

来源：[https://github.com/Mantle/Mantle](https://github.com/Mantle/Mantle)

版本：1.5.3

*Mantle makes it easy to write a simple model layer for your Cocoa or Cocoa Touch application.*

由上面这句话可知，Mantle的目的是让我们能简化Cocoa和Cocoa Touch应用的model层。那先来看看通常我们是怎么处理model层的吧。

## 解决的问题

在我们写代码时，总要面对不同的数据来源。这些数据可能是来自网络服务器、本地数据库或者是内存中。通常我们需要将这些数据存储到一个Model中。一般情况下，我们会怎么去定义一个Model呢？以Mantle官方的例子为例，可能是这样的：

	typedef enum : NSUInteger {
	    GHIssueStateOpen,
	    GHIssueStateClosed
	} GHIssueState;
	
	@interface GHIssue : NSObject <NSCoding, NSCopying>
	
	@property (nonatomic, copy, readonly) NSURL *URL;
	@property (nonatomic, copy, readonly) NSURL *HTMLURL;
	@property (nonatomic, copy, readonly) NSNumber *number;
	@property (nonatomic, assign, readonly) GHIssueState state;
	@property (nonatomic, copy, readonly) NSString *reporterLogin;
	@property (nonatomic, copy, readonly) NSDate *updatedAt;
	@property (nonatomic, strong, readonly) GHUser *assignee;
	@property (nonatomic, copy, readonly) NSDate *retrievedAt;
	
	@property (nonatomic, copy) NSString *title;
	@property (nonatomic, copy) NSString *body;
	
	- (id)initWithDictionary:(NSDictionary *)dictionary;
	
	@end
	
假定我们从网络服务器上获取了一组GHIssue对应的JSON数据，并已经将其转换为字典后，我们便可以用这个字典对GHIssue对象进行初始化了，-initWithDictionary:的实现如下：

	- (id)initWithDictionary:(NSDictionary *)dictionary {
	    self = [self init];
	    if (self == nil) return nil;
	
	    _URL = [NSURL URLWithString:dictionary[@"url"]];
	    _HTMLURL = [NSURL URLWithString:dictionary[@"html_url"]];
	    _number = dictionary[@"number"];
	
	    if ([dictionary[@"state"] isEqualToString:@"open"]) {
	        _state = GHIssueStateOpen;
	    } else if ([dictionary[@"state"] isEqualToString:@"closed"]) {
	        _state = GHIssueStateClosed;
	    }
	
	    _title = [dictionary[@"title"] copy];
	    _retrievedAt = [NSDate date];
	    _body = [dictionary[@"body"] copy];
	    _reporterLogin = [dictionary[@"user"][@"login"] copy];
	    _assignee = [[GHUser alloc] initWithDictionary:dictionary[@"assignee"]];
	
	    _updatedAt = [self.class.dateFormatter dateFromString:dictionary[@"updated_at"]];
	
	    return self;
	}

如果GHIssue对象有归档需求，则还需要实现以下两个方法：

	- (id)initWithCoder:(NSCoder *)coder {
	    self = [self init];
	    if (self == nil) return nil;
	
	    _URL = [coder decodeObjectForKey:@"URL"];
	    _HTMLURL = [coder decodeObjectForKey:@"HTMLURL"];
	    _number = [coder decodeObjectForKey:@"number"];
	    _state = [coder decodeUnsignedIntegerForKey:@"state"];
	    _title = [coder decodeObjectForKey:@"title"];
	    _retrievedAt = [NSDate date];
	    _body = [coder decodeObjectForKey:@"body"];
	    _reporterLogin = [coder decodeObjectForKey:@"reporterLogin"];
	    _assignee = [coder decodeObjectForKey:@"assignee"];
	    _updatedAt = [coder decodeObjectForKey:@"updatedAt"];
	
	    return self;
	}
	
	- (void)encodeWithCoder:(NSCoder *)coder {
	    if (self.URL != nil) [coder encodeObject:self.URL forKey:@"URL"];
	    if (self.HTMLURL != nil) [coder encodeObject:self.HTMLURL forKey:@"HTMLURL"];
	    if (self.number != nil) [coder encodeObject:self.number forKey:@"number"];
	    if (self.title != nil) [coder encodeObject:self.title forKey:@"title"];
	    if (self.body != nil) [coder encodeObject:self.body forKey:@"body"];
	    if (self.reporterLogin != nil) [coder encodeObject:self.reporterLogin forKey:@"reporterLogin"];
	    if (self.assignee != nil) [coder encodeObject:self.assignee forKey:@"assignee"];
	    if (self.updatedAt != nil) [coder encodeObject:self.updatedAt forKey:@"updatedAt"];
	
	    [coder encodeUnsignedInteger:self.state forKey:@"state"];
	}
	
额，好多代码。嗯，说实话，以前也经常写这种代码，真可谓又臭又长啊。也许我的工程中还有很多这样的Model，然后，然后......靠，好烦啊。再然后，某天，服务端的同事告诉我有N个接口需要加字段，额～～崩溃中。而且，从上面的Model中，我无法将其还原为对应的JSON串，且如果某些信息变了，那么归档的数据可能就无法使用了。

Mantle就是针对这几个问题而开发的一个开源库。

## 使用方法

其实Mantle的使用还是很简单的，它最主要的就是二个类和一个协议，即：

1. MTLModel类：通常是作为我们的Model的基类，该类提供了一些默认的行为来处理对象的初始化和归档操作，同时可以获取到对象所有属性的键值集合。
2. MTLJSONAdapter类：用于在MTLModel对象和JSON字典之间进行相互转换，相当于是一个适配器。
3. MTLJSONSerializing协议：需要与JSON字典进行相互转换的MTLModel的子类都需要实现该协议，以方便MTLJSONApadter对象进行转换。

还以GHIssue为例，我们通常会以以下方式来定义我们的Model：

	@interface GHIssue : MTLModel <MTLJSONSerializing>
	
	@property (nonatomic, copy, readonly) NSURL *URL;
	@property (nonatomic, copy, readonly) NSURL *HTMLURL;
	@property (nonatomic, copy, readonly) NSNumber *number;
	@property (nonatomic, assign, readonly) GHIssueState state;
	
	...
	
	@end

可以看到，我们的Model继承了通常是MTLModel类，同时实现了MTLJSONSerializing协议。这样，我们不再需要像上面那样写一大堆的赋值代码和编码解码方法，而只需要实现MTLJSONSerializing协议的+JSONKeyPathsByPropertyKey类方法，将我们的属性名的键值与JSON字典的键值做一个映射，我们便可以在MTLJSONAdapter对象的帮助下自动进行赋值操作和编码解码操作。我们来看看GHIssue类的具体实现：

	@implementation GHIssue
	
	...
	
	+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	    return @{
	        @"URL": @"url",
	        @"HTMLURL": @"html_url",
	        @"reporterLogin": @"user.login",
	        @"assignee": @"assignee",
	        @"updatedAt": @"updated_at"
	    };
	}
	
	...
	
	@end
	
可以看到，Model对象的属性与JSON数据之间的映射是通过字典来实现的。通过这种对应关系，Model对象便可以和JSON数据相互转换。需要注意的是返回中字典中的key值在Model对象中必须有对应的属性，否则Model对象将无法初始化成功。

当然这两者的值之间的转换关系可能需要我们自己来定义，这时我们就可以在Model中自定义+(NSValueTransformer *)<key>JSONTransformer方法来完成这一操作，如下代码所示：

	@implementation GHIssue
	
	...
	
	+ (NSValueTransformer *)URLJSONTransformer {
	    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
	}
	
	+ (NSValueTransformer *)HTMLURLJSONTransformer {
	    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
	}
	
	+ (NSValueTransformer *)stateJSONTransformer {
	    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
	        @"open": @(GHIssueStateOpen),
	        @"closed": @(GHIssueStateClosed)
	    }];
	}
	
	...
	
	@end
	
这样，在转换过程中，会自动调用这些方法来做数据的转换。而如果没有实现相应的方法，则会调用默认的+JSONTransformerForKey:来做处理，具体的实现可以参考[《源码篇：Mantle》](http://southpeak.github.io/blog/2015/01/11/yuan-ma-pian-:mantle/)。

有了上面这些准备工作，我们就需要通过MTLJSONAdapter类来适配MTLModel对象和JSON数据了，这个更容易了，代码如下所示：

	NSError *error = nil;
	
	NSDictionary *JSONDictionary = ...;
	
	GHIssue *issue = [MTLJSONAdapter modelOfClass:GHIssue.class fromJSONDictionary:JSONDictionary error:&error];
	
这样就根据一个JSON字典创建了一个GHIssue对象，而如果要从这个对象中获取到相应的JSON字典，则可以如下操作：

	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:issue];
	
以上便是Mantle的简单使用，当然更多的使用方式还需要在实践中多挖掘了。

这里还需要注意的是：

1. MTLModel的转换只针对我们定义的属性，而无法支持成员变量。
2. 支持嵌套属性的转换，这对于对象属性来说非常有用。

## 导入工程

想在我们的工程中使用Mantle，可以通过以下步骤导入：

1. 将Mantle库作为应用的子模块添加进来。
2. 运行Mantle文件夹下的script/bootstrap脚本。
3. 将Mantle.xcodeproj拖进我们的XCode工程或工作空间。
4. 在程序target的Build Phases选项卡中，在Link Binary With Libraries下添加Mantle的相关信息。在iOS工程中，添加libMantle.a库。
5. 在"Header Search Paths"设置中添加"$(BUILD_ROOT)/../IntermediateBuildFilesPath/UninstalledProducts/include" $(inherited)。
6. 对于iOS目标，在"Other Linker Flags"设置中添加-ObjC。
7. 如果我们将Mantle添加到工程(而不是工作空间)，则我们需要将Mantle依赖的库添加到程序的"Target Dependencies"中。

不过，我还是喜欢用CocoaPods来处理，只需要在Podfile中添加以下代码：

	pod 'Mantle', '~> 1.5.3'

然后在对应目录下运行pod install，稍等片刻便可以使用Mantle了。关于CocoaPods的使用，可参考[github上的cocoapods工程](https://github.com/CocoaPods/CocoaPods)。

## 不足之处

Mantle使用简单方便，极大的简化了我们的代码，可以满足我们大部分的需求。不过有时候我们可能会遇到这样的情况，由服务端提供的两个接口A和B，其实际上返回的数据可以转换为程序的同一个Model，只不过由于提供接口的是两个人，而且没有相互约定；抑或是服务端接口返回的数据与本地数据库的数据可以转换化同一个Model，但由于历史原因，这两者的字段也没对应上，如下所示：

	// A接口返回的JSON数据为
	{"user": "abc", "password": "abc"}
	
	// B接口返回的JSON数据为
	{"user": "123", "pwd": "123"}
	
这种情况下如何使用Mantle呢？看着实际上都一样，只是字段名不一样。这时似乎就不好处理了。因为+JSONKeyPathsByPropertyKey中，字典的key表示的是MTLModel的属性键值，是通过属性的键值去找相应的JSON数据的key。因此，这种情况下可能就得定义两个Model了。

在我们之前的工程中，也有做过类似Mantle的处理，只不过没有做得这么细致。针对上面的问题，我们的方案是刚好反过来，这个映射字典的key是JSON字典的key值，而映射字典的value是对象属性的key值。这样，我们就可以将不回数据来源的JSON字典的不同key映射到同一个Model对象的同一个属性上了。

另外一方面，由于转换过程涉及到一些映射查找操作，所以性能上也不如直接写赋值语句来得快。不过Mantle已以通过缓存对此做了优化，所以这一点还是可以接受的。

## 参考与推荐

1. [Mantle工程](https://github.com/Mantle/Mantle)
2. [源码篇：Mantle](http://southpeak.github.io/blog/2015/01/11/yuan-ma-pian-:mantle/)
2. [Mantle 初步使用](http://ourui.github.io/blog/2014/01/22/mantle-use/)
3. [使用Mantle处理Model层对象](http://blog.codingcoder.com/use-mantle-to-model/)
