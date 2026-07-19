#import "FLApplicationController.h"
#import "FLProject.h"
#import "FLProjectStore.h"

@implementation FLApplicationController

- (void)dealloc
{
    [_store release];
    [_projects release];
    [_selectedProject release];
    [_window release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *flowPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Flow"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:flowPath]) [fileManager createDirectoryAtPath:flowPath attributes:nil];

    NSError *error = nil;
    _store = [[FLProjectStore alloc] initWithPath:[flowPath stringByAppendingPathComponent:@"Flow.sqlite"] error:&error];
    if (!_store) {
        NSRunAlertPanel(@"Flow could not start", @"The Flow database could not be opened.", @"Quit", nil, nil);
        [NSApp terminate:nil];
        return;
    }
    if (![_store seedSampleProjectsIfNeeded:&error]) {
        NSRunAlertPanel(@"Flow warning", @"Sample Flow items could not be added.", @"OK", nil, nil);
    }
    [self buildWindow];
    [self reloadProjects];
    [self showCatalogue:nil];
    [_window makeKeyAndOrderFront:nil];
}

- (NSButton *)buttonWithTitle:(NSString *)title frame:(NSRect)frame action:(SEL)action
{
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    [button setTitle:title];
    [button setTarget:self];
    [button setAction:action];
    return [button autorelease];
}

- (NSTextField *)labelWithText:(NSString *)text frame:(NSRect)frame
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:text];
    [label setEditable:NO];
    [label setBordered:NO];
    [label setDrawsBackground:NO];
    [label setFont:[NSFont systemFontOfSize:11.0]];
    return [label autorelease];
}

- (void)buildWindow
{
    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 760, 500)
                                           styleMask:(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask)
                                             backing:NSBackingStoreBuffered defer:NO];
    [_window setTitle:@"Flow — Flow Library"];
    [_window setMinSize:NSMakeSize(640, 400)];
    NSView *content = [_window contentView];

    NSButton *catalogueButton = [self buttonWithTitle:@"Catalogue" frame:NSMakeRect(14, 466, 100, 24) action:@selector(showCatalogue:)];
    NSButton *detailButton = [self buttonWithTitle:@"Flow Detail" frame:NSMakeRect(122, 466, 110, 24) action:@selector(showDetail:)];
    NSButton *newButton = [self buttonWithTitle:@"New Flow" frame:NSMakeRect(240, 466, 100, 24) action:@selector(showNewProject:)];
    NSButton *importButton = [self buttonWithTitle:@"Import" frame:NSMakeRect(348, 466, 80, 24) action:@selector(importLibrary:)];
    NSButton *exportButton = [self buttonWithTitle:@"Export" frame:NSMakeRect(436, 466, 80, 24) action:@selector(exportLibrary:)];
    NSButton *quitButton = [self buttonWithTitle:@"Quit" frame:NSMakeRect(666, 466, 80, 24) action:@selector(quitApplication:)];
    [catalogueButton setAutoresizingMask:NSViewMinYMargin];
    [detailButton setAutoresizingMask:NSViewMinYMargin];
    [newButton setAutoresizingMask:NSViewMinYMargin];
    [importButton setAutoresizingMask:NSViewMinYMargin];
    [exportButton setAutoresizingMask:NSViewMinYMargin];
    [quitButton setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
    [content addSubview:catalogueButton];
    [content addSubview:detailButton];
    [content addSubview:newButton];
    [content addSubview:importButton];
    [content addSubview:exportButton];
    [content addSubview:quitButton];

    _catalogueView = [[NSView alloc] initWithFrame:NSMakeRect(14, 14, 732, 440)];
    [_catalogueView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [content addSubview:_catalogueView];
    [self buildCatalogueView];

    _detailView = [[NSView alloc] initWithFrame:[_catalogueView frame]];
    [_detailView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [content addSubview:_detailView];
    [self buildDetailView];

    _newProjectView = [[NSView alloc] initWithFrame:[_catalogueView frame]];
    [_newProjectView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [content addSubview:_newProjectView];
    [self buildNewProjectView];
}

- (void)buildCatalogueView
{
    NSTextField *heading = [self labelWithText:@"Flow Library" frame:NSMakeRect(0, 412, 300, 18)];
    [heading setFont:[NSFont boldSystemFontOfSize:14.0]];
    [_catalogueView addSubview:heading];
    [_catalogueView addSubview:[self labelWithText:@"Select a Flow item and open Flow Detail to view it." frame:NSMakeRect(0, 390, 420, 17)]];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 732, 380)];
    [scroll setHasVerticalScroller:YES];
    [scroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    _tableView = [[NSTableView alloc] initWithFrame:[[scroll contentView] bounds]];
    [self addColumn:@"title" title:@"Flow Item" width:170 toTable:_tableView];
    [self addColumn:@"flow" title:@"Flow" width:115 toTable:_tableView];
    [self addColumn:@"subcategory" title:@"Subcategory" width:110 toTable:_tableView];
    [self addColumn:@"classification" title:@"Classification" width:125 toTable:_tableView];
    [self addColumn:@"tags" title:@"Tags" width:190 toTable:_tableView];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setAllowsEmptySelection:YES];
    [_tableView setDoubleAction:@selector(showDetail:)];
    [_tableView setTarget:self];
    [scroll setDocumentView:_tableView];
    [_catalogueView addSubview:scroll];
    [scroll release];
}

- (void)addColumn:(NSString *)identifier title:(NSString *)title width:(CGFloat)width toTable:(NSTableView *)table
{
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifier];
    [column setWidth:width];
    [[column headerCell] setStringValue:title];
    [table addTableColumn:column];
    [column release];
}

