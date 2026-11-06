#import <Foundation/Foundation.h>
@interface LFAI : NSObject
+ (NSString *)routineSystem;
+ (NSString *)routinePrompt:(NSDictionary *)options;
+ (NSArray *)parseRoutines:(NSString *)text options:(NSDictionary *)options error:(NSString **)error;
+ (NSString *)summary;
+ (NSString *)reviewSystem;
@end
