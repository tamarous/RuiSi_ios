//
//  DataManager.m
//  RuiSi
//
//  Created by 汪泽伟 on 2016/12/2.
//  Copyright © 2016年 aloes. All rights reserved.
//
#import "DataManager.h"
#import "User.h"
#import "Member.h"
#import "Constants.h"
#import "ThreadDetail.h"
#import "HTMLParser.h"
#import "OCGumbo.h"
#import "OCGumbo+Query.h"
@interface DataManager()
@property (nonatomic,copy) NSString * baseURLString;
@property (nonatomic,strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic,copy) NSString *userAgentMobile;
@property (nonatomic,copy) NSString *userAgentPC;
@end

@implementation DataManager


#pragma mark - Base Methods
- (instancetype) init {
    if (self = [super init]) {
        
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        self.userAgentMobile = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        self.userAgentPC = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/537.75.14";
        
        BOOL isLogin = [[[NSUserDefaults standardUserDefaults] objectForKey:kUserIsLogin] boolValue];
        if (isLogin) {
            User *user = [[User alloc] init];
            user.isLogin = YES;
            Member *member = [[Member alloc] init];
            user.member = member;
            user.member.memberName = [[NSUserDefaults standardUserDefaults] valueForKey:kUserName];
            user.member.memberUid = [[NSUserDefaults standardUserDefaults] valueForKey:kUserID];
            user.member.memberAvatarSmall = [[NSUserDefaults standardUserDefaults] valueForKey:kUserAvatarURL];
            _user = user;
        }
        [self setBaseURL];
    }
    
    return self;
}

- (void) setBaseURL {
    if ([DataManager isSchoolNet]) {
        self.baseURLString = kSchoolNetURL;
    } else {
        self.baseURLString = kPublicNetURL;
    }
    
    NSURL *baseURL = [NSURL URLWithString:self.baseURLString];
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    self.sessionManager.requestSerializer = serializer;
}

- (void) setUser:(User *)user {
    _user = user;
    if (user) {
        self.user.isLogin = YES;
        [userDefaults setObject:user.member.memberName forKey:kUserName];
        [userDefaults setObject:user.member.memberUid forKey:kUserID];
        [userDefaults setObject:user.member.memberAvatarMiddle forKey:kUserAvatarURL];
        [userDefaults setObject:@"YES" forKey:kUserIsLogin];
        [userDefaults setObject:user.member.memberHomepage forKey:kUserHomepage];
        [userDefaults synchronize];
    } else {
        [userDefaults removeObjectForKey:kUserName];
        [userDefaults removeObjectForKey:kUserID];
        [userDefaults removeObjectForKey:kUserAvatarURL];
        [userDefaults removeObjectForKey:kUserIsLogin];
        [userDefaults removeObjectForKey:kUserHomepage];
        [userDefaults synchronize];
    }
}

+ (instancetype) manager {
    static DataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DataManager alloc] init];
        [[NSNotificationCenter defaultCenter] addObserverForName:kLoginSuccessNotification object:manager queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            manager.user.isLogin = YES;
        }];
    });
    return manager;
}

+ (BOOL)isSchoolNet {
    return false;
}

+ (BOOL)isUserLogined {
    return [DataManager manager].user.isLogin;
}

