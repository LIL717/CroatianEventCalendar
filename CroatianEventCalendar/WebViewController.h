//
//  WebViewController.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 3/29/14.
//  Copyright (c) 2014 Lori Hill. All rights reserved.
//

#import <UIKit/UIWebView.h>

@interface WebViewController : UIViewController  <UIWebViewDelegate> {
    UIWebView *webView_;
    UIBarButtonItem *backButton_;
    UIBarButtonItem *forwardButton_;
    NSURL *urlObject_;

}
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) NSURL *urlObject;

-(void) updateButtons;
-(void) goForward;
-(void) goBack;

@end