---
layout: post
title: "Foundation: NSKeyValueObserving(KVO)"
date: 2015-04-23 17:31:16 +0800
comments: true
categories: Foundation iOS
---

`NSKeyValueObserving`非正式协议定义了一种机制，它允许对象去监听其它对象的某个属性的修改。

我们可以监听一个对象的属性，包括简单属性，一对一的关系，和一对多的关系。一对多关系的监听者会被告知集合变更的类型，以及哪些对象参与了变化。

`NSObject`提供了一个`NSKeyValueObserving`协议的默认实现，它为所有对象提供了一种自动发送修改通知的能力。我们可以通过禁用自动发送通知并使用这个协议提供的方法来手动实现通知的发送，以便更精确地去处理通知。

在这里，我们将通过具体的实例来看看`NSKeyValueObserving`提供了哪些方法。我们的基础代码如代码清单1所示：

**代码清单1：示例基础代码**

``` objective-c
#pragma mark - PersonObject

@interface PersonObject : NSObject
@end

@implementation PersonObject

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    NSLog(@"keyPath = %@, change = %@, context = %s", keyPath, change, (char *)context);
}

@end

#pragma mark - BankObject

@interface BankObject : NSObject

@property (nonatomic, assign) int accountBalance;
@property (nonatomic, copy) NSString *bankCodeEn;
@property (nonatomic, strong) NSMutableArray *departments;

@end
```

在这段代码中，我们定义一两个类，一个是`PersonObject`类，这个类的对象在下面将充当观察者的角色。另一个是`BankObject`类，我们在这个类中定义了三个属性，作为被监听的属性。由于`NSObject`类已经实现了`NSKeyValueObserving`协议，所以我们不需要再显式地去让我们的类实现这个协议。

接下来，我们便来看看`NSKeyValueObserving`协议有哪些功能。

## 注册/移除观察者

要让一个对象监听另一个对象的属性的变化，首先需要将这个对象注册为相关属性的观察者，我们可以使用以下方法来实现：

``` objective-c
- (void)addObserver:(NSObject *)anObserver
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context
```

这个方法带有四个参数，描述如下：

1. `anObserver`：观察者对象，这个对象必须实现`observeValueForKeyPath:ofObject:change:context:`方法，以响应属性的修改通知。
2. `keyPath`：被监听的属性。这个值不能为nil。
3. `options`：监听选项，这个值可以是`NSKeyValueObservingOptions`选项的组合。关于监听选项，我们会在下面介绍。
4. `context`：任意的额外数据，我们可以将这些数据作为上下文数据，它会传递给观察者对象的`observeValueForKeyPath:ofObject:change:context:`方法。这个参数的意义在于用于区分同一对象监听同一属性(从属于同一对象)的多个不同的监听。我们将在下面看到。

监听选项是由枚举`NSKeyValueObservingOptions`定义的，是传入`-addObserver:forKeyPath:options:context:`方法中以确定哪些值将被传到-`observeValueForKeyPath:ofObject:change:context:`方法中。这个枚举的定义如下：

``` objective-c
enum {
	// 提供属性的新值
   	NSKeyValueObservingOptionNew = 0x01,
   	
   	// 提供属性的旧值
   	NSKeyValueObservingOptionOld = 0x02,
   	
   	// 如果指定，则在添加观察者的时候立即发送一个通知给观察者，
   	// 并且是在注册观察者方法返回之前
   	NSKeyValueObservingOptionInitial = 0x04,
   	
   	// 如果指定，则在每次修改属性时，会在修改通知被发送之前预先发送一条通知给观察者，
   	// 这与-willChangeValueForKey:被触发的时间是相对应的。
   	// 这样，在每次修改属性时，实际上是会发送两条通知。
   	NSKeyValueObservingOptionPrior = 0x08 
};
typedef NSUInteger NSKeyValueObservingOptions;
```

需要注意的是，当设定了`NSKeyValueObservingOptionPrior`选项时，第一条通知不会包含`NSKeyValueChangeNewKey`。当观察者自身的KVO需要为自己的某个属性调用`-willChange...`方法，而这个属性的值又依赖于被观察对象的属性时，我们可以使用这个选项。

另外，在添加观察者时还有两点需要注意的是：

1. 调用这个方法时，两个对象(即观察者对象及属性所属的对象)都不会被`retain`。
2. 可以多次调用这个方法，将同一个对象注册为同一属性的观察者(所有参数可以完全相同)。这时，即便在所有参数一致的情况下，新注册的观察者并不会替换原来观察者，而是会并存。这样，当属性被修改时，两次监听都会响应。

对于第2点，我们在代码清单2中来验证一下：

