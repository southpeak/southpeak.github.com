---
layout: post

title: "ReactiveCocoa指南一：信号"

date: 2014-08-02 23:03:12 +0800

comments: true

categories: iOS ReactiveCocoa

---

原文由Colin Eberhardt发表于raywenderlich，[ReactiveCocoa Tutorial – The Definitive Introduction: Part 1/2](http://www.raywenderlich.com/62699/reactivecocoa-tutorial-pt1)

在编写iOS代码时，我们的大部分代码都是在响应一些事件：按钮点击、接收网络消息、属性变化等等。但是这些事件在代码中的表现形式却不一样：如target-action、代理方法、KVO、回调或其它。ReactiveCocoa的目的就是定义一个统一的事件处理接口，这样它们可以非常简单地进行链接、过滤和组合。

ReactiveCocoa结合了一些编程模式：

1. 函数式编程：利用高阶函数，即将函数作为其它函数的参数。
2. 响应式编程：关注于数据流及变化的传播。

基于以上两点，ReactiveCocoa被当成是函数响应编程(Functional Reactive Programming, FRP)框架。我们将在下面以实例来看看ReactiveCocoa的实用价值。

## Reactive Playground实例

虽然这是一篇指南性质的文章，但我们将以一个简单的实例来介绍ReactiveCocoa。可以在[这里](http://cdn2.raywenderlich.com/wp-content/uploads/2014/01/ReactivePlayground-Starter.zip)下载源代码，然后编译并运行以确保程序可以运行。

ReactivePlayground是个非常简单的应用，只有一个用户登录界面。只需要提供正确的用户名及密码，就可以显示一幅可爱的小猫的图片。如下图所示：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/01/ReactivePlaygroundStarter.jpg)

这个工程很简单，所以花几分钟来熟悉一下这个工程。打开RWViewController.m，可以快速查找一下如何设置Sign in按钮可用的代码，以及显示/隐藏signInFailure Label的规则。在简单的实现中，我们能快速定位这些问题，但如果实现很复杂，那可能需要花一些时间来分析代码。

现在，我们有了ReactiveCocoa，它能让代码变得更清晰。来看看它是怎么做到的吧。

## 添加ReactiveCocoa框架

添加ReactiveCocoa框架到我们工程的最简单的方法是使用Cocoapods。我们先关闭ReactivePlayground工程。Cocoapods会创建一个Xcode workspace，它会替代我们的原始工程文件。

首先创建一个名为Podfile的空文件，打开并添加如下信息：

	platform :ios, '6.0'
	inhibit_all_warnings!
	xcodeproj 'RWReactivePlayground'
	
	target :RWReactivePlayground do
	    
	    pod 'ReactiveCocoa', '~> 2.3.1'
	
	end
	
	post_install do |installer|
	installer.project.targets.each do |target|
	puts "#{target.name}"
	end
	end

配置完成后保存文件，打开终端并转到工程所在目录，然后输入以下命令：

	pod install

然后终端会有如下输出

	Analyzing dependencies
	Downloading dependencies
	Installing ReactiveCocoa (2.3.1)
	Generating Pods project
	Pods-RWReactivePlayground-ReactiveCocoa
	Pods-RWReactivePlayground
	Integrating client project
	
	[!] From now on use `RWReactivePlayground.xcworkspace`.

这表示已经下载了ReactiveCocoa框架，同时Cocoapods创建了一个Xcode workspace，同时将框架整合到了我们的工程中。打开新生成的workspace文件(RWReactivePlayground.xcworkspace)，将看到如下的工程结构：

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/01/AddedCocoaPods.png)

我们看到有一个命名为ReactivePlayground的工程，这实际上是我们的初始工程，它依赖于Pods工程。做完这一切后，我们就可以开始玩了，哈哈。

## Time to Play

如上所述，ReactiveCocoa提供了一个标准的接口来处理不同的事件流。在ReactiveCocoa中，这些被统一称为信号，由RACSignal类表示。

打开程序的初始视图控制器RWViewController.m文件，在文件头部导入以下头文件：

	#import <ReactiveCocoa/ReactiveCocoa.h>

我们暂时先不替换原来的代码，先看看如何使用ReactiveCocoa。在viewDidLoad方法中加入如下代码：

    [self.usernameTextField.rac_textSignal subscribeNext:^(id x) {
        
        NSLog(@"%@", x);
    }];