- (void)buildDetailView
{
    NSTextField *heading = [self labelWithText:@"Flow Detail" frame:NSMakeRect(0, 412, 300, 18)];
    [heading setFont:[NSFont boldSystemFontOfSize:14.0]];
    [_detailView addSubview:heading];
    [_detailView addSubview:[self labelWithText:@"Structure is Flow and subcategory; classification and tags describe the item." frame:NSMakeRect(0, 390, 550, 17)]];

    [_detailView addSubview:[self labelWithText:@"Title" frame:NSMakeRect(0, 350, 160, 17)]];
    _detailTitleField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 326, 500, 24)];
    [_detailTitleField setAutoresizingMask:NSViewWidthSizable];
    [_detailView addSubview:_detailTitleField];

    [_detailView addSubview:[self labelWithText:@"Flow" frame:NSMakeRect(0, 288, 160, 17)]];
    _detailFlowPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 262, 220, 26) pullsDown:NO];
    [_detailFlowPopup addItemsWithTitles:[NSArray arrayWithObjects:@"Musical Pieces", @"Instruments", @"Thoughts", @"Promotion", @"Apps", @"Purchases", @"Health", nil]];
    [_detailFlowPopup setTarget:self];
    [_detailFlowPopup setAction:@selector(flowSelectionChanged:)];
    [_detailView addSubview:_detailFlowPopup];
    [_detailView addSubview:[self labelWithText:@"Subcategory" frame:NSMakeRect(246, 288, 100, 17)]];
    _detailSubcategoryPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(246, 262, 140, 26) pullsDown:NO];
    [_detailView addSubview:_detailSubcategoryPopup];
    [_detailView addSubview:[self labelWithText:@"Classification" frame:NSMakeRect(406, 288, 100, 17)]];
    _detailClassificationField = [[NSTextField alloc] initWithFrame:NSMakeRect(406, 264, 150, 24)];
    [_detailView addSubview:_detailClassificationField];
    [_detailView addSubview:[self labelWithText:@"Tags" frame:NSMakeRect(576, 288, 100, 17)]];
    _detailTagsField = [[NSTextField alloc] initWithFrame:NSMakeRect(576, 264, 156, 24)];
    [_detailView addSubview:_detailTagsField];
    [_detailView addSubview:[self labelWithText:@"Mood" frame:NSMakeRect(0, 224, 100, 17)]];
    _detailMoodField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 200, 140, 24)];
    [_detailView addSubview:_detailMoodField];
    [_detailView addSubview:[self labelWithText:@"BPM" frame:NSMakeRect(160, 224, 60, 17)]];
    _detailBpmField = [[NSTextField alloc] initWithFrame:NSMakeRect(160, 200, 94, 24)];
    [_detailView addSubview:_detailBpmField];
    [_detailView addSubview:[self labelWithText:@"Stage" frame:NSMakeRect(274, 224, 160, 17)]];
    _detailStagePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(274, 198, 212, 26) pullsDown:NO];
    [_detailStagePopup addItemsWithTitles:[NSArray arrayWithObjects:@"Idea", @"Sketch", @"Writing", @"Demo", @"Recording", @"Editing", @"Mixing", @"Mastering", @"Released", nil]];
    [_detailView addSubview:_detailStagePopup];

    [_detailView addSubview:[self labelWithText:@"Completion" frame:NSMakeRect(506, 224, 100, 17)]];
    _detailCompletionField = [[NSTextField alloc] initWithFrame:NSMakeRect(506, 200, 55, 24)];
    [_detailView addSubview:_detailCompletionField];
    [_detailView addSubview:[self labelWithText:@"%" frame:NSMakeRect(566, 204, 20, 17)]];
    [_detailView addSubview:[self labelWithText:@"Next Action" frame:NSMakeRect(0, 162, 200, 17)]];
    _detailNextActionField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 138, 500, 24)];
    [_detailView addSubview:_detailNextActionField];
    NSButton *saveButton = [self buttonWithTitle:@"Save Flow" frame:NSMakeRect(610, 138, 122, 28) action:@selector(saveProjectChanges:)];
    [saveButton setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
    [_detailView addSubview:saveButton];

    [_detailView addSubview:[self labelWithText:@"Notes" frame:NSMakeRect(0, 112, 100, 17)]];
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 732, 102)];
    [scroll setHasVerticalScroller:YES];
    [scroll setBorderType:NSBezelBorder];
    [scroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    _detailNotesView = [[NSTextView alloc] initWithFrame:[[scroll contentView] bounds]];
    [_detailNotesView setVerticallyResizable:YES];
    [scroll setDocumentView:_detailNotesView];
    [_detailView addSubview:scroll];
    [scroll release];
}

