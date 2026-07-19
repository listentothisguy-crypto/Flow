#import "FLProjectStore.h"
#import "FLProject.h"
#import <sqlite3.h>
#import <CoreFoundation/CoreFoundation.h>
#include <time.h>

static NSString *FLStoreErrorDomain = @"com.flowapp.Flow.Store";

static NSString *FLCurrentTimestamp(void)
{
    char buffer[32];
    time_t now = time(NULL);
    struct tm utc;
    gmtime_r(&now, &utc);
    strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &utc);
    return [NSString stringWithUTF8String:buffer];
}

static NSString *FLNewIdentifier(void)
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef string = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    NSString *identifier = [(NSString *)string autorelease];
    CFRelease(uuid);
    return identifier;
}

static void FLBindText(sqlite3_stmt *statement, int index, NSString *value)
{
    if (value) {
        sqlite3_bind_text(statement, index, [value UTF8String], -1, SQLITE_TRANSIENT);
    } else {
        sqlite3_bind_null(statement, index);
    }
}

static NSString *FLColumnText(sqlite3_stmt *statement, int index)
{
    const unsigned char *text = sqlite3_column_text(statement, index);
    return text ? [NSString stringWithUTF8String:(const char *)text] : nil;
}

static BOOL FLIsValidFlowAndSubcategory(NSString *flowName, NSString *subcategory)
{
    if ([flowName isEqualToString:@"Musical Pieces"])
        return [subcategory isEqualToString:@"Songs"] || [subcategory isEqualToString:@"Instrumentals"];
    if ([flowName isEqualToString:@"Instruments"])
        return [subcategory isEqualToString:@"Synthesizers"] || [subcategory isEqualToString:@"Guitars"] || [subcategory isEqualToString:@"Drum Modules"];
    if ([flowName isEqualToString:@"Thoughts"] || [flowName isEqualToString:@"Promotion"] || [flowName isEqualToString:@"Apps"] || [flowName isEqualToString:@"Purchases"] || [flowName isEqualToString:@"Health"])
        return !subcategory || [subcategory length] == 0;
    return NO;
}

static void FLSetValidationError(NSError **error, NSString *description)
{
    if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:SQLITE_CONSTRAINT userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
}

