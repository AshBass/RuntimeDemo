//
//  ViewController.m
//  RuntimeStudy
//
//  Created by XunXinKeJi on 2018/7/25.
//  Copyright © 2018年 CrimsonHo. All rights reserved.
//

#import "ViewController.h"
#import "TestModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"%@",[NSDate new]);
    TestModel *testModel = [TestModel mf_instancetypeWithKeyValue:@{@"modelId":@1,@"ModelName":@"Ash",@"modelNumber":@"3"}];
    NSLog(@"%@",[NSDate new]);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
