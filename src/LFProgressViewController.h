#import <UIKit/UIKit.h>
#import "LFSkin.h"
// Simple CoreGraphics line/bar chart for iOS 4.
@interface LFChartView : UIView { NSArray *xs, *ys; BOOL bars; NSString *unitStr; }
- (void)setXs:(NSArray *)x ys:(NSArray *)y bars:(BOOL)b unit:(NSString *)u;
@end
@interface LFProgressViewController : UITableViewController <LFTrimMemory> { NSArray *weights, *weekly, *exerciseIds; LFChartView *weightChart, *volumeChart; }
@end
@interface LFBodyWeightViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate, LFTrimMemory> { NSArray *entries; UIView *drum; UIPickerView *picker; }
@end
@interface LFExerciseProgressViewController : UITableViewController <LFTrimMemory> { NSString *eid; NSArray *sessions; UISegmentedControl *mode; NSInteger modeIndex; LFChartView *chart; }
- (id)initWithExercise:(NSString *)e;
@end
