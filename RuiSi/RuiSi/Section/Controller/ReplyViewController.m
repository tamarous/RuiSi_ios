//
//  ReplyViewController.m
//  RuiSi
//
//  Created by 汪泽伟 on 2017/2/12.
//  Copyright © 2017年 aloes. All rights reserved.
//

#import "ReplyViewController.h"
@interface ReplyViewController () <UITextFieldDelegate>
@property (nonatomic,strong) UIBarButtonItem *publishBarButtonItem;
@property (nonatomic,strong) UIBarButtonItem *cancelBarButtonItem;
@end

@implementation ReplyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.replyTextField.delegate = self;
    [self.replyTextField becomeFirstResponder];
}

- (void) loadView {
    [super loadView];
    [self congifureNavigationBarItems];
    [self configureTextViews];
    [self configureKeyboard];
}

- (void) configureTextViews {
    
    self.replyTextField = [[UITextField alloc] initWithFrame:self.view.frame];
    self.replyTextField.backgroundColor = [UIColor whiteColor];
    self.replyTextField.font = [UIFont systemFontOfSize:17.0f];
    self.replyTextField.textColor = [UIColor blackColor];
    self.replyTextField.returnKeyType = UIReturnKeyDone;
    self.replyTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.replyTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    self.replyTextField.clearButtonMode = UITextFieldViewModeNever;
    self.replyTextField.placeholder = @"说点什么吧";
    [self.view addSubview:self.replyTextField];
    
}


- (void) configureKeyboard {
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, 30)];
    toolbar.barStyle = UIBarStyleDefault;
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelItemClicked)];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *emotionItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"happy"] style:UIBarButtonItemStylePlain target:self action:@selector(emotionItemClicked)];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneItemClicked)];
    toolbar.items = [NSArray arrayWithObjects:cancelItem,spaceItem,emotionItem,spaceItem,doneItem, nil];
    [toolbar sizeToFit];
    self.replyTextField.inputAccessoryView = toolbar;
}

- (void) cancelItemClicked {
    
}

- (void) doneItemClicked {
    [self.replyTextField resignFirstResponder];
}

- (void) emotionItemClicked {
    
}

- (void) takeActionBlock:(void (^)())block {
    block();
}

- (void) congifureNavigationBarItems {
    self.publishBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发布" style:UIBarButtonItemStylePlain target:self action:@selector(publish)];
    self.cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = self.publishBarButtonItem;
    self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
}

- (void) cancel {
    [self.delegate replyViewControllerDidCancel:self];
}
- (void) publish {
    if ([DataManager isUserLogined]) {
        ThreadDetail *detail = [[ThreadDetail alloc] init];
        Member *me = [DataManager manager].user.member;
        NSDate *date = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *currentDateString = [dateFormatter stringFromDate:date];
        detail.createTime = currentDateString;
        detail.content = self.replyTextField.text;
        detail.threadCreator = me;
        [self.delegate replyViewController:self didPublishThreadDetail:detail];
    } else {
        [self.delegate replyViewControllerHaveNotLogin:self];
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.replyTextField.text.length > 0) {
        [self.replyTextField resignFirstResponder];
        return YES;
    }
    return NO;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = YES;
}
@end
