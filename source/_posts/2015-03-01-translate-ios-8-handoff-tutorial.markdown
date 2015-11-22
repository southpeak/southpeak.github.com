---
layout: post
title: "iOS 8 Handoff Tutorial"
date: 2015-03-01 12:33:51 +0800
comments: true
categories: translate iOS
---

原文由`Soheil Azarpour`发表于`raywenderlich`，地址是[iOS 8 Handoff Tutorial](http://www.raywenderlich.com/84174/ios-8-handoff-tutorial)

`Handoff`是`iOS 8`和`OS X Yosemite`中的一个新特性。它让我们在不同的设备间切换时，可以不间断地继续一个`Activity`，而不需要重新配置任何设备。

我们可以为在`iOS 8`和`Yosemite`上的应用添加`Handoff`特性。在这篇指南中，我们将学习`Handoff`的基本功能和如何在非基于文档的`app`中使用`Handoff`。

## Handoff概览

在开始写代码前，我们需要先来了解一下`handoff`的一些基本概念。

### 起步

`Handoff`不仅可以将当前的`activity`从一个`iOS`设备传递到`OS X`设备，还可以将`activity`在不同的`iOS`设备传递。目前在模拟器上还不能使用`Handoff`功能，所以需要在`iOS`设备上运行我们的实例。

#### 设备兼容性：iOS

为了查看我们的`iOS`设备是否支持`handoff`功能，我们可以查看“设置”->“通用”列表。如果在列表中看到“Handoff与建议的应用程序”，则设备具备`Handoff`功能。以下截图显示了`iPhone 5s`(具备`Handoff`功能)和`iPad3`(不具备`Handoff`功能)的对比：

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/10/settings_screenshots-436x320.jpg)

`Handoff`功能依赖于以下几点：

1. 一个`iCloud`账户：我们必须在希望使用`Handoff`功能的多台设备上登录同一个`iCloud`账户。
2. 低功耗蓝牙(`Bluetooth LE 4.0`)：`Handoff`是通过低功耗蓝牙来广播`activities`的，所以广播设备和接收设备都必须支持`Bluetooth LE 4.0`。
3. `iCloud`配对：设备必须已经通过`iCloud`配对。当在支持`Handoff`的设备上登录`iCloud`账户后，每台设备都会与其它支持`Handoff`的设备进行配对。

此时，我们需要确保已经使用同一`iCloud`账号在两台支持`Handoff`功能且运行`iOS 8+`系统的设备上登录了。(译者注：具体配置可以参考[在 Chrome（iOS 版）中使用 Handoff](https://support.google.com/chrome/answer/6153783?hl=zh-Hans))

### User Activities

`Handoff`是基于`User Activity`的。`User Activity`是一个独立的信息集合单位，可以不依赖于任何其它信息而进行传输(`be handed off`)。

`NSUserActivity`对象表示一个`User Activity`实例。它封装了程序的一些状态，这些状态可以在其它设备相关的程序中继续使用。

有三种方法和一个`NSUserActivity`对象交互：

1) 创建一个`user activity`：原始应用程序创建一个`NSUserActivity`实例并调用`becomeCurrent()`以开启一个广播进程。下面是一个实例：

``` objective-c
let activity = NSUserActivity(activityType: "com.razeware.shopsnap.view")
activity.title = "Viewing"
activity.userInfo = ["shopsnap.item.key": ["Apple", "Orange", "Banana"]]
self.userActivity = activity;
self.userActivity?.becomeCurrent()
```

我们可以使用`NSUserActivity`的`userInfo`字典来传递本地数据类型对象或可编码的自定义对象以将其传输到接收设备。本地数据类型包括`NSArray`, `NSData`, `NSDate`, `NSDictionary`, `NSNull`, `NSNumber`, `NSSet`, `NSString`, `NSUUID`和`NSURL`。通过`NSURL`可能会有点棘手。在使用`NSURL`前可以先参考一下下面的“最佳实践”一节。

2) 更新`user activity`：一旦一个`NSUserActivity`成为当前的`activity`，则`iOS`会在最上层的视图控制器中调用`updateUserActivityState(activity:)`方法，以让我们有机会来更新`user activity`。下面是一个实例：

