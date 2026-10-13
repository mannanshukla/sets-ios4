#import <UIKit/UIKit.h>
#import "LFExercisesViewController.h"
@interface LFRoutinesViewController : UITableViewController { NSMutableArray *routines; }
- (void)reload;
@end
@interface LFRoutineEditViewController : UITableViewController <LFExercisePicker, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
    NSMutableDictionary *routine; NSMutableArray *exercises; UITextField *nameField; BOOL isNew;
    UIView *drum; UIPickerView *picker; UILabel *drumTitle; NSInteger pickRow;   // sets × reps wheel for one exercise row
}
- (id)initWithRoutine:(NSDictionary *)r;
@end
@interface LFGenerateViewController : UITableViewController {
    UISegmentedControl *goal, *level, *equipment; UISlider *days, *minutes; UILabel *daysLabel, *minutesLabel; BOOL busy; NSString *status;
}
@end
