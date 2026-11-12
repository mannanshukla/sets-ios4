#import <UIKit/UIKit.h>
#import "LFSkin.h"
#import "LFStore.h"
#import "LFWorkoutViewController.h"
#import "LFCoachViewController.h"
#import "LFExercisesViewController.h"
#import "LFProgressViewController.h"

@interface LFAppDelegate : NSObject <UIApplicationDelegate> { UIWindow *window; UITabBarController *tabs; }
@end
@implementation LFAppDelegate
- (UINavigationController *)wrap:(UIViewController *)vc { UINavigationController *n = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease]; n.navigationBar.tintColor = [UIColor colorWithRed:0x5B/255.0 green:0x3F/255.0 blue:0xA6/255.0 alpha:1]; LFSkinNavBar(n.navigationBar); return n; }
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    tabs = [[UITabBarController alloc] init];
    LFWorkoutViewController *w = [[[LFWorkoutViewController alloc] init] autorelease];
    LFCoachViewController *r = [[[LFCoachViewController alloc] init] autorelease];
    LFExercisesViewController *e = [[[LFExercisesViewController alloc] init] autorelease];
    LFHistoryViewController *h = [[[LFHistoryViewController alloc] init] autorelease];
    LFProgressViewController *p = [[[LFProgressViewController alloc] init] autorelease]; p.tabBarItem.image = [UIImage imageNamed:@"tab-progress.png"];
    w.tabBarItem.image = [UIImage imageNamed:@"tab-workout.png"];
    e.tabBarItem.image = [UIImage imageNamed:@"tab-exercises.png"]; h.tabBarItem.image = [UIImage imageNamed:@"tab-history.png"];
    tabs.viewControllers = [NSArray arrayWithObjects:[self wrap:w], [self wrap:r], [self wrap:e], [self wrap:h], [self wrap:p], nil];
    tabs.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lf_tab"];
    [window addSubview:tabs.view]; [window makeKeyAndVisible];
    app.applicationIconBadgeNumber = 0;
    return YES;
}
// iOS 5 keeps a suspended app's memory resident until it kills the app, and on a 256 MB iPod that squeezes whatever is
// playing. Going to the background, and on memory warnings, every screen that is not showing drops its view the way a
// memory warning would; screens drop their own rebuildable state; the parsed catalog and history go unless a showing
// list still holds them, so they are never parsed twice. All of it comes back on next use.
- (void)collect:(UIViewController *)vc into:(NSMutableArray *)all {
    if (!vc || [all indexOfObjectIdenticalTo:vc] != NSNotFound) return;
    [all addObject:vc];
    if ([vc isKindOfClass:[UITabBarController class]]) for (UIViewController *c in [(UITabBarController *)vc viewControllers]) [self collect:c into:all];
    if ([vc isKindOfClass:[UINavigationController class]]) for (UIViewController *c in [(UINavigationController *)vc viewControllers]) [self collect:c into:all];
    [self collect:vc.modalViewController into:all];
}
- (void)trimMemory {
    NSMutableArray *all = [NSMutableArray array]; [self collect:tabs into:all];
    BOOL keepCatalog = NO, keepHistory = NO;
    for (UIViewController *vc in all) {
        if ([vc isKindOfClass:[UITabBarController class]] || [vc isKindOfClass:[UINavigationController class]]) continue;
        if (LFViewIsVisible(vc)) { keepCatalog |= [vc isKindOfClass:[LFExercisesViewController class]]; keepHistory |= [vc isKindOfClass:[LFHistoryViewController class]] || [vc isKindOfClass:[LFProgressViewController class]]; }
        else LFUnloadHiddenView(vc);
        if ([vc conformsToProtocol:@protocol(LFTrimMemory)]) [(id<LFTrimMemory>)vc trimMemory];
    }
    if (!keepCatalog) [LFExercisesViewController releaseSharedIndex];
    [LFStore trimCachesKeepingCatalog:keepCatalog history:keepHistory];
    LFSkinPurgeCache();
}
- (void)applicationDidEnterBackground:(UIApplication *)app { [self trimMemory]; }
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)app { [self trimMemory]; }
- (void)applicationDidBecomeActive:(UIApplication *)app { app.applicationIconBadgeNumber = 0;[LFStore publishWeightsForMeals]; }
- (void)applicationWillTerminate:(UIApplication *)app { [[NSUserDefaults standardUserDefaults] setInteger:tabs.selectedIndex forKey:@"lf_tab"]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)dealloc { [tabs release]; [window release]; [super dealloc]; }
@end
int main(int argc, char *argv[]) { NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init]; int r = UIApplicationMain(argc, argv, nil, @"LFAppDelegate"); [p release]; return r; }
