#import "LFSkin.h"
#import <QuartzCore/QuartzCore.h>
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
// One rendered sheet per row size, shared by every row, header and background of that size. Views that implement
// drawRect: each get their own bitmap (a 320x44 row is 220 KB at 2x), and the Workout tab rebuilds its rows on every tap;
// with a handful of shared images the paper costs nothing per cell.
static UIImage *paperImage(CGSize sz, BOOL selected) {
    if (sz.width < 1 || sz.height < 1) return nil;
    static NSMutableDictionary *cache = nil; if (!cache) cache = [[NSMutableDictionary alloc] init];
    NSString *k = [NSString stringWithFormat:@"%gx%g%@", sz.width, sz.height, selected ? @"s" : @""];
    UIImage *img = [cache objectForKey:k]; if (img) return img;
    UIGraphicsBeginImageContextWithOptions(sz, YES, 0); CGContextRef c = UIGraphicsGetCurrentContext();
    drawPaper(c, CGRectMake(0, 0, sz.width, sz.height), YES);
    if (selected) { [[UIColor colorWithWhite:0 alpha:0.06] set]; CGContextFillRect(c, CGRectMake(0, 0, sz.width, sz.height)); }
    img = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext();
    if (img) [cache setObject:img forKey:k];
    return img;
}
// The sheet behind the rows: the row image stacked down the table in sublayers, so the rules line up with the rows.
@interface LFPaperBackground : UIView @end
@implementation LFPaperBackground
- (void)layoutSubviews {
    [super layoutSubviews];
    UITableView *tv = (UITableView *)self.superview; CGFloat h = [tv isKindOfClass:[UITableView class]] && tv.rowHeight >= 30 ? tv.rowHeight : RULE_H;
    CGSize sz = self.bounds.size; UIImage *img = paperImage(CGSizeMake(sz.width, h), NO);
    NSUInteger n = img ? (NSUInteger)ceilf(sz.height / h) : 0;
    NSArray *have = [NSArray arrayWithArray:self.layer.sublayers ?: [NSArray array]];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (NSUInteger i = 0; i < MAX(n, [have count]); i++) {
        if (i >= n) { [[have objectAtIndex:i] removeFromSuperlayer]; continue; }
        CALayer *l = i < [have count] ? [have objectAtIndex:i] : nil;
        if (!l) { l = [CALayer layer]; [self.layer addSublayer:l]; }
        l.frame = CGRectMake(0, i * h, sz.width, h); l.contents = (id)img.CGImage; l.contentsScale = img.scale;
    }
    [CATransaction commit];
}
@end
@interface LFPaperRow : UIView { BOOL selected; } @property (nonatomic, assign) BOOL selected; @end
@implementation LFPaperRow
@synthesize selected;
- (id)initWithFrame:(CGRect)f { if ((self = [super initWithFrame:f])) { self.opaque = YES; [self setNeedsLayout]; } return self; }
- (void)setSelected:(BOOL)s { selected = s; [self setNeedsLayout]; }
- (void)layoutSubviews { [super layoutSubviews]; UIImage *img = paperImage(self.bounds.size, selected); self.layer.contents = (id)img.CGImage; self.layer.contentsScale = img ? img.scale : 1; }
@end
void LFSkinPaperTable(UITableView *tv) {
    LFPaperBackground *bg = [[[LFPaperBackground alloc] initWithFrame:tv.bounds] autorelease]; tv.backgroundView = bg; tv.backgroundColor = [UIColor clearColor]; tv.separatorStyle = UITableViewCellSeparatorStyleNone;
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
UITableViewCell *LFPaperNoteCell(NSString *text) {
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease]; LFPaperCell(c); c.selectionStyle = UITableViewCellSelectionStyleNone;
    c.textLabel.text = text; c.textLabel.font = [UIFont italicSystemFontOfSize:13]; c.textLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1]; c.textLabel.numberOfLines = 2;
    c.textLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.8]; c.textLabel.shadowOffset = CGSizeMake(0, 1);
    return c;
}
void LFFitTitle(UIViewController *vc, NSString *title) {
    vc.title = title;
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)] autorelease]; l.text = title; l.backgroundColor = [UIColor clearColor];
    l.font = [UIFont boldSystemFontOfSize:20]; l.adjustsFontSizeToFitWidth = YES; l.minimumFontSize = 16; l.textAlignment = UITextAlignmentCenter;
    if ([title sizeWithFont:[UIFont boldSystemFontOfSize:16]].width > 176) { l.frame = CGRectMake(0, 0, 176, 44); l.font = [UIFont boldSystemFontOfSize:14]; l.numberOfLines = 2; l.lineBreakMode = UILineBreakModeWordWrap; l.adjustsFontSizeToFitWidth = NO; }   // long exercise names wrap onto two lines
    l.textColor = [UIColor whiteColor]; l.shadowColor = [UIColor colorWithWhite:0 alpha:0.5]; l.shadowOffset = CGSizeMake(0, -1);
    vc.navigationItem.titleView = l;
}