**代码清单2：验证多次使用相同参数来添加观察者的实际效果**

``` objective-c
PersonObject *personInstance = [[PersonObject alloc] init];
BankObject *bankInstance = [[BankObject alloc] init];

[bankInstance addObserver:personInstance forKeyPath:@"accountBalance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
[bankInstance addObserver:personInstance forKeyPath:@"accountBalance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];

[bankInstance addObserver:personInstance forKeyPath:@"accountBalance" options:NSKeyValueObservingOptionNew context:"person instance"];
[bankInstance addObserver:personInstance forKeyPath:@"accountBalance" options:NSKeyValueObservingOptionNew context:"person instance 2"];

bankInstance.accountBalance = 10;
```

(注，以上代码为在MRC环境下调用，确保`personInstance`和`bankInstance`不会被释放。)

这段代码的输出如下所示：

``` objective-c
keyPath = accountBalance, change = {
    kind = 1;
    new = 10;
}, context = person instance 2
keyPath = accountBalance, change = {
    kind = 1;
    new = 10;
}, context = person instance
keyPath = accountBalance, change = {
    kind = 1;
    new = 10;
    old = 0;
}, context = (null)
keyPath = accountBalance, change = {
    kind = 1;
    new = 10;
    old = 0;
}, context = (null)
```

可以看到KVO为每次注册都调用了一次监听处理操作。所以多次调用同样的注册操作会产生多个观察者。另外，多个观察者之间的`observeValueForKeyPath:ofObject:change:context:`方法调用顺序是按照先进后出的顺序来的(所有的监听信息都是放在一个数组中的，我们将在下面了解到)。

一个良好的实践是在观察者不再需要监听属性变化时，必须调用`removeObserver:forKeyPath:`或`removeObserver:forKeyPath:context:`方法来移除观察者，这两个方法的声明如下：

``` objective-c
- (void)removeObserver:(NSObject *)anObserver
            forKeyPath:(NSString *)keyPath
            
- (void)removeObserver:(NSObject *)observer
            forKeyPath:(NSString *)keyPath
               context:(void *)context
```

这两个方法会根据传入的参数(主要是`keyPath`和`context`)来移除观察者。如果`observer`没有监听`keyPath`属性，则调用这两个方法会抛出异常。大家可以试一下，程序会果断的崩溃。并报类似于以下的错误：

``` objective-c
*** Terminating app due to uncaught exception 'NSRangeException', reason: 'Cannot remove an observer <PersonObject 0x7ff541534e20> for the key path "accountBalance" from <BankObject 0x7ff541528430> because it is not registered as an observer.'
```

所以，我们必须确保先注册了观察者，才能调用移除方法。

那如果我们忘记调用移除观察者方法，会怎么样呢？我们来制造一个场景，看看会是什么结果。还是使用上面的代码，只不过这次我们在ARC下来测试：

**代码清单3：未移除观察者的影响**

``` objective-c
- (void)testKVO {
    
    PersonObject *personInstance = [[PersonObject alloc] init];
    BankObject *bankInstance = [[BankObject alloc] init];
    
    [bankInstance addObserver:personInstance forKeyPath:@"accountBalance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    bankInstance.accountBalance = 20;
}
```

其输出结果如下所示：

``` objective-c
keyPath = accountBalance, change = {
    kind = 1;
    new = 20;
    old = 0;
}, context = (null)
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'An instance 0x7fc88047e7e0 of class BankObject was deallocated while key value observers were still registered with it. Current observation info: <NSKeyValueObservationInfo 0x7fc880770fa0> (
<NSKeyValueObservance 0x7fc880771850: Observer: 0x7fc8804737a0, Key path: accountBalance, Options: <New: YES, Old: YES, Prior: NO> Context: 0x0, Property: 0x7fc88076edd0>
)'
......
```

程序在调用一次KVO后，很爽快地崩溃了。给我们的解释是`bankInstance`被释放了，但KVO中仍然还有关于它的注册信息。实际上，我们上面说过，在添加观察者的时候，观察者对象与被观察属性所属的对象都不会被`retain`，然而在这些对象被释放后，相关的监听信息却还存在，KVO做的处理是直接让程序崩溃。

## 处理属性修改通知

当被监听的属性修改时，KVO会发出一个通知以告知所有监听这个属性的观察者对象。而观察者对象必须实现

`-observeValueForKeyPath:ofObject:change:context:`方法，来对属性修改通知做相应的处理。这个方法的声明如下：

``` objective-c
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
```

这个方法有四个参数，描述如下：

