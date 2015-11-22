---

layout: post

title: "Quartz 2D编程指南之十：Quartz 2D中的数据管理"

date: 2014-12-11 09:19:08 +0800

comments: true

categories: iOS

---

管理数据是每一个图形应用程序所需要处理的工作。对于Quartz来说，数据管理涉及为Quartz 2D程序提供数据，及从中获取数据。一些Quartz 2D程序将数据传输到Quartz中，如从文件或程序其它部分获取图片或PDF数据。另一些程序则获取Quartz数据，如将图像或PDF数据写入到文件，或提供给程序其它部分这些数据。

Quartz提供了一系列的函数来管理数据。通过学习本章，我们可以了解到哪些函数是最适合我们的程序的。

	注：我们推荐使用图像I/O框架来读取和写入数据，该框架在iOS 4、Mac OS X 10.4或者更高版本中可用。查看《Image I/OProgramming Guide 》可以获取更多关于CGImageSourceRef和CGImageDestinationRef的信息。图像源和目标不仅提供了访问图像数据的方法，不提供了更多访问图像原数据的方法。

Quartz可识别三种类型的数据源和目标：

1. URL：通过URL指定的数据可以作为数据的提供者和接收者。我们使用Core Foundation数据类型CFURLRef作为参数传递给Quartz函数。
2. CFData：Core Foundation数据类型CFDataRef和CFMutableDataRef可简化Core Foundation对象的内存分配行为。CFData是一个”toll-freebridged”类，CocoaFoundation中对应的类是NSData；如果在Quartz 2D中使用Cocoa框架，你可以传递一个NSData对象给Quartz方法，以取代CFData对象。
3. 原始数据：我们可以提供一个指向任何类型数据的指针，连同处理这些数据基本内存管理的回调函数集合。

这些数据，无论是URL、CFData对象，还是数据缓存，都可以是图像数据或PDF数据。图像数据可以是任何格式的数据。Quartz能够解析大部分常用的图像文件格式。一些Quartz数据管理函数专门用于处理图像数据，一些只处理PDF数据，还有一些可同时处理PDF和图像数据。

URL，CFData和原始数据源和目标中的数据都是在Mac OS X 或者iOS图像领域范围之外的，如图10-1所示。Mac OS X或iOS的其它图像技术通常会提供它们自己的方式来和Quartz通信。例如，一个Mac OS X 应用程序可以传输一个Quartz图像给Core Image，并使用Core Image来实现更复杂的效果。

Figure 10-1  Moving data to and from Quartz 2D in Mac OS X

![image](https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/movingdata.gif)

## 传输数据给Quartz 2D

表10-1列出了从数据源获取数据的方法。所有的这些函数，除了CGPDFDocumentCreateWithURL，都返回一个图像源(CGImageSourceRef)或者数据提供者(CGDataProviderRef)。图像源和数据提供者抽象了数据访问工作，并避免了程序去管理原始内存缓存。

图像源是将图像数据传输给Quartz的首先方式。图像源可表示很多种图像数据。一个图像源可表示多于一个图像，也可表示缩略图、图像的属性和图像文件。当我们拥有CGImageSourceRef对象后，我们可以完成如下工作：

1. 使用函数CGImageSourceCreateImageAtIndex,CGImageSourceCreateThumbnailAtIndex, CGImageSourceCreateIncremental创建图像(CGImageRef). 一个CGImageRef数据类型表示一个单独的Quartz图像。
2. 通过函数CGImageSourceUpdateData或CGImageSourceUpdateDataProvider来添加内容到图像源中。
3. 使用函数CGImageSourceGetCount, CGImageSourceCopyProperties和CGImageSourceCopyTypeIdentifiers获取图像源的信息。

CFPDFDocumentCreateWithURL函数可以方便地从URL指定的文件创建PDF文档。

数据提供者是比较老的机制，它有很多限制。它们可用于获取图像或PDF数据。

我们可以将数据提供者用于：

1. 一个图像创建函数，如CGImageCreate,CGImageCreateWithPNGDataProvider或者CGImageCreateWithJPEGDataProvider。
2. PDF文档的创建函数CGPDFDocumentCreateWithProvider.
3. 函数CGImageSourceUpdateDataProvider用于更新已存在的图像源。

关于图像的更多信息，可查看“Bitmap Images andImage Masks”。

![image](http://cc.cocimg.com/bbs/attachment/thumb/Fid_6/6_38018_23d72ec7c568bf5.png)

## 获取Quartz 2D的数据

表10-2列出地从Quartz 2D中获取数据的方法。所有这些方法，除了CGPDFContextCreateWithURL，都返回一个图像目标(CGImageDestinationRef)或者是数据消费者(CGDataComsumerRef)。图像目标和数据消费者抽象的数据写入工作，让Quartz来处理细节。

一个图像目标是获取Quartz数据的首先方法。与图像源一样，图像目标也可以表示很多图像数据，如一个单独图片、多个图片、缩略图、图像属性或者图片文件。在获取到CGImageDestinationRef后，我们可以完成以下工作：
 
1. 使用函数CGImageDestinationAddImage或者CGImageDestinationAddImageFromSource添加一个图像(CGImageRef)到目标中。一个CGImageRef表示一个图片。
2. 使用函数CGImageDestinationSetProperties设置属性
3. 使用函数CGImageDestinationCopyTypeIdentifiers和CGImageDestinationGetTypeID从图像目标中获取信息。

函数CGPDFContextCreateWithURL可以方便地将PDF数据写入URL指定的位置。

数据消费者是一种老的机制，有很多限制。它们用于写图像或PDF数据。我们可以将数据消费者用于：

1. PDF上下文创建函数CGPDFContextCreate。该函数返回一个图形上下文，用于记录一系列的PDF绘制命令。
2. 函数CGImageDestinationCreateWithDataConsumer，用于从数据消费者中创建图像目标。

关于图像的更多信息，可查看“Bitmap Images andImage Masks”。

![image](http://cc.cocimg.com/bbs/attachment/thumb/Fid_6/6_38018_ad38140dfa05446.png)