static NSString *FLValue(NSDictionary *dictionary, NSString *key)
{
    id value = [dictionary objectForKey:key];
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

static void FLAddValue(NSMutableDictionary *dictionary, NSString *key, NSString *value)
{
    if (value) [dictionary setObject:value forKey:key];
}

static BOOL FLProjectExists(sqlite3 *database, NSString *identifier)
{
    if (!identifier || ![identifier length]) return NO;
    sqlite3_stmt *statement = NULL;
    BOOL exists = NO;
    if (sqlite3_prepare(database, "SELECT 1 FROM projects WHERE id = ?", -1, &statement, NULL) == SQLITE_OK) {
        FLBindText(statement, 1, identifier);
        exists = (sqlite3_step(statement) == SQLITE_ROW);
    }
    if (statement) sqlite3_finalize(statement);
    return exists;
}

@implementation FLProjectStore

- (id)initWithPath:(NSString *)path error:(NSError **)error
{
    self = [super init];
    if (!self) return nil;

    _databasePath = [path copy];
    if (sqlite3_open([_databasePath fileSystemRepresentation], &_database) != SQLITE_OK) {
        if (error) {
            *error = [NSError errorWithDomain:FLStoreErrorDomain code:1 userInfo:nil];
        }
        [self close];
        [self release];
        return nil;
    }

    if (![self createSchema:error]) {
        [self close];
        [self release];
        return nil;
    }
    return self;
}

- (void)dealloc
{
    [self close];
    [_databasePath release];
    [super dealloc];
}

- (BOOL)createSchema:(NSError **)error
{
    const char *sql =
        "CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL, description TEXT NOT NULL);"
        "CREATE TABLE IF NOT EXISTS projects ("
        "id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL DEFAULT 'Vincent Foissard', project_type TEXT NOT NULL DEFAULT 'Song', mood TEXT, bpm INTEGER, production_stage TEXT, "
        "completion_percent INTEGER NOT NULL DEFAULT 0, next_action TEXT, notes TEXT, "
        "created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT);"
        "CREATE TABLE IF NOT EXISTS flows (name TEXT PRIMARY KEY, display_order INTEGER NOT NULL);"
        "CREATE TABLE IF NOT EXISTS flow_subcategories (flow_name TEXT NOT NULL REFERENCES flows(name), name TEXT NOT NULL, display_order INTEGER NOT NULL, PRIMARY KEY(flow_name, name));"
        "CREATE TABLE IF NOT EXISTS collections (id TEXT PRIMARY KEY, name TEXT NOT NULL, collection_type TEXT NOT NULL CHECK(collection_type IN ('Album', 'EP', 'Playlist', 'Live Set')), notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);"
        "CREATE TABLE IF NOT EXISTS collection_items (collection_id TEXT NOT NULL REFERENCES collections(id) ON DELETE CASCADE, musical_piece_id TEXT NOT NULL REFERENCES projects(id), position INTEGER NOT NULL CHECK(position > 0), PRIMARY KEY(collection_id, musical_piece_id), UNIQUE(collection_id, position));"
        "CREATE TABLE IF NOT EXISTS relationships (id TEXT PRIMARY KEY, source_item_id TEXT NOT NULL REFERENCES projects(id), relationship TEXT NOT NULL, target_item_id TEXT NOT NULL REFERENCES projects(id), notes TEXT, created_at TEXT NOT NULL, UNIQUE(source_item_id, relationship, target_item_id));"
        "CREATE INDEX IF NOT EXISTS projects_title_artist ON projects(title, artist);"
        "CREATE INDEX IF NOT EXISTS projects_updated_at ON projects(updated_at);"
        "INSERT OR IGNORE INTO schema_migrations (version, applied_at, description) "
        "VALUES (1, '2026-07-17T00:00:00Z', 'Initial project catalogue');"
        "UPDATE projects SET artist = 'Vincent Foissard' WHERE artist IS NULL OR artist = '';";
    char *message = NULL;
    int result = sqlite3_exec(_database, sql, NULL, NULL, &message);
    if (result != SQLITE_OK) {
        if (error) {
            NSString *description = message ? [NSString stringWithUTF8String:message] : @"Unable to create Flow database.";
            *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
        }
        if (message) sqlite3_free(message);
        return NO;
    }
    sqlite3_exec(_database, "ALTER TABLE projects ADD COLUMN project_type TEXT", NULL, NULL, NULL);
    sqlite3_exec(_database, "ALTER TABLE projects ADD COLUMN mood TEXT", NULL, NULL, NULL);
    sqlite3_exec(_database, "ALTER TABLE projects ADD COLUMN bpm INTEGER", NULL, NULL, NULL);
    sqlite3_exec(_database, "ALTER TABLE projects ADD COLUMN flow_name TEXT", NULL, NULL, NULL);
    sqlite3_exec(_database, "ALTER TABLE projects ADD COLUMN subcategory TEXT", NULL, NULL, NULL);
    sqlite3_exec(_database, "ALTER TABLE projects ADD COLUMN classification TEXT", NULL, NULL, NULL);
    sqlite3_exec(_database, "ALTER TABLE projects ADD COLUMN tags TEXT", NULL, NULL, NULL);
    sqlite3_exec(_database, "ALTER TABLE projects ADD COLUMN metadata TEXT", NULL, NULL, NULL);
    result = sqlite3_exec(_database,
        "UPDATE projects SET project_type = 'Song' WHERE project_type IS NULL OR project_type = '';"
        "UPDATE projects SET flow_name = 'Musical Pieces' WHERE flow_name IS NULL OR flow_name = '';"
        "UPDATE projects SET subcategory = CASE WHEN project_type = 'Instrumental' THEN 'Instrumentals' ELSE 'Songs' END WHERE subcategory IS NULL OR subcategory = '';"
        "CREATE TRIGGER IF NOT EXISTS collection_items_require_musical_piece BEFORE INSERT ON collection_items FOR EACH ROW WHEN NOT EXISTS (SELECT 1 FROM projects WHERE id = NEW.musical_piece_id AND flow_name = 'Musical Pieces' AND subcategory IN ('Songs', 'Instrumentals') AND deleted_at IS NULL) BEGIN SELECT RAISE(ABORT, 'Collections may reference Songs or Instrumentals only'); END;"
        "INSERT OR IGNORE INTO flows (name, display_order) VALUES ('Musical Pieces', 1), ('Instruments', 2), ('Thoughts', 3), ('Promotion', 4), ('Apps', 5), ('Purchases', 6), ('Health', 7);"
        "INSERT OR IGNORE INTO flow_subcategories (flow_name, name, display_order) VALUES ('Musical Pieces', 'Songs', 1), ('Musical Pieces', 'Instrumentals', 2), ('Instruments', 'Synthesizers', 1), ('Instruments', 'Guitars', 2), ('Instruments', 'Drum Modules', 3);"
        "INSERT OR IGNORE INTO schema_migrations (version, applied_at, description) VALUES (2, '2026-07-17T00:00:00Z', 'Set the fixed default artist');"
        "INSERT OR IGNORE INTO schema_migrations (version, applied_at, description) VALUES (3, '2026-07-17T00:00:00Z', 'Add project type');"
        "INSERT OR IGNORE INTO schema_migrations (version, applied_at, description) VALUES (4, '2026-07-17T00:00:00Z', 'Add mood and BPM');"
        "INSERT OR IGNORE INTO schema_migrations (version, applied_at, description) VALUES (5, '2026-07-18T00:00:00Z', 'Add flows, structural subcategories, collections, and relationships');",
        NULL, NULL, &message);
    if (result != SQLITE_OK) {
        if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
        if (message) sqlite3_free(message);
        return NO;
    }
    return YES;
}

- (NSArray *)stringResultsForSQL:(const char *)sql binding:(NSString *)value error:(NSError **)error
{
    sqlite3_stmt *statement = NULL;
    NSMutableArray *results = [NSMutableArray array];
    int result = sqlite3_prepare(_database, sql, -1, &statement, NULL);
    if (result != SQLITE_OK) {
        if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
        return nil;
    }
    if (value) FLBindText(statement, 1, value);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        NSString *item = FLColumnText(statement, 0);
        if (item) [results addObject:item];
    }
    sqlite3_finalize(statement);
    return results;
}