1. `keyPath`：即被观察的属性，与参数`object`相关。
2. `object`：`keyPath`所属的对象。
3. `change`：这是一个字典，它包含了属性被修改的一些信息。这个字典中包含的值会根据我们在添加观察者时设置的`options`参数的不同而有所不同。
4. `context`：这个值即是添加观察者时提供的上下文信息。

在我们的示例中，这个方法的实现是打印一些基本的信息。如代码清单1所示。

对于第三个参数，我们通常称之为**变化字典(Change Dictionary)**，它记录了被监听属性的变化情况。我们可以通过以下key来获取我们想要的信息：

``` objective-c
// 属性变化的类型，是一个NSNumber对象，包含NSKeyValueChange枚举相关的值
NSString *const NSKeyValueChangeKindKey;

// 属性的新值。当NSKeyValueChangeKindKey是 NSKeyValueChangeSetting，
// 且添加观察的方法设置了NSKeyValueObservingOptionNew时，我们能获取到属性的新值。
// 如果NSKeyValueChangeKindKey是NSKeyValueChangeInsertion或者NSKeyValueChangeReplacement，
// 且指定了NSKeyValueObservingOptionNew时，则我们能获取到一个NSArray对象，包含被插入的对象或
// 用于替换其它对象的对象。
NSString *const NSKeyValueChangeNewKey;

// 属性的旧值。当NSKeyValueChangeKindKey是 NSKeyValueChangeSetting，
// 且添加观察的方法设置了NSKeyValueObservingOptionOld时，我们能获取到属性的旧值。
// 如果NSKeyValueChangeKindKey是NSKeyValueChangeRemoval或者NSKeyValueChangeReplacement，
// 且指定了NSKeyValueObservingOptionOld时，则我们能获取到一个NSArray对象，包含被移除的对象或
// 被替换的对象。
NSString *const NSKeyValueChangeOldKey;

// 如果NSKeyValueChangeKindKey的值是NSKeyValueChangeInsertion、NSKeyValueChangeRemoval
// 或者NSKeyValueChangeReplacement，则这个key对应的值是一个NSIndexSet对象，
// 包含了被插入、移除或替换的对象的索引
NSString *const NSKeyValueChangeIndexesKey;

// 当指定了NSKeyValueObservingOptionPrior选项时，在属性被修改的通知发送前，
// 会先发送一条通知给观察者。我们可以使用NSKeyValueChangeNotificationIsPriorKey
// 来获取到通知是否是预先发送的，如果是，获取到的值总是@(YES)
NSString *const NSKeyValueChangeNotificationIsPriorKey;
```

其中，`NSKeyValueChangeKindKey`的值取自于`NSKeyValueChange`，它的值是由以下枚举定义的：

``` objective-c
enum {

	// 设置一个新值。被监听的属性可以是一个对象，也可以是一对一关系的属性或一对多关系的属性。
   	NSKeyValueChangeSetting = 1,
   	
   	// 表示一个对象被插入到一对多关系的属性。
   	NSKeyValueChangeInsertion = 2,
   	
   	// 表示一个对象被从一对多关系的属性中移除。
   	NSKeyValueChangeRemoval = 3,
   	
   	// 表示一个对象在一对多的关系的属性中被替换
   	NSKeyValueChangeReplacement = 4
};
typedef NSUInteger NSKeyValueChange;
```



## 通知观察者属性的变化

通知观察者的方式有自动与手动两种方式。

默认情况下是自动发送通知，在这种模式下，当我们修改属性的值时，KVO会自动调用以下两个方法：

``` objective-c
- (void)willChangeValueForKey:(NSString *)key
- (void)didChangeValueForKey:(NSString *)key
```

这两个方法的任务是告诉接收者给定的属性将要或已经被修改。需要注意的是不应该在子类中去重写这两个方法。

但如果我们希望自己控制通知发送的一些细节，则可以启用手动控制模式。手动控制通知提供了对KVO更精确控制，它可以控制通知如何以及何时被发送给观察者。采用这种方式可以减少不必要的通知，或者可以将多个修改组合到一个修改中。

实现手动通知的类必须重写`NSObject`中对`automaticallyNotifiesObserversForKey:`方法的实现。这个方法是在`NSKeyValueObserving`协议中声明的，其声明如下：

``` objective-c
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
```

这个方法返回一个布尔值(默认是返回YES)，以标识参数key指定的属性是否支持自动KVO。如果我们希望手动去发送通知，则针对指定的属性返回NO。

假设我们希望`PersonObject`对象去监听`BankObject`对象的`bankCodeEn`属性，并希望执行手动通知，则可以如下处理：

**代码清单4：关闭属性的自动通知发送**

``` objective-c
@implementation BankObject

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    
    BOOL automatic = YES;
    if ([key isEqualToString:@"bankCodeEn"]) {
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:key];
    }
    
    return automatic;
}

@end
```

