//
//  MyViewController.m
//  通知
//
//  Created by 张佳乔 on 2022/7/27.
//

#import "MyViewController.h"
#import "ZJQNotificationCenter.h"

@interface MyViewController ()

@property (nonatomic, strong) UITextField *myTextField;

@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    self.myTextField = [[UITextField alloc] init];
    self.myTextField.frame = CGRectMake(100, 100, 100, 50);
    self.myTextField.placeholder = @"sdsd";
    [self.view addSubview:self.myTextField];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"temp" object:nil userInfo:@{@"content": self.myTextField.text}];
    [[ZJQNotificationCenter defaultCenter] postNotificationName:@"temp" object:nil userInfo:@{@"content": self.myTextField.text}];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
