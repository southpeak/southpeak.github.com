---

layout: post

title: "Quartz 2D编程指南之三：路径(Path)"

date: 2014-11-16 21:44:15 +0800

comments: true

categories: iOS

---

**路径**定义了一个或多个形状，或是子路径。一个子路径可由直线，曲线，或者同时由两者构成。它可以是开放的，也可以是闭合的。一个子路径可以是简单的形状，如线、圆、矩形、星形；也可以是复杂的形状，如山脉的轮廓或者是涂鸦。图3-1显示了一些我们可以创建的路径。左上角的直线可以是虚线；直线也可以是实线。上边中间的路径是由多条曲线组成的开放路径。右上角的同心圆填充了颜色，但没有描边。左下角的加利福尼亚州是闭合路径，由许多曲线和直线构成，且对路径进行填充和描边。两个星形阐明了填充路径的两种方式，我们将在本章详细描述。

Figure 3-1  Quartz supports path-based drawing

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/path_vector_examples.gif)

在本章中，我们将学习如何构建路径，如何对路径进行填充和描边，及影响路径表现形式的参数。

## 创建及绘制路径

路径创建及路径绘制是两个独立的工作。首先我们创建路径。当我们需要渲染路径时，我们需要使用Quartz来绘制它。正如图3-1中所示，我们可以选择对路径进行描边，填充路径，或同时进行这两种操作。我们同样可以将其它对象绘制到路径所表示的范围内，即对对象进行裁减。

图3-2绘制了一个路径，该路径包含两个子路径。左边的子路径是一个矩形，右边的子路径是由直线和曲线组成的抽象形状。两个子路径都进行了填充及描边。

Figure 3-2  A path that contains two shapes, or subpaths

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/subpaths.gif)
 
图3-3显示了多条独立绘制的路径。每个路径饮食随机生成的曲线，一些进行填充，另一些进行了描边。这些路径都包含在一个圆形裁减区域内。

Figure 3-3  A clipping area constrains drawing

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/circle_clipping.gif)
 
## 构建块(Building Block)

子路径是由直线、弧和曲线构成的。Quartz同样也提供了简便的函数用于添加矩形或椭圆等形状。点也是路径最基本的构建块，因为点定义了形状的起始点与终止点。

### 点

点由x, y坐标值定义，用于在用户空间指定 一个位置。我们可以调用函数CGContextMoveToPoint来为新的子路径指定起始点。Quartz跟踪当前点，用于记录路径构建过程中最新的位置。例如，如果调用函数CGContextMoveToPoint并设置位置为(10, 10)，即将当前点移动到位置(10, 10)。如果在水平位置绘制50个单位长度的直线，则直线的终点为(60, 10)，该点变成当前点。直线、弧和曲线总是从当前点开始绘制。

通常我们通过传递(x, y)值给Quartz函数来指定一个点。一些函数需要我们传递一个CGPoint数据结构，该结构包含两个浮点值。

### 直线

直线由两个端点定义。起始点通常是当前点，所以创建直线时，我们只需要指定终止点。我们使用函数CGContextAddLineToPoint来添加一条直线到子路径中。

我们可以调用CGContextAddLines函数添加一系列相关的直线到子路径中。我们传递一个点数组给这个函数。第一个点必须是第一条直线的起始点；剩下的点是端点。Quartz从第一个点开始绘制一个新子路径，然后每两个相邻点连接成一条线段。

### 弧

弧是圆弧段。Quartz提供了两个函数来创建弧。函数CGContextAddArc从圆中来创建一个曲线段。我们指定一个圆心，半径和放射角(以弧度为单位)。放射角为2 PI时，创建的是一个圆。图3-4显示了多个独立的路径。每个路径饮食一个自动生成的圆；一些是填充的，另一些是描边的。

Figure 3-4  Multiple paths; each path contains a randomly generated circle

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/circles.gif)
 
函数CGContextAddArcToPoint用于为矩形创建内切弧的场景。Quartz使用我们提供的端点创建两条正切线。同样我们需要提供圆的半径。弧心是两条半径的交叉点，每条半径都与相应的正切线垂直。弧的两个端点是正切线的正切点，如图3-5所示。红色的部分是实际绘制的部分。