运行程序并在用户名输入框中键入"reactive cocoa"，我们可以看到控制台会有如下输出：

	2014-07-31 15:32:30.890 RWReactivePlayground[9191:60b] r
	2014-07-31 15:32:32.007 RWReactivePlayground[9191:60b] re
	2014-07-31 15:32:32.289 RWReactivePlayground[9191:60b] rea
	2014-07-31 15:32:33.990 RWReactivePlayground[9191:60b] reac
	2014-07-31 15:32:34.889 RWReactivePlayground[9191:60b] react
	2014-07-31 15:32:35.557 RWReactivePlayground[9191:60b] reacti
	2014-07-31 15:32:36.022 RWReactivePlayground[9191:60b] reactiv
	2014-07-31 15:32:36.505 RWReactivePlayground[9191:60b] reactive
	2014-07-31 15:32:42.328 RWReactivePlayground[9191:60b] reactive 
	2014-07-31 15:32:47.223 RWReactivePlayground[9191:60b] reactive c
	2014-07-31 15:32:47.794 RWReactivePlayground[9191:60b] reactive co
	2014-07-31 15:32:48.191 RWReactivePlayground[9191:60b] reactive coc
	2014-07-31 15:32:48.657 RWReactivePlayground[9191:60b] reactive coco
	2014-07-31 15:32:49.141 RWReactivePlayground[9191:60b] reactive cocoa

我们可以看到，每次在text field中输入时，都会执行block中的代码。没有target-action，没有代理，只有信号与block。是不是很棒？

ReactiveCocoa信号发送一个事件流到它们的订阅者中。我们需要知道三种类型的事件：next, error和completed。一个信号可能由于error事件或completed事件而终止，在此之前它会发送很多个next事件。在这一部分中，我们将重点关注next事件。在学习关于error和completed事件前，请仔细阅读第二部分。

RACSignal有许多方法用于订阅这些不同的事件类型。每个方法会有一个或多个block，每个block执行不同的逻辑处理。在上面这个例子中，我们看到subscribeNext:方法提供了一个响应next事件的block。

ReactiveCocoa框架通过类别来为大部分标准UIKit控件添加信号，以便这些控件可以添加其相应事件的订阅，如上面的UITextField包含了rac_textSignal属性。

理论讲得差不多了，我们继续吧！！！

ReactiveCocoa有大量的操作右用于处理事件流。例如，如果我们只对长度大于3的用户名感兴趣，则我们可以使用filter操作。在viewDidLoad中更新我们的代码如下：

    [[self.usernameTextField.rac_textSignal filter:^BOOL(id value) {
        NSString *text = value;
        return text.length > 3;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];

运行并在用户名输入框中输入"reactive cocoa"，我们可以看到控制台会有如下输出：

	2014-07-31 15:52:13.558 RWReactivePlayground[9249:60b] reac
	2014-07-31 15:52:15.960 RWReactivePlayground[9249:60b] react
	2014-07-31 15:52:16.589 RWReactivePlayground[9249:60b] reacti
	2014-07-31 15:52:17.158 RWReactivePlayground[9249:60b] reactiv
	2014-07-31 15:52:17.807 RWReactivePlayground[9249:60b] reactive
	2014-07-31 15:52:18.674 RWReactivePlayground[9249:60b] reactive 
	2014-07-31 15:52:19.176 RWReactivePlayground[9249:60b] reactive c
	2014-07-31 15:52:19.710 RWReactivePlayground[9249:60b] reactive co
	2014-07-31 15:52:20.057 RWReactivePlayground[9249:60b] reactive coc
	2014-07-31 15:52:20.530 RWReactivePlayground[9249:60b] reactive coco
	2014-07-31 15:52:20.978 RWReactivePlayground[9249:60b] reactive cocoa

可以看到当长度小于3时，并不执行后续的操作。通过这种方式，我们创建了一个简单的管道。这就是响应式编程的实质，我们将我们程序的功能表示为数据流的形式。我们可以将上述调用表示为以下图例：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/01/FilterPipeline.png)

从上图中我们可以看到rac_textSignal是事件的初始源头。通过filter的数据流只有在其长度大于3时，才会被传递到下一处理流程中。管道的最后一步是subscribeNext:，在这个block中，我们记录日志。

在这里需要注意的是filter操作的输出仍然是一个RACSignal对象。我们可以将上面这段管道处理拆分成如下代码：

	RACSignal *usernameSourceSignal = self.usernameTextField.rac_textSignal;
    
    RACSignal *filteredUsername = [usernameSourceSignal filter:^BOOL(id value) {
        
        NSString *text = value;
        return text.length > 3;
    }];
    
    [filteredUsername subscribeNext:^(id x) {
        
        NSLog(@"%@", x);
    }];

因为RACSignal对象的每个操作都返回一个RACSignal对象，所以我们不需要使用变量就可以构建一个管道。

## 事件是什么

目前为止，我们已经描述了3种不同的事件类型，但还没有深入这些事件的结构。有趣的是，事件可以包含任何东西。为了证明这一点，我们在上面的管道中加入另一个操作。更新我们的代码：

	[[[self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @(text.length);
     }]
     filter:^BOOL(NSNumber *length) {
         return [length intValue] > 3;
     }]
     subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];