- (NSArray *)flowNames:(NSError **)error
{
    return [self stringResultsForSQL:"SELECT name FROM flows ORDER BY display_order" binding:nil error:error];
}

- (NSArray *)subcategoriesForFlow:(NSString *)flowName error:(NSError **)error
{
    return [self stringResultsForSQL:"SELECT name FROM flow_subcategories WHERE flow_name = ? ORDER BY display_order" binding:flowName error:error];
}

- (NSArray *)allProjects:(NSError **)error
{
    NSMutableArray *projects = [NSMutableArray array];
    sqlite3_stmt *statement = NULL;
    const char *sql = "SELECT id, title, artist, project_type, flow_name, subcategory, classification, tags, metadata, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at FROM projects WHERE deleted_at IS NULL ORDER BY updated_at DESC, title COLLATE NOCASE ASC";
    int result = sqlite3_prepare(_database, sql, -1, &statement, NULL);
    if (result != SQLITE_OK) {
        if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
        return nil;
    }
    while (sqlite3_step(statement) == SQLITE_ROW) {
        FLProject *project = [[FLProject alloc] init];
        [project setIdentifier:FLColumnText(statement, 0)];
        [project setTitle:FLColumnText(statement, 1)];
        [project setArtist:FLColumnText(statement, 2)];
        [project setProjectType:FLColumnText(statement, 3)];
        [project setFlowName:FLColumnText(statement, 4)];
        [project setSubcategory:FLColumnText(statement, 5)];
        [project setClassification:FLColumnText(statement, 6)];
        [project setTags:FLColumnText(statement, 7)];
        [project setMetadata:FLColumnText(statement, 8)];
        [project setMood:FLColumnText(statement, 9)];
        [project setBpm:sqlite3_column_int(statement, 10)];
        [project setProductionStage:FLColumnText(statement, 11)];
        [project setCompletionPercent:sqlite3_column_int(statement, 12)];
        [project setNextAction:FLColumnText(statement, 13)];
        [project setNotes:FLColumnText(statement, 14)];
        [project setCreatedAt:FLColumnText(statement, 15)];
        [project setUpdatedAt:FLColumnText(statement, 16)];
        [projects addObject:project];
        [project release];
    }
    sqlite3_finalize(statement);
    return projects;
}

