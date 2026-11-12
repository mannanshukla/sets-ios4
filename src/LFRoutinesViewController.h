#import <UIKit/UIKit.h>
#import "LFExercisesViewController.h"
#import "CLAIRequest.h"
#import "LFSkin.h"
@interface LFRoutinesViewController : UITableViewController { NSMutableArray *routines; }
- (void)reload;
@end
@interface LFRoutineEditViewController : UITableViewController <LFExercisePicker, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, LFTrimMemory> {
    NSMutableDictionary *routine; NSMutableArray *exercises; UITextField *nameField; BOOL isNew;
    UIView *drum; UIPickerView *picker; UILabel *drumTitle; NSInteger pickRow;   // sets × reps wheel for one exercise row
}
- (id)initWithRoutine:(NSDictionary *)r;
@end
@interface LFGenerateViewController : UITableViewController <UITextFieldDelegate,CLAIRequestDelegate> {
    UISegmentedControl *goal, *level, *equipment; UISlider *days, *minutes; UILabel *daysLabel, *minutesLabel; CLAIRequest *request; NSDictionary *pendingOptions; NSString *status;
 UITextField *notes;}
@end

@interface LFPlanPreviewController : UITableViewController { NSArray *proposed;NSMutableIndexSet *chosen; }
- (id)initWithRoutines:(NSArray *)routines;
@end