Figure 3-5  Defining an arc with two tangent lines and a radius

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rounded_corner.gif)
 
如果当前路径已经包含了一个子路径，Quartz将追加一条从当前点到弧的起始点的直线段。如果当前路径为空，Quartz将创建一个新的子路径，该子路径从弧的起始点开始，而不添加初始的直线段。

### 曲线

二次与三次Bezier曲线是代数曲线，可以指定任意的曲线形状。曲线上的点通过一个应用于起始、终点及一个或多个控制点的多项式计算得出。这种方式定义的形状是向量图的基础。这个公式比将位数组更容易存储，并且曲线可以在任何分辨下重新创建。

图3-6显示了一些路径的曲线。每条路径包含一条随机生成的曲线；一些是填充的，另一些是描边的。

Figure 3-6  Multiple paths; each path contains a randomly generated curve

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/bezier_paths.gif)
 
我们使用函数CGContextAddCurveToPoint将Bezier曲线连接到当前点，并传递控制点和端点作为参数，如图3-7所示。两个控制点的位置决定了曲线的形状。如果两个控制点都在两个端点上面，则曲线向上凸起。如果两个控制点都在两个端点下面，则曲线向下凹。如果第二个控制点比第一个控制点离得当前点近，则曲线自交叉，创建了一个回路。
 
Figure 3-7  A cubic Bézier curve uses two control points

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/cubic_bezier_curve.gif)
 
我们也可以调用函数CGContextAddQuadCurveToPoint来创建Bezier，并传递端点及一个控制点，如图3-8所示。控制点决定了曲线弯曲的方向。由于只使用一个控制点，所以无法创建出如三次Bezier曲线一样多的曲线。例如我们无法创建出交叉的曲线。

Figure 3-8  A quadratic Bézier curve uses one control point

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/quadratic_bezier_curve.gif)
 
### 闭合路径

我们可以调用函数CGContextClosePath来闭合曲线。该函数用一条直接来连接当前点与起始点，以使路径闭合。起始与终点重合的直线、弧和曲线并不自动闭合路径，我们必须调用CGContextClosePath来闭合路径。

Quartz的一些函数将路径的子路径看成是闭合的。这些函数显示地添加一条直线来闭合 子路径，如同调用了CGContextClosePath函数。

在闭合一条子路径后，如果程序再添加直线、弧或曲线到路径，Quartz将在闭合的子路径的起点开始创建一个子路径。

### 椭圆

椭圆是一种特殊的圆。椭圆是通过定义两个焦点，在平面内所有与这两个焦点的距离之和相等的点所构成的图形。图3-9显示了一些独立的路径。每个路径都包含一个随机生成的椭圆；一些进行了填充，另一边进行了描边。

Figure 3-9  Multiple paths; each path contains a randomly generated ellipse

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/ellipses.gif) 
 
我们可以调用CGContextAddEllipseInRect函数来添加一个椭圆到当前路径。我们提供一个矩形来定义一个椭圆。Quartz利用一系列的Bezier曲线来模拟椭圆。椭圆的中心就是矩形的中心。如果矩形的宽与高相等，则椭圆变成了圆，且圆的半径为矩形宽度的一半。如果矩形的宽与高不相等，则定义了椭圆的长轴与短轴。

添加到路径中的椭圆开始于一个move-to操作，结束于一个close-subpath操作，所有的移动方向都是顺时针。

### 矩形
我们可以调用CGContextAddRect来添加一个矩形到当前路径中，并提供一个CGRect结构体(包含矩形的原点及大小)作为参数。

添加到路径的矩形开始于一个move-to操作，结束于一个close-subpath操作，所有的移动方向都是顺时针。

我们也可能调用CGContextAddRects函数来添加一系列的矩形到当前路径，并传递一个CGRect结构体的数组。图3-10显示了一些独立的路径。每个路径包含一个随机生成的矩形；一些进行了填充，另一边进行了描边。
 
Figure 3-10  Multiple paths; each path contains a randomly generated rectangle

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rectangles.gif)

