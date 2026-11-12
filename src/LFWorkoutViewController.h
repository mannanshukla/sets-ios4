#import <UIKit/UIKit.h>
#import "LFExercisesViewController.h"
#import "LFWeightViewController.h"
#import "LFSkin.h"
@interface LFWorkoutViewController : UITableViewController <LFWeightDelegate, LFExercisePicker, UITextFieldDelegate, UIActionSheetDelegate, UIPickerViewDataSource, UIPickerViewDelegate, LFTrimMemory> {
    NSMutableDictionary *active; NSMutableArray *exercises;   // live copy of the active workout
    NSTimer *tick; NSTimeInterval restEnds; NSArray *routines;
    UIView *drum; UIPickerView *picker; UILabel *drumTitle; NSInteger pickSection, pickRow;   // the slide-up number wheel
}
+ (void)startFromRoutine:(NSDictionary *)routine;   // creates the active workout file
+ (void)startEmpty;
@end
@interface LFHistoryViewController : UITableViewController <LFTrimMemory> { NSArray *workouts; NSDateFormatter *dateFormat; }
@end
@interface LFWorkoutDetailViewController : UITableViewController { NSDictionary *workout; }
- (id)initWithWorkout:(NSDictionary *)w;
@end