``` objective-c
override func updateUserActivityState(activity: NSUserActivity) {
    let activityListItems = // ... get updated list of items
    activity.addUserInfoEntriesFromDictionary(["shopsnap.item.key": activityListItems])
    super.updateUserActivityState(activity)
}
```

注意我们不要将`userInfo`设置为一个新的字典或直接更新它，而是应该使用便捷方法`addUserInfoEntriesFromDictionary()`。

在下文中，我们将学习如何按需求强制刷新`user activity`，或者是在程序的`app delegate`级别来获取一个相似功能的回调。

3) 接收`user activity`：当我们的接收程序以`Handoff`的方式启动时，程序代理会调用`application(:willContinueUserActivityWithType:)`方法。注意这个方法的参数不是`NSUserActivity`对象，因为接收程序在下载并传递`NSUserActivity`数据需要花费一定的时间。在`user activity`已经被下载完成后，会调用以下的回调函数：

``` objective-c
func application(application: UIApplication!, 
                 continueUserActivity userActivity: NSUserActivity!,
                 restorationHandler: (([AnyObject]!) -> Void)!) 
                 -> Bool {
 
    // Do some checks to make sure you can proceed
    if let window = self.window {
        window.rootViewController?.restoreUserActivityState(userActivity)
    }
    return true
}
```

然后我们可以使用存储在`NSUserActivity`对象中的数据来重新创建用户的`activity`。在这里，我们更新我们的应用以继续相关的`activity`。

### Activity类型

当创建一个`user activity`后，我们必须为其指定一个`activity`类型。一个`activity`类型是一个简单的唯一字符串，通常使用反转`DNS`语义，如`com.razeware.shopsnap.view`。

每一个可以接收`user activity`的程序都必须声明其可接收的`activity`类型。这类似于在程序中声明支持的`URL`方案(`URL schemes`)。对于非基于文本的程序，`activity`类型需要在`Info.plist`文件中定义，其键值为`NSUserActivityTypes`，如下所示：

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/10/image10-38-480x259.png)

对于支持一个给定`activity`的程序来说，需要满足三个要求：

1. 相同的组：两个程序都必须源于使用同一开发者组`ID(developer Team ID)`的开发者。
2. 相同的`activity`类型：发送程序创建某一`activity`类型的`user activity`，接收程序必须有相应类型的`NSUserActivityTypes`入口。
3. 签约：两个程序必须通过`App store`来发布或使用同一开发者账号来签约。

现在我们已经学习了`user activities`和`activity`类型的基础知识，接下来让我们来看一个实例。

## 启动工程

本指南的启动工程可以在“[启动工程](http://cdn2.raywenderlich.com/wp-content/uploads/2014/10/ShopSnap-Starter.zip)”中下载。下载后，使用`Xcode`打开工程并在`iPhone`模拟器中运行。

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/10/App_Screenshots-700x412.jpg)

工程名是`ShopSnap`，我们可以在这个程序中构建一个简单的购物清单。一个购物项由一个字符串表示，然后我们将购物项存储在一个字符串的数组中。点击+按钮添加一个新的项目到清单中，而轻扫可以移除项目。

我们将在程序中定义两个独立的`user activity`：

1. 查看清单。如果用户当前正在查看清单，我们将传输整个数组。
2. 添加或编译项目。如果用户当前正在添加新的项目，我们将传递一个单一项目的“编辑”`activity`。

### 设置开发组

为了让`Handoff`工作，发送和接收`app`都必须使用相同的开发组来签约。由于这个示例程序即是发送者也是接收者，所以这很简单！

