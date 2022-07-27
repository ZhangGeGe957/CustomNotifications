# 一、通知
## 1.概要
通知都熟的不能再熟了，以前也都写过[通知传值](https://blog.csdn.net/m0_55124878/article/details/119346945?spm=1001.2014.3001.5502)，这里就不过多赘述了。

- 观察者和被观察者都无需知晓对方，只需要通过标记在`NSNotificationCenter`中找到监听该通知所对应的类，从而调用该类的方法。
- 并且在`NSNotificationCenter`中，观察者可以只订阅某一特定的通知，并对齐做出相应操作，而不用对某一个类发的所有通知都进行更新操作。
- `NSNotificationCenter`对观察者的调用不是随机的，而是遵循注册顺序一一执行的，并且在该线程内是同步的。

## 2.通知使用步骤
总体分为三步走：
#### 2.1 在要传递参数的地方，发送通知给通知中心
```objectivec
[[NSNotificationCenter defaultCenter] postNotificationName:@"temp" object:nil userInfo:@{@"content": self.myTextField.text}];
```
#### 2.2 在接收参数的地方注册通知，并实现定义方法
```objectivec
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(Notificate:) name:@"temp" object:nil];
```
### 2.3 在不需要通知的时候，移除通知
```objectivec
[[NSNotificationCenter defaultCenter] removeObserver:self];
```

这都很简单，不是通知的重点，通知的重点是如何自己实现通知。

## 3.自定义实现通知功能
首先创建一个自定义文件`ZJQNotificationCenter`，继承自`NSObject`，用作自定义通知的类，因为通知是可以实现多对多关系的，所以我们在这个类中还需要定义一个可变的字典属性，用来存储注册的通知。又因为注册的通知数据需要一直保存下来，所以我们使用单例来完成这一操作，保证我们在想要访问已经注册的通知的时候，其数据是存在的。
```objectivec
@interface ZJQNotificationCenter ()

// 因为通知是多对多的关系，所以这里定义一个可变字典用来存储对应关系
@property (nonatomic, strong) NSMutableDictionary *classDictionary;

@end
@implementation ZJQNotificationCenter

// 实现默认的通知中心，是个单例，防止其自动销毁
+ (instancetype)defaultCenter {
    // 定义一个锁
    static dispatch_once_t onceToken;
    // 创建通知中心的单例，同时初始化其中数据
    static ZJQNotificationCenter *notificationCenter = nil;
    dispatch_once(&onceToken, ^{
        notificationCenter = [ZJQNotificationCenter new];
        notificationCenter.classDictionary = [NSMutableDictionary dictionary];
    });
    return notificationCenter;
}
@end
```
因为我们使用通知的目的就是为了传递参数，供别的类来使用，所以我们这里再定义一个专门保存通知的类`ZJQNotification`，其中包含通知的必要信息：通知的名称、通知传递的参数信息、以及一个`id`类型的`object`。因为这是需要给外界透露的接口，外界不能对其进行写操作，所以为只读（`readOnly`）属性，除了这三个参数，当然还得需要一个快速的初始化类的方法：
```objectivec
// 通知类，用来保存通知及其参数
@interface ZJQNotification : NSObject

// 对外有三个只读属性
@property (readonly, copy) NSNotificationName name; // 通知名
@property (nullable, readonly, copy) NSDictionary *userInfo; // 参数信息
@property (nullable, readonly, retain) id object; // 接收通知的对象

// 快速初始化类参数的方法
- (instancetype)initWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end
```
该通知类中的三个参数是对外只读的，内部可以进行修改，所以我们在内部重写属性，实现可读可写，同时实现该类快速初始化方法：
```objectivec
@interface ZJQNotification()
// 在内部可修改这三个属性
@property (nonatomic, copy) NSString *name; // 通知名
@property (nonatomic, copy) NSDictionary *userInfo; // 参数信息
@property (nonatomic, retain) id object; // 接收通知的对象

@end
 
// 通知类，用来保存通知及其参数
@implementation ZJQNotification

// 快速初始化类参数的方法
- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo {
    ZJQNotification *notification = [ZJQNotification new];
    notification.name = name;
    notification.object = object;
    notification.userInfo = userInfo;
    return notification;
}

@end
```
接着我们在之前定义的通知中心`ZJQNotificationCenter`中再定义通知常用的对外开放的接口，注册通知、发送通知、删除通知：
```objectivec
// 通知中心
@interface ZJQNotificationCenter : NSObject

// 默认的通知中心
+ (instancetype)defaultCenter;

// 添加通知中心
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString *)aName object:(nullable id)anObject;

// 发送通知
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject;
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;

// 移除通知
- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject;

@end
```
接着就一个一个实现，首先是添加通知的逻辑，我们在添加、调用通知的时候，需要知道三个必要信息，一个是创建该通知的实例类，一个是通知要调用的自定义方法，以及一个`object`。所以我们需要将这三个信息保存起来，一起保存到刚刚我们创建的通知中心单例的`classDictionary`属性中，为了方便我们后续的查找，所以该属性的`key`我们使用注册通知时通知的名称标识，因为一个通知可能对应多个类，所以这里我们`value`使用一个数组，该数组中的每个变量又是一个字典，其中的内容就是上边所说的三个参数：
```objectivec
// 添加通知中心
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString *)aName object:(nullable id)anObject {
    // 以通知名为key来设置value并保存在通知中心
    // 从通知中心获取该通知名的所有注册信息
    NSMutableArray *array = self.classDictionary[aName];
    // 如果通知中心没有储存过该通知名的信息，就新建
    if (!array) {
        array = [NSMutableArray array];
    }
    // 向数组中添加传递过来的信息
    [array addObject:@{@"class": observer, @"selector": NSStringFromSelector(aSelector), @"object": anObject ? : [NSNull null]}];
    // 将更新过的数组重新添加到通知中心
    [self.classDictionary setObject:array forKey:aName];
}
```
发送通知的逻辑，其实就是通过发送过来的通知名标识`aName`在`classDictionary`属性中查找对应的通知信息，然后依次使用`objc_msgSend`发送消息，从而达到传值的目的，这里我们用系统封装好的`NSInvocation`类进行调用：
```objectivec
// 发送通知
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject {
    [self postNotificationName:aName object:anObject userInfo:nil];
}

- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo {
    // 通过发送通知的通知名，找到在通知中心保存的该通知名的所有注册的类的信息
    NSMutableArray *array = self.classDictionary[aName];
    // 通过获取到的信息中的方法名和类信息，来逐一使用msgSend发送消息给目标类
    for (NSDictionary *mapDictionary in array) {
        // 当mapDictionary中的object与anObject一致或者接收者为null时，才调用方法，确保信息无误不会发错
        if ([mapDictionary[@"object"] isEqual:anObject] || [mapDictionary[@"object"] isKindOfClass:[NSNull class]]) {
            // NSInvocation;用来包装方法和对应的对象，它可以存储方法的名称，对应的对象，对应的参数,
            /*
             NSMethodSignature：签名：再创建NSMethodSignature的时候，必须传递一个签名对象，签名对象的作用：用于获取参数的个数和方法的返回值
             */
            // 创建签名对象的时候不是使用NSMethodSignature这个类创建，而是方法属于谁就用谁来创建，创建当前访问信息的class类中的selector方法的签名
            NSMethodSignature *signature = [[mapDictionary[@"class"] class] instanceMethodSignatureForSelector:NSSelectorFromString(mapDictionary[@"selector"])];
            
            // 1、通过创建的方法签名，创建NSInvocation对象
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            // 给NSInvocation对象设置实现该selector方法的类信息
            invocation.target = mapDictionary[@"class"];
            // 给NSInvocation对象设置调用的方法的信息
            invocation.selector = NSSelectorFromString(mapDictionary[@"selector"]);
            // 包装要使用通知传递的信息，通过消息转发机制来实现跨界面传值
            // 注意：设置参数的索引时不能从0开始，因为0已经被self占用，1已经被_cmd占用
            ZJQNotification *notification = [[ZJQNotification alloc] initWithName:aName object:anObject userInfo:aUserInfo];
            [invocation setArgument:&notification atIndex:2];
            /* 第一个参数：需要给指定方法传递的值
                   第一个参数需要接收一个指针，也就是传递值的时候需要传递地址 */
            // 第二个参数：需要给指定方法的第几个参数传值
            
            // 2、调用NSInvocation对象的invoke方法
            // 只要调用invocation的invoke方法，就代表需要执行NSInvocation对象中制定对象的指定方法，并且传递指定的参数
            [invocation invoke];
        }
    }
}
```
移除通知时，通过给定的通知的信息，在`classDictionary`中删除对应的数据即可：
```objectivec
// 移除通知
// 找到对应的类，在classDictionary中删除即可
// 全部移除
- (void)removeObserver:(id)observer {
    // 创建一个临时字典，存放删除完了的数据，最后用这个字典更新classDictionary数据
    NSMutableDictionary *tempDictionary = [NSMutableDictionary dictionary];
    // 枚举遍历
    [self.classDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableArray *tempArray = [obj mutableCopy];
        for (NSDictionary * mapDictionary in obj) {
            // 判断该类是不是observer的类，是就删除
            if ([mapDictionary[@"class"] isKindOfClass:[observer class]]) {
                [tempArray removeObject:mapDictionary];
            }
        }
        // 删除完了，添加到tempDictionary中
        [tempDictionary setObject:tempArray forKey:key];
    }];
    // 更新classDictionary数据
    self.classDictionary = tempDictionary;
}

// 根据通知名移除
- (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    // 获取该通知名注册的所有信息
    NSMutableArray *array = self.classDictionary[aName];
    NSMutableArray *tempArray = [array mutableCopy];
    for (NSDictionary *mapDictionary in array) {
        // 判断该类是不是observer的类
        if ([mapDictionary[@"class"] isKindOfClass:[observer class]]) {
            // 如果该通知的接收方相等或者接收方不存在，再删除，确保不会误删
            if ([mapDictionary[@"object"] isEqual:anObject] || !anObject) {
                [tempArray removeObject:mapDictionary];
            }
        }
    }
    // 更新classDictionary数据
    [self.classDictionary setValue:tempArray forKey:aName];
}
```
到这里我们自定义通知就完成了，如果觉得我的讲述的不太清楚或者什么的，可以自己下载Demo看看：[自定义通知](https://github.com/ZhangGeGe957/CustomNotifications)
