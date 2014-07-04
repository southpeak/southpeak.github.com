---
layout: post

title: "Swift协议基础"

date: 2014-07-02 14:09:11 +0800

comments: true

categories: iOS Swift

---

Swift的Protocol(协议)与Objective-C的协议一样，用于定义一系列的特定任务和功能的集合。Protocol自身并不提供这些任务的实现，只是描述实现看起来应该是什么样的。类、结构体或枚举可以实现一个Protocol，并提供Protocol中任务和功能的具体实现。Protocol可以要求这些实现类型有指定的实例属性、实例方法、类型方法、操作符和下标等。

Protocol的语法如下所示:

	protocol SomeProtocol {
	    // 协议定义
	}

类、结构体、枚举可以同时实现多个Protocol，如下所示:

	struct SomeStructure: SomeProtocol, AnotherProcotol {
	    // 协议定义
	}

需要注意的是，子类在实现Protocol时，需要把父类写在前面，后面再跟上Protocol列表。

我们下面介绍Protocol可以定义的一些功能需求

## 属性

Protocol可以要求实现类型提供指定名称和类型的实例属性或类型属性。Protocol不指定属性是存储属性还是计算属性，它只定义属性名和类型。Protocol也可以指定每个属性是只读的还是可读写的。

如果Protocol要求属性是可读写的，那么这个属性不能是常量存储属性或者只读的计算属性；如果Protocol只是要求属性是可读的，则这个属性可以是任何类型的属性，这种情况下我们的实现代码同样可以指定属性为可写的。通常情况下，在Protocol中属性一般定义为变量，具体语法如下所示：

	protocol SomeProtocol {
	    var mustBeSettable: Int { get set }
	    var doesNotNeedToBeSettable: Int { get }
	    class var someTypeProperty: Int { get set }
	}

如果是类型属性，我们需要在前面加上class，即便是结构体可枚举来实现这个Protocol，也是一样。如上面代码所示。

代码清单1是一个详细的例子，定义了一个协议FullyNamed，其中声明了fullName属性，而在其两个个体的实现类型中，将fullName实现为不同的属性类型

###### 代码清单1

	protocol FullyNamed {
	    var fullName: String { get }
	}
	
	struct Person: FullyNamed {
	    var fullName: String        // 可读写存储属性
	}
	
	class Sharship: FullyNamed {
	    
	    var prefix: String?
	    var name: String?
	    
	    var fullName: String {      // 只读的计算属性
	    return (prefix ? prefix! + " " : "") + name
	    }
	}


## 方法

在Protocol中声明方法与在类中定义类似，只是没有实现体。另外声明方法是使用可变参数也是可以的，唯一的不同是在Protocol的方法声明中不能指定默认值。

与属性声明一样，如果是类型方法，需要加上class前缀。方法的声明及实现类型的实现如代码清单2所示：

	protocol RandomNumberGenerator {
	    func random() -> Double
	}
	
	
	class LinearCongruentialGenerator: RandomNumberGenerator {
	    var lastRandom = 42.0
	    let m = 139968.0
	    let a = 3877.0
	    let c = 29573.0
	    func random() -> Double {
	        lastRandom = ((lastRandom * a + c) % m)
	        return lastRandom / m
	    }
	}
	let generator = LinearCongruentialGenerator()
	
	generator.random()      // 0.37464991998171

另外，如果我们需要在方法中修改实例，则在方法前添加mutating关键字，与结构体中方法的定义是一样的。需要注意的是，只有在结构体和枚举的实现中才需要加mutating，类的实现是不需要的。


## 该Protocol做为类型

Protocol可以作为一种类型在代码中使用。因为它是一种类型，所以在很多情况下都可以使用，包括

1. 作为函数、方法、初始化方法的参数或返回值
2. 作为常量、变量或属性的类型
3. 作为数组、字典或其它容器的元素

基于此，Protocol也可以放入集合中，如数组、字典等。


下面是将Protocol作为类型的例子

	class Dice {
	    let sides: Int
	    let generator: RandomNumberGenerator
	    init (sides: Int, generator: RandomNumberGenerator) {
	        self.sides = sides
	        self.generator = generator
	    }
	    
	    func roll() -> Int {
	        return Int(generator.random() * Double(sides)) + 1
	    }
	}
	
	// 具体使用
	var dice = Dice(sides: 6, generator: LinearCongruentialGenerator())



## 代理(Delegation)
Swift与Objective-C的代理一样，允许将一个类或结构体的一些处理放到另外一个类型中(代理类)。Swift中代理模式的实现就是通过定义一个Protocol来封装代理方法，然后具体的实现类来实现这些代理方法。代理可以用于响应特定的行为，或者从外部资源获取数据，而不需要知道这些资源的类型。