选择`ShopSnap`工程，在“通用”选项卡中，在"`Team`"中选择自己的开发组：

![image](http://cdn2.raywenderlich.com/wp-content/uploads/2014/10/image15-49-700x232.png)

在支持`Handoff`的设备中编译并运行程序，以确保运行正常，然后继续。

### 配置activity类型

接下来是配置程序所支持的`activity`类型。打开`"Supporting Files\Info.plist"`，点击`"Information Property List"`旁边的"+"按钮，在`"Information Property List"`中添加一个新的选项：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/10/image16-52-480x268.png)

键名为`"NSUserActivityTypes"`，类型设备为数组类型，如下所示：

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/10/image17-55-480x233.png)

在`NSUserActivityTypes`下添加两项并设置类型为字符串。`Item 0`的值为`com.razeware.shopsnap.view`，`Item 1`的值为`com.razeware.shopsnap.edit`。

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/10/image18-58-480x85.png)

这些任意的`activity`类型对于我们的程序来说是特定和唯一的。因为我们将在程序的不同地方引用它们，所以在独立的文件中将其添加为常量是一种好的实践。

在工程导航中右键点击`ShopSnap`组，选择`"New File \ iOS \ Source \ Swift File"`。将文件命名为`Constants.swift`并确保新类被添加到`ShopSnap target`中。

在类中添加以下代码：

``` objective-c
let ActivityTypeView = "com.razeware.shopsnap.view"
let ActivityTypeEdit = "com.razeware.shopsnap.edit"
 
let ActivityItemsKey = "shopsnap.items.key"
let ActivityItemKey  = "shopsnap.item.key"
```

然后我们就可以使用这两个`activity`类型的常量。同时我们定义一些用于`user activity`的`userInfo`字典的键名字符串。

### 快速端到端测试

让我们来运行一个快速端到端测试以确保设备可以正确地通信。

打开`ListViewController.swift`并添加以下两个函数：

``` objective-c
// 1.
func startUserActivity() {
    let activity = NSUserActivity(activityType: ActivityTypeView)
    activity.title = "Viewing Shopping List"
    activity.userInfo = [ActivityItemsKey: ["Ice cream", "Apple", "Nuts"]]
    userActivity = activity
    userActivity?.becomeCurrent()
}
 
// 2.
override func updateUserActivityState(activity: NSUserActivity) {
    activity.addUserInfoEntriesFromDictionary([ActivityItemsKey: ["Ice cream", "Apple", "Nuts"]])
    super.updateUserActivityState(activity)
}
```

我们通过硬编码一个`user activity`来快速测试，以确保我们可以在另一端正常接收。

上面的代码做了以下两件事：

1. `startUserActivity()`是一个辅助函数，它使用一个硬编码的购物清单来创建了一个`NSUserActivity`实例。然后调用`becomeCurrent()`来广播这个`activity`。
2. 在调用`becomeCurrent()`后，系统将定期调用`updateUserActivityState()`。`UIViewController`从`UIResponder`类中继承了这个方法，我们应该重写它来更新我们的`userActivity`的状态。在这里，我们像前面一样使用硬编码来更新购物清单。注意，我们应该使用`addUserInfoEntriesFromDictionary`方法来修改`NSUserActivity的userInfo`字典。我们应该总是在方法的结尾调用`super.updateUserActivityState()`。

注意，我们只需要调用上面的起始方法。在`viewDidLoad()`起始行下面添加以下代码

``` objective-c
startUserActivity()
```

开始广播至少需要以上步骤。现在来看看接收者。打开AppDelegate.swift并添加以下代码：

``` objective-c
func application(application: UIApplication!, 
                 continueUserActivity userActivity: NSUserActivity!, 
                 restorationHandler: (([AnyObject]!) -> Void)!) 
                 -> Bool {
 
    let userInfo = userActivity.userInfo as NSDictionary
    println("Received a payload via handoff: \(userInfo)")
    return true
}
```

