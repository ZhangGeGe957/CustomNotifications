//
//  ZJQNotificationCenter.m
//  通知
//
//  Created by 张佳乔 on 2022/7/27.
//

#import "ZJQNotificationCenter.h"

#pragma mark - ZJQNotificationCenter
// 通知中心
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
            /* 第一个参数：需要给指定方法传递的值
                   第一个参数需要接收一个指针，也就是传递值的时候需要传递地址 */
            // 第二个参数：需要给指定方法的第几个参数传值
            // 包装要使用通知传递的信息，通过消息转发机制来实现跨界面传值
            // 注意：设置参数的索引时不能从0开始，因为0已经被self占用，1已经被_cmd占用
            ZJQNotification *notification = [[ZJQNotification alloc] initWithName:aName object:anObject userInfo:aUserInfo];
            [invocation setArgument:&notification atIndex:2];
            
            // 2、调用NSInvocation对象的invoke方法
            // 只要调用invocation的invoke方法，就代表需要执行NSInvocation对象中制定对象的指定方法，并且传递指定的参数
            [invocation invoke];
        }
    }
}

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

@end



#pragma mark - ZJQNotification

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
