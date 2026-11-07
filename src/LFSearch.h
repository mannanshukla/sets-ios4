#import <Foundation/Foundation.h>
// Offline token matching: exact name/alias, prefix, then bounded Damerau–Levenshtein distance.
@interface LFSearch : NSObject { NSArray *index; }
- (id)initWithExercises:(NSArray *)exercises;
- (NSArray *)resultsForQuery:(NSString *)query kind:(NSInteger)kind; // 0 all, 1 lifts, 2 stretches
@end