这样我们便可以手动去发送属性修改通知了。需要注意的是，对于对象中其它没有处理的属性，我们需要调用`[super automaticallyNotifiesObserversForKey:key]`，以避免无意中修改了父类的属性的处理方式。

现在我们已经通过`+automaticallyNotifiesObserversForKey:`方法设置了对象中哪些属性需要手动处理。接下来就是实际操作了。为了实现手动发送通知，我们需要在修改属性值前调用`willChangeValueForKey:`，然后在修改属性值之后调用`didChangeValueForKey:`方法。继续上面的示例，我们需要对`bankCodeEn`属性做如下处理：

**代码清单5：手动控制通知发送**

``` objective-c
@implementation BankObject

- (void)setBankCodeEn:(NSString *)bankCodeEn {
    
    [self willChangeValueForKey:@"bankCodeEn"];
    _bankCodeEn = bankCodeEn;
    [self didChangeValueForKey:@"bankCodeEn"];
}

@end
```

如果我们希望只有当`bankCodeEn`实际被修改时发送通知，以尽量减少不必要的通知，则可以如下实现：

**代码清单6：在发送通知前测试值是否修改**

``` objective-c
- (void)setBankCodeEn:(NSString *)bankCodeEn {
    
    if (bankCodeEn != _bankCodeEn) {
        [self willChangeValueForKey:@"bankCodeEn"];
        _bankCodeEn = bankCodeEn;
        [self didChangeValueForKey:@"bankCodeEn"];
    }
}
```

我们来测试一下上面这段代码的实际效果：

**代码清单7：测试避免属性未实际修改下不发送通知**

``` objective-c
PersonObject    *personInstance = [[PersonObject alloc] init];
BankObject      *bankInstance = [[BankObject alloc] init];

[bankInstance addObserver:personInstance forKeyPath:@"bankCodeEn" options:NSKeyValueObservingOptionNew context:NULL];

NSString *bankCodeEn = @"CCB";
bankInstance.bankCodeEn = bankCodeEn;
bankInstance.bankCodeEn = bankCodeEn;
```

这段代码的输出结果如下所示：

``` objective-c
keyPath = bankCodeEn, change = {
    kind = 1;
    new = CCB;
}, context = (null)
```

我们可以看到只输出了一次，而不是两次。

如果我们在`setter`方法之外改变了实例变量(如`_bankCodeEn`)，且希望这种修改被观察者监听到，则需要像在`setter`方法里面做一样的处理。这也涉及到我们通常会遇到的一个问题，在类的内部，对于一个属性值，何时用属性(`self.bankCodeEn`)访问而何时用实例变量(`_bankCodeEn`)访问。一般的建议是，在获取属性值时，可以用实例变量，在设置属性值时，尽量用`setter`方法，以保证属性的`KVO`特性。当然，性能也是一个考量，在设置值时，使用实例变量比使用属性设置值的性能高不少。

另外，对于一对多关系的属性，如果想手动处理通知，则可以使用以下几个方法：

``` objective-c
// 有序的一对多关系
- (void)willChange:(NSKeyValueChange)change valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key
- (void)didChange:(NSKeyValueChange)change valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key
  
// 无序的一对多关系
- (void)willChangeValueForKey:(NSString *)key withSetMutation:(NSKeyValueSetMutationKind)mutationKind usingObjects:(NSSet *)objects
- (void)didChangeValueForKey:(NSString *)key withSetMutation:(NSKeyValueSetMutationKind)mutationKind usingObjects:(NSSet *)objects
```

同样，在子类中也不应该去重写这几个方法。

## 计算属性(注册依赖键)

有时候，我们的监听的某个属性可能会依赖于其它多个属性的变化(类似于`swift`，可以称之为计算属性)，不管所依赖的哪个属性发生了变化，都会导致计算属性的变化。对于这种一对一(`To-one`)的关系，我们需要做两步操作，首先是确定计算属性与所依赖属性的关系。如我们在`BankObject`类中定义一个`accountForBank`属性，其`get`方法定义如下：

**代码清单8：计算属性**

``` objective-c
@implementation BankObject

- (NSString *)accountForBank {
    
    return [NSString stringWithFormat:@"account for %@ is %d", self.bankCodeEn, self.accountBalance];
}

@end
```

定义了这种依赖关系后，我们就需要以某种方式告诉`KVO`，当我们的被依赖属性修改时，会发送`accountForBank`属性被修改的通知。此时，我们需要重写`NSKeyValueObserving`协议的`keyPathsForValuesAffectingValueForKey:`方法，该方法声明如下：

