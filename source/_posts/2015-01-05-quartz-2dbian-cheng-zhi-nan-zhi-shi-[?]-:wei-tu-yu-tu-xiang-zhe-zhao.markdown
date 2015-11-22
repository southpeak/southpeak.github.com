---

layout: post

title: "Quartz 2D编程指南之十一：位图与图像遮罩"

date: 2015-01-05 23:10:23 +0800

comments: true

categories: iOS

---

位图与图像遮罩和Quartz中的其它绘制元素一样。这两者在Quartz中都是用CGImageRef数据类型来表示。正如在本章后面看到的一样，我们有一系列的方法来创建一个图像。其中一些需要数据提供者或图像源来提供位图数据。另外一些函数则通过拷贝图像或在图像上应用操作来从已存在的图像中创建图像。不管我们是以何种方式来创建图像，我们都可以将图像绘制到任何类型的图形上下文。记住，位图是在指定分辨率下的一个字节数组。如果我们将位图绘制到一个依赖于分辨率的图形上下文中(如PDF图形上下文)，则位图受限于创建它的图形上下文的分辨率。

我们可以通过调用CGImageMaskCreate函数来创建一个Quartz图像遮罩。我们将在“创建图像遮罩”一节中看到如何创建遮罩。使用图像遮罩不是绘制遮罩的唯一方法，具体的我们都会在下面看到。

## 位图和图像遮罩

一个位图是一个像素数组。每一个像素表示图像中的一个点。JPEG, TIFF和PNG图像文件都是位图。应用程序的icon也是位图。位图被限定在一个矩形内。但是通过使用alpha分量，它们可以呈现不同的形式，也可以旋转或被裁剪，如图11-1所示：

Figure 11-1  Bitmap images

![image](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/images.gif)

位图中的每一个采样包含特定颜色空间下的一个或更多颜色分量，以及一个额外的用于指定alpha值以表示透明度的分量。每一个分量可以是从1-32位。在Mac OS X中，Quartz支持浮点值分量。在Mac OS X和iOS中支持的格式将会在下文中介绍。ColorSync提供了位图支持的颜色空间。

Quartz同样支持图像遮罩(image masks)。一个图像遮罩也是一个位图，它指定了一个绘制区域，而不是颜色。从效果上来说，一个图像遮罩更像一个模块，它指定在page中绘制颜色的位置。Quartz使用当前的填充颜色来绘制一个图像遮罩。一个颜色遮罩可以有1-8位的深度。

## 位图信息

Quartz提供了很多图像格式并内建了多种常用的格式。在iOS中，这些格式包括JPEG, GIF, PNG, TIF, ICO, GMP, XBM, 和CUR。其它的位图格式或专有格式需要我们指定图像格式的详细信息，以便Quartz能正确地解析图像。我们提供给CGImageCreate函数的图像数据必须是以像素为单位的，而不是基于扫描线的。Quartz不支持平面数据。

这一节描述了与位图相关的信息。当我们创建并使用Quartz图像时(使用CGImageRef数据类型)，我们将看到一些Quartz图像创建函数需要我们指定所有的信息，而其它函数只需要部分信息。我们所需要提供的信息依赖于位图数据的编码，以及位图是表示一个图像还是图像遮罩。

	注意：当使用原始图像数据时，为了获得更好的性能，我们可以使用vImage框架。我们可以使用vImageBuffer_InitWithCGImage函数从一个CGImageRef引用导入图像数据到vImage中。

创建一个位图(CGImageRef)时，Quartz使用以下信息：

1. 位图数据源：可以是一个Quartz数据提供者或者是一个Quartz图像源。
2. 可选的解码数组。(Decode Array)
3. 插值设置：这是一个布尔值，指定Quartz在重置图像大小时是否使用插值算法。
4. 渲染意图：指定如何映射位于图形上下文中的目标颜色空间中的颜色。该值在图像遮罩中不需要。
5. 图像尺寸
6. 像素格式，包括每个分量中的位数，每个像素的位数和每行中的字节数。
7. 对于图像来说，颜色空间和位图布局信息描述了alpha的位置和位置是否使用浮点值。图像遮罩不需要这个信息。

### 解码数组

一个解码数组将图像颜色值映射到其它颜色值，这对于诸如对一个图像做去饱和或者反转颜色值非常有用。数组包含每个颜色分量的一个数值对。当Quartz渲染图像时，它利用一个线性转换将原始分量值映射到一个目标颜色空间中的指定范围内一个相关值。例如，在RGB颜色空间中的一个图像的解码数组包含6个输入，分别用于红、绿、蓝颜色分量。