`AppDelegate`中的这个方法在所有事情都准备好，且一个`userActivity`被成功传送后调用。在这里我们简单打印`userActivity`中的`userInfo`字典。我们返回`true`来标识我们处理了`user activity`。

让我们来试试！要想在两台设备中正常工作，还需要做一些协调工作，所以还得仔细跟着。

1. 在第一台设备上安装并运行程序。
2. 在第二台设备上安装并运行程序。确保在`Xcode`中调用程序以便我们能看到打印输出。
3. 按下电源按钮让第二台设备休眠。在同一台设备上，按下`Home`键。如果所有事件都正常运行，我们应该可以看到`ShopSnap`程序的`icon`显示在屏幕的左下角上。从这里我们可以启动程序，然后在`Xcode`控制台可以看到以下的日志信息：

``` objective-c
Received a payload via handoff: {
    "shopsnap.items.key" = (
    "Ice cream",
    Apple,
    Nuts
  );
}
```

如果在锁屏下没有看到程序的`icon`，则在源设备上关闭并重新打开程序。这将强制系统重新广播信息。同时确认一下设备的控制台以查看是否有来自于`Handoff`的错误消息。

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/10/image20-63-180x320.png)

## 创建一个新的Activity

现在我们有一个基本上可以工作的`Handoff`程序，是时候来扩展它了。打开`ListViewController.swift`，更新`startUserActivity()`方法，这次我们传入实际的购物清单以代码硬编码。使用以下代码来更新方法：

``` objective-c
func startUserActivity() {
    let activity = NSUserActivity(activityType: ActivityTypeView)
    activity.title = "Viewing Shopping List"
    activity.userInfo = [ActivityItemsKey: items]
    userActivity = activity
    userActivity?.becomeCurrent()
}
```

同样，更新`ListViewController.swift`的`updateUserActivityState(activity:)`方法，传递购物清单数组：

``` objective-c
override func updateUserActivityState(activity: NSUserActivity) {
    activity.addUserInfoEntriesFromDictionary([ActivityItemsKey: items])
    super.updateUserActivityState(activity)
}
```

现在，更新`ListViewController.swift`中的`viewDidLoad()`，在从前面的代码中成功获取到清单后开启`userActivity`，如下所示：

``` objective-c
override func viewDidLoad() {
    title = "Shopping List"
    weak var weakSelf = self
    PersistentStore.defaultStore().fetchItems({ (items:[String]) in
        if let unwrapped = weakSelf {
            unwrapped.items = items
            unwrapped.tableView.reloadData()
            if items.isEmpty == false {
                unwrapped.startUserActivity()
            }
        }
    })
    super.viewDidLoad()
}
```

当然，如果程序开始时，清单是空的，则程序不会去广播`user activity`。我们需要解决这个问题：在用户第一次添加一个购物项到列表时开启`user activity`。

为了做到这一点，更新`ListViewController.swift`中代理回调`detailViewController(controller:didFinishWithUpdatedItem:)`的实现，如下所示：

``` objective-c
func detailViewController(#controller: DetailViewController,
                          didFinishWithUpdatedItem item: String) {
    // ... some code
    if !items.isEmpty {
        startUserActivity()
    }
}
```

在此有三种可能：

1. 用于更新一个已存在的购物项
2. 用户删除一个存在的购物项
3. 用户添加一个新的购物项

现存的代码处理了所有的可能性；我们只需要添加一些检测代码，以在有一个非空的清单时开始一个`activity`。

在两台设备上编译并运行。此时，我们应该可以在一台设备上添加新的项目，然后将其发送给另外一台设备。

### 收尾

当用户开始添加一个新的项目或编辑一个已存在的项目时，用户可能不是在查看购物清单。所以我们需要停止广播当前`activity`。同样，当清单中的所有项目被删除时，没有理由去继续广播当前`activiry`。在`ListViewController.swift`中添加以下辅助方法：

