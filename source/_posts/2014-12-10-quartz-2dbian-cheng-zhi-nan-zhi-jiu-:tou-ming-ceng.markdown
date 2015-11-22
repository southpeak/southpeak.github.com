---

layout: post

title: "Quartz 2D编程指南之九：透明层"

date: 2014-12-10 09:13:04 +0800

comments: true

categories: iOS

---

透明层(TransparencyLayers)通过组合两个或多个对象来生成一个组合图形。组合图形被看成是单一对象。当需要在一组对象上使用特效时，透明层非常有用，如图9-1所示的给三个圆使用阴影的效果。

Figure 9-1  Three circles as a composite in a transparency layer

![image](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/trans_layer1.gif)

如果没有使用透明层来渲染图9-1中的三个圆，对它们使用阴影的效果将是如图9-2所示：

Figure 9-2  Three circles painted as separate entities

![image](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/trans_layer2.gif) 

## 透明层的工作方式

Quartz的透明层类似于许多流行的图形应用中的层。层是独立的实体。Quartz维护为每个上下文维护一个透明层栈，并且透明层是可以嵌套的。但由于层通常是栈的一部分，所以我们不能单独操作它们。

我们通过调用函数CGContextBeginTransparencyLayer来开始一个透明层，该函数需要两个参数：图形上下文与CFDictionary对象。字典中包含我们所提供的指定层额外信息的选项，但由于Quartz 2D API中没有使用字典，所以我们传递一个NULL。在调用这个函数后，图形状态参数保持不变，除了alpha值[默认设置为1]、阴影[默认关闭]、混合模式[默认设置为normal]、及其它影响最终组合的参数。

在开始透明层操作后，我们可以绘制任何想显示在层上的对象。指定上下文中的绘制操作将被当成一个组合对象绘制到一个透明背景上。这个背景被当作一个独立于图形上下文的目标缓存。

当绘制完成后，我们调用函数CGContextEndTransparencyLayer。Quartz将结合对象放入上下文，并使用上下文的全局alpha值、阴影状态及裁减区域作用于组合对象。

## 在透明层中进行绘制

在透明层中绘制需要三步：

1. 调用函数CGContextBeginTransparencyLayer
2. 在透明层中绘制需要组合的对象
3. 调用函数CGContextEndTransparencyLayer

图9-3显示了在透明层中绘制三个矩形，其中将这三个矩形当成一个整体来渲染阴影。

Figure 9-3  Three rectangles painted to a transparency layer

![image](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/trans_code.gif)

代码清单9-1显示了如何利用透明层生成图9-3所示的矩形。

Listing 9-1  Painting to a transparency layer

	void MyDrawTransparencyLayer (CGContext myContext, float wd,float ht)
	{
	    CGSize myShadowOffset = CGSizeMake (10, -20);
	    CGContextSetShadow (myContext, myShadowOffset, 10);   
	    CGContextBeginTransparencyLayer (myContext, NULL);
	    
	    // Your drawing code here
	    CGContextSetRGBFillColor (myContext, 0, 1, 0, 1);
	    CGContextFillRect (myContext, CGRectMake (wd/3+ 50,ht/2 ,wd/4,ht/4));
	    CGContextSetRGBFillColor (myContext, 0, 0, 1, 1);
	    CGContextFillRect (myContext, CGRectMake (wd/3-50,ht/2-100,wd/4,ht/4));
	    CGContextSetRGBFillColor (myContext, 1, 0, 0, 1);
	    CGContextFillRect (myContext, CGRectMake (wd/3,ht/2-50,wd/4,ht/4));
	    CGContextEndTransparencyLayer (myContext);
	}