//
//  CASSimpleFormViewController.m
//  ClassyExample
//
//  Created by Jonas Budelmann on 21/10/13.
//  Copyright (c) 2013 Jonas Budelmann. All rights reserved.
//

#import "CASSimpleFormViewController.h"
@import Classy;

#import "ClassyExample-Swift.h"

@interface CASSimpleFormViewController ()

@end

@implementation CASSimpleFormViewController

- (id)init {
    self = [super init];
    if (!self) return nil;

    self.title = @"Simple Form";

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    v.backgroundColor = [UIColor redColor];
    v.cas_styleClass = @"shadow-view";
    [self.view addSubview:v];
    
    SwiftExampleView *swiftView = [[SwiftExampleView alloc] init];
    swiftView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:swiftView];
    
    [swiftView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [swiftView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    [swiftView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [swiftView.heightAnchor constraintEqualToConstant:100].active = YES;
}

@end
