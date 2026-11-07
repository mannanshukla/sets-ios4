#import <UIKit/UIKit.h>
#import <TargetConditionals.h>
#import "weightlink.h"
@interface WeightAudit:NSObject<UIApplicationDelegate> { UIWindow *window; }
@end
@implementation WeightAudit
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options { window=[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];window.rootViewController=[[[UIViewController alloc] init] autorelease];[window makeKeyAndVisible];[self performSelector:@selector(run) withObject:nil afterDelay:.3];return YES; }
- (void)run { NSString *p=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/weights.txt"];freopen([p fileSystemRepresentation],"w",stdout);freopen([p fileSystemRepresentation],"a",stderr);runWeightStoreTests();exit(0); }
- (void)dealloc { [window release];[super dealloc]; }
@end
int main(int argc,char **argv) { NSAutoreleasePool *p=[NSAutoreleasePool new];int r=UIApplicationMain(argc,argv,nil,@"WeightAudit");[p drain];return r; }
