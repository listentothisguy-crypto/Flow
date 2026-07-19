#import <Cocoa/Cocoa.h>
#import "FLApplicationController.h"

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSApplication *application = [NSApplication sharedApplication];
    FLApplicationController *controller = [[FLApplicationController alloc] init];
    [application setDelegate:controller];
    [application run];
    [controller release];
    [pool release];
    return 0;
}
