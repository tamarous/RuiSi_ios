//
//  ThreadListViewController.m
//  RuiSi
//
//  Created by aloes on 2016/11/23.
//  Copyright © 2016年 aloes. All rights reserved.
//

#import "ThreadListViewController.h"
#import "ThreadDetailViewController.h"
#import "Thread.h"
#import "ThreadListCell.h"

NSString *kThreadListCell = @"ThreadListCell";
NSString *kShowThreadDetail = @"showThreadDetail";
@interface ThreadListViewController ()
@property (nonatomic,assign) NSInteger currentPage;
@end

@implementation ThreadListViewController


#pragma mark - Lifecylce Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentPage = 1;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView registerNib:[UINib nibWithNibName:kThreadListCell bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kThreadListCell];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.85 green:0.13 blue:0.16 alpha:1.0];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.navigationItem.title = self.name;
    
    [self configureRefresh];
    if(! [[AFNetworkReachabilityManager sharedManager] isReachable]) {
        
    } else {
        [self.tableView.mj_header beginRefreshing];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        if(self.tableView.mj_header.isRefreshing) {
            [self.tableView.mj_header endRefreshing];
        }
        if(self.tableView.mj_footer.isRefreshing) {
            [self.tableView.mj_footer endRefreshing];
        }
    }
    [super viewWillDisappear:animated];
}


#pragma mark - Configurations

- (void) configureBlocks {
    //@weakify(self);
    
    if (! self.getThreadListBlock) {
//        self.getThreadListBlock = ^(NSInteger page){
//            @strongify(self);
//            self.currentPage = page;
//            return [[DataManager manager] getHotThreadListWithPage:page success:^(ThreadList *threadList) {
//                @strongify(self);
//                self.threadList = threadList;
//            } failure:^(NSError *error) {
//                ;
//            }];
//        };
    }
    
    if (! self.getMoreListBlock && self.needToGetMore) {
//        self.getMoreListBlock = ^(NSInteger page) {
//            @strongify(self);
//            self.currentPage = page;
//            return [[DataManager manager] getHotThreadListWithPage:page success:^(ThreadList *threadList) {
//                @strongify(self);
//                NSMutableArray *threadLists = [[NSMutableArray alloc] initWithArray:self.threadList.list];
//                [threadLists addObjectsFromArray:threadList.list];
//                self.threadList.list = [NSArray arrayWithArray:threadLists];
//            } failure:^(NSError *error) {
//                ;
//            }];
//        };
    }
}

- (void) configureRefresh {
    __weak typeof(self) wself = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadCurrentPage)];
    [self.tableView.mj_header setEndRefreshingCompletionBlock:^{
        [wself.tableView reloadData];
    }];
    ((MJRefreshNormalHeader *)self.tableView.mj_header).lastUpdatedTimeLabel.hidden = YES;
    [((MJRefreshNormalHeader *)self.tableView.mj_header) setTitle:@"下拉刷新" forState:MJRefreshStateIdle];
    [((MJRefreshNormalHeader *)self.tableView.mj_header) setTitle:@"正在加载..." forState:MJRefreshStateRefreshing];
    [((MJRefreshNormalHeader *)self.tableView.mj_header) setTitle:@"释放以加载" forState:MJRefreshStatePulling];
    [((MJRefreshNormalHeader *)self.tableView.mj_header).stateLabel setTextColor:[UIColor darkGrayColor]];
    
    if (self.needToGetMore) {
        self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadNextPage)];
        [self.tableView.mj_footer setEndRefreshingCompletionBlock:^{
            [wself.tableView reloadData];
        }];
        
        [((MJRefreshAutoNormalFooter *)self.tableView.mj_footer) setTitle:@"点击或上拉以加载更多" forState:MJRefreshStateIdle];
        [((MJRefreshAutoNormalFooter *)self.tableView.mj_footer) setTitle:@"正在加载..." forState:MJRefreshStateRefreshing];
        [((MJRefreshAutoNormalFooter *)self.tableView.mj_footer) setTitle:@"没有更多数据啦..." forState:MJRefreshStateNoMoreData];
        [((MJRefreshAutoNormalFooter *)self.tableView.mj_footer).stateLabel setTextColor:[UIColor darkGrayColor]];
    }
}

#pragma mark - Helper Methods

- (void) loadCurrentPage {
    if(! [[AFNetworkReachabilityManager sharedManager] isReachable]) {
        [self.tableView.mj_header endRefreshing];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"哎呀，似乎丢失了网络连接～" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"好的～" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okayAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.getThreadListBlock(1);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView.mj_header endRefreshing];
            });
        });
    }
}

- (void) loadNextPage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self readyForNextPage];
        self.getMoreListBlock(self.currentPage);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView.mj_footer endRefreshing];
        });
    });
}

// TODO:需要知道当前帖子的最大页数是多少
- (void)readyForNextPage {
    self.currentPage = self.currentPage + 1;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_threadList countOfList];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThreadListCell *cell = [tableView dequeueReusableCellWithIdentifier:kThreadListCell forIndexPath:indexPath];
    
    Thread *thread = _threadList.list[indexPath.row];
    
    cell.thread = thread;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    ThreadDetailViewController *threadDetailViewController = [[ThreadDetailViewController alloc] init];
    threadDetailViewController.hidesBottomBarWhenPushed = YES;
    Thread *thread = [self.threadList.list objectAtIndex:indexPath.row];
    threadDetailViewController.thread = thread;
    [self.navigationController pushViewController:threadDetailViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

@end