- (BOOL)saveProject:(FLProject *)project error:(NSError **)error
{
    sqlite3_stmt *statement = NULL;
    NSString *timestamp = FLCurrentTimestamp();
    BOOL isNew = !FLProjectExists(_database, [project identifier]);
    if (!FLIsValidFlowAndSubcategory([project flowName], [project subcategory])) {
        FLSetValidationError(error, @"Only Musical Pieces and Instruments may have subcategories; use a supported subcategory for those flows.");
        return NO;
    }
    const char *sql = isNew ?
        "INSERT INTO projects (id, title, artist, project_type, flow_name, subcategory, classification, tags, metadata, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" :
        "UPDATE projects SET title = ?, artist = ?, project_type = ?, flow_name = ?, subcategory = ?, classification = ?, tags = ?, metadata = ?, mood = ?, bpm = ?, production_stage = ?, completion_percent = ?, next_action = ?, notes = ?, updated_at = ? WHERE id = ?";
    int result = sqlite3_prepare(_database, sql, -1, &statement, NULL);
    if (result != SQLITE_OK) goto failure;

    if (isNew) {
        if (![[project identifier] length]) [project setIdentifier:FLNewIdentifier()];
        if (![[project createdAt] length]) [project setCreatedAt:timestamp];
        [project setUpdatedAt:timestamp];
        FLBindText(statement, 1, [project identifier]);
        FLBindText(statement, 2, [project title]);
        FLBindText(statement, 3, [project artist]);
        FLBindText(statement, 4, [project projectType]);
        FLBindText(statement, 5, [project flowName]);
        FLBindText(statement, 6, [project subcategory]);
        FLBindText(statement, 7, [project classification]);
        FLBindText(statement, 8, [project tags]);
        FLBindText(statement, 9, [project metadata]);
        FLBindText(statement, 10, [project mood]);
        sqlite3_bind_int(statement, 11, (int)[project bpm]);
        FLBindText(statement, 12, [project productionStage]);
        sqlite3_bind_int(statement, 13, (int)[project completionPercent]);
        FLBindText(statement, 14, [project nextAction]);
        FLBindText(statement, 15, [project notes]);
        FLBindText(statement, 16, [project createdAt]);
        FLBindText(statement, 17, [project updatedAt]);
    } else {
        [project setUpdatedAt:timestamp];
        FLBindText(statement, 1, [project title]);
        FLBindText(statement, 2, [project artist]);
        FLBindText(statement, 3, [project projectType]);
        FLBindText(statement, 4, [project flowName]);
        FLBindText(statement, 5, [project subcategory]);
        FLBindText(statement, 6, [project classification]);
        FLBindText(statement, 7, [project tags]);
        FLBindText(statement, 8, [project metadata]);
        FLBindText(statement, 9, [project mood]);
        sqlite3_bind_int(statement, 10, (int)[project bpm]);
        FLBindText(statement, 11, [project productionStage]);
        sqlite3_bind_int(statement, 12, (int)[project completionPercent]);
        FLBindText(statement, 13, [project nextAction]);
        FLBindText(statement, 14, [project notes]);
        FLBindText(statement, 15, [project updatedAt]);
        FLBindText(statement, 16, [project identifier]);
    }

    result = sqlite3_step(statement);
    sqlite3_finalize(statement);
    if (result == SQLITE_DONE) return YES;

failure:
    if (statement) sqlite3_finalize(statement);
    if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
    return NO;
}

