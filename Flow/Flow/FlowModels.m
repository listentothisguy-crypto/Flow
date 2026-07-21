//
//  FlowModels.m
//

#import "FlowModels.h"

#pragma mark -
#pragma mark FLReferenceMix

@implementation FLReferenceMix

@synthesize name;
@synthesize audioFile;

- (id)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void)dealloc
{
    [name release];
    [audioFile release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLMedia

@implementation FLMedia

@synthesize type;
@synthesize file;

- (id)init
{
    self = [super init];
    if (self)
    {
        type = FLMediaTypeMP3;
    }

    return self;
}

- (void)dealloc
{
    [file release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLMusicalPiece

@implementation FLMusicalPiece

@synthesize musicalPieceID;
@synthesize title;
@synthesize type;
@synthesize origin;
@synthesize version;

@synthesize bpm;
@synthesize keyNote;
@synthesize keyAccidental;
@synthesize timeSignature;

@synthesize moodsTags;
@synthesize emotionalStructureGraphic;

@synthesize orchestrationLevel;

@synthesize lyricsFile;
@synthesize notesGenesisOther;

@synthesize relationships;

@synthesize media;
@synthesize referenceMix;

@synthesize guitarSounds;
@synthesize synthSounds;
@synthesize drumSounds;

@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;
@synthesize releaseDate;

@synthesize stage;
@synthesize progression;
@synthesize logicFile;

@synthesize colorCoding;
@synthesize widestSpectrum;
@synthesize fontCoding;

@synthesize publishingPackageOwnership;
@synthesize publishingPackageData;


- (id)init
{
    self = [super init];

    if (self)
    {
        type = FLTypeSong;
        origin = FLOriginOriginal;
        version = FLVersionStudio;

        bpm = 120;

        keyNote = FLNoteC;
        keyAccidental = FLAccidentalNone;

        orchestrationLevel = FLOrchestrationLevelStraight;
        stage = FLStageIdea;
        progression = 0.0f;

        moodsTags = [[NSMutableArray alloc] init];
        relationships = [[NSMutableArray alloc] init];
        media = [[NSMutableArray alloc] init];

        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}


- (void)touch
{
    [modifiedTimeStamp release];
    modifiedTimeStamp = [[NSDate date] retain];
}


- (void)dealloc
{
    [musicalPieceID release];
    [title release];

    [timeSignature release];

    [moodsTags release];
    [emotionalStructureGraphic release];

    [lyricsFile release];
    [notesGenesisOther release];

    [relationships release];

    [media release];
    [referenceMix release];

    [guitarSounds release];
    [synthSounds release];
    [drumSounds release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];
    [releaseDate release];

    [logicFile release];

    [colorCoding release];
    [widestSpectrum release];
    [fontCoding release];

    [publishingPackageOwnership release];
    [publishingPackageData release];

    [super dealloc];
}

@end
//
//  FlowModels.m
//



#pragma mark -
#pragma mark FLThought

@implementation FLThought

@synthesize thoughtID;
@synthesize title;
@synthesize essay;
@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;
@synthesize relationships;

- (id)init
{
    self = [super init];

    if (self)
    {
        relationships = [[NSMutableArray alloc] init];

        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}

- (void)dealloc
{
    [thoughtID release];
    [title release];
    [essay release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];

    [relationships release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLSynthesiser

@implementation FLSynthesiser

@synthesize synthesiserID;
@synthesize model;
@synthesize voiceListFile;
@synthesize observations;
@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;

- (id)init
{
    self = [super init];

    if (self)
    {
        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}

- (void)dealloc
{
    [synthesiserID release];
    [model release];
    [voiceListFile release];
    [observations release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLDrumModule

@implementation FLDrumModule

@synthesize drumModuleID;
@synthesize model;
@synthesize voiceDataManagementFile;
@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;

- (id)init
{
    self = [super init];

    if (self)
    {
        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}

- (void)dealloc
{
    [drumModuleID release];
    [model release];
    [voiceDataManagementFile release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLGuitar

@implementation FLGuitar

@synthesize guitarID;
@synthesize model;
@synthesize stateUseParticularity;
@synthesize maintenanceLog;
@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;

- (id)init
{
    self = [super init];

    if (self)
    {
        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}

- (void)dealloc
{
    [guitarID release];
    [model release];
    [stateUseParticularity release];
    [maintenanceLog release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLIntegration

@implementation FLIntegration

@synthesize name;
@synthesize integrationDescription;
@synthesize supportedFileExtension;

- (id)init
{
    self = [super init];

    if (self)
    {
    }

    return self;
}

- (void)dealloc
{
    [name release];
    [integrationDescription release];
    [supportedFileExtension release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLApp

@implementation FLApp

@synthesize appID;
@synthesize name;

@synthesize appDescription;

@synthesize designIssues;
@synthesize guiIssues;
@synthesize targets;
@synthesize dataStructure;

@synthesize integrations;
@synthesize languages;

@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;

@synthesize relationships;

- (id)init
{
    self = [super init];

    if (self)
    {
        integrations = [[NSMutableArray alloc] init];
        languages = [[NSMutableArray alloc] init];
        relationships = [[NSMutableArray alloc] init];

        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}

- (void)dealloc
{
    [appID release];
    [name release];

    [appDescription release];

    [designIssues release];
    [guiIssues release];
    [targets release];
    [dataStructure release];

    [integrations release];
    [languages release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];

    [relationships release];

    [super dealloc];
}

@end
#pragma mark -
#pragma mark FLPurchase

@implementation FLPurchase

@synthesize purchaseID;
@synthesize purchaseType;
@synthesize neededFor;
@synthesize informationSpecs;
@synthesize estimatedValue;
@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;
@synthesize relationships;

- (id)init
{
    self = [super init];

    if (self)
    {
        purchaseType = FLPurchaseTypeBuy;
        estimatedValue = 0.0;

        relationships = [[NSMutableArray alloc] init];

        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}

- (void)dealloc
{
    [purchaseID release];
    [neededFor release];
    [informationSpecs release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];

    [relationships release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLHealth

@implementation FLHealth

@synthesize healthID;
@synthesize name;
@synthesize healthDefinition;
@synthesize observation;
@synthesize practice;
@synthesize goals;

@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;

@synthesize relationships;

- (id)init
{
    self = [super init];

    if (self)
    {
        relationships = [[NSMutableArray alloc] init];

        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}

- (void)dealloc
{
    [healthID release];
    [name release];

    [healthDefinition release];
    [observation release];
    [practice release];
    [goals release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];

    [relationships release];

    [super dealloc];
}

@end


#pragma mark -
#pragma mark FLPromotion

@implementation FLPromotion

@synthesize promotionID;
@synthesize name;
@synthesize promotionDescription;

@synthesize taskCompleted;

@synthesize dateCreated;
@synthesize dateExecuted;

@synthesize createdTimeStamp;
@synthesize modifiedTimeStamp;

@synthesize media;
@synthesize relationships;

- (id)init
{
    self = [super init];

    if (self)
    {
        taskCompleted = NO;

        media = [[NSMutableArray alloc] init];
        relationships = [[NSMutableArray alloc] init];

        createdTimeStamp = [[NSDate date] retain];
        modifiedTimeStamp = [[NSDate date] retain];
    }

    return self;
}

- (void)dealloc
{
    [promotionID release];
    [name release];

    [promotionDescription release];

    [dateCreated release];
    [dateExecuted release];

    [createdTimeStamp release];
    [modifiedTimeStamp release];

    [media release];
    [relationships release];

    [super dealloc];
}

@end