### 像素格式

像素格式包含以下信息：

1. 每个分量的位数，即在一个像素中每个独立颜色分量的位数。对于一个图像遮罩，这个值是源像素中遮罩bit的数目。例如，如果源图片是8-bit的遮罩，则指定每个分量是8位。
2. 每个像素的位数，即一个源像素所占的总的位数。这个值必须至少是每个分量的位数乘以每个像素中分量的数目。
3. 每行的字节数，即图像中水平行的字节数。

### 颜色空间和位图布局

为了确保Quartz能正确的解析每个像素的位，我们必须指定：

1. 一个位图是否包含alpha通道。Quartz包含RGB,CMYK和灰度颜色空间。它也支持alpha，或者透明度，虽然并不是所有位图图像格式都支持alpha通道。当它可用时，alpha分量可以位于像素最显著的位置，也可以是最不显著的位置。
2. 对于有alpha分量的位图，指定颜色分量是否已经乘以了alpha值。预乘alpha(Premultiplied alpha)表示一个已将颜色分量乘以了alpha值的源颜色。这种预处理通过消除每个颜色分量的额外的乘法运算来加速图片的渲染。
3. 采样的数据格式--是整型还是浮点型。

当我们使用CGImageCreate函数来创建一个图像时，我们提供一个类型为CGImageBitmapInfo的bitmapInfo参数，来指定位置布局信息。以下的常量指定了alpha分量的位置及颜色分量是否做预处理：

1. kCGImageAlphaLast：alpha分量存储在每个像素中最不显著的位置，如RGBA。
2. kCGImageAlphaFirst：alpha分量存储在每个像素中最显著的位置，如ARGB。
3. kCGImageAlphaPremultipliedLast：alpha分量存储在每个像素中最不显著的位置，但颜色分量已经乘以了alpha值。
4. kCGImageAlphaPremultipliedFirst：alpha分量存储在每个像素中最显著的位置，同时颜色分量已经乘以了alpha值。
5. kCGImageAlphaNoneSkipLast：没有alpha分量。如果像素的总大小大于颜色空间中颜色分量数目所需要的空间，则最不显著位置的位将被忽略。
6. kCGImageAlphaNoneSkipFirst：没有alpha分量。如果像素的总大小大于颜色空间中颜色分量数目所需要的空间，则最显著位置的位将被忽略。
7. kCGImageAlphaNone：等于kCGImageAlphaNoneSkipLast。

我们使用常量kCGBitmapFloatComponents来标识一个位图格式使用浮点值。对于浮点格式，我们将这个常量与上而描述的合适的常量进行逻辑OR操作。例如，对于每个像素有128位的使用预处理的浮点格式，同时alpha值位于像素中最不显示位置，我们将以下信息提供给Quartz：

	kCGImageAlphaPremultipliedLast | kCGBitmapFloatComponents

图11-2演示了一个像素在使用16-或32-bit整型像素格式的CMYK和RGB颜色空间中如何表示。32-bit整型像素格式中，每个分量占8位。16-bit整型像素格式中每个分量占5位。Quartz同样支持128-bit浮点像素格式，每个分量占32位。128-bit格式没有显示在下图中。

Figure 11-2  32-bit and 16-bit pixel formats for CMYK and RGB color spaces in Quartz 2D

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/colorformatrgba32.gif)

## 创建图像

表11-1罗列了Quartz提供的用于创建CGImageRef对象的函数。函数的选择依赖于图像的数据源。最常用的函数是CGImageCreate。它可以从任何类型的位图数据来创建一个图像。然而，它是最复杂的函数，因为需要提供所有的位图信息。为了使用这个函数，我们需要熟悉上面讨论的位图图像信息的内容。

如果我们想从一个标准的图像格式，如PNG或JPEG，来创建一个CGImage对象，则最简单的方法是调用函数CGImageSourceCreateWithURL来创建一个图像源，然后调用CGImageSourceCreateImageAtIndex以使用从图像源中索引index指定的图像数据来创建一个图像。如果源图像文件只包含一个图像，则索引为0。如果图像文件格式支持包含多个图像的文件，则需要提供所需要图像的索引值，记住起始值是0。

如果我们已经将内容渲染到一个位图图形上下文，并想要从中获取到CGImage对象，则调用CGBitmapContextCreateImage函数。

有几个函数可以操作已有的图像，如拷贝、创建一个缩略图，或从一个大图像中创建一个图像。不管如何创建一个图像对象，我们都使用函数CGContextDrawImage将图像绘制到一个图形上下文中。记住CGImage是不可变的。当不再需要一个CGImage对象时，调用CGImageRelease函数来释放它。

