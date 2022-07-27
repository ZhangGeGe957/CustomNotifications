//
//  ZJQNotificationCenter.h
//  通知
//
//  Created by 张佳乔 on 2022/7/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#pragma mark - ZJQNotificationCenter
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



#pragma mark - ZJQNotification
// 通知类，用来保存通知及其参数
@interface ZJQNotification : NSObject

// 对外有三个只读属性
@property (readonly, copy) NSNotificationName name; // 通知名
@property (nullable, readonly, copy) NSDictionary *userInfo; // 参数信息
@property (nullable, readonly, retain) id object; // 接收通知的对象

// 快速初始化类参数的方法
- (instancetype)initWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end
NS_ASSUME_NONNULL_END
