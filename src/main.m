#import <UIKit/UIKit.h>
#import "LFWorkoutViewController.h"
#import "LFRoutinesViewController.h"
#import "LFExercisesViewController.h"
#import "LFProgressViewController.h"

@interface LFAppDelegate : NSObject <UIApplicationDelegate> { UIWindow *window; UITabBarController *tabs; }
@end
@implementation LFAppDelegate
- (UINavigationController *)wrap:(UIViewController *)vc { UINavigationController *n = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease]; n.navigationBar.tintColor = [UIColor colorWithRed:0x4D/255.0 green:0x7C/255.0 blue:0x0F/255.0 alpha:1]; return n; }
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    tabs = [[UITabBarController alloc] init];
    LFWorkoutViewController *w = [[[LFWorkoutViewController alloc] init] autorelease];
    LFRoutinesViewController *r = [[[LFRoutinesViewController alloc] init] autorelease];
    LFExercisesViewController *e = [[[LFExercisesViewController alloc] init] autorelease];
    LFHistoryViewController *h = [[[LFHistoryViewController alloc] init] autorelease];
    LFProgressViewController *p = [[[LFProgressViewController alloc] init] autorelease]; p.tabBarItem.image = [UIImage imageNamed:@"tab-progress.png"];
    w.tabBarItem.image = [UIImage imageNamed:@"tab-workout.png"]; r.tabBarItem.image = [UIImage imageNamed:@"tab-routines.png"];
    e.tabBarItem.image = [UIImage imageNamed:@"tab-exercises.png"]; h.tabBarItem.image = [UIImage imageNamed:@"tab-history.png"];
    tabs.viewControllers = [NSArray arrayWithObjects:[self wrap:w], [self wrap:r], [self wrap:e], [self wrap:h], [self wrap:p], nil];
    tabs.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lf_tab"];
    [window addSubview:tabs.view]; [window makeKeyAndVisible];
    app.applicationIconBadgeNumber = 0;
    return YES;
}
- (void)applicationDidBecomeActive:(UIApplication *)app { app.applicationIconBadgeNumber = 0; }
- (void)applicationWillTerminate:(UIApplication *)app { [[NSUserDefaults standardUserDefaults] setInteger:tabs.selectedIndex forKey:@"lf_tab"]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)dealloc { [tabs release]; [window release]; [super dealloc]; }
@end
int main(int argc, char *argv[]) { NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init]; int r = UIApplicationMain(argc, argv, nil, @"LFAppDelegate"); [p release]; return r; }
