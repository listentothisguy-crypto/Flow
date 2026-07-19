#import <Foundation/Foundation.h>
#import "../Sources/FLProject.h"
#import "../Sources/FLProjectStore.h"

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *path = @"/tmp/flow-store-smoke.sqlite";
    NSString *archivePath = @"/tmp/flow-store-smoke.flowlib";
    NSString *importPath = @"/tmp/flow-store-import.sqlite";
    [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
    [[NSFileManager defaultManager] removeFileAtPath:archivePath handler:nil];
    [[NSFileManager defaultManager] removeFileAtPath:importPath handler:nil];

    NSError *error = nil;
    FLProjectStore *store = [[FLProjectStore alloc] initWithPath:path error:&error];
    if (!store) return 1;

    NSArray *flows = [store flowNames:&error];
    if ([flows count] != 7) return 10;
    NSArray *musicalPieceCategories = [store subcategoriesForFlow:@"Musical Pieces" error:&error];
    if ([musicalPieceCategories count] != 2 || ![[musicalPieceCategories objectAtIndex:1] isEqualToString:@"Instrumentals"]) return 11;
    NSArray *instrumentCategories = [store subcategoriesForFlow:@"Instruments" error:&error];
    if ([instrumentCategories count] != 3 || ![[instrumentCategories objectAtIndex:2] isEqualToString:@"Drum Modules"]) return 12;

    FLProject *project = [[FLProject alloc] init];
    [project setTitle:@"Smoke Test"];
    [project setProductionStage:@"Idea"];
    [project setCompletionPercent:10];
    [project setNextAction:@"Verify persistence"];
    [project setNotes:@"Basic SQLite test record."];
    if (![store saveProject:project error:&error]) return 2;

    NSArray *projects = [store allProjects:&error];
    if ([projects count] != 1) return 3;
    FLProject *loaded = [projects objectAtIndex:0];
    if (![[loaded title] isEqualToString:@"Smoke Test"]) return 4;
    if ([loaded completionPercent] != 10) return 5;
    if (![[loaded artist] isEqualToString:@"Vincent Foissard"]) return 6;
    if (![[loaded projectType] isEqualToString:@"Song"]) return 7;
    if (![[loaded flowName] isEqualToString:@"Musical Pieces"] || ![[loaded subcategory] isEqualToString:@"Songs"]) return 13;

    FLProject *thought = [[FLProject alloc] init];
    [thought setTitle:@"App navigation idea"];
    [thought setFlowName:@"Thoughts"];
    [thought setSubcategory:nil];
    [thought setClassification:@"App idea"];
    [thought setTags:@"ui, workflow"];
    if (![store saveProject:thought error:&error]) return 14;

    NSString *collectionIdentifier = [store createCollectionWithName:@"Smoke Album" type:@"Album" notes:nil error:&error];
    if (!collectionIdentifier) return 16;
    if (![store addMusicalPiece:[project identifier] toCollection:collectionIdentifier atPosition:1 error:&error]) return 17;
    if ([store addMusicalPiece:[thought identifier] toCollection:collectionIdentifier atPosition:2 error:&error]) return 18;
    if (![store saveRelationshipFrom:[project identifier] relationship:@"inspired" to:[thought identifier] notes:nil error:&error]) return 19;

    FLProject *invalidThought = [[FLProject alloc] init];
    [invalidThought setTitle:@"Invalid thought"];
    [invalidThought setFlowName:@"Thoughts"];
    [invalidThought setSubcategory:@"App Ideas"];
    if ([store saveProject:invalidThought error:&error]) return 15;
    if (![store exportArchiveToPath:archivePath error:&error]) return 20;
    FLProjectStore *importStore = [[FLProjectStore alloc] initWithPath:importPath error:&error];
    if (!importStore || ![importStore importArchiveFromPath:archivePath error:&error]) return 21;
    NSArray *imported = [importStore allProjects:&error];
    if ([imported count] != 2) return 22;
    [importStore release];
    if (![store seedSampleProjectsIfNeeded:&error]) return 8;
    projects = [store allProjects:&error];
    if ([projects count] != 12) return 9;

    [invalidThought release];
    [thought release];
    [project release];
    [store release];
    [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
    [[NSFileManager defaultManager] removeFileAtPath:archivePath handler:nil];
    [[NSFileManager defaultManager] removeFileAtPath:importPath handler:nil];
    [pool release];
    return 0;
}
