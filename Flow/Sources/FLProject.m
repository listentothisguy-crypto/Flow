#import "FLProject.h"

@implementation FLProject

- (id)init
{
    self = [super init];
    if (self) {
        _completionPercent = 0;
        _artist = [@"Vincent Foissard" retain];
        _projectType = [@"Song" retain];
        _flowName = [@"Musical Pieces" retain];
        _subcategory = [@"Songs" retain];
    }
    return self;
}

- (void)dealloc
{
    [_identifier release];
    [_title release];
    [_artist release];
    [_projectType release];
    [_flowName release];
    [_subcategory release];
    [_classification release];
    [_tags release];
    [_metadata release];
    [_mood release];
    [_productionStage release];
    [_nextAction release];
    [_notes release];
    [_createdAt release];
    [_updatedAt release];
    [super dealloc];
}

- (NSString *)identifier { return _identifier; }
- (void)setIdentifier:(NSString *)value { [value retain]; [_identifier release]; _identifier = value; }
- (NSString *)title { return _title; }
- (void)setTitle:(NSString *)value { [value retain]; [_title release]; _title = value; }
- (NSString *)artist { return _artist; }
- (void)setArtist:(NSString *)value
{
    if (!value || [value length] == 0) value = @"Vincent Foissard";
    [value retain];
    [_artist release];
    _artist = value;
}
- (NSString *)projectType { return _projectType; }
- (void)setProjectType:(NSString *)value
{
    if (!value || [value length] == 0) value = @"Song";
    [value retain];
    [_projectType release];
    _projectType = value;
}
- (NSString *)flowName { return _flowName; }
- (void)setFlowName:(NSString *)value { [value retain]; [_flowName release]; _flowName = value; }
- (NSString *)subcategory { return _subcategory; }
- (void)setSubcategory:(NSString *)value { [value retain]; [_subcategory release]; _subcategory = value; }
- (NSString *)classification { return _classification; }
- (void)setClassification:(NSString *)value { [value retain]; [_classification release]; _classification = value; }
- (NSString *)tags { return _tags; }
- (void)setTags:(NSString *)value { [value retain]; [_tags release]; _tags = value; }
- (NSString *)metadata { return _metadata; }
- (void)setMetadata:(NSString *)value { [value retain]; [_metadata release]; _metadata = value; }
- (NSString *)mood { return _mood; }
- (void)setMood:(NSString *)value { [value retain]; [_mood release]; _mood = value; }
- (NSInteger)bpm { return _bpm; }
- (void)setBpm:(NSInteger)value { _bpm = value; }
- (NSString *)productionStage { return _productionStage; }
- (void)setProductionStage:(NSString *)value { [value retain]; [_productionStage release]; _productionStage = value; }
- (NSInteger)completionPercent { return _completionPercent; }
- (void)setCompletionPercent:(NSInteger)value { _completionPercent = value; }
- (NSString *)nextAction { return _nextAction; }
- (void)setNextAction:(NSString *)value { [value retain]; [_nextAction release]; _nextAction = value; }
- (NSString *)notes { return _notes; }
- (void)setNotes:(NSString *)value { [value retain]; [_notes release]; _notes = value; }
- (NSString *)createdAt { return _createdAt; }
- (void)setCreatedAt:(NSString *)value { [value retain]; [_createdAt release]; _createdAt = value; }
- (NSString *)updatedAt { return _updatedAt; }
- (void)setUpdatedAt:(NSString *)value { [value retain]; [_updatedAt release]; _updatedAt = value; }

@end
