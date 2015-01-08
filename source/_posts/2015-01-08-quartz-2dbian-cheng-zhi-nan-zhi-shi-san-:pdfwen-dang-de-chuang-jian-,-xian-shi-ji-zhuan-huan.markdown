---

layout: post

title: "Quartz 2D编程指南之十三：PDF文档的创建、显示及转换"

date: 2015-01-08 22:51:40 +0800

comments: true

categories: iOS

---

PDF文档存储依赖于分辨率的向量图形、文本和位图，并用于程序的一系列指令中。一个PDF文档可以包含多页的图形和文本。PDF可用于创建跨平台、只读的文档，也可用于绘制依赖于分辨率的图形。

Quartz为所有应用程序创建高保真的PDF文档，这些文档保留应用的绘制操作，如图13-1所示。PDF文档的结果将通过系统的其它部分或第三方法的产品来有针对性地进行优化。Quartz创建的PDF文档在Preview和Acrobat中都能正确的显示。

Figure 13-1  Quartz creates high-quality PDF documents

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/postscript_to_PDF.gif)

Quartz不仅仅只使用PDF作为它的数字页，它同样包含一些API来显示和生成PDF文件，及完成一些其它PDF相关的工作。

## 打开和查看PDF

Quartz提供了CGPDFDocumentRef数据类型来表示PDF文档。我们可以使用CGPDFDocumentCreateWithProvider或CGPDFDocumentCreateWithURL来创建CGPDFDocument对象。在创建CGPDFDocument对象后，我们可以将其绘制到图形上下文中。图13-2显示了在一个窗体中绘制PDF文档。

Figure 13-2  A PDF document

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rooster_up.gif)

代码清单13-1显示了如何创建一个CGPDFDocument对象及获取文档的页数。

Listing 13-1  Creating a CGPDFDocument object from a PDF file

	CGPDFDocumentRef MyGetPDFDocumentRef (const char *filename)
	{
	    CFStringRef path;
	    CFURLRef url;
	    CGPDFDocumentRef document;
	    size_t count;
	 
	    path = CFStringCreateWithCString (NULL, filename,
	                         kCFStringEncodingUTF8);
	    url = CFURLCreateWithFileSystemPath (NULL, path, 
	                        kCFURLPOSIXPathStyle, 0);
	    CFRelease (path);
	    document = CGPDFDocumentCreateWithURL (url);
	    CFRelease(url);
	    count = CGPDFDocumentGetNumberOfPages (document);
	    if (count == 0) {
	        printf("`%s' needs at least one page!", filename);
	        return NULL;
	    }
	    return document;
	}

代码清单显示了如何将一个PDF页绘制到图形上下文中。

Listing 13-2  Drawing a PDF page

	void MyDisplayPDFPage (CGContextRef myContext,
	                    size_t pageNumber,
	                    const char *filename)
	{
	    CGPDFDocumentRef document;
	    CGPDFPageRef page;
	 
	    document = MyGetPDFDocumentRef (filename);
	    page = CGPDFDocumentGetPage (document, pageNumber);
	    CGContextDrawPDFPage (myContext, page);
	    CGPDFDocumentRelease (document);
	}

## 为PDF页创建一个转换
Quartz提供了函数CGPDFPageGetDrawingTransform来创建一个仿射变换，该变换基于将PDF页的BOX映射到指定的矩形中。函数原型是：

	CGAffineTransform CGPDFPageGetDrawingTransform (
	        CGPPageRef page,
	        CGPDFBox box,
	        CGRect rect,
	        int rotate,
	        bool preserveAspectRatio
	);


该函数通过如下算法来返回一个仿射变换：

1. 将在box参数中指定的PDF box的类型相关的矩形(media, crop, bleed, trim, art)与指定的PDF页的/MediaBox入口求交集。相交的部分即为一个有效的矩形(effectiverectangle)。
2. 将effective rectangle旋转参数/Rotate入口指定的角度。
3. 将得到的矩形放到rect参数指定的中间。
4. 如果rotate参数是一个非零且是90的倍数，函数将effective rectangel旋转该值指定的角度。正值往右旋转；负值往左旋转。需要注意的是我们传入的是角度，而不是弧度。记住PDF页的/Rotate入口也包含一个旋转，我们提供的rotate参数是与/Rotate入口接合在一起的。
5. 如果需要，可以缩放矩形，从而与我们提供的矩形保持一致。
6. 如果我们通过传递true值给preserveAspectRadio参数以指定保持长宽比，则最后的矩形将与rect参数的矩形的边一致。

【注：上面这段翻译得不是很好】

例如，我们可以使用这个函数来创建一个与图13-3类似的PDF浏览程序。如果我们提供一个Rotate Left/Rotate Right属性，则可以调用CGPDFPageGetDrawingTransform来根据当前的窗体大小和旋转设置计算出适当的转换。

Figure 13-3  A PDF page rotated 90 degrees to the right

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/rooster_rotate.gif)
 
程序清单13-3显示了为一个PDF页创建及应用仿射变换，然后绘制PDF。

