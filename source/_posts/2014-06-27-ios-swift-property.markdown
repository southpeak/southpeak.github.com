---
layout: post

title: "Swift属性Property"

date: 2014-06-27 20:34:38 +0800

comments: true

categories: iOS Swift

---


Swift的属性与Objective-C中的属性是一样的，不同的是Swift细化了属性的类型，另外除了类之外，结构体和枚举也可以有属性。

Swift中有这么几种属性：

1. 存储属性(Stored properties)：存储实例的常量和变量，与类、结构体、枚举的实例相关
2. 计算属性(Computed properties)：通过某种方式计算出来的属性，只与类、结构体的实例相关，枚举没有计算属性
3. 类型属性(type properties)：与类型自身相关。

另外，我们可以定义属性观察者来监听属性值的改变，以执行一些额外的操作。属性观察者可以添加到自定义的存储属性上，也可以添加到父类继承而来的属性上。

下面我们将详细介绍这些属性

## 存储属性

存储属性是最简单的属性，它作为类或结构体实例的一部分，用于存储常量和变量。


关于存储属性，有以下几点：

1. 我们可以给存储属性提供一个默认值，也可以在初始化方法中对其进行初始化，即使是常量型属性，也可以这样做。
2. 如果创建一个常量结构体实例，我们不能修改该实例的变量型存储属性。这是因为结构体是值类型，当一个值类型的实例标记为常量时，它的所有属性也是常量。由于类是引用类型，所以该条不适用于类类型。
3. 如果我们希望属性在使用到的时候再初始化，则可以使用懒惰存储属性(lazy stored property，使用修饰符@lazy)。懒惰存储属性总是应该定义为变量，因为常量型属性总需要在初始化方法完成之前初始化。
4. 与Objective-C不同的是，Swift中的属性不需要一个与之对应的成员变量，我们不能直接访问属性的后备存储(backing store)。这种方式避免了混淆不同上下文环境下对值的访问，并将属性简化为单一、明确的声明。

###### 代码清单1：

	struct FixedLengthRange {
	    var firstValue:Int      // 变量存储属性
	    let length:Int          // 常量存储属性
	}
	
	var item1 = FixedLengthRange(firstValue: 10, length: 10)
	
	let item2 = FixedLengthRange(firstValue: 10, length: 10)
	//item2.firstValue = 6        // 错误：不能修改常量结构体实例的存储属性



## 计算属性

计算属性并不存储实际的值，而是提供一个getter和一个可选的setter来间接获取和设置其它属性。

关于计算属性，有以下几点：

1. 如果计算属性的setter没有定义一个新值的变量名，则默认为newValue
2. 如果只提供getter，而不提供setter，则该计算属性为只读属性
3. 我们只能声明变量型只读属性，因为它们的值不是固定的
4. 如果计算属性是只读的，则可以不使用get{}

计算属性的实例如代码清单2：


###### 代码清单2：

	struct Point {
	    var x = 0.0, y = 0.0
	}
	
	struct Size {
	    var width = 0.0, height = 0.0
	}
	
	struct Rect {
	    var origin = Point()
	    var size = Size()
	    
	    var center:Point {          // 计算属性
	    get {
	        let centerX = origin.x + (size.width / 2)
	        let centerY = origin.y + (size.height / 2)
	        return Point(x: centerX, y: centerY)
	    }
	    set(newCenter) {            // 若不提供新值变量名，则默认为newValue
	        origin.x = newCenter.x - size.width / 2
	        origin.y = newCenter.y - size.height / 2
	    }
	    }
	    
	    var maxX:Float {        // 只读属性，省略get{}
	        return Float(origin.x) + Float(size.width)
	    }
	}
	
	var square = Rect(origin:Point(x: 0.0, y: 0.0), size:Size(width:100, height:100))
	
	let initialSquareCenter = square.center
	square.center = Point(x: 15.0, y:15.0)
	square.maxX



## 类型属性

类型属性是与类型相关联的，而不是与类型的实例相关联。对于某一类型的所有实例，类型属性都只有一份拷贝。对于值类型，我们可以定义存储类型属性和计算类型属性。对于类，我们只能定义计算类型属性。和实例属性不同的是，我们总是需要给存储类型属性一个默认值。这是因为类型没有初始化方法来初始化类型属性。

类型属性的访问和设置与实例属性一样，不一样的是，类型属性通过类型来获取和设置，而不是类型的实例

###### 代码清单3

	struct AudioChannel {
	    static let threaholdLevel = 10
	    static var maxInputLevelForAllChannels = 0
	    
	    var currentLevel:Int = 0 {
	    didSet{
	        if currentLevel > AudioChannel.threaholdLevel {
	            currentLevel = AudioChannel.threaholdLevel
	        }
	        
	        if currentLevel > AudioChannel.maxInputLevelForAllChannels {
	            AudioChannel.maxInputLevelForAllChannels = currentLevel
	        }
	    }
	    }
	}
	
	var leftChannel = AudioChannel()
	var rightChannel = AudioChannel()
	
	leftChannel.currentLevel = 7
	
	println(leftChannel.currentLevel)       // 7
	println(AudioChannel.maxInputLevelForAllChannels)   // 7
	
	rightChannel.currentLevel = 11
	println(rightChannel.currentLevel)      // 10
	println(AudioChannel.maxInputLevelForAllChannels)   // 10


## 属性观察者

属性观察者用于监听和响应属性值的变化。在每次设置属性值的时候都会调用属性观察者方法，即使新旧值是一样的。我们可以为任何存储属性定义属性观察者，除了懒惰存储属性。我们同样可以在子类中给继承而来的属性添加观察者。

对于计算属性，我们不需要定义属性观察者，因为我们可以在计算属性的setter中直接观察并响应这种值的变化。

我们通过设置以下观察方法来定义观察者

1. willSet：在属性值被存储之前设置。此时新属性值作为一个常量参数被传入。该参数名默认为newValue，我们可以自己定义该参数名
2. didSet：在新属性值被存储后立即调用。与willSet相同，此时传入的是属性的旧值，默认参数名为oldValue。

willSet与didSet只有在属性第一次被设置时才会调用，在初始化时，不会去调用这些监听方法。