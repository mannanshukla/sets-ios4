#import <UIKit/UIKit.h>
@interface LFCustomExercise : UITableViewController <UITextFieldDelegate> { UITextField *name,*aliases; UISegmentedControl *logging; NSString *muscle,*equipment; }
@property(nonatomic,copy) NSString *muscle,*equipment;
@end