``` objective-c
func stopUserActivity() {
    userActivity?.invalidate()
}
```

在`stopUserActivity()`中，我们废止已存在的`NSUserActivity`。这让`handoff`停止广播。

现在有了`stopUserActivity()`，是时候在适当的地方调用它了。

在`ListViewController.swift`中，更新`prepareForSegue(segue:, sender:)`方法的实现，如下所示：

``` 
override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    // ... some code
    stopUserActivity()
}
```

当用户选择一行或者点击添加按钮时，`ListViewController`准备导航到详情视图。我们废弃当前的清单查看`activity`。

在同一文件中，更新`tableView(_:commitEditingStyle:forRowAtIndexPath:)`的实现，如下所示：

``` objective-c
override func tableView(tableView: UITableView, 
                        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
                        forRowAtIndexPath indexPath: NSIndexPath) {
    // ... some code
    if items.isEmpty {
        stopUserActivity()
    } else {
        userActivity?.needsSave = true
    }
}
```

当用户从清单中删除一项时，我们需要相应地更新`user activity`。如果移除清单中的所有项目，我们停止广播。否则，我们设置`userActivity`的`needsSave`属性为`true`。当我们这样做时，系统会立即回调`updateUserActivityState(activity:)`，在这里我们会更新`userActivity`。

结束这一节之前，还有一种情况需要考虑，用户点击取消按钮，然后从`DetailViewController`中返回。这触发了一个已存在的场景。我们需要重新开始`userActivity`。更新`unwindDetailViewController(unwindSegue:)`的实现，如下所示：

``` 
@IBAction func unwindDetailViewController(unwindSegue: UIStoryboardSegue) {
  // ... some code
  startUserActivity()
}
```

编译并运行，确保所有事情运行正常。尝试添加一些项目到清单中，确保它们在设备间传输。

## 创建一个编辑Activity

接下来，我们以类似的方式来处理`DetailViewController`。这一次，我们广播另一个`activity`类型。

打开`DetailViewController.swift`并修改`textFieldDidBeginEditing(textField:)`，如下所示：

``` objective-c
func textFieldDidBeginEditing(textField: UITextField!) {
    // Broadcast what we have, if there is anything!
    let activity = NSUserActivity(activityType: ActivityTypeEdit)
    activity.title = "Editing Shopping List Item"
    let activityItem = (countElements(textField.text!) > 0) ? textField.text : ""
    activity.userInfo = [ActivityItemKey: activityItem]
    userActivity = activity
    userActivity?.becomeCurrent()
}
```

​	

上面的方法使用项目的字符串的当前内容创建一个“编辑”`activity`。

当用户继续编辑项目时，我们需要更新`user activity`。仍然是在`DetailViewController.swift`中，更新`textFieldTextDidChange(notification:)`的实现，如下所示：

``` objective-c
func textFieldTextDidChange(notification: NSNotification) {
    if let text = textField!.text {
        item = text
    }

    userActivity?.needsSave = true
}
```

现在我们已经标记了`activity`需要更新，接下来实现`updateUserActivityState(activity:)`，以备系统的更新需求：

``` objective-c
override func updateUserActivityState(activity: NSUserActivity) {
    let activityListItem = (countElements(textField!.text!) > 0) ? textField!.text : ""
    activity.addUserInfoEntriesFromDictionary([ActivityItemKey: activityListItem])
    super.updateUserActivityState(activity)
}
```

这里我们简单地更新了当前项为文本输入框中的文本。

编译并运行。此时，如果我们在一个设备中开始添加一个新项或编辑已存在的项目，我们可以将编辑进程同步给另一个设备。

### 收尾

因为`needsSave`是一个轻量级的操作，在上面的代码中，你可以根据需要来设置它，然后在每次按键时更新`userInfo`。

