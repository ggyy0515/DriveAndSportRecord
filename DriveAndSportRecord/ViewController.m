//
//  ViewController.m
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/14.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import "ViewController.h"
#import "DSDriveAndSportRecord.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *longitudeTF;
@property (weak, nonatomic) IBOutlet UITextField *LatitudeTF;
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) ECLogServer *logServer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _logServer = APP_DELEGATE.logServer;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:DESLNG]) {
        _longitudeTF.text = [[[NSUserDefaults standardUserDefaults] objectForKey:DESLNG] stringValue];
        [DSDriveAndSportRecord sharedRecord].desLongitude = [[[NSUserDefaults standardUserDefaults] objectForKey:DESLNG] doubleValue];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:DESLAT]) {
        _LatitudeTF.text = [[[NSUserDefaults standardUserDefaults] objectForKey:DESLAT] stringValue];
        [DSDriveAndSportRecord sharedRecord].desLatitude = [[[NSUserDefaults standardUserDefaults] objectForKey:DESLAT] doubleValue];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_logServer addObserver:self forKeyPath:@"logs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_logServer removeObserver:self forKeyPath:@"logs"];
}

- (IBAction)confirmBtnAction:(UIButton *)sender {
//    if (!_LatitudeTF.text || !_longitudeTF.text || [_LatitudeTF.text isEqualToString:@""] || [_longitudeTF.text isEqualToString:@""]) {
//        [SVProgressHUD showInfoWithStatus:@"请输入车库门的经纬度"];
//        [APP_DELEGATE.logServer insertDetailTableWithInterface:NSStringFromClass([self class])
//                                                          type:type_info
//                                                          text:@"未输入经纬度，点击确认按钮"];
//        return;
//    }
    if ([_LatitudeTF isFirstResponder]) {
        [_LatitudeTF resignFirstResponder];
    }
    if ([_longitudeTF isFirstResponder]) {
        [_longitudeTF resignFirstResponder];
    }
    [SVProgressHUD show];
//    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:_longitudeTF.text.doubleValue] forKey:DESLNG];
//    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:_LatitudeTF.text.doubleValue] forKey:DESLAT];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    [DSDriveAndSportRecord sharedRecord].desLongitude = _longitudeTF.text.doubleValue;
//    [DSDriveAndSportRecord sharedRecord].desLatitude = _LatitudeTF.text.doubleValue;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getLocation:)
                                                 name:@"REQUESTCURRENTLOCATION"
                                               object:nil];
}

- (IBAction)tapAction:(UITapGestureRecognizer *)sender {
    if ([_LatitudeTF isFirstResponder]) {
        [_LatitudeTF resignFirstResponder];
    }
    if ([_longitudeTF isFirstResponder]) {
        [_longitudeTF resignFirstResponder];
    }
}



- (void)getLocation:(NSNotification *)notifacetion {
    CLLocation *location = notifacetion.userInfo[@"location"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:DESLNG];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:DESLAT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _longitudeTF.text = [NSString stringWithFormat:@"%lf", location.coordinate.longitude];
    _LatitudeTF.text = [NSString stringWithFormat:@"%lf", location.coordinate.latitude];
    [DSDriveAndSportRecord sharedRecord].desLongitude = _longitudeTF.text.doubleValue;
    [DSDriveAndSportRecord sharedRecord].desLatitude = _LatitudeTF.text.doubleValue;
    [SVProgressHUD dismiss];
    [APP_DELEGATE.logServer insertDetailTableWithInterface:NSStringFromClass([self class])
                                                      type:type_info
                                                      text:@"车库门经纬度获取成功"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"REQUESTCURRENTLOCATION" object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"logs"]) {
        [_tableView reloadData];
        NSArray <NSIndexPath *> *arr = [_tableView indexPathsForVisibleRows];
        [arr enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.row == _logServer.logs.count - 5) {
                [_tableView scrollToRowAtIndexPath:obj atScrollPosition:UITableViewScrollPositionTop animated:NO];
                *stop = YES;
            }
        }];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _logServer.logs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELL"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:12.f];
        cell.textLabel.numberOfLines = 0; 
    }
    cell.textLabel.text = [_logServer.logs objectAtIndex:indexPath.row];
    return cell;
    
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
