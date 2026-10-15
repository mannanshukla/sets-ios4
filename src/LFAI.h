#import <Foundation/Foundation.h>
// One non-streaming chat completion against OpenRelay, used to generate routines. Synchronous; call off the main thread.
@interface LFAI : NSObject
+ (NSString *)complete:(NSString *)system user:(NSString *)user model:(NSString *)model error:(NSString **)err;
// Builds routines from the model: returns array of routine dicts {id, name, exercises:[{id, sets, reps}]} validated against the exercise DB.
+ (NSArray *)generateRoutinesForGoal:(NSString *)goal days:(NSInteger)days equipment:(NSString *)equipment level:(NSString *)level minutes:(NSInteger)minutes notes:(NSString *)notes error:(NSString **)err;   // notes: free text from the lifter, may be empty
@end