``` objective-c
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
```

这个方法返回的是一个集合对象，包含了那些影响key指定的属性依赖的属性所对应的字符串。所以对于`accountForBank`属性，该方法的实现如下：

**代码清单9：accountForBank属性的keyPathsForValuesAffectingValueForKey方法的实现**

``` objective-c
@implementation BankObject

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"accountForBank"]) {
        
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"accountBalance", @"bankCodeEn"]];
    }
    
    return keyPaths;
}

@end
```

我们来再来看看监听`accountForBank`属性是什么效果：

**代码清单10：监听accountForBank属性**

``` objective-c
PersonObject    *personInstance = [[PersonObject alloc] init];
BankObject      *bankInstance = [[BankObject alloc] init];

[bankInstance addObserver:personInstance forKeyPath:@"accountForBank" options:NSKeyValueObservingOptionNew context:NULL];

bankInstance.accountBalance = 10;
bankInstance.bankCodeEn = @"CCB";
```

其输出结果为：

``` objective-c
keyPath = accountForBank, change = {
    kind = 1;
    new = "account for (null) is 10";
}, context = (null)
keyPath = accountForBank, change = {
    kind = 1;
    new = "account for CCB is 10";
}, context = (null)
```

可以看到，不管是`accountBalance`还是`bankCodeEn`被修改了，都会发送`accountForBank`属性被修改的通知。

需要注意的就是当我们重写`+keyPathsForValuesAffectingValueForKey:`时，需要去调用`super`的对应方法，并返回一个包含父类中可能会对`key`指定属性产生影响的属性集合。

另外，我们还可以实现一个命名为`keyPathsForValuesAffecting\<Key\>`的类方法来达到同样的目的，其中`<Key>`是我们计算属性的名称。所以对于`accountForBank`属性，还可以如下实现：

``` objective-c
+ (NSSet *)keyPathsForValuesAffectingAccountForBank {
    
    return [NSSet setWithObjects:@"accountBalance", @"bankCodeEn", nil];
}
```

两种方法的实现效果是一样的。不过更建议使用后面一种方法，这种方法让依赖关系更加清晰明了。

## 集合属性的监听

`keyPathsForValuesAffectingValueForKey:`只支持一对一的关系，而不支持一对多的关系，即不支持对集合的处理。

对于集合的`KVO`，我们需要了解的一点是，`KVO`旨在观察关系(`relationship`)而不是集合。对于不可变集合属性，我们更多的是把它当成一个整体来监听，而无法去监听集合中的某个元素的变化；对于可变集合属性，实际上也是当成一个整体，去监听它整体的变化，如添加、删除和替换元素。

在KVC中，我们可以使用**集合代理对象(collection proxy object)**来处理集合相关的操作。我们以数组为例，在我们的`BankObject`类中有一个`departments`数组属性，如果我们希望通过集合代理对象来负责响应`departments`所有的方法，则需要实现以下方法：

``` objective-c
-countOf<Key>

// 以下两者二选一
-objectIn<Key>AtIndex:
-<key>AtIndexes:

// 可选（增强性能）
-get<Key>:range:
```

因此，我们的实现以下几个方法：

**代码清单11：集合代码对象的实现**

``` objective-c
@implementation BankObject

#pragma mark - 集合代理对象

- (NSUInteger)countOfDepartments {

    return [_departments count];
}

- (id)objectInDepartmentsAtIndex:(NSUInteger)index {

    return [_departments objectAtIndex:index];
}

@end
```

实现以上方法之后，对于不可变数组，当我们调用`[bankInstance valueForKey:@"departments"]`的时候，便会返回一个由以上方法来代理所有调用方法的~对象。这个代理数组对象支持所有正常的`NSArray`调用。换句话说，调用者并不知道返回的是一个真正的`NSArray`，还是一个代理的数组。

另外，对于可变数组的代理对象，我们需要实现以下几个方法：

``` objective-c
// 至少实现一个插入方法和一个删除方法
-insertObject:in<Key>AtIndex:
-removeObjectFrom<Key>AtIndex:
-insert<Key>:atIndexes:
-remove<Key>AtIndexes:

// 可选（增强性能）以下方法二选一
-replaceObjectIn<Key>AtIndex:withObject:
-replace<Key>AtIndexes:with<Key>:
```

这些方法分别对应插入、删除和替换，有批量操作的，也有只改变一个对象的方法。可以根据实际需要来实现。

另外，对于可变集合，我们通常不使用`valueForKey:`来获取代理对象，而是使用以下方法：

``` objective-c
- (NSMutableArray *)mutableArrayValueForKey:(NSString *)key;
```

