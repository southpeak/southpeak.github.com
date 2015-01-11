---

layout: post

title: "源码篇：Mantle"

date: 2015-01-11 22:01:00 +0800

comments: true

categories: iOS

---

Mantle是一个用于简化Cocoa或Cocoa Touch程序中model层的第三方库。通常我们的应该中都会定义大量的model来表示各种数据结构，而这些model的初始化和编码解码都需要写大量的代码。而Mantle的优点在于能够大大地简化这些代码。

Mantle源码中最主要的内容包括：

1. MTLModel类：通常是作为我们的Model的基类，该类提供了一些默认的行为来处理对象的初始化和归档操作，同时可以获取到对象所有属性的键值集合。
2. MTLJSONAdapter类：用于在MTLModel对象和JSON字典之间进行相互转换，相当于是一个适配器。
3. MTLJSONSerializing协议：需要与JSON字典进行相互转换的MTLModel的子类都需要实现该协议，以方便MTLJSONApadter对象进行转换。

在此就以这三者作为我们的分析点。

## 基类MTLModel

MTLModel是一个抽象类，它主要提供了一些默认的行为来处理对象的初始化和归档操作。

### 初始化

MTLModel默认的初始化方法-init并没有做什么事情，只是调用了下[super init]。而同时，它提供了一个另一个初始化方法：

	- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;

其中参数dictionaryValue是一个字典，它包含了用于初始化对象的key-value对。我们来看下它的具体实现：

	- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
		...
	
		for (NSString *key in dictionary) {

			// 1. 将value标记为__autoreleasing，这是因为在MTLValidateAndSetValue函数中，
			//	  可以会返回一个新的对象存在在该变量中
			__autoreleasing id value = [dictionary objectForKey:key];
			
			// 2. value如果为NSNull.null，会在使用前将其转换为nil
			if ([value isEqual:NSNull.null]) value = nil;
	
			// 3. MTLValidateAndSetValue函数利用KVC机制来验证value的值对于key是否有效，
			//	  如果无效，则使用使用默认值来设置key的值。
			//	  这里同样使用了对象的KVC特性来将value值赋值给model对应于key的属性。
			//	  有关MTLValidateAndSetValue的实现可参考源码，在此不做详细说明。
			BOOL success = MTLValidateAndSetValue(self, key, value, YES, error);
			if (!success) return nil;
		}
	
		...
	}
	
子类可以重写该方法，以在设置完对象的属性后做进一步的处理或初始化工作，不过需要记住的是：应该通过super来调用父类的实现。

### 获取属性的键(key)、值(value)

MTLModel类提供了一个类方法+propertyKeys，该方法返回所有@property声明的属性所对应的名称字符串的一个集合，但不包括只读属性和MTLModel自身的属性。在这个类方法会去遍历model的所有属性，如果属性是非只读且其ivar值不为NULL，则获取到表示属性名的字符串，并将其放入到集合中，其实现如下：

	+ (NSSet *)propertyKeys {
		// 1. 如果对象中已有缓存的属性名的集合，则直接返回缓存。该缓存是放在一个关联对象中。
	    NSSet *cachedKeys = objc_getAssociatedObject(self, MTLModelCachedPropertyKeysKey);
	    if (cachedKeys != nil) return cachedKeys;
	    
	    NSMutableSet *keys = [NSMutableSet set];
	    
	    // 2. 遍历对象所有的属性
	    //	  enumeratePropertiesUsingBlock方法会沿着superclass链一直向上遍历到MTLModel，
	    //	  查找当前model所对应类的继承体系中所有的属性(不包括MTLModel)，并对该属性执行block中的操作。
	    //	  有关enumeratePropertiesUsingBlock的实现可参考源码，在此不做详细说明。
	    [self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
	        mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
	        @onExit {
	            free(attributes);
	        };
	        
	        // 3. 过滤只读属性和ivar为NULL的属性
	        if (attributes->readonly && attributes->ivar == NULL) return;
	        
	        // 4. 获取属性名字符串，并存储到集合中
	        NSString *key = @(property_getName(property));
	        [keys addObject:key];
	    }];
	    
	    // 5. 将集合缓存到关联对象中。
	    objc_setAssociatedObject(self, MTLModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);
	    
	    return keys;
	}
	
