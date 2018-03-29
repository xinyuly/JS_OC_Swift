//
//  ViewController.m
//  JS_JavaScriptCore
//
//  Created by xinyu on 2018/3/26.
//  Copyright © 2018年 MaChat. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()<UIWebViewDelegate,JSDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) JSContext *context;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.webView];
    
    self.webView.delegate = self;
    // UIWebView 滚动的比较慢，这里设置为正常速度
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]]];
    [self.webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.context = context;
    //设置异常处理
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        [JSContext currentContext].exception = exception;
        NSLog(@"exception:%@",exception);
    };
    //注入JS需要的“OC”对象,该对象与html中的保持一致即可
    self.context[@"OC"] = self;
    // JS 调用OC 方法
    [self showMessage:context];
    [self showTitleAndMessage:context];
    [self doSomethingThenCallBack:context];
}

#pragma mark - Methods
- (void)showMessage:(JSContext *)context {
    __weak typeof(self) weakSelf = self;
    context[@"showMessage"] = ^(NSString *message) {
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertCtr addAction:cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
    };
}

- (void)showTitleAndMessage:(JSContext *)context {
    __weak typeof(self) weakSelf = self;
    context[@"showTitleAndMessage"] = ^(NSString *title, NSString *message){
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertCtr addAction:cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
    };
}

- (void)doSomethingThenCallBack:(JSContext *)context {
    __weak typeof(self) weakSelf = self;
    self.context[@"doSomethingThenCallBack"] = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertCtr addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"请输入传入的数据!";
                [textField addTarget:weakSelf action:@selector(textFieldChange:) forControlEvents:UIControlEventEditingChanged];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertCtr addAction:cancel];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UITextField *textField = [alertCtr.textFields firstObject];
                //OC 调用 JS 方法
                
                //方法一
                JSValue *callback = weakSelf.context[@"callback"];
                [callback callWithArguments:@[textField.text]];
                
            }];
            [alertCtr addAction:ok];
            ok.enabled = NO;
            
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
    };
}

#pragma mark - JSDelegate
- (void)showMessageToYou:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"问候" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertCtr addAction:cancel];
        [self presentViewController:alertCtr animated:YES completion:nil];
    });
}

- (void)doActionCallBack {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertCtr addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"请输入传入的数据!";
            [textField addTarget:self action:@selector(textFieldChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertCtr addAction:cancel];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textField = [alertCtr.textFields firstObject];
            //方法二
            NSString *jsStr = [NSString stringWithFormat:@"callback('%@')",textField.text];
            [weakSelf.context evaluateScript:jsStr];
        }];
        [alertCtr addAction:ok];
        ok.enabled = NO;
        
        [weakSelf presentViewController:alertCtr animated:YES completion:nil];
    });
}

- (void)showA:(NSString *)aString andB:(NSString*)bString {
    JSValue *alertCallback = self.context[@"alertCallback"];
    [alertCallback callWithArguments:@[aString,bString]];
}

#pragma mark - UITextField
- (void)textFieldChange:(UITextField *)sender {
    UIAlertController *alertCtr = (UIAlertController *)self.presentedViewController;
    UIAlertAction *okAction = [alertCtr.actions lastObject];
    if (sender.text.length > 0) {
        okAction.enabled = YES;
    } else {
        okAction.enabled = NO;
    }
}

@end