如下是一个实现UITableView代理的简单例子
	
	class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	    
	    var tableView: UITableView?
	                            
	    override func viewDidLoad() {
	        super.viewDidLoad()
	        // Do any additional setup after loading the view, typically from a nib.
	        
	        tableView = UITableView(frame: self.view.bounds, style: UITableViewStyle.Plain)
	        tableView!.delegate = self
	        tableView!.dataSource = self
	    }
	
		// 实现UITableViewDataSource
		
	    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
	        return 20
	    }
	    
	    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
	        return nil
	    }
	}


## 在扩展中实现Protocol

如果我们想让某个已存在的类型(我们没有源码的情况下)实现某个Protocol，则可以借助扩展。当类型的扩展实现了Protocol时，该类会自动实现Protocol(听着有点绕口)。但如果类型已经实现了Protocol的所有必须的方法(类型未采用Protocol)，这种情况下，若想让类型采用Protocol，则可以使用一个空的扩展来声明类型采用Protocol。如下代码所示：

	protocol TextRepresentable {
	    func asText() -> String
	}
	
	struct Hamster {
	    var name: String
	    func asText() -> String {
	        return "A Hamster"
	    }
	}
	
	extension Hamster : TextRepresentable {}


## Protocol继承
一个Protocol可以继承自一个或多个Protocol，并在自己的实现中添加更多的功能需求。Protocol继承的语法与类型继承是一样的，其语法如下所示：

	protocol InheritingProtocol : SomeProtocol, AnotherProtocol {
	    
	}

在上面的例子中，所有实现子InheritingProtocol的类型都必须实现InheritingProtocol、SomeProtocol、AnotherProtocol三者中所有的必要功能。

## Protocol组合

让一个类型同时实现多个Protocol是很有用的。这种情况下，我们可以使用Protocol组合来将多个Protocol组合成一个整体。其语法如下所示：

	protocol<SomeProtocol, AnotherProtocol>

我们可以将多个Protocol放在<>中，在使用时，我们将其当成一个整体来处理，这种组合的实际含义是：任何同时实现<>所有Protocol的类型。让我们看看下面的例子：

	protocol P1 {
	    var variable1 : String { get }
	}
	
	protocol P2 {
	    var variable2 : Int { get }
	}
	
	struct MyStruct : P1, P2 {
	    var variable1: String
	    var variable2: Int
	}
	
	func funcWithProtocols(protocols: protocol<P1, P2>) {
	    
	}
	
	let st = MyStruct(variable1: "v", variable2: 2)
	
	funcWithProtocols(st)


需要注意的是，Protocol组合并没有定义一个新的永久的Protocol类型，它仅仅是定义了一个临时的本地Protocol，该Protocol包含了组合中所有的功能。


## 检查Protocol的一致性

我们可以使用is操作符来检查Protocol的一致性，用as操作符来作Protocol转换。

1. 如果is操作符返回true，则一个实例实现了protocol，否则没有
2. as?操作符返回protocol类型的可选值，如果实例没有实现protocol，则返回nil
3. as操作符强制作类型转换，如果实例没有实现protocol，则引发一个错误

需要注意的是，只有当protocol使用@objc属性标记时，才可以检查其一致性。@objc属性表明protocol应该暴露给Objective-C代码。但即使我们的代码不与Objective-C交互，如果需要对protocol进行一致性检测，也需要使用这个属性。另外@objc标明的protocol只能被类实现，而不能被结构体或枚举实现。

我们举个具体的例子：

	@objc protocol HasArea {
	    var area: Double { get }
	}
	
	class Circle: HasArea {
	    let pi = 3.1415927
	    var radius: Double
	    var area: Double { return pi * radius * radius }
	    init(radius: Double) { self.radius = radius }
	}
	
	class Country: HasArea {
	    var area: Double
	    init(area: Double) { self.area = area }
	}
	
	class Animal {
	    var legs: Int
	    init(legs: Int) { self.legs = legs }
	}
	
	let objects: AnyObject[] = [
	    Circle(radius: 2.0),
	    Country(area: 243_610),
	    Animal(legs: 4)
	]
	
	for object : AnyObject in objects {
	    if let objectWithArea = object as? HasArea {
	        println("Area is \(objectWithArea.area)")
	    } else {
	        println("Something that doesn't have an area")
	    }
	}
	
	// Area is 12.5663708
	// Area is 243610.0
	// Something that doesn't have an area


## 可选需求

与Objective-C类似，Swift的Protocol可以定义一些可选的需求，这些需求在实现类型中可以选择性的实现。我们使用@optional修饰符来定义这些需求。

一个可选的需求可以通过可选链来实现，这个可选链可以满足当某个类型没有实现所采用的Protocol的可选需求。这种调用的基本语法如下：

	someOptionalMethod?(someArgument)

另外，可选的方法如果有返回值，总是返回一个可选值，以满足可能未被实现的需求。