通过这个方法，我们便可以将可变数组与强大的`KVO`结合在一起。`KVO`机制能在集合改变的时候把详细的变化放进`change`字典中。

我们先来看看下面的代码：

**代码清单12：使用真正的数组对象监听可变数组属性**

``` objective-c
BankObject *bankInstance = [[BankObject alloc] init];

PersonObject    *personInstance = [[PersonObject alloc] init];
[bankInstance addObserver:personInstance forKeyPath:@"departments" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];

bankInstance.departments = [[NSMutableArray alloc] init];

[bankInstance.departments addObject:@"departments"];
```

其输出为：

``` objective-c
keyPath = departments, change = {
    kind = 1;
    new =     (
    );
    old =     (
    );
}, context = (null)
```

可以看到通过这种方法，我们获取的是真正的数组，只在`departments`属性整体被修改时，才会触发`KVO`，而在添加元素时，并没有触发`KVO`。

现在我们通过代理集合对象来看看：

**代码清单13：使用代理集合对象监听可变数组属性**

``` objective-c
BankObject *bankInstance = [[BankObject alloc] init];

PersonObject    *personInstance = [[PersonObject alloc] init];
[bankInstance addObserver:personInstance forKeyPath:@"departments" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];

bankInstance.departments = [[NSMutableArray alloc] init];

NSMutableArray *departments = [bankInstance mutableArrayValueForKey:@"departments"];
[departments insertObject:@"departments 0" atIndex:0];
```

其输出是：

``` objective-c
keyPath = departments, change = {
    kind = 1;
    new =     (
    );
    old =     (
    );
}, context = (null)
keyPath = departments, change = {
    indexes = "<NSIndexSet: 0x7fcd18673150>[number of indexes: 1 (in 1 ranges), indexes: (0)]";
    kind = 2;
    new =     (
        "departments 0"
    );
}, context = (null)
```

可以看到，在往数组中添加对象时，也触发了KVO，并将改变的详细信息也写进了`change`字典。在第二个消息中，`kind`的值为2，即表示这是一次插入操作。同样，可变数组的删除，替换操作也是一样的。

集合(`Set`)也有一套对应的方法来实现集合代理对象，包括无序集合与有序集合；而字典则没有，对于字典属性的监听，还是只能作为一个整理来处理。

如果我们想到手动控制集合属性消息的发送，则可以使用上面提到的几个方法，即：

``` objective-c
-willChange:valuesAtIndexes:forKey:
-didChange:valuesAtIndexes:forKey:

或

-willChangeValueForKey:withSetMutation:usingObjects:
-didChangeValueForKey:withSetMutation:usingObjects:
```

不过得先保证把自动通知关闭，否则每次改变`KVO`都会被发送两次。

## 监听信息

如果我们想获取一个对象上有哪些观察者正在监听其属性的修改，则可以查看对象的`observationInfo`属性，其声明如下：

``` objective-c
@property void *observationInfo
```

可以看到它是一个`void`指针，指向一个包含所有观察者的一个标识信息对象，这些信息包含了每个监听的观察者，注册时设定的选项等等。我们还是用示例来看看。

**代码清单14：observationInfo的使用**

``` objective-c
PersonObject    *personInstance = [[PersonObject alloc] init];
BankObject      *bankInstance = [[BankObject alloc] init];

[bankInstance addObserver:personInstance forKeyPath:@"bankCodeEn" options:NSKeyValueObservingOptionNew context:NULL];
[bankInstance addObserver:personInstance forKeyPath:@"accountBalance" options:NSKeyValueObservingOptionOld context:NULL];

NSLog(@"%p", personInstance);
NSLog(@"%p", bankInstance);

id info = bankInstance.observationInfo;
NSLog(@"%@", [info description]);
```

其输出结果如下：

``` objective-c
personInstance = 0x7fdc2369e5e0
bankInstance = 0x7fdc2369d8f0
<NSKeyValueObservationInfo 0x7fdc236a19d0> (
<NSKeyValueObservance 0x7fdc236a17a0: Observer: 0x7fdc2369e5e0, Key path: bankCodeEn, Options: <New: YES, Old: NO, Prior: NO> Context: 0x0, Property: 0x7fdc236a15c0>
<NSKeyValueObservance 0x7fdc236a1960: Observer: 0x7fdc2369e5e0, Key path: accountBalance, Options: <New: NO, Old: YES, Prior: NO> Context: 0x0, Property: 0x7fdc236a1880>
)
```

我们可以看到`observationInfo`指针实际上是指向一个`NSKeyValueObservationInfo`对象，它包含了指定对象上的所有的监听信息。而每条监听信息而是封装在一个`NSKeyValueObservance`对象中，从上面可以看到，这个对象中包含消息的观察者、被监听的属性、添加观察者时所设置的一些选项、上下文信息等。

