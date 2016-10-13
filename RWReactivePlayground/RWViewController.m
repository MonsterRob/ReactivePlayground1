//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa.h>
@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@end

@implementation RWViewController

// filter map flattenMap combineLatest RAC

- (void)viewDidLoad {
  [super viewDidLoad];
  //self.signInFailureText.hidden = YES;
    /**
     *  将每次文本改变的信号值（文本值）映射为真假值
     *
     *  @param userName 文本值
     *
     *  @return 真假值（对象）
     */
    RACSignal *validUserNameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString * userName) {
        return @([self isValidUsername:userName]);
    }];
    
    /**
     *  将信号值应用到对象的属性上
     *
     *  @param self.usernameTextField 对象
     *  @param backgroundColor        属性
     *
     *  @return 根据真假判断 给出响应的值 并返回
     */
    RAC(self.usernameTextField,backgroundColor) = [validUserNameSignal map:^id(NSNumber * numsig) {
        
        return [numsig boolValue] ?[UIColor clearColor]:[UIColor yellowColor];
    }];
  
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString * password) {
        return @([self isValidPassword:password]);
    }];
    RAC(self.passwordTextField,backgroundColor) = [validPasswordSignal map:^id(NSNumber * value) {
        return [value boolValue] ? [UIColor clearColor]:[UIColor yellowColor];
    }];
    
    /**
     *  信号聚合
     *
     *  @param validUser     信号源1
     *  @param validPassword 信号源2
     *
     *  @return 新的信号值
     */
    RACSignal *signInCombibeSig = [RACSignal combineLatest:@[validPasswordSignal,validUserNameSignal] reduce:^id(NSNumber* validUser,NSNumber *validPassword){
        return @([validUser boolValue] && [validPassword boolValue]);
    }];
    /**
     *  聚合信号/副作用 -> 只要编辑，隐藏失败文本
     *
     *  @param x 信号值
     *
     *  @return
     */
    [[signInCombibeSig doNext:^(id x) {
        self.signInFailureText.hidden = YES;
    }]subscribeNext:^(NSNumber* valid ) {
        self.signInButton.enabled = [valid boolValue];
    }];
    
    /**
     *  信号转换/副作用
     *
     *  @param value 点击信号
     *  flattenMap 内部信号映射
     *  @return 验证信号（内部信号）
     */
    
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(UIButton * button) {
        button.enabled = NO;
        self.signInFailureText.hidden = YES;
    }] flattenMap:^id(id value) {
        
        return [self signInSignal];// 返回的是信号源本身
        
    }] subscribeNext:^(NSNumber * value) {
        
        BOOL success = [value boolValue];
        self.signInFailureText.hidden = success;
        if (success) {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
        
    }];
}


-(RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [RWDummySignInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success) {
            
            [subscriber sendNext:@(success)];// 发送内部信号
            [subscriber sendCompleted];// 发送完毕
        }];
        return nil;
    }];
}
- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

//- (IBAction)signInButtonTouched:(id)sender {
//  
//  // disable all UI controls
//  self.signInButton.enabled = NO;
//  self.signInFailureText.hidden = YES;
//  // sign in
//  [RWDummySignInService signInWithUsername:self.usernameTextField.text
//                            password:self.passwordTextField.text
//                            complete:^(BOOL success) {
//                              self.signInButton.enabled = YES;
//                              self.signInFailureText.hidden = success;
//                              if (success) {
//                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//                              }
//                            }];
//}


// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid




@end
