#import <UIKit/UIKit.h>
#import "LFExercisesViewController.h"
@interface LFWorkoutViewController : UITableViewController <LFExercisePicker, UITextFieldDelegate, UIActionSheetDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
    NSMutableDictionary *active; NSMutableArray *exercises;   // live copy of the active workout
    NSTimer *tick; NSTimeInterval restEnds; NSArray *routines;
    UIView *drum; UIPickerView *picker; UILabel *drumTitle; NSInteger pickSection, pickRow;   // the slide-up number wheel
}
+ (void)startFromRoutine:(NSDictionary *)routine;   // creates the active workout file
+ (void)startEmpty;
@end
@interface LFHistoryViewController : UITableViewController { NSArray *workouts; }
@end
@interface LFWorkoutDetailViewController : UITableViewController { NSDictionary *workout; }
- (id)initWithWorkout:(NSDictionary *)w;
@end
