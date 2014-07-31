---
layout: post

title: "Core Bluetooth框架之二：后台处理"

date: 2014-07-31 23:28:24 +0800

comments: true

categories: iOS Network

---

在开发BLE相关应用时，由于应用在后台时会有诸多资源限制，需要考虑应用的后台处理问题。默认情况下，当程序位于后台或挂起时，大多数普通的Core Bluetooth任务都无法使用，不管是Central端还是Peripheral端。但我们可以声明我们的应用支持Core Bluetooth后台执行模式，以允许程序从挂起状态中被唤醒以处理蓝牙相关的事件。

然而，即使我们的应用支持两端的Core Bluetooth后台执行模式，它也不能一直运行。在某些情况下，系统可能会关闭我们的应用来释放内存，以为当前前台的应用提供更多的内存空间。在iOS7及后续版本中，Core Bluetooth支持保存Central及Peripheral管理器对象的状态信息，并在程序启动时恢复这些信息。我们可以使用这个特性来支持与蓝牙设备相关的长时间任务。

下面我们将详细讨论下这些问题。

## 只支持前台操作(Foreground-Only)的应用

大多数应用在进入到后台后都会在短时间内进入挂起状态，除非我们请求执行一些特定的后台任务。当处理挂起状态时，我们的应用无法继续执行蓝牙相关的任务。

在Central端，Foreground-Only应用在进入后台或挂起时，无法继续扫描并发现下在广告的Peripheral设备。而在Peripheral端，无法广告自身，同时Central端对其的任何访问操作都会返回一个错误。

Foreground-Only应用挂起时，所有蓝牙相关的事件都会被系统放入一个队列，当应用进入前台后，系统会将这些事件发送给我们的应用。也就是说，当某些事件发生时，Core Bluetooth提供了一种方法来提示用户。用户可以使用这些提示来决定是否将应用放到前台。在《Core Bluetooth框架之一：Central与Peripheral》中我们介绍了connectPeripheral:options:方法，在调用这个方法时，我们可以设备options参数来设置这些提示：

1. CBConnectPeripheralOptionNotifyOnConnectionKey：当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
2. CBConnectPeripheralOptionNotifyOnDisconnectionKey：当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
3. CBConnectPeripheralOptionNotifyOnNotificationKey：当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提示。

## Core Bluetooth后台执行模式

我们可以在Info.plist文件中设置Core Bluetooth后台执行模式，以让应用支持在后台执行一些蓝牙相关的任务。当应用声明了这一功能时，系统会将应用唤醒以允许它处理蓝牙相关的任务。这个特性对于与那种定时发送数据的BLE交互的应用非常有用。

有两种Core Bluetooth后台执行模式，一种用于实现Central端操作，一种用于实现Peripheral端操作。如果我们的应用同时实现了这两端的功能，则需要声明同时支持两种模式。我们需要在Info.plist文件添加UIBackgroundModes键，同时添加以下两个值或其中之一：

1. bluetooth-central(App communicates using CoreBluetooth)
2. bluetooth-peripheral(App shares data using CoreBluetooth)

#### bluetooth-central模式

如果设置了bluetooth-central值，则我们的应用在后台时，仍然可以查找并连接到Peripheral设备，以及查找相应数据。另外，系统会在CBCentralManagerDelegate或CBPeripheralDelegate代理方法被调用时唤醒我们的应用，允许应用处理事件，如建立连接或断开连接等等。

虽然应用在后台时，我们可以执行很多蓝牙相关任务，但需要记住应用在前后台扫描Peripheral设备时还是不一样的。当我们的应用在后台扫描Peripheral设备时，

1. CBCentralManagerScanOptionAllowDuplicatesKey扫描选项会被忽略，同一个Peripheral端的多个发现事件会被聚合成一个发现事件。
2. 如果扫描Peripheral设备的多个应用都在后台，则Central设备扫描广告数据的时间间隔会增加。结果是发现一个广告的Peripheral设备可能需要很长时间。

这些处理在iOS设备中最小化无线电的使用及改善电池的使用寿命非常有用。