![image](http://a3.qpic.cn/psb?/V130i6W71atwfr/W9ZJHCPpoB6QElZy*ePoumPixMBNcMaHrVryzqP12b0!/b/dBmKcHUpFAAA&bo=pAaAAgAAAAADBwI!&rf=viewer_4)

接下来将讨论如何创建：

1. 从一个已存在图像中创建一个子图像
2. 从一个图像图形上下文中创建一个图像

### 从一个大图片中创建一个图像

我们可以使用CGImageCreateWithImageInRect函数从一个大图像中创建一个图像。图11-3演示了这一情形。

Figure 11-3  A subimage created from a larger image

![image](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/subimage.gif)

函数CGImageCreateWithImageInRect返回的图像保留了源图像的一个引用，这意味着我们在调用完这个函数后可以释放源图像。

图11-4是另外一个例子。在这种情况下，公鸡的头部被从大图中提取出来，然后绘制到一个大于子图像的矩形中。

代码清单11-1显示了创建并绘制子图像的过程。CGContextDrawImage函数绘制公鸡头部的矩形区域是所提取的子图像的四倍大小。清单中的只是一个代码片断。我们需要声明合适的变量，创建公鸡头像，并部署公鸡图像及公鸡头部子图像。因为只是代码片断，所以没有演示如何创建一个图形上下文。我们可以使用任何我们所喜欢的图形上下文。创建图形上下文的例子可以查看“图形上下文”一章。

Figure 11-4  An image, a subimage taken from it and drawn so it’s enlarged

![image](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rooster_image_zoom.gif)

Listing 11-1  Code that creates a subimage and draws it enlarged
	
	myImageArea = CGRectMake (rooster_head_x_origin, rooster_head_y_origin,
	                            myWidth, myHeight);
	mySubimage = CGImageCreateWithImageInRect (myRoosterImage, myImageArea);
	myRect = CGRectMake(0, 0, myWidth*2, myHeight*2);
	CGContextDrawImage(context, myRect, mySubimage);

### 从一个位图图形上下文创建一个图像

为了从一个已存在的位图图形上下文创建一个图像，我们可以调用函数CGBitmapContextCreateImage，如以下：

	CGImageRef myImage;
	myImage = CGBitmapContextCreateImage (myBitmapContext);

这个函数返回的CGImage对象是通过一个拷贝操作创建的。因此我们对位图图形上下文所做的修改都不会影响到已返回的CGImage对象。在一些情况下，这个拷贝操作实际上沿用了copy-on-write语义，即只有当位图图形上下文中的数据被修改时才会去实际拷贝这些数据。我们可能需要在绘制额外数据到位图图形上下文之前使用结果数据或者释放它们，以便我们可以避免实际去拷贝这些数据。

如何创建一个位图图形上下文，可以参考"创建图形上下文"相关的内容。

## 创建一个图像遮罩

一个Quartz位图图像遮罩如同艺术家使用丝网印刷品(silkscreen)一样。一个位图图像遮罩定义了如何转换颜色，而不是使用哪些颜色。图像遮罩中的每个采样值指定了在特定位置中，当前填充颜色值被遮罩的数量。采样值指定了遮罩的不透明度。值越大，表示越不透明，Quartz在指定位置绘制的颜色越少。我们可以将采样值当成alpha值的反转。1表示透明的，而0表示不透明。

图像遮罩的每个分量可能是1，2，4或者8位。对于1-bit的遮罩，采样值1指定遮罩的区域掩盖了当前的填充颜色。值为0表示当绘制遮罩时，显示当前的填充颜色。我们可以将1-bit遮罩当成黑色和白色；要么完全遮挡，要么完全显示。

每个分量中有2，4，8位的图像遮罩代表灰度值。每个分量使用以下的公式将值映射到[0, 1]之间的值：

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/inline_equations.jpg)

例如，一个4-bit的遮罩其值位于[0, 1]之间，且增长的步长为1/15。0和1这两个值分别是最小和最大值--分别表示完全遮盖或完全透明。0和1之间的值使用(1-MaskSampleValue)这个公式来处理局部绘制。例如，如果一个8-bit遮罩的采样值设置为0.7，则那些alpha值为(1-0.7)，即0.3的颜色将会被绘制。

函数CGImageMaskCreate从我们提供的位图图像信息中创建一个Quartz图像遮罩。我们提供的信息与创建图像所提供的信息是一样的，只是不需要提供颜色空间信息，位图信息常量或渲染意图，我们可以从代码清单11-2中看到这个函数原型：

