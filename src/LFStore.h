#import <Foundation/Foundation.h>
// Local-only storage: exercises from the bundle, routines/workouts as JSON files in Documents.
@interface LFStore : NSObject
+ (NSArray *)exercises;                              // bundled, sorted by name: {id, name, equipment, primary[], secondary[], level, instructions[], images[]}
+ (NSDictionary *)exercise:(NSString *)eid;
+ (NSArray *)muscleGroups;                           // ordered list of primary muscle names present
+ (NSArray *)exercisesForMuscle:(NSString *)m;
+ (NSString *)imagePath:(NSString *)eid frame:(int)i;

+ (NSArray *)routines;     + (void)saveRoutines:(NSArray *)r;    // {id, name, exercises:[{id, sets, reps}]}
+ (NSArray *)workouts;     + (void)saveWorkouts:(NSArray *)w;    // {id, name, start, end, exercises:[{id, sets:[{weight, reps, done}]}]}
+ (NSDictionary *)activeWorkout; + (void)saveActiveWorkout:(NSDictionary *)w;   // nil clears
+ (NSString *)newId;
+ (NSString *)apiKey; + (void)setApiKey:(NSString *)k;
+ (NSInteger)restSeconds; + (void)setRestSeconds:(NSInteger)s;
+ (BOOL)useKg; + (void)setUseKg:(BOOL)v;
+ (NSDictionary *)bestSetFor:(NSString *)eid;        // {weight, reps} heaviest completed set in history, or nil
+ (double)volumeOf:(NSDictionary *)workout;
+ (double)e1rm:(double)weight reps:(int)reps;      // Epley estimate
+ (NSArray *)bodyWeights;                           // [{t, w}] sorted oldest first
+ (void)logBodyWeight:(double)w;                    // replaces today's entry
+ (void)deleteBodyWeightAt:(NSUInteger)i;
+ (NSArray *)exerciseProgress:(NSString *)eid;      // per workout: {t, weight, reps, e1rm, volume, sets}, oldest first
+ (NSArray *)exerciseIdsInHistory;                  // most-trained first
+ (NSArray *)weeklyVolume:(int)weeks;               // oldest first: {t (week start), volume, count}
+ (NSInteger)weekStreak;                            // consecutive weeks with a workout, counting this or last week
@end