编译并运行，我们会发现控制台输出如下信息：

	2014-07-31 16:13:47.652 RWReactivePlayground[9321:60b] 4
	2014-07-31 16:13:47.819 RWReactivePlayground[9321:60b] 5
	2014-07-31 16:13:47.985 RWReactivePlayground[9321:60b] 6
	2014-07-31 16:13:48.134 RWReactivePlayground[9321:60b] 7
	2014-07-31 16:13:48.284 RWReactivePlayground[9321:60b] 8
	2014-07-31 16:13:48.417 RWReactivePlayground[9321:60b] 9
	2014-07-31 16:13:48.583 RWReactivePlayground[9321:60b] 10
	2014-07-31 16:13:48.734 RWReactivePlayground[9321:60b] 11
	2014-07-31 16:13:48.883 RWReactivePlayground[9321:60b] 12

新添加的map操作使用提供的block来转换事件数据。对于收到的每一个next事件，都会运行给定的block，并将返回值作为next事件发送。在上面的代码中，map操作获取一个NSString输入，并将其映射为一个NSNumber对象，并返回。下图演示了这个管道处理：

![image](http://cdn2.raywenderlich.com/wp-content/uploads/2014/01/FilterAndMapPipeline.png)

我们可以看到，map操作后的每一步接收的都是一个NSNumber对象。我们可以使用map操作来转换我们想要的数据，只需要它是一个对象。

OK，是时候修改ReactivePlayground应用的代码了。

## 创建有效的状态信号

我们要做的第一件事就是创建一对信号来校验用户名与密码的输入是否有效。添加如下代码到RWViewController.m的viewDidLoad中。

    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];

我们使用将map操作应用于文本输入框的rac_textSignal，输出是一个NSNumber对象。接着将转换这些信号，以便其可以为文本输入框提供一个合适的背影颜色。我们可以订阅这个信号并使用其结果来更新文本输入框的颜色。可以如下操作：

    [[validPasswordSignal map:^id(NSNumber *passwordValid) {
        return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
    }] subscribeNext:^(UIColor *color) {
        self.passwordTextField.backgroundColor = color;
    }];

从概念上讲，我们将信号的输出值赋值给文本输入框的backgroundColor属性。但是这段代码有点糟糕。我们可以以另外一种方式来做相同的处理。这得益于ReactiveCocoa定义的一些宏。如下代码所示：

    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:^id(NSNumber *passwordValid) {
        return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    RAC(self.usernameTextField, backgroundColor) = [validUsernameSignal map:^id(NSNumber *passwordValid) {
        return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
    }];

RAC宏我们将信号的输入值指派给对象的属性。它带有两个参数，第一个参数是对象，第二个参数是对象的属性名。每次信号发送下一个事件时，其输出值都会指派给给定的属性。这是个非常优雅的解决方案，对吧？

在运行前，我们先找到updateUIState方法，并注释掉下面两行代码：

	self.usernameTextField.backgroundColor = self.usernameIsValid ? [UIColor clearColor] : [UIColor yellowColor];
	self.passwordTextField.backgroundColor = self.passwordIsValid ? [UIColor clearColor] : [UIColor yellowColor];

运行程序，我们可以看到当输入无效时文本输入框是高亮的，有效时则清除高亮。在这里，我们可以看到两条带有文本信号的简单的管道，都是将它们映射到标明是否有效的布尔对象，然后再映射到UIColor对象。如下图所示：

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/01/TextFieldValidPipeline.png)

## 组合信号

在当前的程序中，Sign in按钮只有在两个输入框都有效时才可点击。是时候处理这个响应了。

当前代码有两个信号来标识用户名和密码是否有效：validUsernameSignal和validPasswordSignal。我们的任务是要组合这两个信号，来确定按钮是否可用。

在viewDidLoad中添加下面的代码

    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal]
                                                      reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
                                                          
                                                          return @([usernameValid boolValue] && [passwordValid boolValue]);
                                                      }];

上面的代码使用了combineLatest:reduce:方法来组合validUsernameSignal与validPasswordSignal最后输出的值，并生成一个新的信号。每次两个源信号中的一个输出新值时，reduce块都会被执行，而返回的值会作为组合信号的下一个值。

