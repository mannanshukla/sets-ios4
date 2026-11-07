#import <UIKit/UIKit.h>
#import "LFStore.h"
#import "LFSearch.h"
#import "LFAI.h"
@interface CatalogAudit : NSObject<UIApplicationDelegate> { UIWindow *window; }
@end
@implementation CatalogAudit
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options { window=[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];window.rootViewController=[[[UIViewController alloc] init] autorelease];[window makeKeyAndVisible];[self performSelector:@selector(run) withObject:nil afterDelay:.3];return YES; }
- (void)run { NSString *path=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/catalog.txt"];freopen([path fileSystemRepresentation],"w",stdout);freopen([path fileSystemRepresentation],"a",stderr);NSArray *ex=[LFStore exercises];NSCAssert([ex count]==900,@"900 catalog records");LFSearch *search=[[LFSearch alloc] initWithExercises:ex];NSArray *cases=[NSArray arrayWithObjects:[NSArray arrayWithObjects:@"nordic curl",@"Natural_Glute_Ham_Raise",nil],[NSArray arrayWithObjects:@"seal row",@"Sets_Seal_Row",nil],[NSArray arrayWithObjects:@"db rdl",@"Sets_Dumbbell_Romanian_Deadlift",nil],[NSArray arrayWithObjects:@"cable hip abduction",@"Sets_Cable_Hip_Abduction",nil],nil];for(NSArray *c in cases) { BOOL found=NO;NSArray *results=[search resultsForQuery:[c objectAtIndex:0] kind:0];for(NSDictionary *e in [results subarrayWithRange:NSMakeRange(0,MIN(8,[results count]))])if([[e objectForKey:@"id"] isEqual:[c objectAtIndex:1]])found=YES;NSCAssert(found,@"expected result"); }[search release];NSDictionary *options=[NSDictionary dictionaryWithObjectsAndKeys:@"strength",@"goal",@"beginner",@"level",@"full gym",@"equipment",@"",@"notes",@3,@"days",@45,@"minutes",nil];NSUInteger size=[[LFAI routinePrompt:options] length];NSCAssert(size<96000,@"prompt budget");printf("PASS 900 exercises, native aliases and new movements; coach prompt %lu characters\n",(unsigned long)size);fflush(stdout);exit(0); }
- (void)dealloc { [window release];[super dealloc]; }
@end
int main(int argc,char **argv) { NSAutoreleasePool *p=[NSAutoreleasePool new];int r=UIApplicationMain(argc,argv,nil,@"CatalogAudit");[p drain];return r; }