## 创建路径

当我们需要在一个图形上下文中构建一个路径时，我们需要调用CGContextBeginPath来标记Quartz。然后，我们调用函数CGContextMovePoint来设置每一个图形或子路径的起始点。在构建起始点后，我们可以添加直线、弧、曲线。记住如下规则：

1. 在开始绘制路径前，调用函数CGContextBeginPath；
2. 直线、弧、曲线开始于当前点。空路径没有当前点；我们必须调用CGContextMoveToPoint来设置第一个子路径的起始点，或者调用一个便利函数来隐式地完成该任务。
3. 如果要闭合当前子路径，调用函数CGContextClosePath。随后路径将开始一个新的子路径，即使我们不显示设置一个新的起始点。
4. 当绘制弧时，Quartz将在当前点与弧的起始点间绘制一条直线。
5. 添加椭圆和矩形的Quartz程序将在路径中添加新的闭合子路径。
6. 我们必须调用绘制函数来填充或者描边一条路径，因为创建路径时并不会绘制路径。

在绘制路径后，将清空图形上下文。我们也许想保留路径，特别是在绘制复杂场景时，我们需要反复使用。基于此，Quartz提供了两个数据类型来创建可复用路径—CGPathRef和CGMutablePathRef。我们可以调用函数CGPathCreateMutable来创建可变的CGPath对象，并可向该对象添加直线、弧、曲线和矩形。Quartz提供了一个类似于操作图形上下文的CGPath的函数集合。这些路径函数操作CGPath对象，而不是图形上下文。这些函数包括：

1. CGPathCreateMutable，取代CGContextBeginPath
2. CGPathMoveToPoint，取代CGContextMoveToPoint
3. CGPathAddLineToPoint，取代CGContexAddLineToPoint
4. CGPathAddCurveToPoint，取代CGContexAddCurveToPoint
5. CGPathAddEllipseInRect，取代CGContexAddEllipseInRect
6. CGPathAddArc，取代CGContexAddArc
7. CGPathAddRect，取代CGContexAddRect
8. CGPathCloseSubpath，取代CGContexClosePath

如果想要添加一个路径到图形上下文，可以调用CGContextAddPath。路径将保留在图形上下文中，直到Quartz绘制它。我们可以调用CGContextAddPath再次添加路径。

## 绘制路径

我们可以绘制填充或描边的路径。描边(Stroke)是绘制路径的边框。填充是绘制路径包含的区域。Quartz提供了函数来填充或描边路径。描边线的属性(宽度、颜色等)，填充色及Quartz用于计算填充区域的方法都是图形状态的一部分。

### 影响描边的属性

我们可以使用表3-1中的属性来决定如何对路径进行描边操作。这边属性是图形上下文的一部分，这意味着我们设置的值将会影响到后续的描边操作，直到我们个性这些值。

Table 3-1  Parameters that affect how Quartz strokes the current path