#### bluetooth-peripheral模式
如果设置了bluetooth-peripheral值，则我们的应用在后台时，应用会被唤醒以处理来自于连接的Central端的读、写及订阅请求，Core Bluetooth还允许我们在后台进行广告。与Central端类似，也需要注意前后台的操作区别。特别是在广告时，有以下几点区别：

1. CBAdvertisementDataLocalNameKey广告key值会被忽略，Peripheral端的本地名不会被广告
2. CBAdvertisementDataServiceUUIDsKey键的所有服务的UUID都被放在一个"overflow"区域中，它们只能被那些显示要扫描它们的网络设备发现。
3. 如果多个应用在后台广告，则Peripheral设备发送广告包的时间间隔会变长。

## 在后台执行长(Long-Term)任务

虽然建议尽快完成后台任务，但有些应该仍然需要使用Core Bluetooth来执行一个长任务。这时就涉及到状态的保存与恢复操作。

#### 状态保存与恢复
因为状态保存与恢复是内置于Core Bluetooth的，我们的程序可以选择这个特性，让系统保存Central和Peripheral管理器的状态并继续执行一些蓝牙相关的任务，即使此时程序不再运行。当这些任务中的一个完成时，系统会在后台重启程序，程序可以恢复先前的状态以处理事件。Core Bluetooth支持Central端、Peripheral端的状态保存与恢复，也可以同时支持两者。

在Central端，系统会在关闭程序释放内存时保存Central管理器对象的状态(如果有多个Central管理器，我们可以选择系统跟踪哪个管理器)。对于给定的CBCentralManager对象，系统会跟踪如下信息：

1. Central管理器扫描的服务
2. Central管理器尝试或已经连接的Peripheral
3. Central管理器订阅的特性

在Peripheral端，对于给定的CBPeripheralManager对象，系统会跟踪以下信息：

1. Peripheral管理器广告的数据
2. Peripheral管理器发布到设备数据库的服务和特性
3. 订阅Peripheral管理器的特性值的Central端

当系统将程序重启到后台后，我们可以重新重新初始化我们程序的Central和Peripheral管理器并恢复状态。我们接下来将详细介绍一下如何使用状态保存与恢复。

#### 添加状态保存和恢复支持

Core Bluetooth中的状态保存与恢复是可选的特性，需要程序的支持才能工作。我们可以按照以下步骤来添加这一特性的支持：

1. (必要步骤)当分配及初始化Central或Peripheral管理器对象时，选择性加入状态保存与恢复。
2. (必要步骤)在系统重启程序时，重新初始化Central或Peripheral管理器对象
3. (必要步骤)实现适当的恢复代理方法
4. (可选步骤)更新Central或Peripheral管理器初始化过程

##### 选择性加入状态保存与恢复

为了选择性加入状态保存与恢复特性，在分配及初始化Central或Peripheral管理器时提供一个一个唯一恢复标识。**恢复标识**是一个字条串，用来让Core Bluetooth和程序标识Central或Peripheral管理器。字符串的值只在自己的代码中有意义，但这个字符串告诉Core Bluetooth我们需要保存对象的状态。Core Bluetooth只保存那些有恢复标识的对象。

例如，在实现Central端时，为了选择性加入状态保存与恢复特性，在初始化CBCentralManager对象时，可以指定初始化选项CBCentralManagerOptionRestoreIdentifierKey，并提供一个恢复标识，如下代码所示：

	centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionRestoreIdentifierKey: @"restoreIdentifier"}];

实现Peripheral端时的操作也类似，只不过我们使用选项CBPeripheralManagerOptionRestoreIdentifierKey键。

因为程序可以有多个Central或Peripheral管理器，所以需要确保恢复标识是唯一的，这样系统可以区分这些管理器对象。

##### 重新初始化Central或Peripheral管理器对象

当系统重启程序到后台后，我们所需要做的第一件事就是使用恢复标识来重新初始化这些对象。如果我们的应用只有一个Central管理器或Peripheral管理器，且管理器在程序的整个生命周期都存在，则后续我们便不需要再做更多的处理。但如果我们有多个管理器，或者管理器不是存在于程序的整个生命周期，则系统重启应用时，我们需要知道重新初始化哪一个管理器。我们可以通过在程序代理对象的application:didFinishLaunchingWithOptions:方法中，使用合适的启动选项键来访问管理器对象的列表(这个列表是程序关闭是系统为程序保存的)。

