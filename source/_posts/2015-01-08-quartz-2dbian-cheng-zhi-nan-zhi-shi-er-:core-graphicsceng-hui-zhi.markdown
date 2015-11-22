---

layout: post

title: "Quartz 2D编程指南之十二：Core Graphics层绘制"

date: 2015-01-08 22:47:51 +0800

comments: true

categories: iOS

---

CGLayer对象(CGLayerRef数据类型)允许程序使用层来进行绘制。

层适合于以下几种情况：

1. 高质量离屏渲染，以绘制我们想重用的图形。例如，我们可能要建立一个场景并重用相同的背景。将背景场景绘制于一个层上，然后在需要的时候再绘制层。一个额外的好处是我们不需要知道颜色空间或其它设备依赖的信息来绘制层。
2. 重复绘制。例如，我们可能想创建一个由相同元素反复绘制而组成的模式。将元素绘制到一个层中，然后重复绘制这个层，如图12-1所示。任何我们重复绘制的Quartz对象，包括CGPath, CGShading和CGPDFPage对象，都可以通过将其绘制到CGLayer来优化性能。注意一个层不仅仅是用于离屏绘制；我们也可以将其用于那些不是面向屏幕的图形上下文，如PDF图形上下文。
3. 缓存。虽然我们可以将层用于此目的，但通常不需要这样做，因为Quartz Compositor已经做了此事。如果我们必须绘制一个缓存，则使用层来代替位图图形上下文。

Figure 12-1  Repeatedly painting the same butterfly image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/stamp_layers.gif)

CGLayer对象和透明层是与CGPath对象以及CGContext函数创建的路径并行的。对于一个CGLayer或者CGPath对象，我们可以将其绘制到一个抽象目标，之后可以将其完整地绘制到另一个目标，如显示器或才PDF中。当我们在透明层上绘制或者使用绘制路径的CGContext函数时，可以直接绘制到图形上下文表示的目标上，而不需要负责组装绘制的中间抽象目标。

## 层如何工作

一个层由CGLayerRef数据类型表示，是为优化性能而设计的。在可能的时候，Quartz使用合适的机制将一个CGLayer对象缓存到与之相关的Quartz图形上下文中。例如，与显卡相关的图形上下文可能将层缓存到显卡中，这样绘制在层中的内容时，就比渲染从一个位图图形上下文中构造的类似图像要快得多。基于这个原因，层比位图图形上下文更适用于离屏绘制。

所有的Quartz绘制函数都是绘制到图形上下文中。图形上下文提供了一个抽象的渲染目标，而将我们从目标的细节中解放出来。我们使用用户空间，Quartz执行必要的转换来将绘图正确地渲染到目标。当我们使用CGLayer对象来绘制时，我们也是绘制到图形上下文中。图12-1演示了层绘制的必要步骤。

Figure 12-2  Layer drawing

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/layer_context.gif)

所有在图形上下文中层的绘制都是以使用函数CGLayerCreateWithContext创建一个CGLayer对象开始的。用于创建CGLayer对象的图形上下文通常是一个window图形上下文。Quartz创建一个层，使得它具有图形上下文的所有特性：包括分辨率，颜色空间和图形状态设置。如果我们不想使用图形上下文的大小，则可以提供一个大小给层。在图12-2中，左侧显示了用于创建层的图形上下文。框右侧的灰色部分，即标记为CGLayer对象的部分表示新创建的层。

在我们可以绘制层之前，我们必须通过调用CGLayerGetContext函数来获取与层相关的图形上下文。这个图形上下文与用于创建层的图形上下文是差不多的。只要用于创建层的图形上下文是一个window图形上下文，则CGLayer图形上下文会尽可能地被缓存到GPU中。图12-2中位于框右侧的白色部分表示新创建的层图形上下文。

在层图形上下文中绘制与在其它图形上下文中绘制一样，将层图形上下文作为参数传给绘制函数。图12-2显示了一片绘制到层图形上下文的叶子。

当我们准备使用层的内容时，我们可以调用函数CGContextDrawLayerInRect或者CGContextDrawLayerAtPoint将层绘制到一个图形上下文。通常情况下，我们会将层绘制到创建层对象的图形上下文中，但这不是必须的。我们可以将层绘制到任意的图形上下文，记住：层带有创建层对象的图形上下文的所有特性，这可能会产生一些限制(如性能或分辨率)。例如，与屏幕关联的层可能会被缓存到显卡中。如果目标上下文是一个打印机或PDF上下文，则可能需要将层对象从显卡中取出并放到内存中，从而导致性能很差。

