//
//  ViewController.m
//  WZRunLoopObserver
//
//  Created by WonkeyZ on 2017/11/10.
//  Copyright © 2017年 WZ. All rights reserved.
//

#import "ViewController.h"
#import "WZRunLoopObserver.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) BOOL optimize;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initSubViews];
}

- (void)initSubViews {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:_tableView];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"启动优化" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction)];
    self.navigationItem.rightBarButtonItem = item;
    
    // 计算FPS
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Action
- (void)handleDisplayLink:(CADisplayLink *)displayLink {
    if (self.lastTime == 0) {
        self.lastTime = self.displayLink.timestamp;
        return;
    }
    self.count++;
    NSTimeInterval timeout = self.displayLink.timestamp - self.lastTime;
    if (timeout >= 1) {
        CGFloat fps = self.count / timeout;
        self.count = 0;
        self.title = [NSString stringWithFormat:@"%.f FPS",fps];
        self.lastTime = self.displayLink.timestamp;
    }
}

- (void)rightBarButtonAction {
    self.optimize = !self.optimize;
    NSString *title = self.optimize ? @"关闭优化" : @"启动优化";
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction)];
    self.navigationItem.rightBarButtonItem = item;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1000;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 150;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
        
        CGFloat imageWidth = ceilf(kScreenWidth / 2);
        UIImageView *imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageWidth, 150)];
        imageView1.tag = 1;
        [cell.contentView addSubview:imageView1];
        
        UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(imageWidth, 0, imageWidth, 150)];
        imageView2.tag = 2;
        [cell.contentView addSubview:imageView2];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
        label.textColor = [UIColor whiteColor];
        label.tag = 3;
        [cell.contentView addSubview:label];
    }
    
    UIImageView *imageView1 = (UIImageView *)[cell.contentView viewWithTag:1];
    UIImageView *imageView2 = (UIImageView *)[cell.contentView viewWithTag:2];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"hs" ofType:@"jpg"];
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:3];
    label.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    
    if (self.optimize) {
        WZRunLoopObserver.main.limit(50).add(^{
            imageView1.image = [UIImage imageWithContentsOfFile:path];
        }).add(^{
            imageView2.image = [UIImage imageWithContentsOfFile:path];
        });
    }else {
        imageView1.image = [UIImage imageWithContentsOfFile:path];
        imageView2.image = [UIImage imageWithContentsOfFile:path];
    }

    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
