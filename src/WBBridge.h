#import <Foundation/Foundation.h>
// Shared versioned on-device protocol. This never uses the user's general clipboard.
NSString *WBDay(NSDate *date);
BOOL WBValidDay(id value);
NSArray *WBCanonicalRows(id rows, BOOL useKg);
NSDictionary *WBSnapshot(NSArray *rows, BOOL enabled, NSDate *now);
BOOL WBValidSnapshot(id value);
void WBPublish(NSDictionary *snapshot);
NSDictionary *WBRead(void);