有了上面这个类方法，要想获取到对象中所有属性及其对应的值就方法了。为此MTLModel提供了一个只读属性dictionaryValue来取一个包含当前model所有属性及其值的字典。如果属性值为nil，则会用NSNull来代替。另外该属性不会为nil。

	@property (nonatomic, copy, readonly) NSDictionary *dictionaryValue;
	
	// 实现
	- (NSDictionary *)dictionaryValue {
	    return [self dictionaryWithValuesForKeys:self.class.propertyKeys.allObjects];
	}
	
### 合并对象

合并对象是指将两个MTLModel对象按照自定义的方法将其对应的属性值进行合并。为此，在MTLModel定义了以下方法：

	- (void)mergeValueForKey:(NSString *)key fromModel:(MTLModel *)model;
	
该方法将当前对象指定的key属性的值与model参数对应的属性值按照指定的规则来进行合并，这种规则由我们自定义的-merge<Key>FromModel:方法来确定。如果我们的子类中实现了-merge<Key>FromModel:方法，则会调用它；如果没有找到，且model不为nil，则会用model的属性的值来替代当前对象的属性的值。具体实现如下：

	- (void)mergeValueForKey:(NSString *)key fromModel:(MTLModel *)model {
	    NSParameterAssert(key != nil);
	    
	    // 1. 根据传入的key拼接"merge<Key>FromModel:"字符串，并从该字符串中获取到对应的selector
	    //	  如果当前对象没有实现-merge<Key>FromModel:方法，且model不为nil，则用model的属性值
	    //	  替代当前对象的属性值
	    //
	    // 	  MTLSelectorWithCapitalizedKeyPattern函数以C语言的方式来拼接方法字符串，具体实现请
	    //	  参数源码，在此不详细说明
	    SEL selector = MTLSelectorWithCapitalizedKeyPattern("merge", key, "FromModel:");
	    if (![self respondsToSelector:selector]) {
	        if (model != nil) {
	            [self setValue:[model valueForKey:key] forKey:key];
	        }
	        
	        return;
	    }
	    
	    // 2. 通过NSInvocation方式来调用对应的-merge<Key>FromModel:方法。
	    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	    invocation.target = self;
	    invocation.selector = selector;
	    
	    [invocation setArgument:&model atIndex:2];
	    [invocation invoke];
	}
	
此外，MTLModel还提供了另一个方法来合并两个对象所有的属性值，即：

	- (void)mergeValuesForKeysFromModel:(MTLModel *)model;
	
需要注意的是model必须是当前对象所属类或其子类。

### 归档对象(Archive)

Mantle将对MTLModel的编码解码处理都放在了MTLModel的NSCoding分类中进行处理了，该分类及相关的定义都放在MTLModel+NSCoding文件中。

对于不同的属性，在编码解码过程中可能需要区别对待，为此Mentle定义了枚举MTLModelEncodingBehavior来确定一个MTLModel属性被编码到一个归档中的行为。其定义如下：

	typedef enum : NSUInteger {
	    MTLModelEncodingBehaviorExcluded = 0,			// 属性绝不应该被编码
	    MTLModelEncodingBehaviorUnconditional,			// 属性总是应该被编码
	    MTLModelEncodingBehaviorConditional,			// 对象只有在其它地方被无条件编码时才应该被编码。这只适用于对象属性
	} MTLModelEncodingBehavior;
	
具体每个属性的归档行为我们可以在+encodingBehaviorsByPropertyKey类方法中设置。MTLModel类为我们提供了一个默认实现，如下：

	+ (NSDictionary *)encodingBehaviorsByPropertyKey {
		// 1. 获取所有属性键值
	    NSSet *propertyKeys = self.propertyKeys;
	    NSMutableDictionary *behaviors = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];
	    
	    // 2. 对每一个属性进行处理
	    for (NSString *key in propertyKeys) {
	        objc_property_t property = class_getProperty(self, key.UTF8String);
	        NSAssert(property != NULL, @"Could not find property \"%@\" on %@", key, self);
	        
	        mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
	        @onExit {
	            free(attributes);
	        };
	        
	        // 3. 当属性为weak时，默认设置为MTLModelEncodingBehaviorConditional，否则默认为MTLModelEncodingBehaviorUnconditional，设置完后，将其封装在NSNumber中并放入字典中。
	        MTLModelEncodingBehavior behavior = (attributes->weak ? MTLModelEncodingBehaviorConditional : MTLModelEncodingBehaviorUnconditional);
	        behaviors[key] = @(behavior);
	    }
	    
	    return behaviors;
	}
	
