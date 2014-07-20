---
layout: post

title: "Bonjour理论2：域命名约定、API及其操作"

date: 2014-07-20 15:52:22 +0800

comments: true

categories: iOS 网络

---


## 域命名约定

服务实例与服务类型的Bonjour名称与DNS域名相关。这里我们将介绍DNS域名，Bonjour本地“域”，和Bonjour服务实例与服务类型的命名规则。

#### 域名与DNS

DNS使用specific-to-general命名方案来为域名命名。最能用的域是".",称为根域名，这是类似于UNIX文件系统中的根目录"/"。所有其它域都在根域名的层次结构中。例如，域名www.apple.com.可以解析为根域"."，其下包含顶级域名"com.",再下面是二级域"apple.com.", 其下就是"www.apple.com."。下图显示了这种层次结构：

![image](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/NetServices/Art/names_01dns_2x.png)

在这棵倒树的顶部是根域。在其下面是一些顶级域：com., edu., org.等。在顶级域下面是一些二级域，如apple, darwin, zeroconf。这棵树可以无限延伸下去。

#### Bonjour和本地链路
Bonjour协议很大程度上都是在处理本地链路(网络的一部分)。一个主机的本地链路或才链路本地网络(link-lock network)包括主机本身及其它可以不修改IP分组数据就是交换包的主机。在实践中，这包含所有没被路由器分开的主机。

在Bonjour系统中，"local."用于标识在本地IP网络中应该使用IP多播查询来进行查找的名称。

注意："local."不是一个真实的域。我们可以将"local."当成一个伪域。它与传统的DNS域有一个根本的区别：其它域的名称是全局唯一的，而链路本地域名不是。www.apple.com在全球只有唯一的一个DNS入口。而以local.结尾的主机名是本地网络中由多播DNS响应者的集合管理的，所以命名范围就是"local."(本地)。所以只要不在同一个本地网络中，就可以有两台命名相同的主机，即使是在同一栋楼中。而在同一个本地网络中，也需要确保名称的唯一性。如果在本地网络中发生名称冲突，一个Bonjour主机会自动查找一个新的名称或让用户输入一个新的。

#### 现有服务类型的Bonjour名称
Bonjour服务根据IP服务的现有网络标准(RFC 2782)来命名。Bonjour服务名结合服务类型和传输协议绑定以形成一个注册类型。注册类型用于注册一个服务并创建DNS资源记录。如果要在DNS资源记录中区分注册类型和域名，可以要注册类型每个组件前使用下划线。其格式如下

**\_ServiceType.\_TransportProtocolName**

服务类型是该服务的官方IANA注册名称，如ftp,http或打印机。传输协议的名称是tcp或udp，取决于服务使用的传输协议。一个运行在TCP上的FTP服务注册类型应该是_ftp._tcp，并将注册一个名称为_ftp._tcp.local.的DNS PTR记录，以作为服务所在主机的多播DNS响应者。

#### 新服务的Bonjour名称
如果我们正在设计一个新的协议以作为Bonjour网络服务来推广，则应该在IANA中注册它。

IANA目前要求每个每个注册的服务都与一个"众所周知的端口"或众所周知的端口范围相关联。例如，http的端口是80，所以我们在浏览器中访问一个站点时，程序都假设HTTP服务运行在80端口上，除非我们另行指定。

但在Bonjour中，我们不需要知道端口号。因为客户端程序通过对服务类型进行简单查询，就能发现我们的服务，因此不需要端口。

#### 服务实例的Bonjour名称
服务实例名称是一种可读的字符串，因此，它们的名称具有描述性，并可以让用户重写我们提供的默认名称。由于它们是可浏览的，而不是类型化的，服务实例名可以是编码为UTF8的任何Unicode字符串，最多63个字节长度。

例如，一个在网络中分享音乐的程序可能使用本地用户名来分享服务(如Emille的曲库)。用户可以重写默认服务名，并将服务命名为Zealous Lizard's Tune Studio.\_music.\_tcp.local.

下图说明了一个Bonjour服务实例的名称结构。在树的顶部是域，如本地网络的local.。下一级是注册类型，它由前面加下划线的服务类型(_music)和传输协议(同样前面有开线)组成。在树的底部是可读的服务实例名，如Zealous Lizard's Tune Studio。完整的名称由底至顶，每个组件由"."分割。

![image](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/NetServices/Art/names_02services_2x.png)



## Bonjour的API架构

Bonjour网络服务的API结构如下图所示：

![image](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/NetServices/Art/rendarch_04apilayers_2x.png)