![image](http://cc.cocimg.com/bbs/attachment/thumb/Fid_6/6_38018_fa8395db5f33397.png)
 
linewidth是线的总宽度，单位是用户空间单元。

linejoin属性指定如何绘制线段间的联接点。Quartz支持表3-2中描述的联接样式。

Table 3-2  Line join styles

![image](http://cc.cocimg.com/bbs/attachment/thumb/Fid_6/6_38018_7e06943cde66626.png)

linecap指定如何绘制直线的端点。Quartz支持表3-3所示的线帽类型。默认的是butt cap。

Table 3-3  Line cap styles

![image](http://cc.cocimg.com/bbs/attachment/thumb/Fid_6/6_38018_a0b926ec7469e04.png) 

闭合路径将起始点看作是一个联接点；起始点同样也使用选定的直线连接方法进行渲染。如果通过添加一条连接到起始点的直线来闭合路径，则路径的两个端点都使用选定的线帽类型来绘制。

Linedash pattern(虚线模式)允许我们沿着描边绘制虚线。我们通过在CGContextSetLineDash结构体中指定虚线数组和虚线相位来控制虚线的大小及位置。

CGContextSetLineDash结构如下：

	void CGContextSetLineDash (
		CGContextRef ctx,
		float phase,
		const float lengths[],
		size_t count,
	);

其中lengths属性指定了虚线段的长度，该值是在绘制片断与未绘制片断之间交替。phase属性指定虚线模式的起始点。图3-11显示了虚线模式：

Figure 3-11  Examples of line dash patterns

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/linedash.gif)
 
描边颜色空间(stroke color space)定义了Quartz如何解析描边的颜色。我们同样也可以指定一个封装了颜色和颜色空间的CGColorRef数据类型。

### 路径描边的函数

Quartz提供了表3-4中的函数来描边当前路径。其中一些是描边矩形及椭圆的便捷函数。

Table 3-4  Functions that stroke paths

![image](http://cc.cocimg.com/bbs/attachment/thumb/Fid_6/6_38018_2f7e77438d8d49c.png)
 
函数CGContextStrokeLineSegments等同于如下代码

	CGContextBeginPath(context);                                                                                                                                                                                                                                                                 
	for(k = 0; k < count; k += 2)
	{
		CGContextMoveToPoint(context,s[k].x, s[k].y); CGContextAddLineToPoint(context,s[k+1].x, s[k+1].y);
	}
	
	CGContextStrokePath(context);

当我们调用CGContextStrokeLineSegments时，我们通过点数组来指定线段，并组织成点对的形式。每一对是由线段的起始点与终止点组成。例如，数组的第一个点指定了第一条直线的起始点，第二个点是第一条直线的终点，第三个点是第二条直线的起始点，依此类推。

### 填充路径
当我们填充当前路径时，Quartz将路径包含的每个子路径都看作是闭合的。然后，使用这些闭合路径并计算填充的像素。 Quartz有两种方式来计算填充区域。椭圆和矩形这样的路径其区域都很明显。但是如果路径是由几个重叠的部分组成或者路径包含多个子路径(如图3-12所示)，我们则有两种规则来定义填充区域。

默认的规则是非零缠绕数规则(nonzero windingnumber rule)。为了确定一个点是否需要绘制，我们从该点开始绘制一条直线穿过绘图的边界。从0开始计数，每次路径片断从左到右穿过直线是，计数加1；而从右到左穿过直线时，计数减1。如果结果为0，则不绘制该点，否则绘制。路径片断绘制的方向会影响到结果。图3-13显示了使用非缠绕数规则对内圆和外圆进行填充的结果。当两个圆绘制方向相同时，两个圆都被填充。如果方向相反，则内圆不填充。

我们也可以使用偶数-奇数规则。为了确定一个点是否被绘制，我们从该点开始绘制一条直线穿过绘图的边界。计算穿过该直线的路径片断的数目。如果是奇数，则绘制该点，如果是偶数，则不绘制该点。路径片断绘制的方向不影响结果。如图3-12所示，无论两个圆的绘制方向是什么，填充结果都是一样的。

Figure 3-12  Concentric circles filled using different fill rules

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/eosampleone.gif)
 
Quartz提供了表3-5中的函数来填充当前路径。其中一些是填充矩形及椭圆的便捷函数。

Table 3-5  Functions that fill paths

![image](http://cc.cocimg.com/bbs/attachment/thumb/Fid_6/6_38018_b20e82e060e2e61.png)

### 设置混合模式

混合模式指定了Quartz如何将绘图绘制到背景上。Quartz默认使用普通混合模式(normal blend mode)，该模式使用如下公式来计算前景绘图与背景绘图如何混合：

	result = (alpha * foreground) + (1 - alpha) *background

“颜色与颜色空间”章节里面详细讨论了颜色值的alpha组件，该组件用于指定颜色的透明度。在本章的例子中，我们可以假设颜色值是完全不透明的(alpha = 0)。对于不透明的颜色值，当我们用普通混合模式时，所有绘制于背景之上的绘图都会遮掩住背景。

我们可以调用函数CGContextSetBlendMode并传递适当的混合模式常量值来设置混合模式来达到我们想到的效果。记住混合模式是图形状态的一部分。如果调用了函数CGContextSaveGState来改变混合模式，则调用函数CGContextRestoreGState来重新设置混合模式为普通混合模式。

接下来的内容例举了不同混合模式上将图3-13的矩形绘制到图3-14的矩形之上的效果。背景图使用普通混合模式来绘制。然后调用CGContextSetBlendMode函数来改变混合模式。最后绘制前景矩形。

Figure 3-13  The rectangles painted in the foreground

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/vertical.gif)

Figure 3-14  The rectangles painted in the background

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/horizontal.gif)
 
注意：我们同样可以使用混合来组合两张图片或将图片与图形上下文中已有的内容进行混合。

#### 普通混合模式

由于普通混合模式是默认的混合模式，所以在设置了其它混合模式后，可以调用CGContextSetBlendMode并传递kCGBlendModeNormal来将混合模式重设为默认。图3-15显示了普通混合模式上图3-13与图3-14混合的效果。

Figure 3-15  Rectangles painted using normal blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_normal.gif)
 