任何不在该返回字典中的属性都不会被归档。子类可以根据自己的需要来指定各属性的归档行为。但在实际时应该通过super来调用父类的实现。

而为了从归档中解码指定的属性，Mantle提供了以下方法：

	- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion;
	
默认情况下，该方法会查找当前对象中类似于**-decode<Key>WithCoder:modelVersion:**的方法，如果找到便会调用相应方法，并按照自定义的方式来处理属性的解码。如果我们没有实现自定义的方法或者coder不需要安全编码，则会对指定的key调用-[NSCoder decodeObjectForKey:]方法。其具体实现如下：

	- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
	    ...
	    
	    SEL selector = MTLSelectorWithCapitalizedKeyPattern("decode", key, "WithCoder:modelVersion:");
	    // 1. 如果自定义了-decode<Key>WithCoder:modelVersion:方法，则通过NSInvocation来调用方法
	    if ([self respondsToSelector:selector]) {
	        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	        invocation.target = self;
	        invocation.selector = selector;
	        [invocation setArgument:&coder atIndex:2];
	        [invocation setArgument:&modelVersion atIndex:3];
	        [invocation invoke];
	        
	        __unsafe_unretained id result = nil;
	        [invocation getReturnValue:&result];
	        return result;
	    }
	    
	    @try {
	    	// 2. 如果没有找到自定义的-decode<Key>WithCoder:modelVersion:方法，
	    	// 	  则走以下流程。
	    	//
	    	// coderRequiresSecureCoding方法的具体实现请参数源码
	        if (coderRequiresSecureCoding(coder)) {
	        	// 3. 如果coder要求安全编码，则会从需要安全编码的字典中取出属性所对象的类型，然后根据指定
	        	//	  类型来对属性进行解码操作。
	        	//	  为此，MTLModel提供了类方法allowedSecureCodingClassesByPropertyKey，来获取
	        	//	  类的对象包含的所有需要安全编码的属性及其对应的类的字典。该方法首先会查看是否已有
	        	//	  缓存的字典，如果没有则遍历类的所有属性。首先过滤掉那些不需要编码的属性，
	        	//	  然后遍历剩下的属性，如果是非对象类型或类类型，则其对应的类型设定为NSValue，
	        	//	  如果是这两者，则对应的类型即为相应类型。
	        	//	  该方法的具体实现请参考源代码。
	            NSArray *allowedClasses = self.class.allowedSecureCodingClassesByPropertyKey[key];
	            NSAssert(allowedClasses != nil, @"No allowed classes specified for securely decoding key \"%@\" on %@", key, self.class);
	            
	            return [coder decodeObjectOfClasses:[NSSet setWithArray:allowedClasses] forKey:key];
	        } else {
	        	// 4. 不需要安全编码
	            return [coder decodeObjectForKey:key];
	        }
	    } @catch (NSException *exception) {
	        ...
	    }
	}

当然，所有的编码解码工作还得需要我们实现-initWithCoder:和-encodeWithCoder:两个方法来完成。我们在定义MTLModel的子类时，可以根据自己的需要来对特定的属性进行处理，不过最好调用super的实现来执行父类的操作。MTLModel对这两个方法的实现请参考源码，在此不多作说明。

## 适配器MTLJSONApadter

为了便于在MTLModel对象和JSON字典之间进行相互转换，Mantle提供了类MTLJSONApadter，作为这两者之间的一个适配器。

### MTLJSONSerializing协议

Mantle定义了一个协议MTLJSONSerializing，那些需要与JSON字典进行相互转换的MTLModel的子类都需要实现该协议，以方便MTLJSONApadter对象进行转换。这个协议中定义了三个方法，具体如下：

	@protocol MTLJSONSerializing
	@required
	
	+ (NSDictionary *)JSONKeyPathsByPropertyKey;
	
	@optional
	
	+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key;
	+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary;
	
	@end