Listing 13-3  Creating an affine transform for a PDF page

	void MyDrawPDFPageInRect (CGContextRef context,
	                    CGPDFPageRef page,
	                    CGPDFBox box,
	                    CGRect rect,
	                    int rotation,
	                    bool preserveAspectRatio)
	{
	    CGAffineTransform m;
	 
	    m = CGPDFPageGetDrawingTransform (page, box, rect, rotation,
	                                    preserveAspectRato);
	    CGContextSaveGState (context);
	    CGContextConcatCTM (context, m);
	    CGContextClipToRect (context,CGPDFPageGetBoxRect (page, box));
	    CGContextDrawPDFPage (context, page);
	    CGContextRestoreGState (context);
	}

## 创建PDF文件

使用Quartz创建PDF与绘制其它图形上下文一下简单。我们指定一个PDF文件地址，设置一个PDF图形上下文，并使用与其它图形上下文一样的绘制程序。如代码清单13-4所示的MyCreatePDFFile函数，显示了创建一个PDF的所有工作。

注意，代码在CGPDFContextBeginPage和CGPDFContextEndPage中来绘制PDF。我们可以传递一个CFDictionary对象来指定页属性，包括media, crop, bleed,trim和art boxes。

Listing 13-4  Creating a PDF file

	void MyCreatePDFFile (CGRect pageRect, const char *filename)
	{
	    CGContextRef pdfContext;
	    CFStringRef path;
	    CFURLRef url;
	    CFDataRef boxData = NULL;
	    CFMutableDictionaryRef myDictionary = NULL;
	    CFMutableDictionaryRef pageDictionary = NULL;
	 
	    path = CFStringCreateWithCString (NULL, filename, 
	                                kCFStringEncodingUTF8);
	    url = CFURLCreateWithFileSystemPath (NULL, path, 
	                     kCFURLPOSIXPathStyle, 0);
	    CFRelease (path);
	    myDictionary = CFDictionaryCreateMutable(NULL, 0,
	                        &kCFTypeDictionaryKeyCallBacks,
	                        &kCFTypeDictionaryValueCallBacks); 
	    CFDictionarySetValue(myDictionary, kCGPDFContextTitle, CFSTR("My PDF File"));
	    CFDictionarySetValue(myDictionary, kCGPDFContextCreator, CFSTR("My Name"));
	    pdfContext = CGPDFContextCreateWithURL (url, &pageRect, myDictionary); 
	    CFRelease(myDictionary);
	    CFRelease(url);
	    pageDictionary = CFDictionaryCreateMutable(NULL, 0,
	                        &kCFTypeDictionaryKeyCallBacks,
	                        &kCFTypeDictionaryValueCallBacks); 
	    boxData = CFDataCreate(NULL,(const UInt8 *)&pageRect, sizeof (CGRect));
	    CFDictionarySetValue(pageDictionary, kCGPDFContextMediaBox, boxData);
	    CGPDFContextBeginPage (pdfContext, pageDictionary); 
	    myDrawContent (pdfContext);
	    CGPDFContextEndPage (pdfContext);
	    CGContextRelease (pdfContext);
	    CFRelease(pageDictionary); 
	    CFRelease(boxData);
	}


## 添加链接

我们可以在PDF上下文中添加链接和锚点。Quartz提供了三个函数，每个函数都以PDF图形上下文作为参数，还有链接的信息：

1. CGPDFContextSetURLForRect可以让我们指定在点击当前PDF页中的矩形时打开一个URL。
2. CGPDFContextSetDestinationForRect指定在点击当前PDF页中的矩形区域时设置目标以进行跳转。我们需要提供一个目标名。
3. CGPDFContextAddDestinationAtPoint指定在点击当前PDF页中的一个点时设置目标以进行跳转。我们需要提供一个目标名。

## 保护PDF内容

为了保护PDF内容，我们可以在辅助字典中指定一些安全选项并传递给CGPDFContextCreate。我们可以通过包含如下关键字来设置所有者密码、用户密码、PDF是否可以被打印或拷贝：

1. kCGPDFContextOwnerPassword: 定义PDF文档的所有者密码。如果指定该值，则文档使用所有者密码来加密；否则文档不加密。该关键字的值必须是ASCII编码的CFString对象。只有前32位是用于密码的。该值没有默认值。如果该值不能表示成ASCII，则无法创建文档并返回NULL。Quartz使用40-bit加密。
2. kCGPDFContextUserPassword: 定义PDF文档的用户密码。如果文档加密了，则该值是文档的用户密码。如果没有指定，则用户密码为空。该关键字的值必须是ASCII编码的CFString对象。只有前32位是用于密码的。如果该值不能表示成ASCII，则无法创建文档并返回NULL。
3. kCGPDFContextAllowsPrinting:指定当使用用户密码锁定时文档是否可以打印。该值必须是CFBoolean对象。默认值是kCGBooleanTrue。
4. kCGPDFContextAllowsCopying: 指定当使用用户密码锁定时文档是否可以拷贝。该值必须是CFBoolean对象。默认值是kCGBooleanTrue。

代码清单14-4(下一章)显示了确认PDF文档是否被锁定，及用密码打开文档。