- (NSURLSessionDataTask *)requestWithMethod:(RequestMethod) method
                                  urlString:(NSString *)urlString
                                 parameters:(NSDictionary *)parameters
                                    success:(void (^)(NSURLSessionDataTask *task,id responseObject))success
                                    failure:(void (^)(NSError *error)) failure {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
    
    void (^responseHandleBlock) (NSURLSessionDataTask *task, id responseObject) = ^(NSURLSessionDataTask *task, id responseObject){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        success(task,responseObject);
    };
    
    
    NSURLSessionDataTask *task = nil;
    [self.sessionManager.requestSerializer setValue:self.userAgentMobile forHTTPHeaderField:@"User-Agent"];
    [self.sessionManager.requestSerializer setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
//    NSString *cookie = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"cookie"];
//    if (cookie != nil) {
//        [self.sessionManager.requestSerializer setValue:cookie forHTTPHeaderField:@"cookie"];
//    }
    
    if (method == RequestMethodHTTPGet) {
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        self.sessionManager.responseSerializer = responseSerializer;
        task = [self.sessionManager GET:urlString parameters:parameters progress:^(NSProgress *  downloadProgress) {
            ;
        } success:^(NSURLSessionDataTask *task, id responseObject) {
//            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
//            NSDictionary *allHeaderFieldsDict = response.allHeaderFields;
//            NSString *setCookie = allHeaderFieldsDict[@"Set-Cookie"];
//            if (setCookie != nil) {
//                NSString *cookie = [[setCookie componentsSeparatedByString:@";"] objectAtIndex:0];
//                [[NSUserDefaults standardUserDefaults] setObject:cookie forKey:@"cookie"];
//            }
            responseHandleBlock(task,responseObject);
        }failure:^(NSURLSessionDataTask *task,NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            failure(error);
        }];
    }
    
    if (method == RequestMethodHTTPPost) {
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        self.sessionManager.responseSerializer = responseSerializer;
        task = [self.sessionManager POST:urlString parameters:parameters progress:^(NSProgress *  uploadProgress) {
            ;
        }  success:^(NSURLSessionDataTask *  task, id  responseObject) {
//            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
//            NSDictionary *allHeaderFieldsDict = response.allHeaderFields;
//            NSString *setCookie = allHeaderFieldsDict[@"Set-Cookie"];
//            if (setCookie != nil) {
//                NSString *cookie = [[setCookie componentsSeparatedByString:@";"] objectAtIndex:0];
//                [[NSUserDefaults standardUserDefaults] setObject:cookie forKey:@"cookie"];
//            }
            responseHandleBlock(task,responseObject);
        } failure:^(NSURLSessionDataTask *  task, NSError *  error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            failure(error);
        }];
    }
    
    return task;
}

#pragma mark - Thread List
- (NSURLSessionDataTask *)getThreadListWithFid:(NSString *)fid
                                          page:(NSInteger )page
                                       success:(void (^)(ThreadList *))success
                                       failure:(void (^)(NSError *))failure {
    NSDictionary *parameters;
    if (page) {
        parameters = @{
                       @"mod":@"forumdisplay",
                       @"fid":fid,
                       @"page":@(page),
                       @"mobile":@"2"
                       };
    } else {
        parameters = @{
                       @"mod":@"forumdisplay",
                       @"fid":fid,
                       @"mobile":@"2"
                       };
    }
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"forum.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        ThreadList *list = [ThreadList getThreadListFromResponseObject:responseObject];
        if (list) {
            success(list);
        } else {
            NSError *error = [[NSError alloc] initWithDomain:self.sessionManager.baseURL.absoluteString code:404 userInfo:nil ];
            failure(error);
        }
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (NSURLSessionDataTask *)getThreadListWithUid:(NSString *)uid
                                       success:(void (^)(ThreadList *))success
                                       failure:(void (^)(NSError *))failure {
    NSDictionary *parameters;
    parameters = @{
                   @"mod":@"space",
                   @"uid":uid,
                   @"do":@"thread",
                   @"view":@"me",
                   @"mobile":@"2"
                   };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"home.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        ThreadList *list = [ThreadList getThreadListFromResponseObject:responseObject];
        success(list);
    } failure:^(NSError *error) {
        
    }];
}

- (NSURLSessionDataTask *)getFavoriteThreadListWithUid:(NSString *)uid
                                               success:(void (^)(ThreadList *))success
                                               failure:(void (^)(NSError *))failure {
    NSDictionary *parameters;
    parameters = @{
                   @"mod":@"space",
                   @"uid":uid,
                   @"do":@"favorite",
                   @"view":@"me",
                   @"type":@"thread",
                   @"mobile":@"2"
                   };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"home.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        ThreadList *list = [ThreadList getThreadListForFavoritesFromResponseObject:responseObject];
        success(list);
    } failure:^(NSError *error) {
        
    }];
}

