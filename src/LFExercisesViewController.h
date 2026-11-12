#import <UIKit/UIKit.h>
#import "LFSkin.h"
@class LFExercisesViewController, LFSearch;
@protocol LFExercisePicker <NSObject>
- (void)exercisesPicker:(LFExercisesViewController *)p didPick:(NSDictionary *)exercise;
@end
// Browse by muscle group with search. In picker mode, tapping a row returns it to the delegate instead of opening detail.
@interface LFExercisesViewController : UITableViewController <UISearchBarDelegate, LFTrimMemory> {
    NSArray *groups,*indexedExercises; NSMutableArray *rows;  // rows: array of arrays per group (filtered)
    UISearchBar *search; NSString *query; LFSearch *searchIndex; NSInteger kind;
    id<LFExercisePicker> picker;
}
@property (nonatomic, assign) id<LFExercisePicker> picker;
+ (void)releaseSharedIndex;   // the search index the tab and the Add Exercise pickers share
@end
@interface LFExerciseDetailViewController : UITableViewController <LFTrimMemory> { NSDictionary *exercise; UIImageView *frame; NSArray *steps, *facts; NSDictionary *best; }
- (id)initWithExercise:(NSDictionary *)e;
@end