- (BOOL)saveCollectionWithIdentifier:(NSString *)identifier name:(NSString *)name type:(NSString *)type notes:(NSString *)notes error:(NSError **)error
{
    if (![name length] || !([type isEqualToString:@"Album"] || [type isEqualToString:@"EP"] || [type isEqualToString:@"Playlist"] || [type isEqualToString:@"Live Set"])) {
        FLSetValidationError(error, @"A Collection needs a name and a type of Album, EP, Playlist, or Live Set.");
        return NO;
    }
    BOOL isNew = !identifier || ![identifier length];
    sqlite3_stmt *statement = NULL;
    const char *sql = isNew ?
        "INSERT INTO collections (id, name, collection_type, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)" :
        "UPDATE collections SET name = ?, collection_type = ?, notes = ?, updated_at = ? WHERE id = ?";
    int result = sqlite3_prepare(_database, sql, -1, &statement, NULL);
    if (result != SQLITE_OK) goto failure;
    NSString *timestamp = FLCurrentTimestamp();
    if (isNew) {
        FLBindText(statement, 1, FLNewIdentifier()); FLBindText(statement, 2, name); FLBindText(statement, 3, type); FLBindText(statement, 4, notes); FLBindText(statement, 5, timestamp); FLBindText(statement, 6, timestamp);
    } else {
        FLBindText(statement, 1, name); FLBindText(statement, 2, type); FLBindText(statement, 3, notes); FLBindText(statement, 4, timestamp); FLBindText(statement, 5, identifier);
    }
    result = sqlite3_step(statement);
    sqlite3_finalize(statement);
    if (result == SQLITE_DONE) return YES;
failure:
    if (statement) sqlite3_finalize(statement);
    if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
    return NO;
}

- (NSString *)createCollectionWithName:(NSString *)name type:(NSString *)type notes:(NSString *)notes error:(NSError **)error
{
    if (![name length] || !([type isEqualToString:@"Album"] || [type isEqualToString:@"EP"] || [type isEqualToString:@"Playlist"] || [type isEqualToString:@"Live Set"])) {
        FLSetValidationError(error, @"A Collection needs a name and a type of Album, EP, Playlist, or Live Set.");
        return nil;
    }
    NSString *identifier = FLNewIdentifier();
    sqlite3_stmt *statement = NULL;
    int result = sqlite3_prepare(_database, "INSERT INTO collections (id, name, collection_type, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)", -1, &statement, NULL);
    NSString *timestamp = FLCurrentTimestamp();
    if (result == SQLITE_OK) {
        FLBindText(statement, 1, identifier); FLBindText(statement, 2, name); FLBindText(statement, 3, type); FLBindText(statement, 4, notes); FLBindText(statement, 5, timestamp); FLBindText(statement, 6, timestamp);
        result = sqlite3_step(statement);
    }
    if (statement) sqlite3_finalize(statement);
    if (result == SQLITE_DONE) return identifier;
    if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
    return nil;
}

- (BOOL)addMusicalPiece:(NSString *)pieceIdentifier toCollection:(NSString *)collectionIdentifier atPosition:(NSInteger)position error:(NSError **)error
{
    if (![pieceIdentifier length] || ![collectionIdentifier length] || position < 1) {
        FLSetValidationError(error, @"A Collection item needs valid collection and musical-piece IDs and a positive position.");
        return NO;
    }
    sqlite3_stmt *statement = NULL;
    int result = sqlite3_prepare(_database, "INSERT INTO collection_items (collection_id, musical_piece_id, position) VALUES (?, ?, ?)", -1, &statement, NULL);
    if (result == SQLITE_OK) {
        FLBindText(statement, 1, collectionIdentifier); FLBindText(statement, 2, pieceIdentifier); sqlite3_bind_int(statement, 3, (int)position);
        result = sqlite3_step(statement);
    }
    if (statement) sqlite3_finalize(statement);
    if (result == SQLITE_DONE) return YES;
    if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
    return NO;
}

- (BOOL)saveRelationshipFrom:(NSString *)sourceIdentifier relationship:(NSString *)relationship to:(NSString *)targetIdentifier notes:(NSString *)notes error:(NSError **)error
{
    if (![sourceIdentifier length] || ![targetIdentifier length] || ![relationship length]) {
        FLSetValidationError(error, @"A relationship needs source ID, relationship, and target ID.");
        return NO;
    }
    sqlite3_stmt *statement = NULL;
    int result = sqlite3_prepare(_database, "INSERT OR REPLACE INTO relationships (id, source_item_id, relationship, target_item_id, notes, created_at) VALUES (?, ?, ?, ?, ?, ?)", -1, &statement, NULL);
    if (result == SQLITE_OK) {
        FLBindText(statement, 1, FLNewIdentifier()); FLBindText(statement, 2, sourceIdentifier); FLBindText(statement, 3, relationship); FLBindText(statement, 4, targetIdentifier); FLBindText(statement, 5, notes); FLBindText(statement, 6, FLCurrentTimestamp());
        result = sqlite3_step(statement);
    }
    if (statement) sqlite3_finalize(statement);
    if (result == SQLITE_DONE) return YES;
    if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
    return NO;
}