这里有一个小细节你可能已经注意到了。视图控制器在`iPad`和`iPhone`的景观模式下中是一个分离视图。这样可以在清单的项目间切换而不需要收起键盘。这种情况发生时，`textFieldDidBeginEditing(textField:)`方法不会被调用，导致我们的`user activity`不会更新为新的文本。

为了解决这个问题，更新`DetailViewController.swift`中`item`属性的`didSet`观察者，如下所示：

``` objective-c
var item: String? {
    didSet {
        if let textField = self.textField {
            textField.text = item
        }
        if let activity = userActivity {
            activity.needsSave = true
        }
    }
}
```

当用户点击`ListViewController`中的一个项目时，`DetailViewController`的`item`属性被设置。一个简单解决方案是让视图控制器知道，在项目更新时它必须更新`activity`。

最后，当用户离开`DetailViewController`时，我们需要废止`userActivity`，以让编辑`activity`不再被广播。

在`DetailViewController.swift`的`textFieldShouldReturn(_:)`方法的起始位置添加以下代码：

``` objective-c
userActivity?.invalidate()
```

编译并运行程序，确保程序工作正常。接下来，我们将处理接收的`activity`。

## 接收Activity

当用户通过`Handoff`启动程序时，处理接收的`NSUserActivity`的任务大部分是由程序的`delegate`来完成的。

假设所有事情运行正常，数据成功传输，`iOS`会调用`application(_:continueUserActivity:restorationHandler:)`方法。这是我们与`NSUserActivity`实例交互的第一次机会。

我们在前面的章节中已经有一个该方法的实现了。现在，我们做如下修改：

​	

``` objective-c
func application(application: UIApplication!, 
                 continueUserActivity userActivity: NSUserActivity!,
                 restorationHandler: (([AnyObject]!) -> Void)!)
                 -> Bool {
 
    if let window = self.window {
        window.rootViewController?.restoreUserActivityState(userActivity)
    }
    return true
}
```

我们将`userActivity`传递给程序的`window`对象的`rootViewController`，然后返回`true`。这告诉系统成功处理了`Handoff`行为。从这里开始，我们将自己转发调用并恢复`activity`。

我们在`rootViewController`中调用的方法是`restoreUserActivityState(activity:)`。这是在`UIResponder`中声明的一个标准方法。系统使用这个方法来告诉接收者恢复一个`NSUserActivivty`实例。

我们现在的任务是沿着视图控制器架构往下，将`activity`从父视图控制器传递到子视图控制器，直到到达需要使用`activity`的地方：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/10/image22-691-700x360.png)

根视图控制器是一个`TraitOverrideViewController`对象，它的任务是管理程序的`size classes`；它对我们的`user activity`不感兴趣。打开`TraitOverrideViewController.swift`并添加以下代码：

``` objective-c
override func restoreUserActivityState(activity: NSUserActivity) {
    let nextViewController = childViewControllers.first as UIViewController
    nextViewController.restoreUserActivityState(activity)
    super.restoreUserActivityState(activity)
}
```

在这里，我们获取`TraitOverrideViewController`的第一个子视图控制器，然后将`activity`往下传递。这样做是安全的，因为我们知道程序的视图控制器只包含一个子视图控制器。

层级架构中的下一个视图控制器是`SplitViewController`，在这里事情会变得更有趣一些。

打开`SplitViewController.swift`并添加以下代码：

``` objective-c
override func restoreUserActivityState(activity: NSUserActivity) {
    // What type of activity is it?
    let activityType = activity.activityType

    // This is an activity for ListViewController.
    if activityType == ActivityTypeView {
        let controller = viewControllerForViewing()
        controller.restoreUserActivityState(activity)
    } else if activityType == ActivityTypeEdit {
        // This is an activity for DetailViewController.
        let controller = viewControllerForEditing()
        controller.restoreUserActivityState(activity)
    }

    super.restoreUserActivityState(activity)
}
```

