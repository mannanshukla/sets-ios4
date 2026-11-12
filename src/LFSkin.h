#import <UIKit/UIKit.h>
// The log-sheet look: ruled paper rows on a clipboard, a leather-bound bar in the app's purple. Textures drawn in code.
void LFSkinNavBar(UINavigationBar *bar);
void LFSkinPaperTable(UITableView *tv);            // plain table: paper behind, no separators
void LFPaperCell(UITableViewCell *c);              // give a cell a ruled paper background
UIView *LFPaperHeader(CGFloat width, CGFloat height, NSString *text);
UITableViewCell *LFPaperNoteCell(NSString *text);  // an italic pencil note on a ruled row, for empty states and hints
void LFFitTitle(UIViewController *vc, NSString *title);   // long names shrink to fit the bar instead of trailing off
// Memory. When the app goes to the background or gets a memory warning, the app delegate drops what can be rebuilt.
void LFSkinPurgeCache(void);                        // shared paper sheets; views keep theirs and new ones are drawn on demand
BOOL LFViewIsVisible(UIViewController *vc);         // view loaded and on screen
void LFUnloadHiddenView(UIViewController *vc);      // drop an off-screen controller's view as a memory warning would, remembering its scroll position
void LFRestoreScroll(UIViewController *vc);         // call at the end of viewWillAppear: puts a dropped table back where it was
@protocol LFTrimMemory <NSObject>
- (void)trimMemory;                                 // release rebuildable state; each controller checks for itself whether it is on screen
@end