下面代码展示了程序重新启动时，我们获取所有Central管理器对象的恢复标识:

	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
	    // Override point for customization after application launch.
	    
	    NSArray *centralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];
	    
	    // TODO: ...
	    
	    return YES;
	}

有了这个恢复标识的列表后，我们就可以重新初始化我们所需要的管理器对象了。

##### 实现适当的恢复代理方法

重新初始化Central或Peripheral管理器对象后，我们通过使用蓝牙系统的状态同步这些对象的状态来恢复它们。此时，我们需要实现一些恢复代理方法。对于Central管理器，我们实现centralManager:willRestoreState:代理方法；对于Peripheral管理器管理器，我们实现peripheralManager:willRestoreState:代理方法。

*对于选择性加入保存与恢复特性的应用来说，这些方法是程序启动到后台以完成一些蓝牙相关任务所调用的第一个方法。而对于非选择性加入特性的应用来说，会首先调用centralManagerDidUpdateState:和peripheralManagerDidUpdateState:代理方法。*

在上述两个代理方法中，最后一个参数是一个字典，包含程序关闭时保存的关于管理器的信息。如下代码所示，我们可以使用CBCentralManagerRestoredStatePeripheralsKey键来获取Central管理器已连接的或尝试连接的所有Peripheral设备的列表:

	- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state
	{
	    NSArray *peripherals = state[CBCentralManagerRestoredStatePeripheralsKey];
	    
	    // TODO: ...
	}

获取到这个列表后，我们便可以根据需要来做处理。

##### 更新初始化过程

在实现了前面的三个步骤后，我们可能想更新我们的管理器的初始化过程。虽然这一步是可选的，但如果要确认任务是否运行正常时，非常有用。例如，我们的程序可能在解析所连接的Peripheral设备的数据的过程中被关闭。当程序使用这个Peripheral设备作恢复操作时，无法知道数据处理到哪了。我们需要确保程序从数据操作停止的位置继续开始操作。

又如下面的代码展示了在centralManagerDidUpdateState:代理方法中初始化程序操作时，我们可以找出是否成功发现了被恢复的Peripheral设备的指定服务：

	NSUInteger serviceUUIDIndex = [peripheral.services indexOfObjectPassingTest:^BOOL(CBService *obj, NSUInteger index, BOOL *stop) {        return [obj.UUID isEqual:myServiceUUIDString];    }];
    	if (serviceUUIDIndex == NSNotFound) {    	[peripheral discoverServices:@[myServiceUUIDString]];    	...
	}    
如上例所述，如果系统在程序完成搜索服务时关闭了应用，则通过调用discoverServices:方法在关闭的那个点开始解析恢复的Peripheral数据。如果程序成功搜索到服务，我们可以确认是否搜索到正确的特性。通过更新初始化过程，我们可以确保在正确的时间调用正确的方法。

## 小结

虽然我们可能需要声明应用支持Core Bluetooth后台执行模式，以完成特定的任务，但总是应该慎重考虑执行后台操作。因为执行太多的蓝牙相关任务需要使用iOS设备的内置无线电，而无线电的使用会影响到电池的寿命，所以尽量减少在后台执行的任务。任何会被蓝牙相关任务唤醒的应用应该尽快处理任务并在完成时重新挂起。

下面是一些基础的准则：

1. 应用应该是基于会话的，并提供接口以允许用户决定什么时候开始及结束蓝牙相关事件的分发。
2. 一旦被唤醒，一个应用大概有10s的时间来完成任务。理想情况下，应用应该尽快完成任务并重新挂起。系统可以对执行时间太长的后台任务进行限流甚至杀死。
3. 应用被唤醒时，不应该执行一些无关紧要的操作。



## 参考

[Core Bluetooth Programming Guide](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/AboutCoreBluetooth/Introduction.html)