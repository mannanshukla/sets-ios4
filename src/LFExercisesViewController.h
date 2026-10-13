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
@interface LFExerciseDetailViewController : UIViewController { NSDictionary *exercise; UIImageView *frame; int frameIndex; NSTimer *flip; UITextView *text; }
- (id)initWithExercise:(NSDictionary *)e;
@end
