//
//  NSObject+ModelFactory.h
//  RuntimeStudy
//
//  Created by XunXinKeJi on 2018/7/25.
//  Copyright © 2018年 CrimsonHo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (ModelFactory)

+ (instancetype)mf_instancetypeWithKeyValue:(id)keyValue;

- (NSDictionary*)mf_customKeys;

- (NSDictionary*)mf_customArrayObjectType;

@end
