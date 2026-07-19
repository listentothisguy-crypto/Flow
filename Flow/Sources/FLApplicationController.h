#import <Cocoa/Cocoa.h>

@class FLProjectStore;
@class FLProject;

@interface FLApplicationController : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    FLProjectStore *_store;
    NSMutableArray *_projects;
    FLProject *_selectedProject;

    NSWindow *_window;
    NSView *_catalogueView;
    NSView *_detailView;
    NSView *_newProjectView;
    NSTableView *_tableView;
    NSTextField *_detailTitleField;
    NSPopUpButton *_detailFlowPopup;
    NSPopUpButton *_detailSubcategoryPopup;
    NSTextField *_detailClassificationField;
    NSTextField *_detailTagsField;
    NSTextField *_detailMoodField;
    NSTextField *_detailBpmField;
    NSPopUpButton *_detailStagePopup;
    NSTextField *_detailCompletionField;
    NSTextField *_detailNextActionField;
    NSTextView *_detailNotesView;
    NSTextField *_newTitleField;
    NSPopUpButton *_newFlowPopup;
    NSPopUpButton *_newSubcategoryPopup;
    NSTextField *_newClassificationField;
    NSTextField *_newTagsField;
}

- (IBAction)showCatalogue:(id)sender;
- (IBAction)showDetail:(id)sender;
- (IBAction)showNewProject:(id)sender;
- (IBAction)createProject:(id)sender;
- (IBAction)saveProjectChanges:(id)sender;
- (IBAction)flowSelectionChanged:(id)sender;
- (IBAction)exportLibrary:(id)sender;
- (IBAction)importLibrary:(id)sender;
- (IBAction)quitApplication:(id)sender;

@end
