#import <UIKit/UIKit.h>
@class LFExercisesViewController;
@protocol LFExercisePicker <NSObject>
- (void)exercisesPicker:(LFExercisesViewController *)p didPick:(NSDictionary *)exercise;
@end
// Browse by muscle group with search. In picker mode, tapping a row returns it to the delegate instead of opening detail.
@interface LFExercisesViewController : UITableViewController <UISearchBarDelegate> {
    NSArray *groups; NSMutableArray *rows;  // rows: array of arrays per group (filtered)
    UISearchBar *search; NSString *query;
    id<LFExercisePicker> picker;
}
@property (nonatomic, assign) id<LFExercisePicker> picker;
@end
@interface LFExerciseDetailViewController : UITableViewController { NSDictionary *exercise; UIImageView *frame; NSArray *steps, *facts; NSDictionary *best; }
- (id)initWithExercise:(NSDictionary *)e;
@end