图12-2显示了层的内容--叶子--被重复地绘制到创建层对象的图形上下文中。我们可以在释放CGLayer对象之前，任意地重复使用层中的绘图。

## 使用层来绘制

我们需要按照如下几个步骤来使用层对象进行绘制：

1. 创建一个使用已存在的图形上下文初始化的层对象
2. 为层获取图形上下文
3. 绘制到CGLayer图形上下文
4. 将层绘制到目标图形上下文

我们将在下面详细描述这几个步骤。

### 创建一个使用已存在的图形上下文初始化的层对象

函数CGLayerCreateWithContext返回一个使用已存在的图形上下文初始化的层对象。这个层对象继承了该图形上下文的所有特性，包括颜色空间、大小、分辨率和像素格式。后期当我们绘制层对象到一个目标时，Quartz会自动对层与目标上下文进行颜色匹配。

函数CGLayerCreateWithContext带有三个参数：

1. 用于创建层的图形上下文。通常我们传递一个window图形上下文以便后面可以离屏绘制层。
2. 层相对于图形上下文的大小。层的大小可以和图形上下文一样，或者更小。如果想要获得层的大小，我们可以调用函数CGLayerGetSize。
3. 一个辅助字典。这个参数现在已经不用了，所以传递NULL即可。

### 为层获取图形上下文

Quartz总是在一个图形上下文中进行绘制。现在我们有了一个层对象，我们必须创建一个与层相关的图形上下文。所有绘制到层图形上下文的内容都是层的一部分。

函数CGLayerGetContext获取一个层对象作为参数，并返回与之相关的图形上下文。


### 绘制到CGLayer图形上下文

在获取到与层相关的图形上下文之后，我们可以在层图形上下文中绘制任何东西。我们可以打开一个PDF文件或一个图像文件，并将文件内容绘制到层中。我们可以使用Quartz 2D的任何函数来绘制矩形、直线或其它绘制单元。图12-3显示了在层中绘制一个矩形和直线。

Figure 12-3  A layer that contains two rectangles and a series of lines

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rect_star_layer.gif)

例如，为了在CGLayer图形上下文中绘制一个填充矩形，我们调用函数CGContextFillRect，并提供从CGLayerGetContext函数中获取到的图形上下文作为参数。假设这个图形上下文命名为myLayerContext，则函数调用如下：

	CGContextFillRect (myLayerContext, myRect)

### 将层绘制到目标图形上下文

当我们已经准备好将层绘制到目标图形上下文时，我们可以使用以下任一一个函数：

1. CGContextDrawLayerInRect：将层绘制到图形上下文中指定的矩形内。
2. CGContextDrawLayerAtPoint：将层绘制到图形上下文中指定的点。

通常情况下，我们提供的目标图形上下文是一个window图形上下文，这也是我们用于创建层对象所使用的图形上下文。图12-4显示了重复绘制图12-3所绘制的层。为了达到模式效果，我们可以使用上面两个方法中的任意一个，只是每次改变偏移量而已。例如，我们每次绘制层时，可以调用函数CGContextTranslateCTM来改变坐标系统的原点。

Figure 12-4  Drawing a layer repeatedly

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rect_star_pattern.gif)

	注意：我们不必要将层绘制到初始层所使用的图形上下文中。然而，如果我们将层绘制到其它图形上下文中，原始图形上下文的所有限制都会反映到我们的绘图中。

## 例子：使用多个CGLayer对象来绘制旗子

这一节演示了如何使用CGLayer对象来在屏幕上绘制图12-5中的旗子。首先我们会看到如何将旗子分解成简单的绘制单元，然后会看到要完成这些任务的代码。

Figure 12-5  The result of using layers to draw the United States flag

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/us_flag.gif)

从上面可以看出，旗子主要分三部分：

1. 红色条纹和白色条纹的模式。我们可以将这个模式分解为一个单一的红色条纹，因为对于屏幕绘制来说，我们可以假设其背景颜色为白色。我们创建一个红色矩形，然后以变化的偏移量来重复绘制这个矩形，以创建美国国旗上的七条红色条纹。我们将红色矩形绘制到一个层，然后将其绘制到屏幕上七次。
2. 一个蓝色矩形。我们只需要一个蓝色矩形，所以没有必要使用层。当绘制蓝色矩形时，直接将其绘制到屏幕上。
3. 50个白色星星的模式。与红色条纹一下，可以使用层来绘制星星。我们创建星星边框的一个路径，然后使用白条来填充。将一个星星绘制到层，然后重复50次绘制这个层，每次绘制时适当调整偏移量。