- (void)buildNewProjectView
{
    NSTextField *heading = [self labelWithText:@"New Flow Item" frame:NSMakeRect(0, 412, 300, 18)];
    [heading setFont:[NSFont boldSystemFontOfSize:14.0]];
    [_newProjectView addSubview:heading];
    [_newProjectView addSubview:[self labelWithText:@"Choose a Flow first. Only Musical Pieces and Instruments have subcategories." frame:NSMakeRect(0, 390, 560, 17)]];
    [_newProjectView addSubview:[self labelWithText:@"Title" frame:NSMakeRect(0, 342, 100, 17)]];
    _newTitleField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 316, 400, 24)];
    [_newProjectView addSubview:_newTitleField];
    [_newProjectView addSubview:[self labelWithText:@"Flow" frame:NSMakeRect(0, 278, 100, 17)]];
    _newFlowPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 250, 220, 26) pullsDown:NO];
    [_newFlowPopup addItemsWithTitles:[NSArray arrayWithObjects:@"Musical Pieces", @"Instruments", @"Thoughts", @"Promotion", @"Apps", @"Purchases", @"Health", nil]];
    [_newFlowPopup setTarget:self];
    [_newFlowPopup setAction:@selector(flowSelectionChanged:)];
    [_newProjectView addSubview:_newFlowPopup];
    [_newProjectView addSubview:[self labelWithText:@"Subcategory" frame:NSMakeRect(246, 278, 100, 17)]];
    _newSubcategoryPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(246, 250, 160, 26) pullsDown:NO];
    [_newProjectView addSubview:_newSubcategoryPopup];
    [_newProjectView addSubview:[self labelWithText:@"Classification" frame:NSMakeRect(0, 212, 100, 17)]];
    _newClassificationField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 188, 280, 24)];
    [_newProjectView addSubview:_newClassificationField];
    [_newProjectView addSubview:[self labelWithText:@"Tags" frame:NSMakeRect(306, 212, 100, 17)]];
    _newTagsField = [[NSTextField alloc] initWithFrame:NSMakeRect(306, 188, 280, 24)];
    [_newProjectView addSubview:_newTagsField];
    [_newProjectView addSubview:[self buttonWithTitle:@"Create Flow" frame:NSMakeRect(0, 132, 120, 28) action:@selector(createProject:)]];
    [self updateSubcategoryPopup:_newSubcategoryPopup forFlow:[_newFlowPopup titleOfSelectedItem] selected:nil];
}

- (void)updateSubcategoryPopup:(NSPopUpButton *)popup forFlow:(NSString *)flowName selected:(NSString *)selected
{
    NSError *error = nil;
    NSArray *subcategories = [_store subcategoriesForFlow:flowName error:&error];
    [popup removeAllItems];
    if ([subcategories count] == 0) {
        [popup addItemWithTitle:@"None"];
        [popup setEnabled:NO];
    } else {
        [popup addItemsWithTitles:subcategories];
        [popup setEnabled:YES];
        if (selected && [subcategories containsObject:selected]) [popup selectItemWithTitle:selected];
    }
}