#### 正片叠底混合模式(Mutiply Blend Mode)

正片叠底混合模式指定将前景的图片采样与背景图片采样相乘。结果颜色至少与两个采样颜色之一一样暗。图3-16显示了混合结果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeMultiply来设置这种混合模式。

Figure 3-16  Rectangles painted using multiply blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_multiply.gif) 

#### 屏幕混合模式(Screen Blend Mode)

屏幕混合模式指定将前景图片采样的反转色与背景图片的反转色相乘。结果颜色至少与两种采样颜色之一一样亮。图3-17显示了混合结果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeScreen来设置这种混合模式。

Figure 3-17  Rectangles painted using screen blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_screen.gif)
 
#### 叠加混合模式(Overlay Blend Mode)

叠加混合模式是将前景图片与背景图片或者正片叠底，或者屏幕化，这取决于背景颜色。背景颜色值与前景颜色值以反映出背景颜色的亮度与暗度。图3-18显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeOverlay来设置这种混合模式。
 
Figure 3-18  Rectangles painted using overlay blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_overlay.gif)
 
#### 暗化混合模式(Darken Blend Mode)

通过选择前景图片与背景图片更暗的采样来混合图片采样。背景图片采样被前景图片采样更暗的部分取代，而其它部分不变。图3-19显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeDarken来设置这种混合模式。

Figure 3-19  Rectangles painted using darken blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_darken.gif) 
 
#### 亮化混合模式(Lighten Blend Mode)

通过选择前景图片与背景图片更亮的采样来混合图片采样。背景图片采样被前景图片采样更亮的部分取代，而其它部分不变。图3-20显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeLighten来设置这种混合模式。

Figure 3-20  Rectangles painted using lighten blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_lighten.gif)
 
#### 色彩减淡模式(ColorDodge Blend Mode)

加亮背景图片采样以反映出前景图片采样。被指定为黑色的前景图片采样值将不产生变化。图3-21显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeColorDodge来设置这种混合模式。

Figure 3-21  Rectangles painted using color dodge blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_color_dodge.gif) 
 
#### 色彩加深模式(ColorBurn Blend Mode)

加深背景图片采样以反映出前景图片采样。被指定为白色的前景图片采样值将不产生变化。图3-21显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeColorBurn来设置这种混合模式。

Figure 3-22  Rectangles painted using color burn blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_color_burn.gif)
 
#### 柔光混合模式(SoftLight Blend Mode)

根据前景采样颜色减淡或加深颜色值。如果前景采样颜色比50%灰度值更亮，则减淡背景，类似于Dodge模式。如果前景采样颜色比50%灰度值更暗，则加强背景，类似于Burn模式。纯黑或纯白的图片采样将产生更暗或更亮的区域。但是但是不产生纯白或纯黑的颜色。该效果类似于将一个漫射光源放于一个前景图前。该效果用于在场景中添加高光效果。图3-23显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeSoftLight来设置这种混合模式。

Figure 3-23  Rectangles painted using soft light blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_soft_light.gif)
 
#### 强光混合模式(Hard Light Blend Mode)