这三个方法都是类方法。其中+JSONKeyPathsByPropertyKey是必须实现的，它返回的字典指定了如何将对象的属性映射到JSON中不同的key path(字符串值或NSNull)中。任何不在此字典中的属性被认为是与JSON中使用的key值相匹配。而映射到NSNull的属性在JSON序列化过程中将不进行处理。

+JSONTransformerForKey:方法指定了如何将一个JSON值转换为指定的属性值。反过来，转换器也用于将属性值转换成JSON值。如果转换器实现了+<key>JSONTransformer方法，则MTLJSONAdapter会使用这个具体的方法，而不使用+JSONTransformerForKey:方法。另外，如果不需要执行自定义的转换，则返回nil。

重写+classForParsingJSONDictionary:方法可以将当前Model解析为一个不同的类对象。这对象类簇是非常有用的，其中抽象基类将被传递给-[MTLJSONAdapter initWithJSONDictionary:modelClass:]方法，而实例化的则是子类。

如果我们希望MTLModel的一个子类能使用MTLJSONApadter来进行转换，则需要实现这个协议，并实现相应的方法。

### 初始化

MTLJSONApadter对象有一个只读属性，该属性即为适配器需要处理的MTLModel对象，其声明如下：

	@property (nonatomic, strong, readonly) MTLModel<MTLJSONSerializing> *model;
	
可见该对象必须是实现了MTLJSONSerializing协议的MTLModel对象。该属性是只读的，因此它只能通过初始化方法来初始化。

MTLJSONApadter对象不能通过-init来初始化，这个方法会直接断言。而是需要通过类提供的两个初始化方法来初始化，如下：

	- (id)initWithJSONDictionary:(NSDictionary *)JSONDictionary modelClass:(Class)modelClass error:(NSError **)error;
	
	- (id)initWithModel:(MTLModel<MTLJSONSerializing> *)model;
	
其中-(id)initWithJSONDictionary:modelClass:error:是使用一个字典和需要转换的类来进行初始化。字典JSONDictionary表示一个JSON数据，这个字典需要符合NSJSONSerialization返回的格式。如果该参数为空，则方法返回nil，且返回带有MTLJSONAdapterErrorInvalidJSONDictionary码的error对象。该方法的具体实现如下：

	- (id)initWithJSONDictionary:(NSDictionary *)JSONDictionary modelClass:(Class)modelClass error:(NSError **)error {
		...
	
		if (JSONDictionary == nil || ![JSONDictionary isKindOfClass:NSDictionary.class]) {
			...
			return nil;
		}
	
		if ([modelClass respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
			modelClass = [modelClass classForParsingJSONDictionary:JSONDictionary];
			if (modelClass == nil) {
				...
	
				return nil;
			}
	
			...
		}
	
		...
	
		_modelClass = modelClass;
		_JSONKeyPathsByPropertyKey = [[modelClass JSONKeyPathsByPropertyKey] copy];
	
		NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];
	
		NSSet *propertyKeys = [self.modelClass propertyKeys];
	
		// 1. 检验model的+JSONKeyPathsByPropertyKey中字典key-value对的有效性
		for (NSString *mappedPropertyKey in self.JSONKeyPathsByPropertyKey) {
			// 2. 如果model对象的属性不包含+JSONKeyPathsByPropertyKey返回的字典中的某个属性键值
			//	  则返回nil。即+JSONKeyPathsByPropertyKey中指定的属性键值必须是model对象所包含
			// 	  的属性。
			if (![propertyKeys containsObject:mappedPropertyKey]) {
				...
				return nil;
			}
	
			id value = self.JSONKeyPathsByPropertyKey[mappedPropertyKey];
	
			// 3. 如果属性不是映射到一个JSON关键路径或者是NSNull，也返回nil。
			if (![value isKindOfClass:NSString.class] && value != NSNull.null) {
				...
				return nil;
			}
		}
	
		for (NSString *propertyKey in propertyKeys) {
			NSString *JSONKeyPath = [self JSONKeyPathForPropertyKey:propertyKey];
			if (JSONKeyPath == nil) continue;
	
			id value;
			@try {
				value = [JSONDictionary valueForKeyPath:JSONKeyPath];
			} @catch (NSException *ex) {
				...
	
				return nil;
			}
	
			if (value == nil) continue;
	
			@try {
				// 4. 获取一个转换器，
				//	  如上所述，+JSONTransformerForKey:会先去查看是否有+<key>JSONTransformer方法，
				//    如果有则会使用这个具体的方法，如果没有，则调用相应的+JSONTransformerForKey:方法
				//	  该方法具体实现请参考源码
				NSValueTransformer *transformer = [self JSONTransformerForKey:propertyKey];
				if (transformer != nil) {
					
					// 5. 获取转换器转换生的值
					if ([value isEqual:NSNull.null]) value = nil;
					value = [transformer transformedValue:value] ?: NSNull.null;
				}
	
				dictionaryValue[propertyKey] = value;
			} @catch (NSException *ex) {
				...
	
				return nil;
			}
		}
	
		// 6. 初始化_model
		_model = [self.modelClass modelWithDictionary:dictionaryValue error:error];
		if (_model == nil) return nil;
	
		return self;
	}