其主要有这么几部分：
1. NSNetService和NSNetServiceBrowser类：在Foundation框架中
2. CFNetServices：Core Services中CFNetwork框架的一部分；
3. DNS Service Discovery for Java(OS X)
4. 底层DNS Service Discovery API：构建在BSD socket

所有这些API集合提供了发布、搜索和网络服务解析的基础方法。下面我们简单介绍一下这几个部分

#### NSNetService和NSNetServiceBrowser

NSNetService和NSNetServiceBrowser提供了服务搜索和发布的面向对象接口。NSNetService对象表示Bonjour服务的实例，用于客户端发布和服务搜索；NSNetServiceBrowser表示特定类型服务的浏览器。大多数Cocoa程序员应该使用这些类来处理需求。如果需要更多详细的控制，可以使用DNS Service Discovery API。

NSNetService和NSNetServiceBrowser被安排到默认的NSRunLoop对象中来异步执行发布、搜索和解析操作。所以NSNetService和NSNetServiceBrowser返回的结果都由代理对象来处理。这些对象必须与一个run loop相关联，但不必是默认的run loop。

#### CFNetServices
CFNetServices API位于Core Services框架中，提供Core Foundation样式的类型和函数来管理服务和服务搜索。CFNetServices定义了三个Core Foundation对象类型: 

1. CFNetService：服务实例的抽象表示，用于发布或其它用途。相关的函数提供了发布和解析服务的支持
2. CFNetServiceBrowser：表示特定域中特定类型服务的浏览者。通常只在基于Core Foundation编码时使用这个类型
3. CFNetServiceMonitor

CFNetService和CFNetServiceBrowser对象通常在CFRunLoop中使用。为了获取结果，程序需要实现处理事件的回调函数，如新的服务产生和消失等。与NSNetService和NSNetServiceBrowser不同的是，CFNetServices类型可以不需要一个run loop，可以在需要的时候同步运行。但通常不建议同步使用。

#### DNS Service Discovery
DNS Service Discovery API声明在/usr/include/dns_sd.h中，它为Bonjour服务提供了低级别BSD socket通信。DNS Service Discovery作为软件与多播DNS响应者或DNS服务器之间的中介层。它为我们管理DNS响应者，让我们编写程序时专注于服务和服务浏览者而不是DNS资源记录。

由于DNS Service Discovery API是Darwin开源工程的一部分，我们应该在写跨平台代码使用它，或者在诸如在NSNetService这样的高级别API无法获取低级特性时使用它。

## Bonjour操作
Bonjour的网络服务结构包含一个简单易用的机制来发布、搜索和使用基于IP的服务。Bonjour支持三种基础操作，每一种都是零配置网络服务所必须的：

1. 发布(Publication): 广告一个服务
2. 搜索(Discovery): 浏览可用的服务
3. 解析(Resolution): 将服务实例名转化为地址和端口

下面将分别介绍这三个部分。

#### Publication
为了发布一个服务，程序或设备必须使用一个多播DNS响应者来注册服务，或者通过高级API，或者直接与响应者(mDNSResponser)通信。Bonjour同样支持在传统的DNS服务中存储记录。当注册服务后，会创建三个相关的DNS记录：服务记录(SRV), 指针记录(PTR)和文本记录(TXT)。其中TXT记录会包含额外的数据用于解析或使用服务，虽然这些数据通常是空的。

##### 服务记录
服务记录将服务实例名称映射到实际使用服务所需要的信息。客户端通过持久化方式存储服务实例名以访问这些服务，并在连接的时候执行针对主机名和端口号的DNS查询。这个额外的indirection级提供了两个重要的特性

1. 服务由一个可读的名称标识，而不是域名和端口号
2. 客户端可以在服务的端口号和IP地址变化时访问服务，只要服务名不变即可。

SRV记录包含两部分信息来标识一个服务

1. 主机名
2. 端口号

主机名是服务可被发现的域名。用主机名代替IP地址的原因是一个主机可能对应多个IP地址，或者可以同时有IPv4地址和IPv6地址。使用主机名可以让所有这些情况被正确的处理。

端口号标识的服务的TCP或UDP端口号。

SRV记录以下面的规则来命名：

**\<Instance Name>.\<Service Type>.\<Domain>**

\<Instance Name>是服务实例名称，可以是任何UTF-8编码的字符串，通常是可读的有意义的字符串

\<Service Type>是标准的IP协议名称，前面带有下划线，后面跟着传输协议(TCP/UDP，前缀也是下划线)。