`NSKeyValueObservationInfo`类及`NSKeyValueObservance`类都是私有类，我们无法在官方文档中找到这两个类的实现。不过从一些对系统库`dump`出来的头文件，我们可以对这两个类有一些初步的了解。[这里](https://github.com/a1anyip/iOS-SDK-4.3-Framework-Header-Dump/tree/master/Frameworks/Foundation.framework)有一个对`iOS SKD 4.3`的`Foundation.framework`的`dump`头文件，可以找到这两个类的头文件，其中`NSKeyValueObservationInfo`的头文件信息如下所示：

``` objective-c
#import <XXUnknownSuperclass.h> // Unknown library

@class NSArray, NSHashTable;

__attribute__((visibility("hidden")))
@interface NSKeyValueObservationInfo : XXUnknownSuperclass {
@private
	int _retainCountMinusOne;
	NSArray* _observances;
	unsigned _cachedHash;
	BOOL _cachedIsShareable;
	NSHashTable* _observables;
}
-(id)_initWithObservances:(id*)observances count:(unsigned)count;
-(id)retain;
-(oneway void)release;
-(unsigned)retainCount;
-(void)dealloc;
-(unsigned)hash;
-(BOOL)isEqual:(id)equal;
-(id)description;
@end
```

可以看到其中有一个数组来存储`NSKeyValueObservance`对象。

`NSKeyValueObservance`类的头文件信息如下：

``` objective-c
#import "Foundation-Structs.h"
#import <XXUnknownSuperclass.h> // Unknown library

@class NSPointerArray, NSKeyValueProperty, NSObject;

__attribute__((visibility("hidden")))
@interface NSKeyValueObservance : XXUnknownSuperclass {
@private
	int _retainCountMinusOne;
	NSObject* _observer;
	NSKeyValueProperty* _property;
	unsigned _options;
	void* _context;
	NSObject* _originalObservable;
	unsigned _cachedUnrotatedHashComponent;
	BOOL _cachedIsShareable;
	NSPointerArray* _observationInfos;
	auto_weak_callback_block _observerWentAwayCallback;
}
-(id)_initWithObserver:(id)observer property:(id)property options:(unsigned)options context:(void*)context originalObservable:(id)observable;
-(id)retain;
-(oneway void)release;
-(unsigned)retainCount;
-(void)dealloc;
-(unsigned)hash;
-(BOOL)isEqual:(id)equal;
-(id)description;
-(void)observeValueForKeyPath:(id)keyPath ofObject:(id)object change:(id)change context:(void*)context;
@end
```

可以看到其中包含了一个监听的基本要素。在此不再做深入分析(没有源代码，深入不下去了啊)。

我们再回到`observationInfo`属性本身来。在文档中，对这个属性的描述有这样一段话：

``` objective-c
The default implementation of this method retrieves the information from a global
dictionary keyed by the receiver’s pointers.
```

即这个方法的默认实现是以对象的指针作为key，从一个全局的字典中获取信息。由此，我们可以理解为，KVO的信息是存储在一个全局字典中，而不是存储在对象本身。这类似于`Notification`，所有关于通知的信息都是放在`NSNotificationCenter`中。

不过，为了提高效率，我们可以重写`observationInfo`属性的set和get方法，以将这个不透明的数据指针存储到一个实例变量中。但是，在重写时，我们不应该尝试去向这些数据发送一个`Objective-C`消息，包括`retain`和`release`。

## KVO的实现机制

【本来这一小节是想放在另一篇总结中来写的，但后来觉得还是放在这里比较合适，所以就此添加上】

了解了`NSKeyValueObserving`所提供的功能后，我们再来看看KVO的实现机制，以便更深入地的理解KVO。

KVO据我所查还没有开源(若哪位大大有查到源代码，还烦请告知)，所以我们无法从源代码的层面来分析它的实现。不过[Mike Ash](https://www.mikeash.com/pyblog/friday-qa-2009-01-23.html)的博文(译文见参考文献4)为我们解开了一些谜团。

基本的思路是：`Objective-C`依托于强大的`runtime`机制来实现KVO。当我们第一次观察某个对象的属性时，`runtime`会创建一个新的继承自这个对象的`class`的`subclass`。在这个新的`subclass`中，它会重写所有被观察的`key`的`setter`，然后将`object`的`isa`指针指向新创建的`class`(这个指针告诉`Objective-C`运行时某个`object`到底是什么类型的)。所以`object`神奇地变成了新的子类的实例。

嗯，让我们通过代码来看看实际的实现：

**代码清单15：探究KVO的实现机制**

``` objective-c
// 辅助方法
static NSArray *ClassMethodNames(Class c) {

    NSMutableArray *array = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(c, &methodCount);
    unsigned int i;
    for (i = 0; i < methodCount; i++) {
        [array addObject:NSStringFromSelector(method_getName(methodList[i]))];
    }
    
    free(methodList);
    
    return array;
}

static void PrintDescription(NSString *name, id obj) {

    struct objc_object *objcet = (__bridge struct objc_object *)obj;
    
    Class cls = objcet->isa;
    
    NSString *str = [NSString stringWithFormat:@"%@: %@\n\tNSObject class %s\n\tlibobjc class %s : super class %s\n\timplements methods <%@>",
                     name,
                     obj,
                     class_getName([obj class]),
                     class_getName(cls),
                     class_getName(class_getSuperclass(cls)),
                     [ClassMethodNames(cls) componentsJoinedByString:@", "]];
    printf("%s\n", [str UTF8String]);
}

// 测试代码
BankObject *bankInstance1 = [[BankObject alloc] init];
BankObject *bankInstance2 = [[BankObject alloc] init];

PersonObject *personInstance = [[PersonObject alloc] init];

[bankInstance2 addObserver:personInstance forKeyPath:@"accountBalance" options:NSKeyValueObservingOptionNew context:NULL];

PrintDescription(@"bankInstance1", bankInstance1);
PrintDescription(@"bankInstance2", bankInstance2);

printf("Using libobjc functions, normal setAccountBalance: is %p, overridden setAccountBalance: is %p", method_getImplementation(class_getInstanceMethod(object_getClass(bankInstance2), @selector(setAccountBalance:))),
       method_getImplementation(class_getInstanceMethod(object_getClass(bankInstance1), @selector(setAccountBalance:))));
```

这段代码的输出如下：

``` objective-c
bankInstance1: <BankObject: 0x7f9e8ae3cf60>
	NSObject class BankObject
	libobjc class BankObject : super class NSObject
	implements methods <accountBalance, setAccountBalance:, bankCodeEn, setBankCodeEn:, departments, setDepartments:>
	
bankInstance2: <BankObject: 0x7f9e8ae3cfc0>
	NSObject class BankObject
	libobjc class NSKVONotifying_BankObject : super class BankObject
	implements methods <setAccountBalance:, class, dealloc, _isKVOA>
	
Using libobjc functions, normal setAccountBalance: is 0x1013cec17, overridden setAccountBalance: is 0x10129fe50
```

从输出中可以看到，`bankInstance2`监听`accountBalance`属性后，其实际上所属的类已经不是`BankObject`了，而是继承自`BankObject`的`NSKVONotifying_BankObject`类。同时，`NSKVONotifying_BankObject`类重写了`setAccountBalance`方法，这个方法将实现如何通知观察者们的操作。当改变`accountBalance`属性时，就会调用被重写的`setAccountBalance`方法，并通过这个方法来发送通知。

另外我们也可以看到`bankInstance2`对象的打印`[bankInstance2 class]`时，返回的仍然是`BankObject`。这是苹果故意而为之，他们不希望这个机制暴露在外面。所以除了重写相应的`setter`，所以动态生成的`NSKVONotifying_BankObject`类还重写了`class`方法，让它返回原先的类。

## 小结

KVO作为`Objective-C`中两个对象间通信机制中的一种，提供了一种非常强大的机制。在经典的MVC架构中，控制器需要确保视图与模型的同步，当`model`对象改变时，视图应该随之改变以反映模型的变化；当用户和控制器交互的时候，模型也应该做出相应的改变。而KVO便为我们提供了这样一种同步机制：我们让控制器去监听一个`model`对象属性的改变，并根据这种改变来更新我们的视图。所有，有效地使用KVO，对我们应用的开发意义重大。

别话：对KVO的总结感觉还是意犹未尽，总感觉缺少点什么，特别是在对集合这一块的处理。还请大家多多提供指点。

## 参考

1. [NSKeyValueObserving Protocol Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Protocols/NSKeyValueObserving_Protocol/#//apple_ref/occ/instm/NSObject/observationInfo)
2. [Key-Value Observing Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html)
3. [iOS-SDK-4.3-Framework-Header-Dump](https://github.com/a1anyip/iOS-SDK-4.3-Framework-Header-Dump)
4. [KVC 和 KVO](http://objccn.io/issue-7-3/)
5. [Understanding Key-Value Observing and Coding](http://www.appcoda.com/understanding-key-value-observing-coding/)
6. [KVO的内部实现](http://www.cocoachina.com/ios/20140107/7667.html)