*注意：RACSignal组合方法可以组合任何数量的信号，而reduce块的参数会对应每一个信号。*

现在我们已以有了一个合适的信号，接着在viewDidLoad结尾中添加以下代码，这将信号连接到按钮的enabled属性。

    [signUpActiveSignal subscribeNext:^(NSNumber *signupActive) {
        
        self.signInButton.enabled = [signupActive boolValue];
    }];

同样，在运行前移除以下代码：

	@property (nonatomic) BOOL passwordIsValid;
	@property (nonatomic) BOOL usernameIsValid;

同时移除viewDidLoad中以下代码：

	[self.usernameTextField addTarget:self action:@selector(usernameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
	[self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged) forControlEvents:UIControlEventEditingChanged];

当然我们还需要移除updateUIState, usernameTextFieldChanged和passwordTextFieldChanged方法及相关的调用。瞧，我们已经删除了不少代码了。感谢自己吧！

运行，并检查Sign in按钮。如同之前一下，如果用户名和密码都有效，则按钮是可用的。

更新后程序的逻辑如下图所示：

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/01/CombinePipeline.png)

上面我们已经用ReactiveCocoa实现了一些非常棒的功能，它包含了两个重要的概念：

1. Spliting: 信号可以有多个订阅者，且作为资源服务于序列化管道的多个步骤。
2. Combining: 多个信号可以组合起来创建新的信号。

在上面的程序中，这些改变让程序不再需要私有属性，来标明两个输入域的有效状态。这是使用响应式编程的关键区别--我们不需要使用实例变量来跟踪短暂的状态。

## 响应Sign-in

程序目前使用了响应式管道来管理输入框与按钮的状态。按钮的点击操作仍然使用target-action。所以，这是我们下一步的目标。

Sign-in按钮的Touch Up Inside事件通过storyboard action连接到RWViewController.m的signInButtonTouched方法中。我们现在使用响应式方法来替换它，所以第一步我们需要解除当前storyboard action的连接。这个自己处理吧。

为了处理按钮事件，我们需要使用ReactiveCocoa添加到UIKit的另一个方法：rac_signalForControlEvents。我们在viewDidLoad结尾加入以下代码：

    [[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        NSLog(@"Button clicked");
    }];
    
上面的代码从按钮的UIControlEventTouchUpInside事件中创建一个信号，并添加订阅以在每次事件发生时添加日志。

运行程序，当按钮可点时点击按钮，会记录以下日志：

	2014-07-31 17:45:43.660 RWReactivePlayground[9617:60b] Button clicked
	2014-07-31 17:45:44.493 RWReactivePlayground[9617:60b] Button clicked
	2014-07-31 17:45:44.660 RWReactivePlayground[9617:60b] Button clicked
	2014-07-31 17:45:44.810 RWReactivePlayground[9617:60b] Button clicked
	2014-07-31 17:45:44.944 RWReactivePlayground[9617:60b] Button clicked

现在点击事件有一个信号了，接下来将信号与登录处理连接起来。打开RWDummySignInService.h文件，我们会看到下面的接口：

	typedef void (^RWSignInResponse)(BOOL);
	
	@interface RWDummySignInService : NSObject
	
	- (void)signInWithUsername:(NSString *)username password:(NSString *)password complete:(RWSignInResponse)completeBlock;
	
	@end

这个方法带有一个用户名、密码和一个完成block。block会在登录成功或失败时调用。我们可以在subscribeNext:块中直接调用这个方法，但为什么不呢？因为这是一个异步操作，小心了。

## 创建信号

幸运的是，将一个已存在的异步API表示为一个信号相当简单。我们来看看。

首先，从RWViewController.m移除当前的signInButtonTouched:方法。我们通过响应式编程来取代它。

在RWViewController.m中添加以下方法：

	- (RACSignal *)signInSignal
	{
	    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
	        
	        [self.signInService signInWithUsername:self.usernameTextField.text
	                                      password:self.passwordTextField.text
	                                      complete:^(BOOL success) {
	                                          [subscriber sendNext:@(success)];
	                                          [subscriber sendCompleted];
	                                      }];
	        return nil;
	    }];
	}

上面的代码创建了一个使用当前用户名与密码登录的信号。现在我们来分解一下这个方法。createSignal:方法用于创建一个信号。描述信号的block是一个信号参数，当信号有一个订阅者时，block中的代码会被执行。

