#import "LFStore.h"
#import "ORJSON.h"

static NSArray *gExercises = nil; static NSDictionary *gById = nil; static BOOL gStretch = NO;

@implementation LFStore
+ (NSString *)docs { return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; }
+ (id)readJSON:(NSString *)name { NSString *t = [NSString stringWithContentsOfFile:[[self docs] stringByAppendingPathComponent:name] encoding:NSUTF8StringEncoding error:nil]; return t ? [ORJSON parse:t] : nil; }
+ (void)writeJSON:(id)obj name:(NSString *)name { [[ORJSON stringify:obj] writeToFile:[[self docs] stringByAppendingPathComponent:name] atomically:YES encoding:NSUTF8StringEncoding error:nil]; }

+ (void)load_ {
    if (gExercises) return;
    NSString *p = [[NSBundle mainBundle] pathForResource:@"exercises" ofType:@"json"];
    NSArray *a = [ORJSON parse:[NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil]] ?: [NSArray array];
    gExercises = [a retain];
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    for (NSDictionary *e in a) [m setObject:e forKey:[e objectForKey:@"id"]];
    gById = [m retain];
}
+ (BOOL)isStretch:(NSDictionary *)e {   // stretches, plus the timed holds that are logged the same way
    if ([[e objectForKey:@"category"] isEqualToString:@"stretching"]) return YES;
    static NSSet *timed = nil; if (!timed) timed = [[NSSet alloc] initWithObjects:@"Plank", @"One_Handed_Hang", @"Side_Plank", @"Wall_Sit", @"Dead_Hang", nil];
    return [timed containsObject:[e objectForKey:@"id"] ?: @""];
}
+ (void)setShowStretches:(BOOL)v { gStretch = v; }
+ (NSArray *)exercises { [self load_]; return gExercises; }
+ (NSDictionary *)exercise:(NSString *)eid { [self load_]; return [gById objectForKey:eid ?: @""]; }
+ (NSArray *)muscleGroups {
    [self load_]; NSMutableArray *muscles = [NSMutableArray array];
    for (NSDictionary *e in gExercises) { if ([self isStretch:e] != gStretch) continue; NSString *pm = [[e objectForKey:@"primary"] count] ? [[e objectForKey:@"primary"] objectAtIndex:0] : @"other"; if (![muscles containsObject:pm]) [muscles addObject:pm]; }
    [muscles sortUsingSelector:@selector(compare:)]; return muscles;
}
+ (NSArray *)exercisesForMuscle:(NSString *)mu {
    NSMutableArray *r = [NSMutableArray array];
    for (NSDictionary *e in [self exercises]) { if ([self isStretch:e] != gStretch) continue; NSArray *p = [e objectForKey:@"primary"]; NSString *pm = [p count] ? [p objectAtIndex:0] : @"other"; if ([pm isEqualToString:mu]) [r addObject:e]; }
    return r;
}
+ (NSString *)imagePath:(NSString *)eid frame:(int)i {
    NSArray *imgs = [[self exercise:eid] objectForKey:@"images"];
    if (i >= (int)[imgs count]) return nil;
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingFormat:@"/exercises/%@", [imgs objectAtIndex:i]];
}
+ (NSArray *)routines { return [self readJSON:@"routines.json"] ?: [NSArray array]; }
+ (void)saveRoutines:(NSArray *)r { [self writeJSON:r name:@"routines.json"]; }
+ (NSArray *)workouts { return [self readJSON:@"workouts.json"] ?: [NSArray array]; }
+ (void)saveWorkouts:(NSArray *)w { [self writeJSON:w name:@"workouts.json"]; }
+ (NSDictionary *)activeWorkout { id a = [self readJSON:@"active.json"]; return [a isKindOfClass:[NSDictionary class]] ? a : nil; }
+ (void)saveActiveWorkout:(NSDictionary *)w {
    NSString *p = [[self docs] stringByAppendingPathComponent:@"active.json"];
    if (w) [self writeJSON:w name:@"active.json"]; else [[NSFileManager defaultManager] removeItemAtPath:p error:nil];
}
+ (NSString *)newId { CFUUIDRef u = CFUUIDCreate(NULL); NSString *s = [(NSString *)CFUUIDCreateString(NULL, u) autorelease]; CFRelease(u); return s; }
+ (NSUserDefaults *)d { return [NSUserDefaults standardUserDefaults]; }
+ (NSString *)apiKey { return [[self d] stringForKey:@"lf_api_key"] ?: @""; }
+ (void)setApiKey:(NSString *)k { [[self d] setObject:k forKey:@"lf_api_key"]; [[self d] synchronize]; }
+ (NSInteger)restSeconds { id v = [[self d] objectForKey:@"lf_rest"]; return v ? [v integerValue] : 90; }
+ (void)setRestSeconds:(NSInteger)s { [[self d] setInteger:s forKey:@"lf_rest"]; [[self d] synchronize]; }
+ (BOOL)useKg { id v = [[self d] objectForKey:@"lf_kg"]; return v ? [v boolValue] : NO; }
+ (void)setUseKg:(BOOL)v { [[self d] setBool:v forKey:@"lf_kg"]; [[self d] synchronize]; }
+ (NSDictionary *)bestSetFor:(NSString *)eid {
    NSDictionary *best = nil; double bw = -1;
    for (NSDictionary *w in [self workouts]) for (NSDictionary *ex in [w objectForKey:@"exercises"]) {
        if (![[ex objectForKey:@"id"] isEqualToString:eid]) continue;
        for (NSDictionary *s in [ex objectForKey:@"sets"]) {
            if (![[s objectForKey:@"done"] boolValue]) continue;
            double wt = [[s objectForKey:@"weight"] doubleValue];
            if (wt > bw) { bw = wt; best = s; }
        }
    }
    return best;
}
+ (double)volumeOf:(NSDictionary *)workout {
    double v = 0;
    for (NSDictionary *ex in [workout objectForKey:@"exercises"]) for (NSDictionary *s in [ex objectForKey:@"sets"]) if ([[s objectForKey:@"done"] boolValue]) v += [[s objectForKey:@"weight"] doubleValue] * [[s objectForKey:@"reps"] doubleValue];
    return v;
}
+ (double)e1rm:(double)weight reps:(int)reps { if (reps <= 0 || weight <= 0) return 0; return reps == 1 ? weight : weight * (1.0 + reps / 30.0); }
+ (NSArray *)bodyWeights { id a = [self readJSON:@"bodyweight.json"]; return [a isKindOfClass:[NSArray class]] ? a : [NSArray array]; }
+ (BOOL)sameDay:(double)a as:(double)b {
    NSCalendar *cal = [NSCalendar currentCalendar]; unsigned u = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *x = [cal components:u fromDate:[NSDate dateWithTimeIntervalSince1970:a]], *y = [cal components:u fromDate:[NSDate dateWithTimeIntervalSince1970:b]];
    return [x year] == [y year] && [x month] == [y month] && [x day] == [y day];
}
+ (void)logBodyWeight:(double)w {
    double now = [[NSDate date] timeIntervalSince1970];
    NSMutableArray *a = [NSMutableArray array];
    for (NSDictionary *e in [self bodyWeights]) if (![self sameDay:[[e objectForKey:@"t"] doubleValue] as:now]) [a addObject:e];
    [a addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:now], @"t", [NSNumber numberWithDouble:w], @"w", nil]];
    [a sortUsingComparator:^NSComparisonResult(id x, id y) { double p = [[x objectForKey:@"t"] doubleValue], q = [[y objectForKey:@"t"] doubleValue]; return p < q ? NSOrderedAscending : p > q ? NSOrderedDescending : NSOrderedSame; }];
    [self writeJSON:a name:@"bodyweight.json"];
}
+ (void)deleteBodyWeightAt:(NSUInteger)i { NSMutableArray *a = [NSMutableArray arrayWithArray:[self bodyWeights]]; if (i < [a count]) { [a removeObjectAtIndex:i]; [self writeJSON:a name:@"bodyweight.json"]; } }
+ (NSArray *)sortedWorkouts {
    NSMutableArray *w = [NSMutableArray arrayWithArray:[self workouts]];
    [w sortUsingComparator:^NSComparisonResult(id x, id y) { double p = [[x objectForKey:@"start"] doubleValue], q = [[y objectForKey:@"start"] doubleValue]; return p < q ? NSOrderedAscending : p > q ? NSOrderedDescending : NSOrderedSame; }];
    return w;
}
+ (NSArray *)exerciseProgress:(NSString *)eid {
    NSMutableArray *out = [NSMutableArray array];
    for (NSDictionary *w in [self sortedWorkouts]) {
        double bestE = 0, bestW = 0; int bestR = 0, nsets = 0; double vol = 0;
        for (NSDictionary *ex in [w objectForKey:@"exercises"]) {
            if (![[ex objectForKey:@"id"] isEqualToString:eid]) continue;
            for (NSDictionary *s in [ex objectForKey:@"sets"]) {
                if (![[s objectForKey:@"done"] boolValue]) continue;
                double wt = [[s objectForKey:@"weight"] doubleValue]; int r = [[s objectForKey:@"reps"] intValue];
                nsets++; vol += wt * r;
                double e = [self e1rm:wt reps:r];
                if (e > bestE || (e == bestE && wt > bestW)) { bestE = e; bestW = wt; bestR = r; }
            }
        }
        if (!nsets) continue;
        [out addObject:[NSDictionary dictionaryWithObjectsAndKeys:[w objectForKey:@"start"], @"t", [NSNumber numberWithDouble:bestW], @"weight", [NSNumber numberWithInt:bestR], @"reps",
                        [NSNumber numberWithDouble:bestE], @"e1rm", [NSNumber numberWithDouble:vol], @"volume", [NSNumber numberWithInt:nsets], @"sets", [w objectForKey:@"name"], @"workout", nil]];
    }
    return out;
}
+ (NSArray *)exerciseIdsInHistory {
    NSMutableDictionary *count = [NSMutableDictionary dictionary];
    for (NSDictionary *w in [self workouts]) for (NSDictionary *ex in [w objectForKey:@"exercises"]) {
        BOOL any = NO; for (NSDictionary *s in [ex objectForKey:@"sets"]) if ([[s objectForKey:@"done"] boolValue]) { any = YES; break; }
        if (!any) continue;
        NSString *k = [ex objectForKey:@"id"]; if (![self exercise:k] || [self isStretch:[self exercise:k]]) continue;   // stretches have no weight to chart
        [count setObject:[NSNumber numberWithInt:[[count objectForKey:k] intValue] + 1] forKey:k];
    }
    NSMutableArray *ids = [NSMutableArray arrayWithArray:[count allKeys]];
    [ids sortUsingComparator:^NSComparisonResult(id x, id y) {
        int a = [[count objectForKey:x] intValue], b = [[count objectForKey:y] intValue];
        if (a != b) return a > b ? NSOrderedAscending : NSOrderedDescending;
        return [[[self exercise:x] objectForKey:@"name"] compare:[[self exercise:y] objectForKey:@"name"]];
    }];
    return ids;
}
+ (double)weekStart:(double)t {
    NSDate *s = nil; [[NSCalendar currentCalendar] rangeOfUnit:NSWeekCalendarUnit startDate:&s interval:NULL forDate:[NSDate dateWithTimeIntervalSince1970:t]];
    return s ? [s timeIntervalSince1970] : t;
}
+ (NSArray *)weeklyVolume:(int)weeks {
    // week boundaries walked backwards through the calendar so DST shifts don't break the buckets
    NSMutableArray *starts = [NSMutableArray array]; double ws = [self weekStart:[[NSDate date] timeIntervalSince1970]];
    for (int i = 0; i < weeks; i++) { [starts addObject:[NSNumber numberWithDouble:ws]]; ws = [self weekStart:ws - 3.5 * 86400.0]; }
    NSMutableArray *out = [NSMutableArray array];
    for (int i = weeks - 1; i >= 0; i--) {
        double s = [[starts objectAtIndex:i] doubleValue], e = i == 0 ? 1e18 : [[starts objectAtIndex:i - 1] doubleValue], vol = 0; int n = 0;
        for (NSDictionary *w in [self workouts]) { double t = [[w objectForKey:@"start"] doubleValue]; if (t >= s && t < e) { n++; vol += [self volumeOf:w]; } }
        [out addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:s], @"t", [NSNumber numberWithDouble:vol], @"volume", [NSNumber numberWithInt:n], @"count", nil]];
    }
    return out;
}
+ (NSInteger)weekStreak {
    NSMutableSet *weeks = [NSMutableSet set];
    for (NSDictionary *w in [self workouts]) [weeks addObject:[NSNumber numberWithLongLong:(long long)[self weekStart:[[w objectForKey:@"start"] doubleValue]]]];
    double cur = [self weekStart:[[NSDate date] timeIntervalSince1970]];
    if (![weeks containsObject:[NSNumber numberWithLongLong:(long long)cur]]) cur = [self weekStart:cur - 3.5 * 86400.0];   // this week may still be in progress
    NSInteger n = 0;
    while ([weeks containsObject:[NSNumber numberWithLongLong:(long long)cur]]) { n++; cur = [self weekStart:cur - 3.5 * 86400.0]; }
    return n;
}
@end