- (IBAction)flowSelectionChanged:(id)sender
{
    if (sender == _detailFlowPopup)
        [self updateSubcategoryPopup:_detailSubcategoryPopup forFlow:[_detailFlowPopup titleOfSelectedItem] selected:nil];
    else
        [self updateSubcategoryPopup:_newSubcategoryPopup forFlow:[_newFlowPopup titleOfSelectedItem] selected:nil];
}

- (IBAction)exportLibrary:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setTitle:@"Export Flow Library"];
    [panel setRequiredFileType:@"flowlib"];
    [panel setNameFieldStringValue:@"Flow Library.flowlib"];
    if ([panel runModal] != NSOKButton) return;
    NSError *error = nil;
    if (![_store exportArchiveToPath:[panel filename] error:&error]) {
        NSRunAlertPanel(@"Export failed", @"The Flow Library archive could not be exported.", @"OK", nil, nil);
        return;
    }
    NSRunAlertPanel(@"Export complete", @"The Flow Library archive was exported successfully.", @"OK", nil, nil);
}

- (IBAction)importLibrary:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setTitle:@"Import Flow Library"];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"flowlib"]];
    if ([panel runModal] != NSOKButton) return;
    NSError *error = nil;
    if (![_store importArchiveFromPath:[panel filename] error:&error]) {
        NSRunAlertPanel(@"Import failed", @"The selected file is not a valid Flow Library archive, or it could not be imported.", @"OK", nil, nil);
        return;
    }
    [self reloadProjects];
    [self showCatalogue:nil];
    NSRunAlertPanel(@"Import complete", @"The Flow Library archive was imported successfully.", @"OK", nil, nil);
}

- (NSString *)legacyProjectTypeForFlow:(NSString *)flowName subcategory:(NSString *)subcategory
{
    if ([flowName isEqualToString:@"Musical Pieces"] && [subcategory isEqualToString:@"Songs"]) return @"Song";
    if ([flowName isEqualToString:@"Musical Pieces"] && [subcategory isEqualToString:@"Instrumentals"]) return @"Instrumental";
    return flowName;
}

- (void)showOnlyView:(NSView *)view title:(NSString *)title
{
    [_catalogueView setHidden:(_catalogueView != view)];
    [_detailView setHidden:(_detailView != view)];
    [_newProjectView setHidden:(_newProjectView != view)];
    [_window setTitle:title];
}

- (void)reloadProjects
{
    NSError *error = nil;
    NSArray *loaded = [_store allProjects:&error];
    if (!loaded) {
        NSRunAlertPanel(@"Flow error", @"Flow items could not be loaded.", @"OK", nil, nil);
        return;
    }
    [_projects release];
    _projects = [loaded mutableCopy];
    [_tableView reloadData];
}

- (IBAction)showCatalogue:(id)sender
{
    [self showOnlyView:_catalogueView title:@"Flow — Flow Library"];
}

- (IBAction)showDetail:(id)sender
{
    if (!_selectedProject) {
        NSRunAlertPanel(@"Select a Flow", @"Select a Flow item in the Library first.", @"OK", nil, nil);
        [self showCatalogue:nil];
        return;
    }
    [_detailTitleField setStringValue:[_selectedProject title]];
    [_detailFlowPopup selectItemWithTitle:[_selectedProject flowName]];
    [self updateSubcategoryPopup:_detailSubcategoryPopup forFlow:[_selectedProject flowName] selected:[_selectedProject subcategory]];
    [_detailClassificationField setStringValue:[_selectedProject classification] ? [_selectedProject classification] : @""];
    [_detailTagsField setStringValue:[_selectedProject tags] ? [_selectedProject tags] : @""];
    [_detailMoodField setStringValue:[_selectedProject mood] ? [_selectedProject mood] : @""];
    [_detailBpmField setIntegerValue:[_selectedProject bpm]];
    [_detailStagePopup selectItemWithTitle:[_selectedProject productionStage]];
    [_detailCompletionField setIntegerValue:[_selectedProject completionPercent]];
    [_detailNextActionField setStringValue:[_selectedProject nextAction] ? [_selectedProject nextAction] : @""];
    [_detailNotesView setString:[_selectedProject notes] ? [_selectedProject notes] : @""];
    [self showOnlyView:_detailView title:@"Flow — Flow Detail"];
}