根据前景图片采样颜色正片叠加或屏幕化颜色。如果前景采样颜色比50%灰度值更亮，则减淡背景，类似于screen模式。如果前景采样颜色比50%灰度值更暗，则加深背景，类似于multiply模式。如果前景采样颜色等于50%灰度，则前景颜色不变。纯黑与纯白的颜色图片采样将产生纯黑或纯白的颜色值。该效果类似于将一个强光源放于一个前景图前。该效果用于在场景中添加高光效果。图3-24显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeHardLight来设置这种混合模式。

Figure 3-24  Rectangles painted using hard light blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_hard_light.gif)
 
#### 差值混合模式(Difference Blend Mode)

将前景图片采样颜色值与背景图片采样值相减，相减的前后关系取决于哪个采样的亮度值更大。黑色的前景采样值不发生变化；白色值转化为背景的值。图3-25显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeDifference来设置这种混合模式。

Figure 3-25  Rectangles painted using difference blend mode 

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_difference.gif)
 
#### 排除混合模式(Exclusion Blend Mode)

该效果类似于Difference效果，只是对比度更低。黑色的前景采样值不发生变化；白色值转化为背景的值。图3-26显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeExclusion来设置这种混合模式。

Figure 3-26  Rectangles painted using exclusion blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_exclusion.gif) 
 
#### 色相混合模式(Hue Blend Mode)

使用背景的亮度和饱和度与前景的色相混合。图3-27显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeHue来设置这种混合模式。

Figure 3-27  Rectangles painted using hue blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_hue.gif)
 
#### 饱和度混合模式(Saturation Blend Mode)

混合背景的亮度和色相前景的饱和度。背景中没有饱和度的区域不发生变化。图3-28显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeSaturation来设置这种混合模式。

Figure 3-28  Rectangles painted using saturation blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_saturation.gif) 
 
#### 颜色混合模式(Color Blend Mode)

混合背景的亮度值与前景的色相与饱和度。该模式保留图片的灰度级。我们可以使用该模式绘制单色图片或彩色图片。图3-29显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeColor来设置这种混合模式。

Figure 3-29  Rectangles painted using color blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_color.gif) 
 
#### 亮度混合模式(Luminosity Blend Mode)

将背景图片的色相、饱和度与背景图片的亮度相混合。该模块产生一个与Color Blend模式相反的效果。图3-30显示了混合效果。我们可以调用CGContextSetBlendMode并传递kCGBlendModeLuminosity来设置这种混合模式。

Figure 3-30  Rectangles painted using luminosity blend mode

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blm_luminosity.gif) 
 
## 裁剪路径

当前裁剪区域是从路径中创建，作为一个遮罩，从而允许遮住我们不想绘制的部分。例如，我们有一个很大的图片，但只需要显示其中一小部分，则可以设置裁减区域来显示我们想显示的部分。

当我们绘制的时候，Quartz只渲染裁剪区域里面的东西。裁剪区域内的闭合路径是可见的；而在区域外的部分是不可见的。

当图形上下文初始创建时，裁减区域包含上下文所有的可绘制区域(例如，PDF上下文的media box)。我们可以通过设置当前路径来改变裁剪区域，然后使用裁减函数来取代绘制函数。裁剪函数与当前已有的裁剪区域求交集以获得路径的填充区域。因此，我们可以求交取得裁减区域，缩小图片的可视区域，但是不能扩展裁减区域。

裁减区域是图形状态的一部分。为了恢复先前的裁减区域，我们可以在裁减前保存图形状态，并在裁减绘制后恢复图形状态。

代码清单3-1显示了绘制圆形后设置裁减区域。该段代码使得绘图被裁减，效果类似于图3-3所示。

Listing 3-1 Setting up a circular clip area

	CGContextBeginPath(context);
	CGContextAddArc(context, w/2, h/2, ((w>h) ? h : w)/2, 0, 2*PI, 0);
	CGContextClosePath(context);
	CGContextClip(context);


Table 3-6  Functions that clip the graphics context

![image](http://cc.cocimg.com/bbs/attachment/thumb/Fid_6/6_38018_9138e0a8166cd38.png)

 