\<Domain>是标准的DNS域名。这可能是一个特定的域名，如apple.com.，也可以是通用的以local.为后缀的域名(用于本地链路的服务)

下面是SRV记录的例子，它是一个运行在TCP上端口号为515上，名称为PrintsAlot的打印后台处理程序：

**PrintsAlot.\_printer.\_tcp.local. 120 IN src 0 0 515 blackhawk.local.**

这条记录将在本地链路的叫做blackhawk.local.的打印机的多播DNS响应者设备上被创建。初始的120是用于缓存的TTL值。两个0是分别表示权重和优先级，在传统DNS上选择多个与给定名匹配的记录时需要使用这两个值，而对于多播DNS，将忽略这两个值。

##### 指针记录

PTR记录可以通过将实例的类型映射到服务的特定类型的实例的名字来开启服务搜索。这个记录添加了另一个indirection层，以便服务可以只通过查询使用服务类型标定的PTR记录就被找到。

这个记录只包含信息的一小块--服务实例的名称。PTR记录的命名与SRV记录类似，不过没有实例名，如下所示：

**\<Service Type>.\<Domain>**

##### 文本记录
TXT记录与相应的SRV记录有相同的名称，并且可以包含少量的关于服务实例的额外的信息，一般不超过100-200个字节。记录也可以是空的。例如，一个网络游戏可以在多人游戏中广告所使用的地图名称。如果需要传输大量的数据，主机需要与客户端建立一个连接并直接发送数据。

通常，这个记录用于运行在同一地址同一端口的多个服务上，例如在同一个打印服务器上运行的多个打印队列，在这种情况下，TXT记录中额外的信息可用于标识预期的打印队列。如下表所示：

![image](http://b140.photo.store.qq.com/psb?/V130i6W71atwfr/AFtWnv5ko6gDjydKCfEChHIKr1la*sMWMqfKcG8VTXg!/b/dCtmdVP4JAAA&bo=TATAAAAAAAADAK0!&rf=viewer_4)

这么做是必要的，因为服务类型曾经与众所周知的端口相关联。建议新的Bonjour协议的设计者在不同的动态分配的端口上来运行每一个服务的实例，而不是在相同的众所周知的端口号上运行它们(这种情况下还需要额外的信息来指定客户端试图通信的服务实例)。

TXT记录中的数据的特性和格式特定于每种服务的类型，所有每个新的服务类型需要为自己相关的TXT记录定义数据的格式，并将其作为协议规范的一部分发布。


#### 搜索

服务搜索使用服务发布期间注册的DNS记录来查找特定类型的服务的所有实例。为了做到这一点，所有的应用执行一个匹配服务类型的PTR记录的查询。如\_http.\_tcp，通常使用高级接口。运行于每个设备上的多播DNS响应者将使用服务实例名来返回PTR记录。以音乐共享服务为例，下图显示了搜索的过程

![image](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/NetServices/Art/rendarch_02discover_2x.png)

在搜索音乐共享服务的过程，主要有两步：

1. 客户端程序向标准多播地址224.0.0.251发出一个在local.域中服务类型为\_music.\_tcp的查询。
2. 网络中的每一个多播DNS响应者都将接收到这个请求，但只有音乐共享设备会使用一个PTR记录来作出响应。在这种情况下，PTR记录保存一个服务实例名Ed's Party Mix._music._tcp.local.，客户端程序可以从PTR记录中提取服务实例名然后将其添加到一个音乐服务器的离线列表中。


#### 解析
服务搜索通常只会发生一次，例如，当用户第一次选择打印机时。这个操作保存了服务实例名，和一个服务的任何给定实例的稳定的标识符。端口号，IP地址，主机名可能经常改变，但用户在每次连接服务时不需要再次选择一个打印机。因此，将一个服务名解析为socket信息只有在服务真正使用时才发生。

为了解析一个服务，程序使用服务名来执行SRV记录的DNS查询。多播DNS响应者使用包含当前信息的SRV记录来作出响应。下图演示了音乐共享实例中服务解析的这样一个过程：

![image](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/NetServices/Art/rendarch_03resolve_2x.png)

这个过程主要分为几步：

1. 解析进程发送一个DNS查询到多播地址224.0.0.251，查询Ed’s Party Mix.\_music.\_tcp.local.的SRV记录。
2. 查询返回服务的主机名和端口号(eds-musicbox.local., 1010)
3. 客户端发送一个IP地址的多播请求
4. 请求解析为IP地址169.254.150.84.然后客户端使用这个IP地址和端口号来连接服务器。这个过程发生在服务被使用时，从而总是查找服务的最新地址和端口号。

































