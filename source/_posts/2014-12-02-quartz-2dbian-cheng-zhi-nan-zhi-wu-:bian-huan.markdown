---

layout: post

title: "Quartz 2D编程指南之五：变换"

date: 2014-12-02 22:27:17 +0800

comments: true

categories: iOS

---

Quartz 2D 绘制模型定义了两种独立的坐标空间：用户空间(用于表现文档页)和设备空间(用于表现设备的本地分辨率)。用户坐标空间用浮点数表示坐标，与设备空间的像素分辨率没有关系。当我们需要一个点或者显示文档时， Quartz会将用户空间坐标系统映射到设备空间坐标系统。因此，我们不需要重写应用程序或添加额外的代码来调整应用程序的输出以适应不同的设备。

我们可以通过操作CTM(current transformation matrix)来修改默认的用户空间。在创建图形上下文后，CTM是单位矩阵，我们可以使用 Quartz的变换函数来修改CTM，从而修改用户空间中的绘制操作。

本章内容包括：

1. 变换操作函数概览
2. 如何修改CTM
3. 如何创建一个仿射变换
4. 如何选择两个相同的变换
5. 如何获取user-to-device-space变换

## Quartz变换函数

我们可能使用Quartz内置的变换函数方便的平移、旋转和缩放我们的绘图。只需要短短几行代码，我们便可以按顺序应用变换或结合使用变换。图5-1显示了缩放和旋转一幅图片的效果。我们使用的每个变换操作都更新了CTM。CTM总是用于表示用户空间和设备空间的当前映射关系。这种映射确保了应用程序的输出在任何显示器或打印机上看上去都很棒。

Figure 5-1  Applying scaling and rotation

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/spaces.gif)
 
Quartz 2D API提供了5个函数，以允许我们获取和修改CTM。我们可以旋转、平移、缩放CTM。我们还可以联结一个仿射变换矩阵。

有时我们可以不想操作用户空间，直到我们决定将变换应用到CTM时，Quartz为此允许我们创建应用于此的仿射矩阵。我们可以使用另外一组函数来创建仿射变换，这些变换可以与CTM联结在一起。

我们可以不需要了解矩阵的数学含义而使用这些函数。

## 修改CTM(Current Transformation Matrix)

我们在绘制图像前操作CTM来旋转、缩放或平移page,从而变换我们将要绘制的对象。以变换CTM之前，我们需要保存图形状态，以便绘制后能恢复。我们同样能用仿射矩阵来联结CTM。在本节中，我们将介绍与CTM函数相关的四种操作--平移、旋转、缩放和联结。

假设我们提供了一个可用的图形上下文、一个指向可绘制图像的矩形的指针和一个可用的CGImage对象，则下面一行代码绘制了一个图像。该行代码可以绘制如图5-2所示的图片。在阅读了本节余下的部分后，我们将看到如何将变换应用于图像。

	CGContextDrawImage (myContext, rect, myImage);

Figure 5-2  An image that is not transformed

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/normal_rooster.gif)
 
平移变换根据我们指定的x, y轴的值移动坐标系统的原点。我们通过调用CGContextTranslateCTM函数来修改每个点的x, y坐标值。如图5-3显示了一幅图片沿x轴移动了100个单位，沿y轴移动了50个单位。具体代码如下：

	CGContextTranslateCTM (myContext, 100, 50);

Figure 5-3  A translated image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/translated_rooster.gif)
 
旋转变换根据指定的角度来移动坐标空间。我们调用CGContextRotateCTM函数来指定旋转角度(以弧度为单位)。图5-4显示了图片以原点(左下角)为中心旋转45度，代码所下所示：

	CGContextRotateCTM (myContext, radians(–45.));

由于旋转操作使图片的部分区域置于上下文之外，所以区域外的部分被裁减。我们用弧度来指定旋转角度。如果需要进行旋转操作，下面的代码将会很有用

	#include <math.h>
	static inline double radians (double degrees) {return degrees * M_PI/180;}
	
Figure 5-4  A rotated image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rotated_rooster.gif)

缩放操作根据指定的x, y因子来改变坐标空间的大小，从而放大或缩小图像。x, y因子的大小决定了新的坐标空间是否比原始坐标空间大或者小。另外，通过指定x因子为负数，可以倒转x轴，同样可以指定y因子为负数来倒转y轴。通过调用CGContextScaleCTM函数来指定x, y缩放因子。图5-5显示了指定x因子为0.5，y因子为0.75后的缩放效果。代码如下：

	CGContextScaleCTM (myContext, .5, .75);

Figure 5-5  A scaled image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/scaled_rooster.gif)
 
