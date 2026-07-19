#import <Foundation/Foundation.h>

@class FLProject;
struct sqlite3;

@interface FLProjectStore : NSObject
{
    struct sqlite3 *_database;
    NSString *_databasePath;
}

- (id)initWithPath:(NSString *)path error:(NSError **)error;
- (NSArray *)allProjects:(NSError **)error;
- (NSArray *)flowNames:(NSError **)error;
- (NSArray *)subcategoriesForFlow:(NSString *)flowName error:(NSError **)error;
- (BOOL)saveProject:(FLProject *)project error:(NSError **)error;
- (BOOL)saveCollectionWithIdentifier:(NSString *)identifier name:(NSString *)name type:(NSString *)type notes:(NSString *)notes error:(NSError **)error;
- (NSString *)createCollectionWithName:(NSString *)name type:(NSString *)type notes:(NSString *)notes error:(NSError **)error;
- (BOOL)addMusicalPiece:(NSString *)pieceIdentifier toCollection:(NSString *)collectionIdentifier atPosition:(NSInteger)position error:(NSError **)error;
- (BOOL)saveRelationshipFrom:(NSString *)sourceIdentifier relationship:(NSString *)relationship to:(NSString *)targetIdentifier notes:(NSString *)notes error:(NSError **)error;
- (BOOL)exportArchiveToPath:(NSString *)path error:(NSError **)error;
- (BOOL)importArchiveFromPath:(NSString *)path error:(NSError **)error;
- (BOOL)seedSampleProjectsIfNeeded:(NSError **)error;
- (void)close;

@end