Listing 11-2  The prototype for the function CGImageMaskCreate

	CGImageRef CGImageMaskCreate (
	        size_t width,
	        size_t height,
	        size_t bitsPerComponent,
	        size_t bitsPerPixel,
	        size_t bytesPerRow,
	        CGDataProviderRef provider,
	        const CGFloat decode[],
	        bool shouldInterpolate
	);


## 遮罩图像

遮罩技术可以让我们通过控制图片的哪一部分被绘制，以生成很多有趣的效果，我们可以：

1. 在一个图像上使用图像遮罩。我们也可以把一个图像作为遮罩图，以获取同使用图像遮罩相反的效果。
2. 使用颜色来遮罩图像的一部分，其中包含被称为颜色遮罩的技术
3. 将图形上下文剪切到一个图像或图像遮罩，当Quartz绘制内容到剪切的图形上下文时来遮罩一个图像。

### 使用一个图像遮罩来遮罩图像

函数CGImageCreateWithMask通过将图像遮罩使用到一个图像上的方式来创建一个图像。这个函数带有两个参数：

1. 原始图像，遮罩将用于其上。这个图像不能是图像遮罩，也不能有与之相关的遮罩颜色。
2. 一个图像遮罩，通过调用CGImageMaskCreate函数创建的。也可以提供一个图像来替代图像遮罩，但这将给出非常不同的结果。这将在下面描述。

一个图像遮罩的采样如同一个反转的alpha值。一个图像遮罩采样值(S)：

1. 为1时，则不会绘制对应的图像样本。
2. 为0时，则允许完全绘制对应的图像样本。
3. 0和1之间的值，则让对应的图像样本的alpha的值为(1-S)。

图11-5显示了一个由Quartz图像创建函数创建的图像，而图11-6显示了一个使用CGImageMaskCreate函数创建的图像遮罩。图11-7则显示了一个使用CGImageCreateWithMask函数将图像遮罩应用于一个图像的效果。

Figure 11-5  The original image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/two_tigers.gif)

Figure 11-6  An image mask

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/two_tiger_mask.gif)

注意，源图像中与遮罩黑色区域对应的区域绘制出来，而与白色区域对应的部分则没有绘制出来。而与遮罩灰色区域对应的区域则使用一个与(1-图像遮罩采样值)相同的alpha值来绘制。

Figure 11-7  The image that results from applying the image mask to the original image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/image_create_w_mask.gif)

### 使用一个图像来遮罩一个图像

我们可以使用函数CGImageCreateWithMask来用一个图像遮罩另一个图像，而不是使用一个图像遮罩。我们可以使用这种方式来达到与使用图像遮罩相反的效果。那此时我们传递给CGImageCreateWithMask函数的就不是一个图像遮罩了，而是传递一个通过Quartz图像创建函数创建的图像。

用于遮罩的图像的采样也是操作alpha值。一个图像采样值(S)：

1. 为1时，则允许完全绘制对应的图像样本。
2. 为0时，则不会绘制对应的图像样本。
3. 0和1之间的值，则让对应的图像样本的alpha的值为S。

图11-8显示了调用CGImageCreateWithMask函数将图11-6中的图像作为遮罩应用于图11-5中的图像上的效果。在这个例子中，我们假定图11-6中的图像是使用Quartz图像创建函数(如CGImageCreate)创建的。比较图11-8与图11-7，可以看出使用图像采样时，可以获取与使用图像遮罩采样相反的效果。

在图11-8的结果图像中，源图像中与图像的黑色区域对应的区域没有绘制出来。与白色区域对应的区域则绘制出来了。在遮罩中与灰色区域对应的区域则使用与遮罩图像采样值相同的alpha值来绘制。

Figure 11-8  The image that results from masking the original image with an image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/image_mask_image.gif)

### 使用颜色来遮罩图像

函数CGImageCreateWithMaskingColors通过遮罩一种颜色或一个颜色范围内的颜色来创建一个图像。使用这个函数，我们可以执行如图11-9所示的颜色遮罩，当然也可以遮罩一个范围内的颜色，如图11-11、11-12和11-13所示的效果。

函数CGImageCreateWithMaskingColors有两个参数：

1. 一个图像，它不能是遮罩图像，也不能是使用过图像遮罩或颜色遮罩的图像。
2. 一个颜色分量数组，指定了一个颜色或一组颜色值，以用于遮罩图像。

Figure 11-9  Chroma key masking

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/chroma_key.gif)

