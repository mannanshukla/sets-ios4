#import "LFStore.h"
#import "WBBridge.h"
#import "ORJSON.h"
static NSString *weightDirectory;
static NSMutableDictionary *weightPrefs;
static NSUInteger weightChecks;
static void wcheck(BOOL ok,const char *text) { weightChecks++;if(!ok) { fprintf(stderr,"FAIL %s\n",text);exit(1); } }
@interface WeightDefaults:NSObject
- (id)objectForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (BOOL)synchronize;
@end
@implementation WeightDefaults
- (id)objectForKey:(NSString *)key { return [weightPrefs objectForKey:key]; }
- (void)setBool:(BOOL)value forKey:(NSString *)key { [weightPrefs setObject:[NSNumber numberWithBool:value] forKey:key]; }
- (BOOL)boolForKey:(NSString *)key { return [[weightPrefs objectForKey:key] boolValue]; }
- (BOOL)synchronize { return YES; }
@end
@interface WeightTestStore:LFStore @end
@implementation WeightTestStore
+ (NSString *)docs { return weightDirectory; }
+ (NSUserDefaults *)d { return (NSUserDefaults *)[[[WeightDefaults alloc] init] autorelease]; }
@end
static void runWeightStoreTests(void) {
 weightDirectory=[[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] retain];weightPrefs=[NSMutableDictionary new];NSFileManager *fm=[NSFileManager defaultManager];[fm createDirectoryAtPath:weightDirectory withIntermediateDirectories:YES attributes:nil error:NULL];NSString *file=[weightDirectory stringByAppendingPathComponent:@"bodyweight.json"];
 double time=[[NSDate date] timeIntervalSince1970];NSArray *raw=@[@{@"w":@180,@"t":[NSNumber numberWithDouble:time-86400*2]},@{@"w":@181,@"t":[NSNumber numberWithDouble:time-86400]}];[[ORJSON stringify:raw] writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:NULL];NSData *original=[NSData dataWithContentsOfFile:file];
 wcheck([WeightTestStore freezeBodyWeightUnits],"freeze existing units");wcheck([original isEqual:[NSData dataWithContentsOfFile:[weightDirectory stringByAppendingPathComponent:@"bodyweight-before-units.json"]]],"byte-exact original weight backup");NSArray *stored=[ORJSON parse:[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL]];for(int i=0;i<2;i++)for(NSString *key in @[@"w",@"t"])wcheck([[[stored objectAtIndex:i] objectForKey:key] isEqual:[[raw objectAtIndex:i] objectForKey:key]],"original fields preserved");
 [WeightTestStore setUseKg:YES];wcheck(fabs([[[[WeightTestStore bodyWeights] objectAtIndex:0] objectForKey:@"w"] doubleValue]-180*.45359237)<.00001,"unit switch converts display only");[WeightTestStore logBodyWeight:80];[WeightTestStore setUseKg:NO];wcheck(fabs([[[[WeightTestStore bodyWeights] lastObject] objectForKey:@"w"] doubleValue]-80/.45359237)<.00001,"new kilograms retain meaning in pounds");wcheck([[WeightTestStore bodyWeights] count]==3,"new day appends");[WeightTestStore logBodyWeight:178];wcheck([[WeightTestStore bodyWeights] count]==3,"same day replaces");
 wcheck([WeightTestStore setSharesWeightsWithMeals:YES],"sharing opt in");
#if TARGET_OS_IPHONE
 NSDictionary *published=WBRead();wcheck(WBValidSnapshot(published)&&[[published objectForKey:@"weights"] count]==3,"native named board publishes complete snapshot");
#endif
 [WeightTestStore deleteBodyWeightAt:0];wcheck([[WeightTestStore bodyWeights] count]==2,"delete keeps remaining source entries");
#if TARGET_OS_IPHONE
 wcheck([[WBRead() objectForKey:@"weights"] count]==2,"source deletion updates board");
#endif
 wcheck([WeightTestStore setSharesWeightsWithMeals:NO],"sharing opt out");
#if TARGET_OS_IPHONE
 wcheck(![[WBRead() objectForKey:@"enabled"] boolValue]&&[[WBRead() objectForKey:@"weights"] count]==0,"opt out clears shared data");
#endif
 [@"broken original" writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:NULL];NSData *broken=[NSData dataWithContentsOfFile:file];wcheck(![WeightTestStore setSharesWeightsWithMeals:YES],"corrupt source cannot enable sharing");[WeightTestStore logBodyWeight:170];wcheck([broken isEqual:[NSData dataWithContentsOfFile:file]],"corrupt weight file never replaced");
 [fm removeItemAtPath:weightDirectory error:NULL];[weightDirectory release];weightDirectory=nil;[weightPrefs release];weightPrefs=nil;printf("PASS %lu Sets weight checks: backup, unit stability, same-day edits, deletion and sharing\n",(unsigned long)weightChecks);fflush(stdout);
}
