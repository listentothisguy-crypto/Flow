//
//  FlowSelector.m
//  fowl
//
//  Created by Vince on 19/07/2026.
//
#import "FlowSelectorController.h"

@implementation FlowSelectorController

- (id)init
{
    self = [super init];

    if (self)
    {
    }

    return self;
}

- (void)loadView
{
    NSView *view;

    view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,200,500)];

    self.view = view;
}

@end