颜色分量数组中元素的个数必须等于图像所在颜色空间的颜色分量数目的两倍。对于颜色空间中的每一个颜色分量，提供一个最小值和一个最大值来限定遮罩颜色的范围。如果只使用一个颜色，则设置最大值等于最小值即可。颜色分量数组中的值按以下顺序来提供：

	{min[1], max[1], ... min[N], max[N]}，其中N是分量的数目
	
如果图像使用整型像素分量，则颜色分量数组中的每个值必须在[0 .. 2^bitsPerComponent - 1]范围之内。如果图像使用浮点像素分量，则值可以是表示任何有效的颜色分量值的浮点数。

一个图像采样如果其颜色值在以下范围内，则不会被绘制：

	{c[1], ... c[N]}，其中min[i] <= c[i] <= max[i] for 1 <= i <= N

图11-10中两只老虎的图像使用了每个分量有8位的RGB颜色空间。为了在这个图像上屏蔽一组颜色，我们提供一组在[0, 255]区间内的最小和最大颜色分量值。

Figure 11-10  The original image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/two_tigers1.gif)

代码清单11-3演示了如何设置颜色分量数组，并将其提供给CGImageCreateWithMaskingColors函数以达到图11-11的效果。

Listing 11-3  Masking light to mid-range brown colors in an image

	CGImageRef myColorMaskedImage;
	const CGFloat myMaskingColors[6] = {124, 255,  68, 222, 0, 165};
	myColorMaskedImage = CGImageCreateWithMaskingColors (image,
	                                        myMaskingColors);
	CGContextDrawImage (context, myContextRect, myColorMaskedImage);

Figure 11-11  An image with light to midrange brown colors masked out

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/beige_brown_masking.gif)

代码清单11-14同样操作图11-10并得到图11-12的效果。这个例子遮罩了一组暗色。

Listing 11-4  Masking shades of brown to black

	CGImageRef myMaskedImage;
	const CGFloat myMaskingColors[6] = { 0, 124, 0, 68, 0, 0 };
	myColorMaskedImage = CGImageCreateWithMaskingColors (image,
	                                        myMaskingColors);
	CGContextDrawImage (context, myContextRect, myColorMaskedImage);

Figure 11-12  A image after masking colors from dark brown to black

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/brown_black_masking_colors.gif)

我们同样可以设置一个填充颜色来作为图像的遮罩颜色，以达到图11-13的效果，其中被遮罩区域使用了填充颜色。代码清单11-15演示了这一过程

Listing 11-5  Masking a range of colors and setting a fill color and

	CGImageRef myMaskedImage;
	const CGFloat myMaskingColors[6] = { 0, 124, 0, 68, 0, 0 };
	myColorMaskedImage = CGImageCreateWithMaskingColors (image,
	                                        myMaskingColors);
	CGContextSetRGBFillColor (myContext, 0.6373,0.6373, 0, 1);
	CGContextFillRect(context, rect);
	CGContextDrawImage(context, rect, myColorMaskedImage);

Figure 11-13  An image drawn after masking a range of colors and setting a fill color

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/fill_color_with_mask.gif)

### 通过裁减上下文来遮罩一个图片

函数CGContextClipToMask将遮罩映射为一个矩形并将其与图形上下文的当前裁减区域求个交集。我们提供以下参数：

1. 需要裁减的图形上下文
2. 要使用遮罩的矩形区域
3. 一个图像遮罩，其通过CGImageMaskCreate函数创建。我们可以使用图像来替代图像遮罩以达到相反的效果。但图像必须使用Quartz图像创建函数来创建，但不能是使用过图像遮罩或颜色遮罩的图像。

裁减区域的结果依赖于是否提供了一个图像遮罩或图像给CGContextClipToMask函数。

我们看看图11-14.假设它是通过调用CGImageMaskCreate函数创建的一个图像遮罩，然后将其作为CGContextClipToMask函数的参数。结果上下文允许绘制黑色区域，而不绘制白色区域，并使用(1-S)的alpha值来绘制灰色区域，其中S是图像遮罩的采样值。如果使用CGContextDrawImage函数来将一个图像绘制到裁减上下文，则可以获得图11-15所示的结果。

Figure 11-14  A masking image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/the_mask.gif)

Figure 11-15  An image drawn to a context after clipping the content with an image mask

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/mask_as_mask.gif)

当遮罩图像被当成一个图像时，可以获得相反的结果，如图11-16所示：

Figure 11-16  An image drawn to a context after clipping the content with an image

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/inverse_mask_clip.gif)


## 在图像中使用混合模式

此处略，类似于在颜色中使用混合模式。