- (NSURLSessionDataTask *)getHotThreadListWithPage:(NSInteger)page
                                           success:(void (^)(ThreadList *))success
                                           failure:(void (^)(NSError *))failure {
    NSDictionary *parameters;
    parameters = @{
                   @"mod":@"guide",
                   @"view":@"hot",
                   @"page":@(page),
                   @"mobile":@"2"
                   };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"forum.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        ThreadList *list = [ThreadList getThreadListFromResponseObject:responseObject];
        success(list);
    } failure:^(NSError *error) {
        ;
    }];
}

#pragma mark - Message List
- (NSURLSessionDataTask *)getMessageListSuccess:(void (^)(MessageList *))success
                                        failure:(void (^)(NSError *))failure {
    NSDictionary *parameters;
    parameters = @{
                   @"mod":@"space",
                   @"do":@"pm",
                   @"mobile":@"2",
                   };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"home.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        MessageList *messageList = [MessageList getMessageListFromResponseObject:responseObject];
        success(messageList);
    } failure:^(NSError *error) {
        
    }];
}


#pragma mark - Detail
- (NSURLSessionDataTask *)getThreadDetailListWithTid:(NSString *)tid
                                                page:(NSInteger)page
                                             success:(void (^)(ThreadDetailList *))success
                                             failure:(void (^)(NSError *))failure {
    NSDictionary *parameters = @{
                       @"mod":@"viewthread",
                       @"tid":tid,
                       @"page":@(page),
                       @"mobile":@"2"
                       };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"forum.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        ThreadDetailList *detailList = [ThreadDetailList getThreadDetailListFromResponseObject:responseObject];
        success(detailList);
    } failure:^(NSError *error) {
        NSLog(@"error discription:%@",error.localizedDescription);
        NSLog(@"error code:%ld",error.code);
        NSLog(@"error domain:%@",error.domain);
        failure(error);
    }];
}

- (NSURLSessionDataTask *)getThreadDetailListAndPageCountWithTid:(NSString *)tid
                                                            page:(NSInteger)page success:(void (^)(ThreadDetailList *, NSString *))success
                                                         failure:(void (^)(NSError *))failure {
    NSDictionary *parameters = @{
                                 @"mod":@"viewthread",
                                 @"tid":tid,
                                 //@"extra":@"page%3D1",
                                 @"page":@(page),
                                 @"mobile":@"2"
                                 };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"forum.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        ThreadDetailList *list = [ThreadDetailList getThreadDetailListFromResponseObject:responseObject];
        NSString *pageCount = [ThreadDetailList getPageCountFromResponseObject:responseObject];
        success(list,pageCount);
    } failure:^(NSError *error) {
        NSLog(@"error discription:%@",error.localizedDescription);
        NSLog(@"error code:%ld",error.code);
        NSLog(@"error domain:%@",error.domain);
        failure(error);
    }];
}


- (NSURLSessionDataTask *)getCreatorOnlyThreadDetailListWithTid:(NSString *)tid
                                                           page:(NSInteger)page authorid:(NSString *)authorid
                                                        success:(void (^)(ThreadDetailList *))success
                                                        failure:(void (^)(NSError *))failure {
    NSDictionary *parameters = @{
                                 @"mod":@"viewthread",
                                 @"tid":tid,
                                 @"page":@(page),
                                 @"authorid":authorid,
                                 @"mobile":@"2"
                                 };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"forum.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        ThreadDetailList *detailList = [ThreadDetailList getThreadDetailListFromResponseObject:responseObject];
        success(detailList);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(NSURLSessionDataTask *)getLinkDictionaryWithTid:(NSString *)tid
                                             page:(NSInteger )page
                                          success:(void (^)(NSDictionary *))success
                                          failure:(void (^)(NSError *))failure {
    NSDictionary *parameters = @{
                                 @"mod":@"viewthread",
                                 @"tid":tid,
                                 @"page":@(page),
                                 @"mobile":@"2"
                                 };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"forum.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *result = [ThreadDetailList getLinkDictionaryFromResponseObject:responseObject];
        success(result);
    } failure:^(NSError *error) {
        failure(error);
    }];
}


