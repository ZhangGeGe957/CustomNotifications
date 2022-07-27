//
//  ViewController.m
//  通知
//
//  Created by 张佳乔 on 2022/7/27.
//

#import "ViewController.h"
#import "MyViewController.h"
#import "ZJQNotificationCenter.h"

@interface ViewController ()

@property (nonatomic, strong) UILabel *myLabel;
@property (nonatomic, strong) MyViewController *myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.myLabel = [[UILabel alloc] init];
    self.myLabel.text = @"通知传值";
    self.myLabel.frame = CGRectMake(100, 100, 100, 50);
    [self.view addSubview:self.myLabel];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(Notificate:) name:@"temp" object:nil];
    [[ZJQNotificationCenter defaultCenter] addObserver:self selector:@selector(Notificate:) name:@"temp" object:nil];
}

- (void)Notificate:(NSNotification *)sender {
    NSLog(@"%@ %@ %@", sender.name, sender.userInfo, sender.object);
    self.myLabel.text = sender.userInfo[@"content"];
}

- (void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[ZJQNotificationCenter defaultCenter] removeObserver:self];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.myView = [[MyViewController alloc] init];
    self.myView.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:self.myView animated:YES completion:nil];
}

@end
