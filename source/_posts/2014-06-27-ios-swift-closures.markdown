---
layout: post

title: "Swift闭包一：闭包基础概念"

date: 2014-06-27 16:25:56 +0800

comments: true

categories: Swift iOS

---

熟悉Objective-C的朋友一定知道Objective-C中的block，iOS在6.0后开始大量使用block。而在swift中，也提供了类似的功能：Closures(在Java等语言中翻译为“闭包”)。

Closures是自包含的功能块。它可以捕获和存储其所在上下文的常量和变量的引用。全局函数和嵌套函数其实都是闭包。闭包有以下三种形式：

1. 全局函数：有函数名，但不能获取任何外部值
2. 嵌套函数：有函数名，同时可以从其上下文中捕获值
3. 闭包表达式：以一种轻量级的语法定义的未命名闭包，可以从其上下文中捕获值

swift对闭包表达式作了一些优化处理，主要包括：

1. 从上下方中推断出参数和返回值
2. 可以从单一表达式闭包中隐式返回
3. 速记(Shorthand)参数名
4. 尾随闭包语法

下面会对这几点分别说明

## 闭包表达式

闭包表达式提供了一种更加简洁、专注的方式来实现内嵌函数的功能。闭包表达式的通用格式如下

	{(parameters) -> return type in
	    statement   
	}

闭包的参数可以是常量、变量、inout、可变参数列表、元组，但是不能提供默认值。返回值可以是通用类型，也可以是元组。闭包实现体位于in关键字后面，该关键字是闭包参数和返回值的声明和实现体的分界。

###### 代码清单1: 使用sort函数对数组进行排序

	let names = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]
	
	// 方法1：使用普通函数(或内嵌函数)提供排序功能
	func backwards(s1:String, s2:String) -> Bool {
	    return s1 > s2
	}
	
	var reversed = sort(names, backwards)
	
	// 方法2：使用闭包表达式提供排序功能
	reversed = sort(names, {
	        (s1:String, s2:String) -> Bool in
	            return s1 > s2
	    })
	    
	// 方法3：类型推断,省略闭包表达式的参数及返回类型
	reversed = sort(names, { s1, s2 in return s1 > s2})
	
	// 方法4：单一表达式：省略return关键字
	reversed = sort(names, { s1, s2 in s1 > s2 })
	
	// 方法5：速记参数名
	reversed = sort(names, { $0 > $1 })
	
	// 方法6：操作符函数
	reversed = sort(names, >)

swift标准库提供了sort用来对数据进行排序，它包含两个参数：

1. 待排序的已知类型的数组
2. 排序函数(闭包)：带有两个类型相同的参数，并返回Bool值来告知第一个参数是显示排在第二个参数之前还是之后。

代码清单1提供了几种方式来实现sort的排序函数

1. 方法1：使用普通函数(嵌套函数)，这种方法略显示复杂，且代码不够紧凑
2. 方法2：内联闭包表达式，参数和返回值都位于大括号内，而不是外部
3. 方法3：借助于swift强大的类型推断功能，我们甚至可以省略参数和返回值的类型。这样返回箭头->和返回类型都可以省略。在传递闭包给函数时，总是可以推断出参数类型和返回值，所以，我们很少需要明确写出内联闭包的完整格式。
4. 方法4：如果闭包体只有一行代码，则可以省略retrun关键字，让闭包隐式返回单一表达式的值。
5. 方法5：速记(Shorthand)参数名：swift为内联闭包提供了速记参数名，可以通过$0, $1, $2等参数名来索引闭包的参数。如果使用这种参数名，则可以直接省略参数列表，而参数的个数和类型可以自动推断出来。in关键字也可以省略
6. 方法6：更极端的情况是，swift的字符串类型定义了>操作符，该操作符可以看作是带有两个参数的函数，并返回一个Bool值。而这正好符合sort函数的需求，我们可以只是简单的传入一个>，swift可以自动推断出我们想使用的实现。


## 尾随闭包(Trailing Closures)
如果将闭包作为函数的最后一个参数，且闭包的实现体很长，则调用函数时可以使用尾随闭包。尾随闭包位于参数列表括号的后面。其格式如下：

	someFunctionThatTakesAClosure() {
		// 尾随闭包实现    
	}

因此sort函数同样可以如下实现

###### 代码清单2: 使用尾随闭包实现sort函数

	// 方法7：尾随闭包
	reversed = sort(names) { $0 > $1 }


另外，如果函数只有一个闭包参数，同时将闭包参数实现为尾随闭包，则在调用函数时可以省略参数列表的()，如代码清单3所示：

###### 代码清单3：函数只有一个闭包参数，同时将闭包参数实现为尾随闭包

	let strings = numbers.map {
	    (var name) -> String in
	    var output = ""
	    while number > 0 {
	        output = digitNames[number % 10]! + output
	        number /= 10
	    }
	    
	    return number
	}


## 获取上下文的值

和Objective-C的block一样，闭包可以获取定义它的上下文中常量或变量的值，同时可以在闭包体内引用和修改这些常量或变量的值，即使定义这些常量或变量的域已经销毁。

由于内嵌函数也是闭包，因此我们以内嵌函数为例，看看闭包如何获取上下文的常量和变量

###### 代码清单4：获取上下文值

	func makeIncrementor(amount:Int) -> () -> Int {
	    var runningTotal = 0
	    func incrementor() -> Int {
	        runningTotal += amount
	        return runningTotal
	    }
	    
	    return incrementor
	}

在代码清单4中，内嵌函数incriminator从上下文获取了两个值runningTotal和amount，其中amount是函数makeIncrementor的参数，runningTotal是函数内部定义的变量。由于incrementor没有修改amount，所以它实际上存储了amount的一份拷贝。而runningTotal在incremetor中被修改了，因此increminator存储了runningTotal的引用，这样确保runningTotal一直有效。

swift决定捕获的值哪些需要拷贝值，而哪些只拷贝引用。在runningTotal不再使用时，swift负责释放其内存。

###### 代码清单5：makeIncrementor使用

	let incrementByTen = makeIncrementor(amount:10)
	
	incrementByTen()    // returns a value of 10
	incrementByTen()    // returns a value of 20
	incrementByTen()    // returns a value of 30
	
	// 定义另一个incrementor，则它有自己独立的runningTotal
	let incrementBySeven = makeIncrementor(amount:7)
	
	incrementBySeven()  // returns a value of 7
	incrementBySeven()  // returns a value of 14
	incrementBySeven()  // returns a value of 21

## 引用类型

在代码清单5中，虽然incrementByTen和incrementBySeven定义为常量，但是闭包仍然可以增加runningTotal的值。这是因为函数和闭包都是引用类型。

当定义一个函数(闭包)常量或变量时，实际上定义的是一个指向函数(闭包)的引用。这意味着如果指定一个闭包给两个不同的常量或变量，则这两个常量和变量将引用同一个函数(闭包)

###### 代码清单6：引用函数(闭包)
	
	let incrementByTen = makeIncrementor(amount:10)
	incrementByTen()    // returns a value of 10
	incrementByTen()    // returns a value of 20
	incrementByTen()    // returns a value of 30
	
	let alsoIncrementByTen = incrementByTen
	alsoIncrementByTen()  // returns a value of 40


这样，就引出另一个问题：循环引用。