- (NSURLSessionDataTask *)getMemberWithUid:(NSString *)uid
                                   success:(void (^)(Member *))success
                                   failure:(void (^)(NSError *))failure {
    NSDictionary *parameters;
    parameters = @{
                   @"mod":@"space",
                   @"uid":uid,
                   @"do":@"profile",
                   @"mobile":@"2"
                   };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:@"home.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        Member *member = [Member getMemberFromResponseObject:responseObject];
        success(member);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (NSURLSessionDataTask *)createReplyWithfid:(NSString *)fid
                                         tid:(NSString *)tid pid:(NSString *)pid
                                        page:(NSInteger )page
                                     content:(NSString *)content
                                     success:(void (^)(ThreadDetail *))success
                                     failure:(void (^)(NSError *))failure {
    NSDictionary *parameters;
    parameters = @{
                   @"mod":@"post",
                   @"action":@"reply",
                   @"fid":fid,
                   @"tid":tid,
                   @"reppost":pid,
                   @"page":@(page),
                   @"mobile":@"2"
                   };
    return [self requestWithMethod:RequestMethodHTTPPost urlString:@"forum.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
    } failure:^(NSError *error) {
        
    }];
}


- (NSURLSessionDataTask *)createReplyWithUrlString:(NSString *)urlString
                                          formhash:(NSString *)formhash
                                           message:(NSString *)message
                                           success:(void (^)(NSString *))success
                                           failure:(void (^)(NSError *))failure {
    NSDictionary *parameters;
    parameters = @{
                   @"formhash":formhash,
                   @"message":message
                   };
    return [self requestWithMethod:RequestMethodHTTPPost urlString:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
//        NSString *htmlString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//        NSLog(@"%@",htmlString);
//        if ([htmlString rangeOfString:@"信息发布成功"].location != NSNotFound) {
//            NSLog(@"发布成功");
//            success(@"发布成功");
//        }
        success(kPostIsSuccessful);
    } failure:^(NSError *error) {
        ;
    }];
    return nil;
}

- (NSURLSessionDataTask *) favorThreadWithTid:(NSString *)tid
                                     formhash:(NSString *)formhash
                                      success:(void (^)(NSString *message)) success
                                      failure:(void (^)(NSError *error)) failure {
    NSString *urlString = [NSString stringWithFormat:@"home.php?mod=spacecp&ac=favorite&type=thread&id=%@&mobile=2",tid];
    NSDictionary *parameters;
    parameters = @{
                   @"favoritesubmit":@"true",
                   @"formhash":formhash,
                   };
    return [self requestWithMethod:RequestMethodHTTPPost urlString:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSString *htmlString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        if ([htmlString rangeOfString:@"信息收藏成功"].location != NSNotFound) {
            NSLog(@"收藏成功！");
            success(kFavoriteIsSuccessful);
        }
    } failure:^(NSError *error) {
        ;
    }];
}

#pragma mark - User
- (NSURLSessionDataTask *)userLoginWithUserName:(NSString *)username
                                       password:(NSString *)password
                                     verifycode:(NSString *)verifycode
                           htmlFieldsDictionary:(NSDictionary *) infoDictionary
                                        success:(void (^)(NSString *))success
                                        failure:(void (^)(NSError *error))failure {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSString *cookieName = @"";
    for (NSHTTPCookie *cookie in [storage cookies]) {
        //[storage deleteCookie:cookie];
        NSString *item = [NSString stringWithFormat:@"%@:%@;",cookie.name, cookie.value];
        cookieName = [cookieName stringByAppendingString:item];
    }
    
    NSDictionary *parameters = @{
                   @"formhash":[infoDictionary objectForKey:@"formhash"],
                   @"referer": [self.baseURLString stringByAppendingString:@"/forum.php?mod=guide&view=hot&mobile=2"],
                   @"fastloginfield":[infoDictionary objectForKey:@"fastloginfield"],
                   @"cookietime":[infoDictionary objectForKey:@"cookietime"],
                   @"username":username,
                   @"password":password,
                   @"questionid":@"0",
                   @"seccodehash":[infoDictionary objectForKey:@"seccodehash"],
                   @"seccodeverify":verifycode
                   };
    NSString *postUrlString = [infoDictionary objectForKey:@"postUrlString"];
    [self.sessionManager.requestSerializer setValue: [self.baseURLString stringByAppendingString:@"/member.php?mod=logging&action=login&mobile=2"] forHTTPHeaderField:@"Referer"];
    return [self requestWithMethod:RequestMethodHTTPPost urlString:postUrlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSString *htmlString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        if ([htmlString rangeOfString:@"欢迎您回来"].location != NSNotFound) {
            NSRange range1 = [htmlString rangeOfString:@"uid="];
            NSRange range2 = [htmlString rangeOfString:@"&do=profile"];
            NSRange range = NSMakeRange(range1.location + range1.length, range2.location-range1.location-range1.length);
            NSString *uid = [htmlString substringWithRange:range];
            success(uid);
            NSLog(@"Login succeed!");
        } else {
            NSError *error = [[NSError alloc] initWithDomain:self.sessionManager.baseURL.absoluteString code:RSErrorTypeLoginFailure userInfo:nil];
            failure(error);
        }
    } failure:^(NSError *error) {
        failure(error);
    }];
}


