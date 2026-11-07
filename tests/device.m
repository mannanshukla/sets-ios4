#import <UIKit/UIKit.h>
#import <malloc/malloc.h>
#import "CLCoachViewController.h"
#import "CLPaper.h"
#import "ORTextLayout.h"
#import "LFCoachViewController.h"
#import "LFWorkoutViewController.h"
#import "LFSearch.h"
#import "LFCustomExercise.h"
#ifdef HABITS
#import "HBHabitsViewController.h"
#import "HBReviewViewController.h"
#import "HBStore.h"
#import "HBAI.h"
#define Generator HBGenerateViewController
#define Review HBReviewViewController
#define Preview HBPickViewController
#else
#import "LFRoutinesViewController.h"
#import "LFProgressViewController.h"
#import "LFStore.h"
#import "LFAI.h"
#define Generator LFGenerateViewController
#define Review LFProgressViewController
#define Preview LFPlanPreviewController
#endif
static NSUInteger checks,closedGenerators,closedReviews,closedCoaches,closedPreviews;
static void check(BOOL b,const char *message) { checks++;if(!b) { fprintf(stderr,"FAIL %s\n",message);exit(1); } }
@interface TrackedGenerator:Generator @end
@implementation TrackedGenerator
- (void)dealloc { closedGenerators++;[super dealloc]; }
@end
@interface TrackedReview:Review @end
@implementation TrackedReview
- (void)dealloc { closedReviews++;[super dealloc]; }
@end
@interface TrackedCoach:CLCoachViewController @end
@implementation TrackedCoach
- (void)dealloc { closedCoaches++;[super dealloc]; }
@end
@interface TrackedPreview:Preview @end
@implementation TrackedPreview
- (void)dealloc { closedPreviews++;[super dealloc]; }
@end
static NSUInteger closedNew;
#define TRACK(name,base) @interface name:base @end @implementation name - (void)dealloc { closedNew++;[super dealloc]; } @end
TRACK(TrackedCustom,LFCustomExercise)
TRACK(TrackedHome,LFCoachViewController)
TRACK(TrackedNote,CLNoteViewController)
TRACK(TrackedCheck,CLCheckInController)
TRACK(TrackedSearch,LFExercisesViewController)
@interface LFWorkoutViewController (Audit)
- (void)load;
@end
@interface PendingProtocol:NSURLProtocol @end
@implementation PendingProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)r { return [[[r URL] host] isEqual:@"api.anthropic.com"]; }
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)r { return r; }
- (void)startLoading {}
- (void)stopLoading {}
@end
static size_t allocated(void) { malloc_statistics_t s;malloc_zone_statistics(NULL,&s);return s.size_in_use; }
static void reload(UIViewController *c) { check(c.view!=nil,"view loads");[c viewWillAppear:NO];[c viewWillDisappear:NO];[c viewDidUnload];c.view=nil;check(c.view!=nil,"view reloads after memory warning");[c viewWillAppear:NO]; }
@interface AuditDelegate:NSObject<UIApplicationDelegate> { UIWindow *window; }
@end
@implementation AuditDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts { window=[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];window.rootViewController=[[[UIViewController alloc] init] autorelease];[window makeKeyAndVisible];[self performSelector:@selector(run) withObject:nil afterDelay:.5];return YES; }
- (void)run {
    NSString *path=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/audit.txt"];freopen([path fileSystemRepresentation],"w",stdout);freopen([path fileSystemRepresentation],"a",stderr);
    NSAutoreleasePool *outer=[NSAutoreleasePool new];[NSURLProtocol registerClass:[PendingProtocol class]];[[NSUserDefaults standardUserDefaults] setObject:@"fixture-only" forKey:@"ai_claude_key"];[[NSUserDefaults standardUserDefaults] setObject:@"claude" forKey:@"ai_provider"];
#ifdef HABITS
    [HBStore saveHabits:[NSArray array]];
    NSArray *plan=[HBAI parseHabits:@"{\"habits\":[{\"name\":\"Read one page\",\"type\":\"check\",\"target\":1,\"days\":[\"mon\"],\"time\":\"\",\"why\":\"Start small.\"}]}" count:1 error:NULL];
#else
    [LFStore saveRoutines:[NSArray array]];
    NSArray *plan=[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fixture-routine",@"id",@"Small start",@"name",[NSArray array],@"exercises",nil]];
#endif
    check([plan count]==1,"plan fixture ready");
    double v=0;check(LFParseWeight(@"13",&v)&&v==13,"13 lb exact entry");check(LFParseWeight(@"13.25",&v)&&v==13.25,"fractional entry");check(LFParseWeight(@"13,25",&v)&&v==13.25,"decimal comma");check(!LFParseWeight(@"NaN",&v)&&!LFParseWeight(@"-1",&v)&&!LFParseWeight(@"12.3.4",&v)&&!LFParseWeight(@"10001",&v),"invalid weights rejected");
    NSDictionary *fixture=[NSDictionary dictionaryWithObjectsAndKeys:@"fixture",@"id",@"Fixture",@"name",[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Barbell_Deadlift",@"id",[NSNumber numberWithInt:1],@"sets",@"8",@"reps",nil]],@"exercises",nil];[LFWorkoutViewController startFromRoutine:fixture];
    LFWorkoutViewController *workout=[LFWorkoutViewController new];[workout load];[workout setValue:[NSNumber numberWithInt:0] forKey:@"pickSection"];[workout setValue:[NSNumber numberWithInt:0] forKey:@"pickRow"];[workout weightSaved:13.25];
    [workout pickerView:nil didSelectRow:8 inComponent:1];NSArray *saved=[[[[LFStore activeWorkout] objectForKey:@"exercises"] objectAtIndex:0] objectForKey:@"sets"];check([[[saved objectAtIndex:0] objectForKey:@"weight"] doubleValue]==13.25,"reps edit preserves exact weight");[workout pickerView:nil didSelectRow:26 inComponent:0];saved=[[[[LFStore activeWorkout] objectForKey:@"exercises"] objectAtIndex:0] objectForKey:@"sets"];check([[[saved objectAtIndex:0] objectForKey:@"weight"] doubleValue]==13,"wheel supports 13 lb");[workout release];[LFStore saveActiveWorkout:nil];
    LFSearch *search=[[LFSearch alloc] initWithExercises:[LFStore exercises]];NSDate *started=[NSDate date];for(int i=0;i<10;i++)[search resultsForQuery:@"dumbell shoulder press" kind:0];printf("10 A4 full-catalog searches %.3fs\n",-[started timeIntervalSinceNow]);[search release];
    NSDictionary *options=[NSDictionary dictionaryWithObjectsAndKeys:@"strength",@"goal",@"beginner",@"level",@"full gym",@"equipment",@"",@"notes",[NSNumber numberWithInt:3],@"days",[NSNumber numberWithInt:45],@"minutes",nil];check([[LFAI routinePrompt:options] length]<96000,"expanded catalog fits request budget");printf("Full catalog plan prompt: %u chars\n",(unsigned)[[LFAI routinePrompt:options] length]);
    LFExercisesViewController *library=[LFExercisesViewController new];[library viewWillAppear:NO];id oldIndex=[[library valueForKey:@"searchIndex"] retain];[library viewWillAppear:NO];check(oldIndex==[library valueForKey:@"searchIndex"],"unchanged library reuses search index");NSDictionary *custom=[NSDictionary dictionaryWithObjectsAndKeys:[@"Audit custom " stringByAppendingString:[LFStore uniqueId]],@"name",@"machine",@"equipment",@"strength",@"category",[NSArray arrayWithObject:@"chest"],@"primary",[NSArray array],@"secondary",[NSArray arrayWithObject:@"audituniquealias"],@"aliases",[NSArray array],@"images",[NSArray array],@"instructions",nil];check([LFStore addCustomExercise:custom error:NULL],"native custom exercise save");[library viewWillAppear:NO];check(oldIndex!=[library valueForKey:@"searchIndex"],"custom addition refreshes existing browser");check([[(LFSearch *)[library valueForKey:@"searchIndex"] resultsForQuery:@"audituniquealias" kind:0] count]>0,"new custom alias searchable");[oldIndex release];[library release];
    NSMutableString *longNote=[NSMutableString string];for(int i=0;i<100;i++)[longNote appendString:@"## A useful heading\n- A **bold** next step with a normal paragraph.\n\n"];ORTextLayout *layout=[[ORTextLayout alloc] initWithText:longNote markdown:YES width:284];check([layout pageCount]>10,"long note paginates without truncation");[layout release];
    size_t baseline=0,last=0;
    for(int i=0;i<50;i++) { NSAutoreleasePool *pool=[NSAutoreleasePool new];
        TrackedCustom *custom=[TrackedCustom new];reload(custom);UISegmentedControl *segment=[custom valueForKey:@"logging"];segment.selectedSegmentIndex=1;reload(custom);check(segment.selectedSegmentIndex==1,"custom hold selection survives view reload");[custom release];TrackedHome *home=[TrackedHome new];reload(home);[home release];TrackedCheck *checkin=[[TrackedCheck alloc] initWithSource:@"Sets"];reload(checkin);[checkin release];TrackedNote *note=[[TrackedNote alloc] initWithTitle:@"Claude" text:@"## Progress\n- **Keep** a consistent plan.\n\n```\nA long line that stays inside its box rather than overflowing the paper.\n```\n"];reload(note);[note release];TrackedSearch *search=[TrackedSearch new];reload(search);[search release];
        TrackedGenerator *g=[TrackedGenerator new];reload(g);CLAIRequest *active=[g valueForKey:@"request"];[active startSystem:@"fixture" user:@"fixture"];check(active.running,"request started for teardown test");[g release];
        TrackedReview *r=[TrackedReview new];reload(r);[r release];
        TrackedCoach *c=[[TrackedCoach alloc] initWithSource:@"Habits" context:@"No history yet." system:@"A small next step."];reload(c);active=[c valueForKey:@"request"];[active startSystem:@"fixture" user:@"fixture"];check(active.running,"coach upload pending");[c release];
#ifdef HABITS
        TrackedPreview *p=[[TrackedPreview alloc] initWithHabits:plan goal:@"Read more"];
        check([[HBStore habits] count]==0,"preview does not save habits");
#else
        TrackedPreview *p=[[TrackedPreview alloc] initWithRoutines:plan];
        check([[LFStore routines] count]==0,"preview does not save routines");
#endif
        reload(p);[p release];[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.02]];[pool drain];last=allocated();if(i==9)baseline=last;
        if(i%10==9) { printf("cycle %d allocated=%lu\n",i+1,(unsigned long)last);fflush(stdout); }
    }
    check(closedNew==250,"new custom, Coach, notes, check-in and search controllers released");
    check(closedGenerators==50 && closedReviews==50 && closedCoaches==50 && closedPreviews==50,"all 200 controllers released, including pending requests");check(last<=baseline+512*1024,"post-warmup heap bounded");
    CLAIRequest *request=[CLAIRequest new];[request startSystem:@"fixture" user:@"fixture"];[[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];check(request.state==CLAICancelled,"background cancels transport");[request release];
    printf("PASS %lu native assertions; 450 controllers released; heap change %+ld bytes\n",(unsigned long)checks,(long)last-(long)baseline);fflush(stdout);[outer drain];exit(0);
}
- (void)dealloc { [window release];[super dealloc]; }
@end
int main(int argc,char **argv) { NSAutoreleasePool *pool=[NSAutoreleasePool new];int result=UIApplicationMain(argc,argv,nil,@"AuditDelegate");[pool drain];return result; }
