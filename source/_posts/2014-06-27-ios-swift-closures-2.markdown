---
layout: post

title: "Swift闭包二：循环引用"

date: 2014-06-27 19:10:38 +0800

comments: true

categories: iOS Swift

---


我们在[闭包的基础概念](http://southpeak.github.io/blog/2014/06/27/ios-swift-closures/)中讲到闭包是引用类型的，因此，与Objective-C的block一样，可能导致循环引用的问题。

## 问题的产生


当我们给一个类指定一个闭包属性时，这个类的实例便包含了闭包的一个引用。如果在这个闭包中，又引用了类实例本身，这是闭包便创建了一个指向类实例的强引用，这种情况下，又产生了循环引用。

如代码清单1所示：HTMLElement类定义了一个闭包属性asHTML。在这个闭包中引用了self，即闭包捕获了self，这就意味着闭包维护了一个指向HTMLElement实例的强引用。这样就在两者间创建了一个强引用循环。


###### 代码清单1：闭包循环引用

	class HTMLElement {
	    
	    let name:String
	    let text:String?
	    
	    @lazy var asHTML:() -> String = {
	        if let text = self.text {
	            return "<\(self.name)]]>\(self.text)</\(self.name)>"
	        } else {
	            return "<\(self.name) />"
	        }
	    }
	    
	    init(name:String, text:String? = nil) {
	        self.name = name
	        self.text = text
	    }
	    
	    deinit {
	        println("\(name) is being deinitialized")
	    }
	}



## 解决方案


我们可以通过“捕获列表”来解决这种循环引用问题。“捕获列表”定义了在闭包内部捕获的引用类型的使用规则。与两个类之间的强引用循环一样，我们声明每一个捕获引用为weak或者unowned引用。选择weak或者unowned依赖于两者之间的关系。


一个“捕获列表项”是一个weak(unowned)—类实例引用对。它们放在[]中，项与项之间使用“,”号隔开。

当闭包和捕获实例总是相互引用，且两者同时释放时，我们将“捕获引用”设置为unowned。如果“捕获引用”可能在某个点被设置成nil，则将其设置为weak。weak引用通常都是optional类型，当引用的实例被释放时，被设置成nil。

在代码清单1中，我们可以用unowned来处理这种循环引用问题。如代码清单2所示：

###### 代码清单2：unowned引用

	class HTMLElement {
	    
	    let name:String
	    let text:String?
	    
	    @lazy var asHTML:() -> String = {
	        [unowned self] in
	        if let text = self.text {
	            return "<\(self.name)]]>\(self.text)</\(self.name)>"
	        } else {
	            return "<\(self.name) />"
	        }
	    }
	    
	    init(name:String, text:String? = nil) {
	        self.name = name
	        self.text = text
	    }
	    
	    deinit {
	        println("\(name) is being deinitialized")
	    }
	}


在这种情况下，闭包维护了HTMLElement实例的一个unowned引用，而不再是一个强引用。

注：虽然在闭包中多次引用了self，但闭包只会维护HTMLElement实例的一个引用