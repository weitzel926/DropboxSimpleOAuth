#import <Specta/Specta.h>
#import <Swizzlean/Swizzlean.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "UIAlertView+TestUtils.h"
#import "FakeAFHTTPSessionManager.h"
#import "DropboxSimpleOAuth.h"
#import "DropboxLoginUtils.h"
#import "DropboxLoginmanager.h"
#import "FakeDropboxLoginManager.h"


@interface DropboxSimpleOAuthViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *dropboxWebView;
@property (strong, nonatomic) DropboxLoginManager *loginManager;
@property (strong, nonatomic) DropboxLoginUtils *dropboxLoginUtils;
@end

SpecBegin(DropboxSimpleOAuthViewControllerTests)

describe(@"DropboxSimpleOAuthViewController", ^{
    __block DropboxSimpleOAuthViewController *controller;
    __block id fakeLoginUtils;
    __block NSURL *callbackURL;
    __block DropboxLoginResponse *retLoginResponse;
    __block NSError *retError;
    
    beforeEach(^{
        callbackURL = [NSURL URLWithString:@"http://Delta-Tau-Chi.ios"];
        controller = [[DropboxSimpleOAuthViewController alloc] initWithAppKey:@"los-llaves"
                                                                    appSecret:@"unodostres"
                                                                  callbackURL:callbackURL
                                                                   completion:^(DropboxLoginResponse *response, NSError *error) {
                                                                       retLoginResponse = response;
                                                                       retError = error;
                                                                   }];
    });
    
    describe(@"init", ^{
        it(@"calls -initWithAppKey:appSecret:callbackURL:completion: with nil parameters", ^{
            DropboxSimpleOAuthViewController *basicController = [[DropboxSimpleOAuthViewController alloc] init];
            expect(basicController.appKey).to.beNil;
            expect(basicController.appSecret).to.beNil;
            expect(basicController.callbackURL).to.beNil;
            expect(basicController.completion).to.beNil;
        });
    });
    
    it(@"has a appKey", ^{
        expect(controller.appKey).to.equal(@"los-llaves");
    });
    
    it(@"has a appSecet", ^{
        expect(controller.appSecret).to.equal(@"unodostres");
    });
    
    it(@"has a callbackURL", ^{
        expect(controller.callbackURL).to.equal([NSURL URLWithString:@"http://Delta-Tau-Chi.ios"]);
    });
    
    it(@"has a completion block", ^{
        BOOL hasCompletionBlock = NO;
        if (controller.completion) {
            hasCompletionBlock = YES;
        }
        expect(hasCompletionBlock).to.beTruthy();
    });
    
    it(@"has shouldShowErrorAlert flag that defaults to YES", ^{
        expect(controller.shouldShowErrorAlert).to.beTruthy();
    });
    
    it(@"conforms to <UIWebViewDelegate>", ^{
        BOOL conformsToWebViewDelegateProtocol = [controller conformsToProtocol:@protocol(UIWebViewDelegate)];
        expect(conformsToWebViewDelegateProtocol).to.equal(YES);
    });
    
    it(@"has an DropboxLoginManager", ^{
        expect(controller.loginManager).to.beInstanceOf([DropboxLoginManager class]);
        expect(controller.loginManager.appKey).to.equal(@"los-llaves");
        expect(controller.loginManager.appSecret).to.equal(@"unodostres");
        expect(controller.loginManager.callbackURL).to.equal(controller.callbackURL);
    });
    
    it(@"has an DropboxLoginUtils", ^{
        expect(controller.dropboxLoginUtils).to.beInstanceOf([DropboxLoginUtils class]);
        expect(controller.dropboxLoginUtils.appKey).to.equal(@"los-llaves");
        expect(controller.dropboxLoginUtils.callbackURL).to.equal(callbackURL);
    });
    
    describe(@"#viewDidAppear", ^{
        __block Swizzlean *superSwizz;
        __block BOOL isSuperCalled;
        __block BOOL retAnimated;
        __block UIWebView *fakeWebView;
        __block id fakeLoginRequest;
        
        beforeEach(^{
            isSuperCalled = NO;
            superSwizz = [[Swizzlean alloc] initWithClassToSwizzle:[UIViewController class]];
            [superSwizz swizzleInstanceMethod:@selector(viewDidAppear:) withReplacementImplementation:^(id _self, BOOL isAnimated) {
                isSuperCalled = YES;
                retAnimated = isAnimated;
            }];
            
            [controller view];
            
            fakeWebView = OCMClassMock([UIWebView class]);
            controller.dropboxWebView = fakeWebView;
            
            fakeLoginRequest = OCMClassMock([NSURLRequest class]);
            
            fakeLoginUtils = OCMClassMock([DropboxLoginUtils class]);
            controller.dropboxLoginUtils = fakeLoginUtils;
            OCMStub([controller.dropboxLoginUtils buildLoginRequest]).andReturn(fakeLoginRequest);
            
            
            [controller viewDidAppear:YES];
        });
        
        it(@"calls super!!! Thanks for asking!!! =)", ^{
            expect(retAnimated).to.beTruthy();
            expect(isSuperCalled).to.beTruthy();
        });
        
        describe(@"dropboxWebView", ^{
            it(@"loads the login using the login request", ^{
                OCMVerify([fakeWebView loadRequest:fakeLoginRequest]);
            });
        });
    });
    
    describe(@"<UIWebViewDelegate>", ^{
        describe(@"#webView:shouldStartLoadWithRequest:navigationType:", ^{
            __block id hudClassMethodMock;
            __block BOOL shouldStartLoad;
            __block id fakeURLRequest;
            __block FakeDropboxLoginManager *fakeLoginManager;
            
            beforeEach(^{
                hudClassMethodMock = OCMClassMock([MBProgressHUD class]);
            });
            
            context(@"request contains dropbox callback URL as the URL Prefix with code param", ^{
                beforeEach(^{
                    fakeURLRequest = OCMClassMock([NSURLRequest class]);
                    
                    fakeLoginUtils = OCMClassMock([DropboxLoginUtils class]);
                    controller.dropboxLoginUtils = fakeLoginUtils;
                    OCMStub([controller.dropboxLoginUtils requestHasAuthCode:fakeURLRequest]).andReturn(YES);
                    OCMStub([controller.dropboxLoginUtils authCodeFromRequest:fakeURLRequest]).andReturn(@"authorization-sir");
                    
                    fakeLoginManager = [[FakeDropboxLoginManager alloc] init];
                    controller.loginManager = fakeLoginManager;
                    
                    shouldStartLoad = [controller webView:nil
                               shouldStartLoadWithRequest:fakeURLRequest
                                           navigationType:UIWebViewNavigationTypeFormSubmitted];
                });
                
                it(@"displays Progress HUD", ^{
                    OCMVerify([hudClassMethodMock showHUDAddedTo:controller.view animated:YES]);
                });
                
                it(@"attempts to authenticate with dropbox with authCode", ^{
                    expect(fakeLoginManager.authCode).to.equal(@"authorization-sir");
                });
                
                context(@"successfully gets auth token from Dropbox", ^{
                    __block id partialMock;
                    __block id fakeDropboxLoginResponse;
                    
                    beforeEach(^{
                        fakeDropboxLoginResponse = OCMClassMock([DropboxLoginResponse class]);
                    });
                    
                    context(@"has a navigation controlller", ^{
                        beforeEach(^{
                            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                            partialMock = OCMPartialMock(navigationController);
                            
                            if (fakeLoginManager.success) {
                                fakeLoginManager.success(fakeDropboxLoginResponse);
                            }
                        });
                        
                        it(@"calls completion with dropbox login response", ^{
                            expect(retLoginResponse).to.equal(fakeDropboxLoginResponse);
                        });
                        
                        it(@"pops itself off the navigation controller", ^{
                            OCMVerify([partialMock popViewControllerAnimated:YES]);
                        });
                        
                        it(@"removes the progress HUD", ^{
                            OCMVerify([hudClassMethodMock hideHUDForView:controller.view
                                                                animated:YES]);
                        });
                    });
                    
                    context(@"does NOT have a navigation controller", ^{
                        beforeEach(^{
                            partialMock = OCMPartialMock(controller);
                            
                            if (fakeLoginManager.success) {
                                fakeLoginManager.success(fakeDropboxLoginResponse);
                            }
                        });
                        
                        it(@"calls completion with dropbox login response", ^{
                            expect(retLoginResponse).to.equal(fakeDropboxLoginResponse);
                        });
                        
                        it(@"pops itself off the navigation controller", ^{
                            OCMVerify([partialMock dismissViewControllerAnimated:YES completion:nil]);
                        });
                        
                        it(@"removes the progress HUD", ^{
                            OCMVerify([hudClassMethodMock hideHUDForView:controller.view
                                                                animated:YES]);
                        });
                    });
                });
                
                context(@"failure while attempting to get auth token from Dropbox", ^{
                    __block id partialMock;
                    __block NSError *bogusError;
                    
                    beforeEach(^{
                        bogusError = [[NSError alloc] initWithDomain:@"bogusDomain" code:177 userInfo:@{ @"NSLocalizedDescription" : @"boooogussss"}];
                    });
                    
                    context(@"shouldShowErrorAlert == YES", ^{
                        beforeEach(^{
                            controller.shouldShowErrorAlert = YES;
                            [controller webView:nil didFailLoadWithError:bogusError];
                        });
                        
                        it(@"displays a UIAlertView with proper error", ^{
                            UIAlertView *errorAlert = [UIAlertView currentAlertView];
                            expect(errorAlert.title).to.equal(@"Dropbox Login Error");
                            expect(errorAlert.message).to.equal(@"bogusDomain - boooogussss");
                        });
                    });
                    
                    context(@"shouldShowErrorAlert == NO", ^{
                        beforeEach(^{
                            controller.shouldShowErrorAlert = NO;
                            [controller webView:nil didFailLoadWithError:bogusError];
                        });
                        
                        it(@"does not display alert view for the error", ^{
                            UIAlertView *errorAlert = [UIAlertView currentAlertView];
                            expect(errorAlert).to.beNil();
                        });
                    });
                    
                    context(@"has a navigation controlller", ^{
                        beforeEach(^{
                            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                            partialMock = OCMPartialMock(navigationController);
                            
                            if (fakeLoginManager.failure) {
                                fakeLoginManager.failure(bogusError);
                            }
                        });
                        
                        it(@"calls completion with nil token", ^{
                            expect(retLoginResponse).to.beNil();
                        });
                        
                        it(@"calls completion with AFNetworking error", ^{
                            expect(retError).to.equal(bogusError);
                        });
                        
                        it(@"pops itself off the navigation controller", ^{
                            OCMVerify([partialMock popViewControllerAnimated:YES]);
                        });
                        
                        it(@"removes the progress HUD", ^{
                            OCMVerify([hudClassMethodMock hideHUDForView:controller.view
                                                                animated:YES]);
                        });
                    });
                    
                    context(@"does NOT have a navigation controller", ^{
                        beforeEach(^{
                            partialMock = OCMPartialMock(controller);
                            
                            if (fakeLoginManager.failure) {
                                fakeLoginManager.failure(bogusError);
                            }
                        });
                        
                        it(@"calls completion with nil token", ^{
                            expect(retLoginResponse).to.beNil();
                        });
                        
                        it(@"calls completion with AFNetworking error", ^{
                            expect(retError).to.equal(bogusError);
                        });
                        
                        it(@"pops itself off the view controller", ^{
                            OCMVerify([partialMock dismissViewControllerAnimated:YES completion:nil]);
                        });
                        
                        it(@"removes the progress HUD", ^{
                            OCMVerify([hudClassMethodMock hideHUDForView:controller.view
                                                                animated:YES]);
                        });
                    });
                });
                
                it(@"returns NO", ^{
                    expect(shouldStartLoad).to.beFalsy();
                });
            });
            
            context(@"request does NOT contain dropbox callback URL", ^{
                beforeEach(^{
                    fakeURLRequest = OCMClassMock([NSURLRequest class]);
                    
                    fakeLoginUtils = OCMClassMock([DropboxLoginUtils class]);
                    controller.dropboxLoginUtils = fakeLoginUtils;
                    OCMStub([controller.dropboxLoginUtils requestHasAuthCode:fakeURLRequest]).andReturn(NO);
                    
                    shouldStartLoad = [controller webView:nil
                               shouldStartLoadWithRequest:fakeURLRequest
                                           navigationType:UIWebViewNavigationTypeFormSubmitted];
                });
                
                it(@"returns YES", ^{
                    expect(shouldStartLoad).to.beTruthy();
                });
            });
        });
        
        describe(@"#webViewDidFinishLoad:", ^{
            __block id hudClassMethodMock;
            
            beforeEach(^{
                hudClassMethodMock = OCMClassMock([MBProgressHUD class]);
                [controller webViewDidFinishLoad:nil];
            });
            
            it(@"removes the progress HUD", ^{
                OCMVerify([hudClassMethodMock hideHUDForView:controller.view
                                                    animated:YES]);
            });
        });
        
        describe(@"#webView:didFailLoadWithError:", ^{
            __block id hudClassMethodMock;
            __block NSError *bogusRequestError;
            
            beforeEach(^{
                hudClassMethodMock = OCMClassMock([MBProgressHUD class]);
            });
            
            context(@"error code 102 (WebKitErrorDomain)", ^{
                beforeEach(^{
                    bogusRequestError = [NSError errorWithDomain:@"LameWebKitErrorThatHappensForNoGoodReason"
                                                            code:102
                                                        userInfo:@{ @"NSLocalizedDescription" : @"WTH Error"}];
                    
                    [controller webView:nil didFailLoadWithError:bogusRequestError];
                });
                
                it(@"does not display alert view for the error", ^{
                    UIAlertView *errorAlert = [UIAlertView currentAlertView];
                    expect(errorAlert).to.beNil();
                });
                
                it(@"removes the progress HUD", ^{
                    OCMVerify([hudClassMethodMock hideHUDForView:controller.view
                                                        animated:YES]);
                });
            });
            
            context(@"all other error codes", ^{
                __block id partialMock;
                
                beforeEach(^{
                    bogusRequestError = [NSError errorWithDomain:@"NSURLBlowUpDomainBOOM"
                                                            code:42
                                                        userInfo:@{ @"NSLocalizedDescription" : @"You have no internetz and what not"}];
                });
                
                context(@"shouldShowErrorAlert == YES", ^{
                    beforeEach(^{
                        controller.shouldShowErrorAlert = YES;
                        [controller webView:nil didFailLoadWithError:bogusRequestError];
                    });
                    
                    it(@"displays a UIAlertView with proper error", ^{
                        UIAlertView *errorAlert = [UIAlertView currentAlertView];
                        expect(errorAlert.title).to.equal(@"Dropbox Login Error");
                        expect(errorAlert.message).to.equal(@"NSURLBlowUpDomainBOOM - You have no internetz and what not");
                    });
                });
                
                context(@"shouldShowErrorAlert == NO", ^{
                    beforeEach(^{
                        controller.shouldShowErrorAlert = NO;
                        [controller webView:nil didFailLoadWithError:bogusRequestError];
                    });
                    
                    it(@"does not display alert view for the error", ^{
                        UIAlertView *errorAlert = [UIAlertView currentAlertView];
                        expect(errorAlert).to.beNil();
                    });
                });
                
                context(@"has a navigation controlller", ^{
                    beforeEach(^{
                        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                        partialMock = OCMPartialMock(navigationController);
                        
                        [controller webView:nil didFailLoadWithError:bogusRequestError];
                    });
                    
                    it(@"calls completion with nil token", ^{
                        expect(retLoginResponse).to.beNil();
                    });
                    
                    it(@"calls completion with request error", ^{
                        expect(retError).to.equal(bogusRequestError);
                    });
                    
                    it(@"pops itself off the navigation controller", ^{
                        OCMVerify([partialMock popViewControllerAnimated:YES]);
                    });
                    
                    it(@"removes the progress HUD", ^{
                        OCMVerify([hudClassMethodMock hideHUDForView:controller.view
                                                            animated:YES]);
                    });
                });
                
                context(@"does NOT have a navigation controller", ^{
                    beforeEach(^{
                        partialMock = OCMPartialMock(controller);
                        
                        [controller webView:nil didFailLoadWithError:bogusRequestError];
                    });
                    
                    it(@"calls completion with nil token", ^{
                        expect(retLoginResponse).to.beNil();
                    });
                    
                    it(@"calls completion with request error", ^{
                        expect(retError).to.equal(bogusRequestError);
                    });
                    
                    it(@"pops itself off the view controller", ^{
                        OCMVerify([partialMock dismissViewControllerAnimated:YES completion:nil]);
                    });
                    
                    it(@"removes the progress HUD", ^{
                        OCMVerify([hudClassMethodMock hideHUDForView:controller.view
                                                            animated:YES]);
                    });
                });
            });
        });
    });
});

SpecEnd