代码清单12-2完成了对图12-5的绘制。myDrawFlag例程在一个Cocoa程序中调用。这个程序传递一个window图形上下文和一个与图形上下文相关的视图的大小。

Listing 12-1  Code that uses layers to draw a flag

	void myDrawFlag (CGContextRef context, CGRect* contextRect)
	{
	    int          i, j,
	                 num_six_star_rows = 5,
	                 num_five_star_rows = 4;
	    CGFloat      start_x = 5.0,
	                 start_y = 108.0,
	                 red_stripe_spacing = 34.0,
	                 h_spacing = 26.0,
	                 v_spacing = 22.0;
	    CGContextRef myLayerContext1,
	                 myLayerContext2;
	    CGLayerRef   stripeLayer,
	                 starLayer;
	    CGRect       myBoundingBox,
	                 stripeRect,
	                 starField;
	 // ***** Setting up the primitives *****
	 	CGPoint point1 = {5, 5}, point2 = {10, 15}, point3 = {10, 15}, point4 = {15, 5};
	 	CGPoint point5 = {15, 5}, point6 = {2.5, 11}, point7 = {2.5, 11}, point8 = {16.5, 11};
	 	CGPoint point9 = {16.5, 11}, point10 = {5, 5};
	    const CGPoint myStarPoints[] = {point1, point2,
	                                    point3, point4,
	                                    point5, point6,
	                                    point7, point8,
	                                    point9, point10};
	 
	    stripeRect  = CGRectMake (0, 0, 400, 17); // stripe
	    starField  =  CGRectMake (0, 102, 160, 119); // star field
	 
	    myBoundingBox = CGRectMake (0, 0, contextRect->size.width, 
	                                      contextRect->size.height);
	 
	     // ***** Creating layers and drawing to them *****
	    stripeLayer = CGLayerCreateWithContext (context, 
	                            stripeRect.size, NULL);
	    myLayerContext1 = CGLayerGetContext (stripeLayer);
	 
	    CGContextSetRGBFillColor (myLayerContext1, 1, 0 , 0, 1);
	    CGContextFillRect (myLayerContext1, stripeRect);
	 
	    starLayer = CGLayerCreateWithContext (context,
	                            starField.size, NULL);
	    myLayerContext2 = CGLayerGetContext (starLayer);
	    CGContextSetRGBFillColor (myLayerContext2, 1.0, 1.0, 1.0, 1);
	    CGContextAddLines (myLayerContext2, myStarPoints, 10);
	    CGContextFillPath (myLayerContext2);    
	 
	     // ***** Drawing to the window graphics context *****
	    CGContextSaveGState(context);    
	    for (i=0; i< 7;  i++)   
	    {
	        CGContextDrawLayerAtPoint (context, CGPointZero, stripeLayer);
	        CGContextTranslateCTM (context, 0.0, red_stripe_spacing);
	    }
	    CGContextRestoreGState(context);
	 
	    CGContextSetRGBFillColor (context, 0, 0, 0.329, 1.0);
	    CGContextFillRect (context, starField);
	 
	    CGContextSaveGState (context);              
	    CGContextTranslateCTM (context, start_x, start_y);      
	    for (j=0; j< num_six_star_rows;  j++)   
	    {
	        for (i=0; i< 6;  i++)
	        {
	            CGContextDrawLayerAtPoint (context,CGPointZero,
	                                            starLayer);
	            CGContextTranslateCTM (context, h_spacing, 0);
	        }
	        CGContextTranslateCTM (context, (-i*h_spacing), v_spacing); 
	    }
	    CGContextRestoreGState(context);
	 
	    CGContextSaveGState(context);
	    CGContextTranslateCTM (context, start_x + h_spacing/2, 
	                                 start_y + v_spacing/2);
	    for (j=0; j< num_five_star_rows;  j++) 
	    {
	        for (i=0; i< 5;  i++)
	        {
	        CGContextDrawLayerAtPoint (context, CGPointZero,
	                            starLayer);
	            CGContextTranslateCTM (context, h_spacing, 0);
	        }
	        CGContextTranslateCTM (context, (-i*h_spacing), v_spacing);
	    }
	    CGContextRestoreGState(context);
	 
	    CGLayerRelease(stripeLayer);
	    CGLayerRelease(starLayer);        
	}

在此不再翻译对代码的注释，请各位看官查看文档原文[Core Graphics Layer Drawing](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_layers/dq_layers.html#//apple_ref/doc/uid/TP30001066-CH219-TPXREF101)。