- (NSArray *)archiveRowsForSQL:(const char *)sql keys:(NSArray *)keys error:(NSError **)error
{
    sqlite3_stmt *statement = NULL;
    NSMutableArray *rows = [NSMutableArray array];
    int result = sqlite3_prepare(_database, sql, -1, &statement, NULL);
    if (result != SQLITE_OK) {
        if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil];
        return nil;
    }
    while (sqlite3_step(statement) == SQLITE_ROW) {
        NSMutableDictionary *row = [NSMutableDictionary dictionary];
        NSUInteger index;
        for (index = 0; index < [keys count]; index++) {
            NSString *value = FLColumnText(statement, (int)index);
            if (value) [row setObject:value forKey:[keys objectAtIndex:index]];
            else if (sqlite3_column_type(statement, (int)index) == SQLITE_INTEGER) [row setObject:[NSNumber numberWithInt:sqlite3_column_int(statement, (int)index)] forKey:[keys objectAtIndex:index]];
        }
        [rows addObject:row];
    }
    sqlite3_finalize(statement);
    return rows;
}

- (BOOL)exportArchiveToPath:(NSString *)path error:(NSError **)error
{
    NSArray *itemKeys = [NSArray arrayWithObjects:@"id", @"title", @"artist", @"project_type", @"flow_name", @"subcategory", @"classification", @"tags", @"metadata", @"mood", @"bpm", @"production_stage", @"completion_percent", @"next_action", @"notes", @"created_at", @"updated_at", nil];
    NSArray *collectionKeys = [NSArray arrayWithObjects:@"id", @"name", @"collection_type", @"notes", @"created_at", @"updated_at", nil];
    NSArray *membershipKeys = [NSArray arrayWithObjects:@"collection_id", @"musical_piece_id", @"position", nil];
    NSArray *relationshipKeys = [NSArray arrayWithObjects:@"id", @"source_item_id", @"relationship", @"target_item_id", @"notes", @"created_at", nil];
    NSArray *items = [self archiveRowsForSQL:"SELECT id, title, artist, project_type, flow_name, subcategory, classification, tags, metadata, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at FROM projects WHERE deleted_at IS NULL ORDER BY title COLLATE NOCASE" keys:itemKeys error:error];
    if (!items) return NO;
    NSArray *collections = [self archiveRowsForSQL:"SELECT id, name, collection_type, notes, created_at, updated_at FROM collections ORDER BY name COLLATE NOCASE" keys:collectionKeys error:error];
    if (!collections) return NO;
    NSArray *memberships = [self archiveRowsForSQL:"SELECT collection_id, musical_piece_id, position FROM collection_items ORDER BY collection_id, position" keys:membershipKeys error:error];
    if (!memberships) return NO;
    NSArray *relationships = [self archiveRowsForSQL:"SELECT id, source_item_id, relationship, target_item_id, notes, created_at FROM relationships ORDER BY created_at" keys:relationshipKeys error:error];
    if (!relationships) return NO;
    NSMutableDictionary *archive = [NSMutableDictionary dictionary];
    [archive setObject:@"Flow Library Archive" forKey:@"format"];
    [archive setObject:[NSNumber numberWithInt:1] forKey:@"version"];
    [archive setObject:FLCurrentTimestamp() forKey:@"exported_at"];
    [archive setObject:items forKey:@"flow_items"];
    [archive setObject:collections forKey:@"collections"];
    [archive setObject:memberships forKey:@"collection_items"];
    [archive setObject:relationships forKey:@"relationships"];
    NSString *serializationError = nil;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:archive format:NSPropertyListXMLFormat_v1_0 errorDescription:&serializationError];
    if (!data) {
        if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:20 userInfo:[NSDictionary dictionaryWithObject:(serializationError ? serializationError : @"Unable to create archive.") forKey:NSLocalizedDescriptionKey]];
        [serializationError release];
        return NO;
    }
    BOOL wrote = [data writeToFile:path atomically:YES];
    if (!wrote && error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:21 userInfo:[NSDictionary dictionaryWithObject:@"Unable to write the Flow Library archive." forKey:NSLocalizedDescriptionKey]];
    return wrote;
}

