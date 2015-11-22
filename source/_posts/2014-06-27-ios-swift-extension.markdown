---
layout: post

title: "Swift扩展(Extension)基础"

date: 2014-06-27 20:54:59 +0800

comments: true

categories: iOS Swift

---

扩展(Extension)用于为已存在的类、结构体或枚举添加新的功能。它类似于Objecitve-C中的分类，不同的是Swift的扩展没有名字

Swift的扩展可以做以下事情：



   * 添加计算属性和静态计算属性

   * 定义实例方法和类型方法

   * 提供新的初始化方法

   * 定义下标操作符

   * 定义并使用新的嵌套类型

   * 让已存在类型实现一个协议



在定义类型的扩展后，访扩展中的功能可以用于类型所有已存在的实例中，即使这些实例在扩展之前定义。

我们使用关键字extension来声明一个扩展，一个扩展可以让类型实现一个或多个协议，如代码清单1所示：

###### 代码清单1：

	extension SomeType: SomeProtocol, AnotherProtocol {
	    // implementation of protocol requirement goes here
	}


下面我们分别介绍如何去扩展一个已有类型的各种功能

## 计算属性

扩展可以添加实例计算属性和类型计算属性。如代码清单2所示：

###### 代码清单2：

	extension Double {
	    var km: Double {return self * 1_000.0}
	    var m: Double { return self }
	    var cm: Double { return self / 100.0 }
	    var mm: Double { return self / 1_000.0 }
	    var ft: Double { return self / 3.28084 }
	}
	
	let onInch = 25.4.mm        // 0.0254
	let threeFeet = 3.ft        // 0.914399970739201


上例扩展了Double，并定义了一些实例计算属性。我们可以将其用于Double的实例，也可以用于Double类型的字面值。

需要注意的是，扩展可以添加新的计算属性，但不能添加存储属性，也不能给已存在的属性添加观察者

## 初始化方法

扩展可以为已存在类型添加新的初始化方法。这可以让我们扩展某一类型以接受我们自定义的类型作为它的初始化方法，或者为现有类型提供额外的初始化方法。

扩展可以为类添加新的便捷初始化方法，但不能添加命名初始化方法(designated initializers)和析构方法，这两者必须由类型的原始实现来提供。

代码清单3定义了Rect类型，并通过扩展为其定义了一个新的初始化方法

###### 代码清单3

	struct Size {
	    var width = 0.0, height = 0.0
	}
	
	struct Point {
	    var x = 0.0, y = 0.0
	}
	
	struct Rect {
	    var origin = Point()
	    var size = Size()
	}
	
	let defaultRect = Rect()
	let memeberwiseRect = Rect(origin: Point(x: 1.0, y: 2.0), size: Size(width: 5.0, height: 10.0))
	
	extension Rect {
	    init (center: Point, size: Size) {
	        let originX = center.x - (size.width / 2)
	        let originY = center.y - size.height / 2
	        self.init(origin: Point(x: originX, y: originY), size:size)
	    }
	}
	
	let centerRect = Rect(center: Point(x: 20.0, y: 3.0), size: Size(width: 10.0, height: 40.0))


需要注意的是，如果我们提供新的初始化方法，仍然需要确保在初始化方法结束前初始化实例的所有常量和变量。

另外，如果我们扩展的类型的所有存储属性都有默认值，而没有定义初始化方法时，我们可以在扩展的初始化方法中调用默认的初始化方法和


## 方法

扩展可以为已存在类型添加新的实例方法和类型方法。对于结构体和枚举类型而言，如果扩展的方法需要修改self或者它的属性的话，需要将实例方法标记为mutating(与结构体和枚举的原始实现相同)。

###### 代码清单4：演示了扩展方法的定义

	extension Int {
	    func repetitions(task: () -> ()) {
	        for i in  0..self {
	            task()
	        }
	    }
	    
	    mutating func square() {        // mutating
	        self = self * self
	    }
	}
	
	var someInt = 3
	someInt.square()


## 下标

扩展可以为已存在类型添加新的下标。例如我们想为Int类型添加一个下标操作，指定下标为n时，返回数字从右侧起第n个数字，即


   * 123456789[0] = 9

   * 123456789[1] = 8

   * …


代码清单5给出了相应的实现

###### 代码清单5

	extension Int {
	    subscript(digitIndex: Int) -> Int {
	        var decimalBase = 1
	            for _ in 1...digitIndex {
	                decimalBase * 10
	            }
	            return (self / decimalBase) % 10
	    }
	}
	
	8738793219[0]   // 9
	8738793219[1]   // 1
	8738793219[2]   // 2
	8738793219[8]   // 7


## 嵌套类型

扩展可以为已存在类型添加新的嵌套类型，如代码清单6所示

###### 代码清单6：

	extension Character {
	    enum Kind {
	        case Vowel, Consonant, Other
	    }
	    
	    var kind:Kind {
	    switch String(self).lowercaseString {
	        case "a", "e", "i", "o", "u":
	            return .Vowel
	        case "b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n",
	             "p", "q", "r", "s", "t", "v", "w", "x", "y", "z":
	            return .Consonant
	        default:
	            return .Other
	    }
	    }
	}

上面为Character类型添加了一个嵌套枚举，以表示字符的类型。定义之后，嵌套类型就可以用于Character的值了。

