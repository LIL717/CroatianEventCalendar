//
//  SplitViewButtonHandler.h
//  CroatianEventCalendar
//
//  Created by Lori Hill on 4/13/14.
//  Copyright (c) 2014 Lori Hill. All rights reserved.
//

@protocol SplitViewButtonHandler <NSObject>

@property (nonatomic, strong) UIBarButtonItem *splitViewButton;

-(void)setSplitViewButton:(UIBarButtonItem *)splitViewButton forPopoverController:(UIPopoverController *)popoverController;

@end