- (BOOL)importArchiveFromPath:(NSString *)path error:(NSError **)error
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString *serializationError = nil;
    id propertyList = data ? [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:NULL errorDescription:&serializationError] : nil;
    if (![propertyList isKindOfClass:[NSDictionary class]] || ![[propertyList objectForKey:@"format"] isEqualToString:@"Flow Library Archive"] || [[propertyList objectForKey:@"version"] intValue] != 1) {
        if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:22 userInfo:[NSDictionary dictionaryWithObject:@"This is not a supported Flow Library (.flowlib) archive." forKey:NSLocalizedDescriptionKey]];
        [serializationError release];
        return NO;
    }
    [serializationError release];
    NSDictionary *archive = propertyList;
    NSArray *items = [archive objectForKey:@"flow_items"];
    NSArray *collections = [archive objectForKey:@"collections"];
    NSArray *memberships = [archive objectForKey:@"collection_items"];
    NSArray *relationships = [archive objectForKey:@"relationships"];
    if (![items isKindOfClass:[NSArray class]] || ![collections isKindOfClass:[NSArray class]] || ![memberships isKindOfClass:[NSArray class]] || ![relationships isKindOfClass:[NSArray class]]) {
        FLSetValidationError(error, @"The Flow Library archive is incomplete.");
        return NO;
    }
    sqlite3_exec(_database, "BEGIN IMMEDIATE TRANSACTION", NULL, NULL, NULL);
    NSUInteger index;
    for (index = 0; index < [items count]; index++) {
        NSDictionary *row = [items objectAtIndex:index];
        FLProject *item = [[FLProject alloc] init];
        [item setIdentifier:FLValue(row, @"id")]; [item setTitle:FLValue(row, @"title")]; [item setArtist:FLValue(row, @"artist")]; [item setProjectType:FLValue(row, @"project_type")]; [item setFlowName:FLValue(row, @"flow_name")]; [item setSubcategory:FLValue(row, @"subcategory")]; [item setClassification:FLValue(row, @"classification")]; [item setTags:FLValue(row, @"tags")]; [item setMetadata:FLValue(row, @"metadata")]; [item setMood:FLValue(row, @"mood")]; [item setBpm:[[row objectForKey:@"bpm"] integerValue]]; [item setProductionStage:FLValue(row, @"production_stage")]; [item setCompletionPercent:[[row objectForKey:@"completion_percent"] integerValue]]; [item setNextAction:FLValue(row, @"next_action")]; [item setNotes:FLValue(row, @"notes")];
        if (![self saveProject:item error:error]) { [item release]; sqlite3_exec(_database, "ROLLBACK", NULL, NULL, NULL); return NO; }
        [item release];
    }
    for (index = 0; index < [collections count]; index++) {
        NSDictionary *row = [collections objectAtIndex:index];
        sqlite3_stmt *statement = NULL;
        int result = sqlite3_prepare(_database, "INSERT OR REPLACE INTO collections (id, name, collection_type, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)", -1, &statement, NULL);
        if (result == SQLITE_OK) { FLBindText(statement, 1, FLValue(row, @"id")); FLBindText(statement, 2, FLValue(row, @"name")); FLBindText(statement, 3, FLValue(row, @"collection_type")); FLBindText(statement, 4, FLValue(row, @"notes")); FLBindText(statement, 5, FLValue(row, @"created_at")); FLBindText(statement, 6, FLValue(row, @"updated_at")); result = sqlite3_step(statement); }
        if (statement) sqlite3_finalize(statement);
        if (result != SQLITE_DONE) { sqlite3_exec(_database, "ROLLBACK", NULL, NULL, NULL); if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil]; return NO; }
    }
    for (index = 0; index < [collections count]; index++) {
        NSDictionary *row = [collections objectAtIndex:index];
        sqlite3_stmt *statement = NULL;
        int result = sqlite3_prepare(_database, "DELETE FROM collection_items WHERE collection_id = ?", -1, &statement, NULL);
        if (result == SQLITE_OK) { FLBindText(statement, 1, FLValue(row, @"id")); result = sqlite3_step(statement); }
        if (statement) sqlite3_finalize(statement);
        if (result != SQLITE_DONE) { sqlite3_exec(_database, "ROLLBACK", NULL, NULL, NULL); if (error) *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:nil]; return NO; }
    }
    for (index = 0; index < [memberships count]; index++) {
        NSDictionary *row = [memberships objectAtIndex:index];
        if (![self addMusicalPiece:FLValue(row, @"musical_piece_id") toCollection:FLValue(row, @"collection_id") atPosition:[[row objectForKey:@"position"] integerValue] error:error]) { sqlite3_exec(_database, "ROLLBACK", NULL, NULL, NULL); return NO; }
    }
    for (index = 0; index < [relationships count]; index++) {
        NSDictionary *row = [relationships objectAtIndex:index];
        if (![self saveRelationshipFrom:FLValue(row, @"source_item_id") relationship:FLValue(row, @"relationship") to:FLValue(row, @"target_item_id") notes:FLValue(row, @"notes") error:error]) { sqlite3_exec(_database, "ROLLBACK", NULL, NULL, NULL); return NO; }
    }
    sqlite3_exec(_database, "COMMIT", NULL, NULL, NULL);
    return YES;
}

