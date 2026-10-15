#import "LFSkin.h"
#define RULE_H 44
static UIColor *paperColor(void) { return [UIColor colorWithRed:0.985 green:0.97 blue:0.91 alpha:1]; }
static UIColor *ruleColor(void) { return [UIColor colorWithRed:0.72 green:0.80 blue:0.88 alpha:1]; }
static void drawPaper(CGContextRef c, CGRect r, BOOL rule) {
    [paperColor() set]; CGContextFillRect(c, r);
    srand(11); for (int i = 0; i < r.size.width * r.size.height / 40; i++) { [[UIColor colorWithWhite:0.55 alpha:0.05] set]; CGContextFillRect(c, CGRectMake(r.origin.x + rand() % (int)r.size.width, r.origin.y + rand() % (int)MAX(1, r.size.height), 1, 1)); }
    if (rule) { [ruleColor() set]; CGContextSetLineWidth(c, 1); CGContextMoveToPoint(c, r.origin.x, CGRectGetMaxY(r) - 0.5); CGContextAddLineToPoint(c, CGRectGetMaxX(r), CGRectGetMaxY(r) - 0.5); CGContextStrokePath(c); }
}
static UIImage *leather(CGSize sz) {
    UIGraphicsBeginImageContextWithOptions(sz, YES, 0); CGContextRef c = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB(); CGFloat locs[2] = {0, 1};
    CGGradientRef g = CGGradientCreateWithColors(cs, (CFArrayRef)[NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.42 green:0.30 blue:0.66 alpha:1].CGColor, (id)[UIColor colorWithRed:0.26 green:0.17 blue:0.46 alpha:1].CGColor, nil], locs);
    CGContextDrawLinearGradient(c, g, CGPointMake(0, 0), CGPointMake(0, sz.height), 0); CGGradientRelease(g); CGColorSpaceRelease(cs);
    srand(5); for (int i = 0; i < sz.width * sz.height / 3; i++) { BOOL light = rand() % 3 == 0; [[UIColor colorWithWhite:light ? 1 : 0 alpha:(rand() % 100) / 100.0 * (light ? 0.10 : 0.22)] set]; CGContextFillRect(c, CGRectMake(rand() % (int)sz.width, rand() % (int)sz.height, 1 + rand() % 2, 1)); }
    [[UIColor colorWithWhite:1 alpha:0.22] set]; CGContextFillRect(c, CGRectMake(0, 0, sz.width, 1));
    CGFloat dash[2] = {5, 4}; CGContextSetLineDash(c, 0, dash, 2); CGContextSetLineWidth(c, 1.5); CGContextSetLineCap(c, kCGLineCapRound);
    [[UIColor colorWithWhite:0 alpha:0.5] set]; CGContextMoveToPoint(c, 0, sz.height - 4.5); CGContextAddLineToPoint(c, sz.width, sz.height - 4.5); CGContextStrokePath(c);
    [[UIColor colorWithRed:0.90 green:0.86 blue:0.96 alpha:0.9] set]; CGContextMoveToPoint(c, 0, sz.height - 5.5); CGContextAddLineToPoint(c, sz.width, sz.height - 5.5); CGContextStrokePath(c);
    CGContextSetLineDash(c, 0, NULL, 0); [[UIColor colorWithWhite:0 alpha:0.6] set]; CGContextFillRect(c, CGRectMake(0, sz.height - 1, sz.width, 1));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return img;
}
void LFSkinNavBar(UINavigationBar *bar) {
    if ([bar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) { static UIImage *img = nil; if (!img) img = [leather(CGSizeMake(320, 44)) retain]; [bar performSelector:@selector(setBackgroundImage:forBarMetrics:) withObject:img withObject:0]; }
}
@interface LFPaperBackground : UIView @end
@implementation LFPaperBackground
- (void)drawRect:(CGRect)r { CGContextRef c = UIGraphicsGetCurrentContext(); drawPaper(c, self.bounds, NO); [ruleColor() set]; CGContextSetLineWidth(c, 1); for (CGFloat y = RULE_H - 0.5; y < self.bounds.size.height; y += RULE_H) { CGContextMoveToPoint(c, 0, y); CGContextAddLineToPoint(c, self.bounds.size.width, y); } CGContextStrokePath(c); }
@end
@interface LFPaperRow : UIView { BOOL selected; } @property (nonatomic, assign) BOOL selected; @end
@implementation LFPaperRow
@synthesize selected;
- (id)initWithFrame:(CGRect)f { if ((self = [super initWithFrame:f])) { self.contentMode = UIViewContentModeRedraw; self.opaque = YES; } return self; }
- (void)drawRect:(CGRect)r { CGContextRef c = UIGraphicsGetCurrentContext(); drawPaper(c, self.bounds, YES); if (selected) { [[UIColor colorWithWhite:0 alpha:0.06] set]; CGContextFillRect(c, self.bounds); } }
@end
void LFSkinPaperTable(UITableView *tv) {
    LFPaperBackground *bg = [[[LFPaperBackground alloc] initWithFrame:tv.bounds] autorelease]; bg.contentMode = UIViewContentModeRedraw; tv.backgroundView = bg; tv.backgroundColor = [UIColor clearColor]; tv.separatorStyle = UITableViewCellSeparatorStyleNone;
}
void LFPaperCell(UITableViewCell *c) {
    if ([c.backgroundView isKindOfClass:[LFPaperRow class]]) return;
    c.backgroundView = [[[LFPaperRow alloc] initWithFrame:CGRectMake(0, 0, 320, RULE_H)] autorelease];
    LFPaperRow *sel = [[[LFPaperRow alloc] initWithFrame:CGRectMake(0, 0, 320, RULE_H)] autorelease]; sel.selected = YES; c.selectedBackgroundView = sel;
    c.backgroundColor = [UIColor clearColor]; c.textLabel.backgroundColor = [UIColor clearColor]; c.detailTextLabel.backgroundColor = [UIColor clearColor];
}
UIView *LFPaperHeader(CGFloat width, CGFloat height, NSString *text) {
    LFPaperRow *v = [[[LFPaperRow alloc] initWithFrame:CGRectMake(0, 0, width, height)] autorelease]; v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(12, 6, width - 24, height - 10)] autorelease]; l.text = text; l.font = [UIFont boldSystemFontOfSize:16]; l.numberOfLines = 0; l.lineBreakMode = UILineBreakModeWordWrap;
    l.textColor = [UIColor colorWithRed:0.30 green:0.20 blue:0.50 alpha:1]; l.shadowColor = [UIColor colorWithWhite:1 alpha:0.8]; l.shadowOffset = CGSizeMake(0, 1); l.backgroundColor = [UIColor clearColor]; l.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [v addSubview:l]; return v;
}