`SplitViewController`知道`ListViewController`和`DetailViewController`。如果`NSUserActivity`是一个列表查看`activity`类型，则将其传递给`ListViewController`；否则，如果是一个编辑`activity`类型，则传递给`DetailViewController`。

我们将所有的`activity`传递给正确的对象，现在是时候从这些`activity`中获取数据了。

打开`ListViewController.swift`并实现`restoreUserActivityState(activity:)`，如下所示：

``` objective-c
override func restoreUserActivityState(activity: NSUserActivity) {
    // Get the list of items.
    if let userInfo = activity.userInfo {
        if let importedItems = userInfo[ActivityItemsKey] as? NSArray {
            // Merge it with what we have locally and update UI.
            for anItem in importedItems {
                addItemToItemsIfUnique(anItem as String)
            }
            PersistentStore.defaultStore().updateStoreWithItems(items)
            PersistentStore.defaultStore().commit()
            tableView.reloadData()
        }
    }
    super.restoreUserActivityState(activity)
}
```

在上面的方法中，我们终于可以继续一个查看`activity`了。因为我们需要维护一个唯一的购物清单时，我们只需要将这些唯一的项目添加到本地列表中，然后保存并更新UI。

编译并运行。现在我们可以看到通过`Handoff`从另一台设备上同步过来的清单数据了。

编辑`activity`以类似的方法来处理。打开`DetailViewController.swift`并实现`restoreUserActivityState(activity:)`，如下所示：

``` objective-c
override func restoreUserActivityState(activity: NSUserActivity) {
    if let userInfo = activity.userInfo {
        var activityItem: AnyObject? = userInfo[ActivityItemKey]
        if let itemToRestore = activityItem as? String {
            item = itemToRestore
            textField?.text = item
        }
    }
    super.restoreUserActivityState(activity)
}
```

这里获取编辑`activity`的信息并更新文本域的内容。

编译并运行，查看运行结果！

### 收尾

当用户在另一台设备上点击程序的`icon`以表明他们想要继续一个`user activity`时，系统启动相应的程序。一旦程序启动后，系统调用`application(_, willContinueUserActivityWithType:)`方法。打开`AppDelegate.swift`并添加以下方法：

``` objective-c
func application(application: UIApplication,
                 willContinueUserActivityWithType userActivityType: String!)
                 -> Bool {
    return true
}
```

到这里，我们的程序已经下载了`NSUserActivity`实例及其`userInfo`有效载荷。现在我们只是简单返回`true`。这强制程序在每次用户初始`Handoff`进程时接收`activity`。如果想要通知用户`activity`正在处理，则这是个好地方。

到这里，系统开始将数据从一台设备同步到另一台设备上。我们已经覆盖了任务正常运行的所有情况。但是可以想象`Handoff`的`activity`在某些情况下会失败。

将以下方法添加到`AppDelegate.swift`中来处理这种情况：

``` objective-c
func application(application: UIApplication!, 
                 didFailToContinueUserActivityWithType userActivityType: String!,
                 error: NSError!) {
 
    if error.code != NSUserCancelledError {
        let message = "The connection to your other device may have been interrupted. Please try again. \(error.localizedDescription)"
        let alertView = UIAlertView(title: "Handoff Error", message: message, delegate: nil, cancelButtonTitle: "Dismiss")
        alertView.show()
    }
}
```

如果我们接收到除了`NSUserCancelledError`之外的任何信息，则发生了某些错误，且我们不能恢复`activity`。在这种情况下，我们显示一个适当的消息给用户。然而，如果用户显示取消`Handoff`行为，则在这里我们不需要做任何事情，只需要放弃操作。

## 版本支持

使用`Handoff`的最佳实践之一是版本化。处理这的一个策略是为每个发送的`Handoff`添加一个版本号，并且只接收来自这个版本号(或者更早的)`handoff`。让我们来试试。

打开`Constants.swift`并添加以下常量：