联合变换将两个矩阵相乘来联接现价变换操作。我们可以联接多个矩阵来得到一个包含所有矩阵累积效果矩阵。通过调用CGContextConcatCTM来联接CTM和仿射矩阵。
另外一种得到累积效果的方式是执行两个或多个变换操作而不恢复图形状态。图5-6显示了先平移后旋转一幅图片的效果，代码如下：

	CGContextTranslateCTM (myContext, w,h);
	CGContextRotateCTM (myContext, radians(-180.));
 
Figure 5-6  An image that is translated and rotated

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/tr_rooster.gif)
 
图5-7显示了平移、缩放和旋转一幅图片，代码如下：

	CGContextTranslateCTM (myContext, w/4, 0);
	CGContextScaleCTM (myContext, .25,  .5);
	CGContextRotateCTM (myContext, radians ( 22.));

Figure 5-7  An image that is translated, scaled, and then rotated

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/tsr_rooster.gif)
 
变换操作的顺序会影响到最终的效果。如果调换顺序，将得到不同的结果。调换上面代码的顺序将得到如图5-8所示的效果，代码如下：

	CGContextRotateCTM (myContext, radians ( 22.));
	CGContextScaleCTM (myContext, .25,  .5);
	CGContextTranslateCTM (myContext, w/4, 0);

Figure 5-8  An image that is rotated, scaled, and then translated

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rst_rooster.gif)
 
## 创建仿射变换

仿射变换操作在矩阵上，而不是在CTM上。我们可以使用这些函数来构造一个之后用于CTM(调用函数CGContextConcatCTM)的矩阵。仿射变换函数使用或者返回一个CGAffineTransform数据对象。我们可以构建简单或复杂的仿射变换。

仿射变换函数能实现与CTM函数相同的操作--平移、旋转、缩放、联合。表5-1列出了仿射变换函数及其用途。注意每种变换都有两个函数。

表5-1 仿射变换函数

![image](http://a3.qpic.cn/psb?/V130i6W71atwfr/hkufClsdxuBLYsVz20Qnbp7zDQIfQE6MOeYCjgzwCVc!/b/dPEupXMnLwAA&bo=mgdqAQAAAAADB9Q!&rf=viewer_4)

Quartz同样提供了一个仿射变换函数(CGAffineTransformInvert)来倒置矩阵。倒置操作通常用于在变换对象中提供点的倒置变换。当我们需要恢复一个被矩阵变换的值时，可以使用倒置操作。将值与倒置矩阵相乘，就可得到原先的值。我们通常不需要倒置操作，因为我们可以通过保存和恢复图形状态来倒置CTM的效果。

在一些情况下，我们可能不需要变换整修空间，而只是一个点或一个大小。我们通过调用CGPointApplyAffineTransform在CGPoint结构上执行变换操作。调用CGSizeApplyAffineTransform在CGSize结构上执行变换操作。调用CGRectApplyAffineTransform在CGRect结构上执行变换操作。CGRectApplyAffineTransform返回一个最小的矩形，该矩形包含了被传递给CGRectApplyAffineTransform的矩形对象的角点。如果矩形上的仿射变换操作只有缩放和平移操作，则返回的矩形与四个变换后的角组成的矩形是一致的。

可以通过调用函数CGAffineTransformMake来创建一个新的仿射变换，但与其它函数不同的是，它需要提供一个矩阵实体。

## 评价仿射变换

我们可以通过调用CGAffineTransformEqualToTransform函数来决定一个仿射变换是否与另一个相同。如果两个变换相同，则返回true；否则返回false。

函数CGAffineTransformIsIdentity用于确认一个变换是否是单位变换。单位变换没有平移、缩放和旋转操作。Quartz常量CGAffineTransformIdentity表示一个单位变换。

## 获取用户空间到设备空间的变换

当使用Quartz 2D时，我们只是在用户空间下工作。Quartz为我们处理用户空间和设备空间的转换。如果我们的应用程序需要获取Quartz转换用户空间和设备空间的仿射变换，我们可以调用函数CGContextGetUserSpaceToDeviceSpaceTransform。

Quartz提供了一系列的函数来转换用户空间和设备空间的几何体。我们会发现这些函数使用赶来比使用CGContextGetUserSpaceToDeviceSpaceTransform函数返回的仿射变换更好用。

1. 点：函数CGContextConvertPointToDeviceSpace和CGContextConvertPointToUserSpace将一个CGPoint数据结构从一个空间变换到另一个空间。
2. 大小：函数CGContextConvertSizeToDeviceSpace和CGContextConvertSizeToUserSpace将一个CGSize数据结构从一个空间变换到另一个空间。
3. 矩形：函数CGContextConvertRectToDeviceSpace和CGContextConvertRectToUserSpace将一个CGPoint数据结构从一个空间变换到另一个空间。
