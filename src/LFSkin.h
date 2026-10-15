#import <UIKit/UIKit.h>
// The log-sheet look: ruled paper rows on a clipboard, a leather-bound bar in the app's purple. Textures drawn in code.
void LFSkinNavBar(UINavigationBar *bar);
void LFSkinPaperTable(UITableView *tv);            // plain table: paper behind, no separators
void LFPaperCell(UITableViewCell *c);              // give a cell a ruled paper background
UIView *LFPaperHeader(CGFloat width, CGFloat height, NSString *text);