``` objective-c
let ActivityVersionKey = "shopsnap.version.key"
let ActivityVersionValue = "1.0"
```

上面的版本键名和值是我们为这个版本的程序随意挑选的键值对。

如果我们回顾一下上面的章节，系统会定期并自动调用`restoreUserActivityState(activity:)`方法。这个方法的实现聚集于并限定于实现它的对象的范围内。例如，`ListViewController`重写了这个方法来更新带有购物清单的`userActivity`，而`DetailViewController`的实现是更新当前正在被编辑的项目。

如果涉及到的东西对于`userActivity`来说是通用的，可用于所有的`user activity`，如版本号，则处理它的最好的地方就是在`AppDelegate`中了。

任何时候调用`restoreUserActivityState(activity:)`，系统都会紧接着调用程序`delegate`的`application(application:, didUpdateUserActivity userActivity:)`方法。我们使用这个方法来为我们的`Handoff`添加版本支持。

打开`AppDelegate.swift`并添加以下代码：

``` objective-c
func application(application: UIApplication, 
                 didUpdateUserActivity userActivity: NSUserActivity) {
    userActivity.addUserInfoEntriesFromDictionary([ActivityVersionKey: ActivityVersionValue])
}
```

在这里我们简单地使用了程序的版本号来更新了`userInfo`字典。

仍然是在`AppDelegate.swift`中，更新`application(_:, continueUserActivity: restorationHandler:)`的实现，如下所示：

``` objective-c
func application(application: UIApplication!,
                 continueUserActivity userActivity: NSUserActivity!,
                 restorationHandler: (([AnyObject]!) -> Void)!)
                 -> Bool {
 
    if let userInfo: NSDictionary = userActivity.userInfo {
        if let version = userInfo[ActivityVersionKey] as? String {
            // Pass it on.
            if let window = self.window {
                window.rootViewController?.restoreUserActivityState(userActivity)
            }
            return true
        }
    }
    return false
}
```

在这里我们检查`userAcitivty`的版本，只有当版本号与我们知道的相匹配时才传递。编译并运行，确保程序运行正常。

## Handoff最佳实践

在结束之前，我们来看看`Handoff`的最佳实践：

1. `NSURL`：在`NSUserActivity`的`userInfo`字典中使用`NSURL`有点棘手。唯一可以安全地在`Handoff`中传输的`NSURLs`是使用`HTTP/HTTPS`和`iCloud`文档的`web`网址。我们不能传递本地文件的URL，因为在接收者端，接收者不能正确地转换并映射这些`URL`。传输文件链接的最好的方式是传递相对路径，然后在接收者端重新构建我们的`URL`。
2. 平台特定值：避免使用平台特定值，如滑动视图的内容偏移量；更好的方法是使用相对位置。例如，如果用户查看`table view`中的一些项目时，在我们的`user activity`中传递`table view`最上面的可视项的`index path`，而不是传递`table view`可视区域的内容偏移量。
3. 版本：想想在程序中使用版本和将来的更新。我们可以在程序的未来版本中添加一些新数据格式或者从`userInfo`字典中移除值。版本让我们可以理好地控制我们的`user activity`在当前和将来版本的程序中的行为。

## 下一步是哪

这里是[示例工程](http://cdn5.raywenderlich.com/wp-content/uploads/2014/10/ShopSnap-Final.zip)的最终版本。

如果想了解更多的关于`Handoff`，流和基于文档的`Handoff`，则可以查看`Handoff`的开发文档[Apple’s Handoff Programming Guide](https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/Handoff/HandoffFundamentals/HandoffFundamentals.html)以获取更多的信息。

如果喜欢这篇文章，则可以下载我们的书[iOS 8 by Tutorials](http://www.raywenderlich.com/store/ios-8-by-tutorials)，这里塞满了这样的教程。

如果有更多的总量或关于这篇文章的评论，那么可以加入下面的讨论。