- (void) userLogOut {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    self.user = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutSuccessNotification object:nil];
}

#pragma mark - Private Methods
//  得到唯一的一个登录地址
- (NSURLSessionDataTask *) requestOnceWithString:(NSString *) urlString
                                         success:(void (^)(NSDictionary *dictionary)) success
                                         failure:(void (^)(NSError *error)) failure {
    NSDictionary *parameters = @{
                                 @"mod":@"logging",
                                 @"action":@"login",
                                 @"mobile":@"2"
                                 };
    return [self requestWithMethod:RequestMethodHTTPGet urlString:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *fields = [self getInfoDictionaryFromHtmlResponseObject:responseObject];
        if (fields) {
            success(fields);
        } else {
            NSError *error = [[NSError alloc] initWithDomain:self.sessionManager.baseURL.absoluteString code:RSErrorTypeRequestFailure userInfo:nil];
            failure(error);
        }
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (NSDictionary *) getInfoDictionaryFromHtmlResponseObject:(id) responseObject {
    __block NSDictionary *result = nil;
    @autoreleasepool {
        NSString *htmlString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];
        OCGumboNode *node = document.Query(@".bg").find(@".loginbox").find(@"form").first();
        NSString *postUrlString = node.attr(@"action");
        OCQueryObject *inputs = node.Query(@"input");
        NSString *formhash = nil;
        NSString *referer = nil;
        NSString *fastloginfield = nil;
        NSString *cookietime = nil;
        NSString *secondhash = nil;
        for (OCGumboNode *input in inputs ) {
            if ([input.attr(@"name") isEqualToString:@"formhash"]) {
                formhash = (NSString *)input.attr(@"value");
            }
            if ([input.attr(@"name") isEqualToString:@"referer"]) {
                //referer = (NSString *)input.attr(@"value");
                referer = @"http://rsbbs.xidian.edu.cn/forum.php?mod=guide&view=hot&mobile=2";
            }
            if ([input.attr(@"name") isEqualToString:@"fastloginfield"]) {
                fastloginfield = (NSString *)input.attr(@"value");
            }
            if ([input.attr(@"name") isEqualToString:@"cookietime"]) {
                cookietime = (NSString *)input.attr(@"value");
            }
        }
        node = node.Query(@"div").find(@".sec_code").first();
        inputs = node.Query(@"input");
        for(OCGumboNode *input in inputs) {
            if ([input.attr(@"name") isEqualToString:@"seccodehash"]) {
                secondhash = (NSString *)input.attr(@"value");
            }
        }
        NSString *verifyImageBaseUrlString = (NSString *) node.Query(@"img").first().attr(@"src");
        NSString *verifyImageUrlString = [self.baseURLString stringByAppendingString:verifyImageBaseUrlString];
        result = [[NSDictionary alloc] initWithObjectsAndKeys:postUrlString,@"postUrlString",formhash,@"formhash",referer,@"referer",fastloginfield,@"fastloginfield",cookietime,@"cookietime", secondhash, @"seccodehash",verifyImageUrlString,@"verifyImageUrlString",nil];
    }
    return result;
}

@end
