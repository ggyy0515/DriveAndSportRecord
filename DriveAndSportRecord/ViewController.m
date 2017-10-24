//
//  ViewController.m
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/14.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *longitudeTF;
@property (weak, nonatomic) IBOutlet UITextField *LatitudeTF;
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)confirmBtnAction:(UIButton *)sender {
    if (!_LatitudeTF.text || !_longitudeTF.text || [_LatitudeTF.text isEqualToString:@""] || [_longitudeTF.text isEqualToString:@""]) {
        [SVProgressHUD showInfoWithStatus:@"请输入车库门的经纬度"];
        return;
    }
    
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
