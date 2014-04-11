//
//  UILabel+AllowCopy.m
//  CroatianEventCalendar
//
//  Created by Lori Hill on 4/10/14.
//  Copyright (c) 2014 Lori Hill. All rights reserved.
//

#import "UILabel+AllowCopy.h"

@implementation UILabel (AllowCopy)

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

@end