另外，MTLJSONApadter还提供了几个类方法来创建一个MTLJSONApadter对象，如下：

	+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error;
	
	+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray error:(NSError **)error;
	
	+ (NSDictionary *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model;

具体实现可参考源码。

### 从对象中获取JSON数据

从MTLModel对象中获取JSON数据是上述初始化过程中的一个逆过程。该过程由-JSONDictionary方法来实现，具体如下：

	- (NSDictionary *)JSONDictionary {
		NSDictionary *dictionaryValue = self.model.dictionaryValue;
		NSMutableDictionary *JSONDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionaryValue.count];
	
		[dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
			NSString *JSONKeyPath = [self JSONKeyPathForPropertyKey:propertyKey];
			if (JSONKeyPath == nil) return;
	
			// 1. 获取属性的值
			NSValueTransformer *transformer = [self JSONTransformerForKey:propertyKey];
			if ([transformer.class allowsReverseTransformation]) {
				if ([value isEqual:NSNull.null]) value = nil;
				value = [transformer reverseTransformedValue:value] ?: NSNull.null;
			}
	
			NSArray *keyPathComponents = [JSONKeyPath componentsSeparatedByString:@"."];
	
			// 2. 对于嵌套属性值的设置，会先从keypath中获取每一层属性，
			//	  如果当前层级的obj中没有该属性，则为其设置一个空字典；然后再进入下一层级，依此类推
			//	  最后设置如下形式的字典: @{@"nested": @{@"name": @"foo"}}
			id obj = JSONDictionary;
			for (NSString *component in keyPathComponents) {
				if ([obj valueForKey:component] == nil) {
					[obj setValue:[NSMutableDictionary dictionary] forKey:component];
				}
	
				obj = [obj valueForKey:component];
			}
	
			[JSONDictionary setValue:value forKeyPath:JSONKeyPath];
		}];
	
		return JSONDictionary;
	}
	
从上可以看出，该方法实际上最终获得的是一个字典。而获得字典后，再将其序列化为JSON串就容易了。

MTLJSONApadter也提供了一个简便的方法，来从一个model中获取一个JSON字典，其定义如下：

	+ (NSDictionary *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model;
	
### MTLManagedObjectAdapter

为了适应Core Data，Mantle专门定义了MTLManagedObjectAdapter类。该类用作MTLModel对象与NSManagedObject对象之前的转换。具体的我们在此不详细描述。

## 技术点总结

Mantle的功能主要是进行对象间数据的转换：即如何在一个MTLModel和一个JSON字典中进行数据的转换。因此，所使用的技术大都是Cocoa Foundation提供的功能。除了对于Core Data的处理之外，主要用到的技术的有如下几条：

1. KVC的应用：这主要体现在对MTLModel子类的属性赋值中，通过KVC机制来验证值的有效性并为属性赋值。
2. NSValueTransform：这主要用于对JSON值转换为属性值的处理，我们可以自定义转换器来满足我们自己的转换需求。
3. NSInvocation：这主要用于统一处理针对特定key值的一些方法的调用。比如-merge<Key>FromModel:这一类方法。
4. Run time函数的使用：这主要用于对从一个字符串中获取到方法对应的字符串，然后通过sel_registerName函数来注册一个selector。

当然在Mantle中还会涉及到其它的一些技术点，在此不多做叙述。

## 参考

1. [Mantle工程](https://github.com/Mantle/Mantle)