- (IBAction)showNewProject:(id)sender
{
    [_newTitleField setStringValue:@""];
    [_newFlowPopup selectItemWithTitle:@"Musical Pieces"];
    [_newClassificationField setStringValue:@""];
    [_newTagsField setStringValue:@""];
    [self updateSubcategoryPopup:_newSubcategoryPopup forFlow:@"Musical Pieces" selected:@"Songs"];
    [self showOnlyView:_newProjectView title:@"Flow — New Flow"];
    [_window makeFirstResponder:_newTitleField];
}

- (IBAction)createProject:(id)sender
{
    NSString *title = [[_newTitleField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([title length] == 0) {
        NSRunAlertPanel(@"A title is required", @"Enter a title before creating a Flow item.", @"OK", nil, nil);
        return;
    }
    FLProject *project = [[FLProject alloc] init];
    [project setTitle:title];
    NSString *flowName = [_newFlowPopup titleOfSelectedItem];
    NSString *subcategory = [_newSubcategoryPopup isEnabled] ? [_newSubcategoryPopup titleOfSelectedItem] : nil;
    [project setFlowName:flowName];
    [project setSubcategory:subcategory];
    [project setProjectType:[self legacyProjectTypeForFlow:flowName subcategory:subcategory]];
    [project setClassification:[_newClassificationField stringValue]];
    [project setTags:[_newTagsField stringValue]];
    [project setProductionStage:@"Idea"];
    NSError *error = nil;
    if (![_store saveProject:project error:&error]) {
        [project release];
        NSRunAlertPanel(@"Flow error", @"This Flow item could not be created.", @"OK", nil, nil);
        return;
    }
    [_selectedProject release];
    _selectedProject = project;
    [self reloadProjects];
    [self showDetail:nil];
}

- (IBAction)saveProjectChanges:(id)sender
{
    if (!_selectedProject) return;
    NSString *title = [[_detailTitleField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([title length] == 0) {
        NSRunAlertPanel(@"A title is required", @"Enter a title before saving this Flow item.", @"OK", nil, nil);
        return;
    }
    NSInteger completion = [_detailCompletionField integerValue];
    if (completion < 0) completion = 0;
    if (completion > 100) completion = 100;
    [_selectedProject setTitle:title];
    NSString *flowName = [_detailFlowPopup titleOfSelectedItem];
    NSString *subcategory = [_detailSubcategoryPopup isEnabled] ? [_detailSubcategoryPopup titleOfSelectedItem] : nil;
    [_selectedProject setFlowName:flowName];
    [_selectedProject setSubcategory:subcategory];
    [_selectedProject setProjectType:[self legacyProjectTypeForFlow:flowName subcategory:subcategory]];
    [_selectedProject setClassification:[_detailClassificationField stringValue]];
    [_selectedProject setTags:[_detailTagsField stringValue]];
    [_selectedProject setMood:[_detailMoodField stringValue]];
    [_selectedProject setBpm:[_detailBpmField integerValue]];
    [_selectedProject setProductionStage:[_detailStagePopup titleOfSelectedItem]];
    [_selectedProject setCompletionPercent:completion];
    [_selectedProject setNextAction:[_detailNextActionField stringValue]];
    [_selectedProject setNotes:[_detailNotesView string]];
    NSError *error = nil;
    if (![_store saveProject:_selectedProject error:&error]) {
        NSRunAlertPanel(@"Flow error", @"This Flow item could not be saved.", @"OK", nil, nil);
        return;
    }
    [self reloadProjects];
}

- (IBAction)quitApplication:(id)sender
{
    [NSApp terminate:sender];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_projects count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    FLProject *project = [_projects objectAtIndex:row];
    NSString *identifier = [column identifier];
    if ([identifier isEqualToString:@"title"]) return [project title];
    if ([identifier isEqualToString:@"flow"]) return [project flowName] ? [project flowName] : @"";
    if ([identifier isEqualToString:@"subcategory"]) return [project subcategory] ? [project subcategory] : @"";
    if ([identifier isEqualToString:@"classification"]) return [project classification] ? [project classification] : @"";
    if ([identifier isEqualToString:@"tags"]) return [project tags] ? [project tags] : @"";
    return @"";
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [_tableView selectedRow];
    if (row < 0 || row >= (NSInteger)[_projects count]) return;
    FLProject *project = [_projects objectAtIndex:row];
    [project retain];
    [_selectedProject release];
    _selectedProject = project;
}

@end
