//
//  NSObject+ModelFactory.m
//  RuntimeStudy
//
//  Created by XunXinKeJi on 2018/7/25.
//  Copyright © 2018年 CrimsonHo. All rights reserved.
//

#import "NSObject+ModelFactory.h"
#import <objc/runtime.h>
@implementation NSObject (ModelFactory)

+ (instancetype)mf_instancetypeWithKeyValue:(id)keyValue {
    id obj = [[self alloc] init];
    if (obj) {
        NSDictionary *dictionary;
        @try {
            if ([keyValue isKindOfClass:[NSDictionary class]]) {
                dictionary = keyValue;
            } else if ([keyValue isKindOfClass:[NSString class]]) {
                NSData *jsonData = [keyValue dataUsingEncoding:NSUTF8StringEncoding];
                dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            }else if ([keyValue isKindOfClass:[NSData class]]) {
                dictionary = [NSJSONSerialization JSONObjectWithData:keyValue options:NSJSONReadingMutableContainers error:nil];
            }
        } @catch (NSException *exception) {
            NSLog(@"json转换出错");
            NSLog(@"%@" , exception);
        } @finally {
            
        }
        
        if (![dictionary isKindOfClass:[NSDictionary class]] || dictionary.allKeys.count == 0) {
            return nil;
        }
        
        @try {
            [obj setValueForKeyValue:dictionary];
        } @catch (NSException *exception) {
            NSLog(@"runtime赋值出错");
            NSLog(@"%@" , exception);
        } @finally {
            
        }
        
    }
    return obj;
}

- (void)setValueForKeyValue:(NSDictionary*)dictionary {
    
    NSDictionary *customKeys = [self mf_customKeys];
    NSDictionary *customArrayObjectType = [self mf_customArrayObjectType];
    
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([self class], &propertyCount);
    
    for (unsigned int i = 0; i < propertyCount; ++i) {
        //获取属性
        objc_property_t property = propertyList[i];
        
        //获取属性的名字
        const char *name = property_getName(property);
        NSString *key = [NSString stringWithUTF8String:name];
        
        //获取属性的类型 例如 ："T@\"NSString\",R,C,N,V_modelName"
        const char *attributeName = property_getAttributes(property);
        NSString *propertyType = [NSString stringWithUTF8String:attributeName];
        NSArray *propertyArray = [propertyType componentsSeparatedByString:@","];
        
        BOOL isNonatomic = NO;
        BOOL isCopy = NO;
        BOOL isReadOnly = NO;
        NSUInteger propertyArrayCount = propertyArray.count;
        for (NSUInteger i = 1; i < propertyArrayCount - 1; ++i) {
            NSString *theProperty = propertyArray[i];
            if ([theProperty isEqualToString:@"N"]) {
                isNonatomic = YES;
            }
            if ([theProperty isEqualToString:@"R"]) {
                isReadOnly = YES;
            }
            if ([theProperty isEqualToString:@"C"]) {
                isCopy = YES;
            }
        }
        if (isReadOnly && [self respondsToSelector:@selector(key)]) {
            continue;
        }
        
        //如果用户有自定义的key值
        NSString *newKey = customKeys[key];
        //获取属性的值
        id value = newKey.length > 0 ? dictionary[newKey] : dictionary[key];
        if (!value || [value isKindOfClass:[NSNull class]]) {
            continue;
        }
        
        if ([propertyType hasPrefix:@"T@"]) {
            //对象
            if ([propertyType hasPrefix:@"T@\""]) {
                // 获取类名
                NSString *runtimeClassName = propertyArray.firstObject;
                NSString *className = [runtimeClassName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                className = [className stringByReplacingOccurrencesOfString:@"T@" withString:@""];
                //获取该对象的类名 ，若不为空，则是自定义类
                Class objClass = NSClassFromString(className);
                
                if (classIsKindOfClass(objClass, [NSString class])) {
                    // NSString
                    [self setValue:[NSString stringWithFormat:@"%@",value] forKey:key];
                } else if (classIsKindOfClass(objClass, [NSNumber class])) {
                    // NSNumber
                    if ([value isKindOfClass:[NSNumber class]]) {
                        [self setValue:value forKey:key];
                    }else if ([value isKindOfClass:[NSString class]]) {
                        [self setValue:@([value doubleValue]) forKey:key];
                    }
                } else if (classIsKindOfClass(objClass, [NSArray class])) {
                    // NSArray
                    if ([value isKindOfClass:[NSArray class]]) {
                        //创建数组
                        NSMutableArray *array = [NSMutableArray new];
                        //获取自定义类类型 ，若不为空 ，则为自定义类
                        NSString *arrayObjType = customArrayObjectType[key];
                        Class arrayObjClass = arrayObjType.length > 0 ? NSClassFromString(arrayObjType) : NULL;
                        if (array != NULL && [arrayObjClass respondsToSelector:@selector(mf_instancetypeWithKeyValue:)]) {
                            // 自定义类型
                            //如果是自定义类型也使用modelFactory
                            for (id objValue in value) {
                                [array addObject:[arrayObjClass mf_instancetypeWithKeyValue:objValue]];
                            }
                        }else {
                            // 系统类型
                            for (id objValue in value) {
                                [array addObject:objValue];
                            }
                        }
                        [self setValue:array forKey:key];
                    }
                } else if ([objClass respondsToSelector:@selector(mf_instancetypeWithKeyValue:)]) {
                    [self setValue:[objClass mf_instancetypeWithKeyValue:value] forKey:key];
                } else {
                    [self setValue:value forKey:key];
                }
            }else {
                // id
                [self setValue:value forKey:key];
            }
        } else if ([propertyType hasPrefix:@"Ti"]) {
            // int
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value intValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"TI"]) {
            // unsigned int
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value longLongValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"Ts"]) {
            // short
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value shortValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"TS"]) {
            // unsigned short
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value integerValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"Tq"]) {
            // long, NSInteger
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value longValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"TQ"]) {
            // unsigned long, NSUInteger
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value longLongValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"Tc"]) {
            // char
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value intValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"TC"]) {
            // unsigned char
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value intValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"TB"]) {
            // BOOL
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value boolValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"Td"]) {
            // double
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value doubleValue]) forKey:key];
            }
        } else if ([propertyType hasPrefix:@"Tf"]) {
            // float
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                [self setValue:@([value floatValue]) forKey:key];
            }
        }
        
    }
}

- (NSDictionary*)mf_customKeys {
    return nil;
}

- (NSDictionary*)mf_customArrayObjectType {
    return nil;
}

bool classIsKindOfClass(Class class1 , Class class2) {
    
    if (class1 == NULL || class2 == NULL) {
        return false;
    }
    
    if (class1 == class2) {
        return true;
    }
    
    return classIsKindOfClass(class_getSuperclass(class1), class2);
}

@end