block传递一个实现RACSubscriber协议的subscriber(订阅者)，这个订阅者包含我们调用的用于发送事件的方法；我们也可以发送多个next事件，这些事件由一个error事件或complete事件结束。在上面这种情况下，它发送一个next事件来表示登录是否成功，后续是一个complete事件。

这个block的返回类型是一个RACDisposable对象，它允许我们执行一些清理任务，这些操作可能发生在订阅取消或丢弃时。上面这个这个信号没有任何清理需求，所以返回nil。

可以看到，我们就这样在信号中封装了一个异步API。现在，我们可以使用这个新的信号了，更新viewDidLoad中我们的代码吧：

    [[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] map:^id(id value) {
        return [self signInButton];
    }] subscribeNext:^(id x) {
        NSLog(@"Sign in result: %@", x);
    }];

上面的代码使用map方法将按钮点击信号转换为登录信号。订阅者简单输出了结果。

运行程序，点击按钮，可以看到以下输出：

	2014-07-31 18:29:27.134 RWReactivePlayground[9749:60b] Sign in result: <UIButton: 0x13651ed40; frame = (192 201; 76 30); opaque = NO; autoresize = RM+BM; layer = <CALayer: 0x178224c00>>

可以看到subscribeNext:块传递了一个正确的信号，但结果不是登录信号。我们用图来展示这个管道操作：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/01/SignalOfSignals.png)

当点击按钮时rac_signalForControlEvents发出了一个next事件。map这一步创建并返回一个登录信号，意味着接下来的管理接收一个RACSignal。这是我们在subscribeNext:中观察到的对象。

上面这个方案有时候称为信号的信号(signal of signals)，换句话说，就是一个外部信号包含一个内部信号。可以在输出信号的subscribeNext:块中订阅内部信号。但这会引起嵌套的麻烦。幸运的是，这是个普遍的问题，而ReactiveCocoa已经提供了解决方案。

## Signal of Signals

这个问题有解决方案是直观的，只需要使用flattenMap来替换map。如下代码所示：

    [[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^RACStream *(id value) {
        return [self signInSignal];
    }] subscribeNext:^(id x) {
        NSLog(@"Sign in result: %@", x);
    }];

这将按钮点击事件映射到一个登录信号，但同时通过将事件从内部信号发送到外部信号，使这个过程变得扁平化。再次运行程序，我们将得到以下的输出

	2014-07-31 18:46:19.535 RWReactivePlayground[9785:60b] Sign in result: 1
	
这回对了。

现在管道处理得到了我们想要的结果，最后我们在subscriptNext中添加登录处理逻辑。使用以下代码：

    [[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^RACStream *(id value) {
        return [self signInSignal];
    }] subscribeNext:^(NSNumber *signedIn) {

        BOOL success = [signedIn boolValue];
        self.signInFailureText.hidden = success;
        if (success)
        {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];

运行程序，我们就可以得到下面的结果了：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/01/ReactivePlaygroundStarter.jpg)

不知道你是否注意到一个细节问题。当点击登录进行验证时，我们应该置灰登录按钮。这样可以阻止用户在验证的过程中再次去点击登录。那么这个逻辑添加在哪呢？改变按钮的可用状态不是个转换、过滤或其它的信号。这就是下一步要讲的。

## 添加附加操作(side-effects)

使用下面的代码替换当前管道：

    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
     doNext:^(id x) {
         self.signInButton.enabled = NO;
         self.signInFailureText.hidden = YES;
     }]
     flattenMap:^RACStream *(id value) {
         return [self signInSignal];
     }]
     subscribeNext:^(NSNumber *signedIn) {
         self.signInButton.enabled = YES;
         BOOL success = [signedIn boolValue];
         self.signInFailureText.hidden = success;
         if (success) {
             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
         }
     }];

我们可以看到在按钮点击事件后添加了doNext:步骤。注意doNext:并不返回一个值，因为它是附加操作。它完成时不改变事件。下图展示了这个过程：

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/01/SideEffects.png)

运行程序看看效果。如何？

注意：在执行异步方法时禁用按钮是个普遍的问题，ReactiveCocoa同样解决了这个问题。**RACCommand**类封装了这个概念，同时有一个enabled信号以允许我们将一个按钮的enabled属性连接到信号。可以试试。

## 小结

ReactiveCocoa的核心是信号，它是一个事件流。使用ReactiveCocoa时，对于同一个问题，可能会有多种不同的方法来解决。ReactiveCocoa的目的就是为了简化我们的代码并更容易理解。如果使用一个清晰的管道，我们可以很容易理解问题的处理过程。在下一部分，我们将会讨论错误事件的处理及完成事件的处理。
