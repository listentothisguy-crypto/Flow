#import "FLApplicationController.h"
#import "FlowModels.h"

@implementation FLApplicationController

@synthesize musicalPieces;
@synthesize thoughts;
@synthesize apps;
@synthesize purchases;
@synthesize healthItems;
@synthesize promotions;

- (id)init
{
    self = [super init];

    if (self)
    {
        musicalPieces = [[NSMutableArray alloc] init];
        thoughts      = [[NSMutableArray alloc] init];
        apps          = [[NSMutableArray alloc] init];
        purchases     = [[NSMutableArray alloc] init];
        healthItems   = [[NSMutableArray alloc] init];
        promotions    = [[NSMutableArray alloc] init];

        NSLog(@"Flow controller initialized.");
    }

    return self;
}

- (void)dealloc
{
    [musicalPieces release];
    [thoughts release];
    [apps release];
    [purchases release];
    [healthItems release];
    [promotions release];

    [super dealloc];
}

@synthesize mainWindow;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
   
    NSLog(@"Flow started.");
    [self loadSampleData];
    flowSelectorController = [[FlowSelectorController alloc] init];
    [[mainWindow contentView] addSubview:[flowSelectorController view]];
    [mainWindow makeKeyAndOrderFront:nil];

}
- (void)showFlows
{
    NSLog(@"Showing Flows");
}

@end
