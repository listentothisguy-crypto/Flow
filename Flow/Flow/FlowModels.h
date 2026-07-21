//////
// FlowModels.h
//

#import <Foundation/Foundation.h>

#pragma mark - Enumerations

typedef NS_ENUM(NSInteger, FLType)
{
    FLTypeSong = 0,
    FLTypeInstrumental
};

typedef NS_ENUM(NSInteger, FLOrigin)
{
    FLOriginOriginal = 0,
    FLOriginCover
};

typedef NS_ENUM(NSInteger, FLVersion)
{
    FLVersionLiveBand = 0,
    FLVersionStudio,
    FLVersionGuitar,
    FLVersionSynth
};

typedef NS_ENUM(NSInteger, FLOrchestrationLevel)
{
    FLOrchestrationLevelAcoustic = 0,
    FLOrchestrationLevelStraight,
    FLOrchestrationLevelElaborated,
    FLOrchestrationLevelLuxurious,
    FLOrchestrationLevelAtmospheric
};

typedef NS_ENUM(NSInteger, FLStage)
{
    FLStageIdea = 0,
    FLStageSketch,
    FLStageDemo,
    FLStageRecording,
    FLStageEditing,
    FLStageMixing,
    FLStagePublished
};

typedef NS_ENUM(NSInteger, FLNote)
{
    FLNoteC = 0,
    FLNoteD,
    FLNoteE,
    FLNoteF,
    FLNoteG,
    FLNoteA,
    FLNoteB
};

typedef NS_ENUM(NSInteger, FLAccidental)
{
    FLAccidentalNone = 0,
    FLAccidentalSharp,
    FLAccidentalFlat
};

typedef NS_ENUM(NSInteger, FLMediaType)
{
    FLMediaTypeMP3 = 0,
    FLMediaTypeJPEG,
    FLMediaTypeMP4,
    FLMediaTypeMOV
};

#pragma mark - Helper Objects

@interface FLReferenceMix : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSURL *audioFile;

@end

@interface FLMedia : NSObject

@property (nonatomic) FLMediaType type;
@property (nonatomic, strong) NSURL *file;

@end

#pragma mark - Musical Piece

@interface FLMusicalPiece : NSObject

#pragma mark - Identity

@property (nonatomic, copy) NSString *musicalPieceID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) FLType type;
@property (nonatomic) FLOrigin origin;
@property (nonatomic) FLVersion version;

#pragma mark - Musical

@property (nonatomic) NSInteger bpm;
@property (nonatomic) FLNote keyNote;
@property (nonatomic) FLAccidental keyAccidental;
@property (nonatomic, copy) NSString *timeSignature;

#pragma mark - Emotional

@property (nonatomic, strong) NSMutableArray<NSString *> *moodsTags;
@property (nonatomic, copy) NSString *emotionalStructureGraphic;

#pragma mark - Arrangement

@property (nonatomic) FLOrchestrationLevel orchestrationLevel;

#pragma mark - Lyrics / Notes

@property (nonatomic, strong) NSURL *lyricsFile;
@property (nonatomic, copy) NSString *notesGenesisOther;

#pragma mark - Relationships

@property (nonatomic, strong) NSMutableArray<NSString *> *relationships;

#pragma mark - Media

@property (nonatomic, strong) NSMutableArray<FLMedia *> *media;
@property (nonatomic, strong) FLReferenceMix *referenceMix;

#pragma mark - Sounds

@property (nonatomic, copy) NSString *guitarSounds;
@property (nonatomic, copy) NSString *synthSounds;
@property (nonatomic, copy) NSString *drumSounds;

#pragma mark - Dates

@property (nonatomic, strong) NSDate *createdTimeStamp;
@property (nonatomic, strong) NSDate *modifiedTimeStamp;
@property (nonatomic, strong) NSDate *releaseDate;

#pragma mark - Workflow

@property (nonatomic) FLStage stage;
@property (nonatomic) float progression;
@property (nonatomic, strong) NSURL *logicFile;

#pragma mark - Display

@property (nonatomic, copy) NSString *colorCoding;
@property (nonatomic, copy) NSString *widestSpectrum;
@property (nonatomic, copy) NSString *fontCoding;

#pragma mark - Publishing

@property (nonatomic, copy) NSString *publishingPackageOwnership;
@property (nonatomic, copy) NSString *publishingPackageData;

@end

#pragma mark - Thought

@interface FLThought : NSObject

@property (nonatomic, copy) NSString *thoughtID;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *essay;

@property (nonatomic, strong) NSDate *createdTimeStamp;

@property (nonatomic, strong) NSDate *modifiedTimeStamp;

@property (nonatomic, strong) NSMutableArray<NSString *> *relationships;

//
// FLInstrument.h
//
@end



#pragma mark - Synthesiser

@interface FLSynthesiser : NSObject

@property (nonatomic, copy) NSString *synthesiserID;

@property (nonatomic, copy) NSString *model;