- (BOOL)seedSampleProjectsIfNeeded:(NSError **)error
{
    const char *sql =
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-001', 'Broken Glass', 'Vincent Foissard', 'Song', 'Dark', 94, 'Recording', 55, 'Guitar', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-002', 'Tokyo Lights', 'Vincent Foissard', 'Song', 'Dreamy', 118, 'Mixing', 82, 'Master', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-003', 'Blue Horizon', 'Vincent Foissard', 'Song', 'Hopeful', 72, 'Writing', 18, 'Lyrics', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-004', 'Midnight Train', 'Vincent Foissard', 'Song', 'Melancholic', 88, 'Demo', 40, 'Arrangement', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-005', 'Echo Machine', 'Vincent Foissard', 'Song', 'Energetic', 132, 'Recording', 67, 'Vocals', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-006', 'Silent River', 'Vincent Foissard', 'Song', 'Ambient', 64, 'Editing', 76, 'Piano', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-007', 'Fire Escape', 'Vincent Foissard', 'Song', 'Aggressive', 148, 'Sketch', 12, 'Structure', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-008', 'Last Summer', 'Vincent Foissard', 'Song', 'Happy', 124, 'Mastering', 95, 'Artwork', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-009', 'Neon Rain', 'Vincent Foissard', 'Song', 'Epic', 110, 'Mixing', 84, 'Bass', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');"
        "INSERT OR IGNORE INTO projects (id, title, artist, project_type, mood, bpm, production_stage, completion_percent, next_action, notes, created_at, updated_at) VALUES ('flow-sample-010', 'Paper Planes', 'Vincent Foissard', 'Song', 'Relaxed', 98, 'Released', 100, 'None', 'Sample Project', '2026-07-17T00:00:00Z', '2026-07-17T00:00:00Z');";
    char *message = NULL;
    int result = sqlite3_exec(_database, sql, NULL, NULL, &message);
    if (result == SQLITE_OK) {
        sqlite3_exec(_database, "UPDATE projects SET flow_name = 'Musical Pieces', subcategory = 'Songs' WHERE flow_name IS NULL OR subcategory IS NULL;", NULL, NULL, NULL);
        return YES;
    }
    if (error) {
        NSString *description = message ? [NSString stringWithUTF8String:message] : @"Unable to add sample Projects.";
        *error = [NSError errorWithDomain:FLStoreErrorDomain code:result userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
    }
    if (message) sqlite3_free(message);
    return NO;
}

- (void)close
{
    if (_database) {
        sqlite3_close(_database);
        _database = NULL;
    }
}

@end
