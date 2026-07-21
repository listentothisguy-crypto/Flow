#import <Cocoa/Cocoa.h>
#import "FlowSelectorController.h"

@class FLMusicalPiece;
@class FLThought;
@class FLApp;
@class FLPurchase;
@class FLHealth;
@class FLPromotion;

@class FlowSelectorController;


@interface FLApplicationController : NSObject <NSApplicationDelegate>
{
    IBOutlet NSWindow *mainWindow;
    NSMutableArray *musicalPieces;
    NSMutableArray *thoughts;
    NSMutableArray *apps;
    NSMutableArray *purchases;
    NSMutableArray *healthItems;
    NSMutableArray *promotions;
    FlowSelectorController *flowSelectorController;
}

@property (assign) IBOutlet NSWindow *mainWindow;
@property (nonatomic, retain) NSMutableArray *musicalPieces;
@property (nonatomic, retain) NSMutableArray *thoughts;
@property (nonatomic, retain) NSMutableArray *apps;
@property (nonatomic, retain) NSMutableArray *purchases;
@property (nonatomic, retain) NSMutableArray *healthItems;
@property (nonatomic, retain) NSMutableArray *promotions;

/* Startup */
- (void)applicationDidFinishLaunching:(NSNotification *)notification;


/* Slice 1 */

- (void)displayFlows;
- (void)showFlowSelector;
- (void)showThoughtCatalog;
- (void)showFlows;


@end