@property (nonatomic, strong) NSURL *voiceListFile;

@property (nonatomic, copy) NSString *observations;

@property (nonatomic, strong) NSDate *createdTimeStamp;

@property (nonatomic, strong) NSDate *modifiedTimeStamp;

@end

#pragma mark - Drum Module

@interface FLDrumModule : NSObject

@property (nonatomic, copy) NSString *drumModuleID;

@property (nonatomic, copy) NSString *model;

@property (nonatomic, strong) NSURL *voiceDataManagementFile;

@property (nonatomic, strong) NSDate *createdTimeStamp;

@property (nonatomic, strong) NSDate *modifiedTimeStamp;

@end

#pragma mark - Guitar

@interface FLGuitar : NSObject

@property (nonatomic, copy) NSString *guitarID;

@property (nonatomic, copy) NSString *model;

@property (nonatomic, copy) NSString *stateUseParticularity;

@property (nonatomic, copy) NSString *maintenanceLog;

@property (nonatomic, strong) NSDate *createdTimeStamp;

@property (nonatomic, strong) NSDate *modifiedTimeStamp;

//
//  FLApp.h
//

@end

#pragma mark - Integration

@interface FLIntegration : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *integrationDescription;

@property (nonatomic, copy) NSString *supportedFileExtension;

@end

#pragma mark - App

@interface FLApp : NSObject

#pragma mark - Identity

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *name;

#pragma mark - Description

@property (nonatomic, copy) NSString *appDescription;

#pragma mark - Development

@property (nonatomic, copy) NSString *designIssues;
@property (nonatomic, copy) NSString *guiIssues;
@property (nonatomic, copy) NSString *targets;
@property (nonatomic, copy) NSString *dataStructure;

#pragma mark - Integrations

@property (nonatomic, strong) NSMutableArray<FLIntegration *> *integrations;

#pragma mark - Technologies

@property (nonatomic, strong) NSMutableArray<NSString *> *languages;

#pragma mark - Dates

@property (nonatomic, strong) NSDate *createdTimeStamp;
@property (nonatomic, strong) NSDate *modifiedTimeStamp;

#pragma mark - Relationships

@property (nonatomic, strong) NSMutableArray<NSString *> *relationships;
@end

//
//  FLPurchase.h
//



#pragma mark - Enumerations

typedef NS_ENUM(NSInteger, FLPurchaseType)
{
    FLPurchaseTypeBuy = 0,
    FLPurchaseTypeSell
};

#pragma mark - Purchase

@interface FLPurchase : NSObject

#pragma mark - Identity

@property (nonatomic, copy) NSString *purchaseID;

#pragma mark - Purchase Type

@property (nonatomic) FLPurchaseType purchaseType;

#pragma mark - Purpose

@property (nonatomic, copy) NSString *neededFor;

#pragma mark - Item

@property (nonatomic, copy) NSString *informationSpecs;

#pragma mark - Financial

@property (nonatomic) double estimatedValue;

#pragma mark - Dates

@property (nonatomic, strong) NSDate *createdTimeStamp;
@property (nonatomic, strong) NSDate *modifiedTimeStamp;

#pragma mark - Relationships

@property (nonatomic, strong) NSMutableArray<NSString *> *relationships;

@end
//
//  FLHealth.h
//



@interface FLHealth : NSObject

#pragma mark - Identity

@property (nonatomic, copy) NSString *healthID;

@property (nonatomic, copy) NSString *name;

#pragma mark - Definition

@property (nonatomic, copy) NSString *healthDefinition;

#pragma mark - Observation

@property (nonatomic, copy) NSString *observation;

#pragma mark - Practice

@property (nonatomic, copy) NSString *practice;

#pragma mark - Goals

@property (nonatomic, copy) NSString *goals;

#pragma mark - Dates

@property (nonatomic, strong) NSDate *createdTimeStamp;
@property (nonatomic, strong) NSDate *modifiedTimeStamp;

#pragma mark - Relationships

@property (nonatomic, strong) NSMutableArray<NSString *> *relationships;


@end
//
//  FLPromotion.h
//



#pragma mark - Promotion

@interface FLPromotion : NSObject

#pragma mark - Identity

@property (nonatomic, copy) NSString *promotionID;

@property (nonatomic, copy) NSString *name;

#pragma mark - Description

@property (nonatomic, copy) NSString *promotionDescription;

#pragma mark - Task

@property (nonatomic) BOOL taskCompleted;

#pragma mark - Dates

@property (nonatomic, strong) NSDate *dateCreated;

@property (nonatomic, strong) NSDate *dateExecuted;

@property (nonatomic, strong) NSDate *createdTimeStamp;
@property (nonatomic, strong) NSDate *modifiedTimeStamp;

#pragma mark - Media

@property (nonatomic, strong) NSMutableArray<NSURL *> *media;

#pragma mark - Relationships

@property (nonatomic, strong) NSMutableArray<NSString *> *relationships;


@end
