#import <UIKit/UIKit.h>
BOOL LFParseWeight(NSString *text,double *value);
@protocol LFWeightDelegate <NSObject>
- (void)weightSaved:(double)value;
@end
@interface LFWeightViewController : UITableViewController <UITextFieldDelegate> { UITextField *field; double initial; NSString *unit; id<LFWeightDelegate> delegate; }
- (id)initWithWeight:(double)value unit:(NSString *)unit delegate:(id<LFWeightDelegate>)delegate;
@end
