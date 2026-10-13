#import "LFProgressViewController.h"
#import "LFStore.h"
#import <QuartzCore/QuartzCore.h>

static NSString *unitS(void) { return [LFStore useKg] ? @"kg" : @"lb"; }
static UIColor *green(void) { return [UIColor colorWithRed:0x4D/255.0 green:0x7C/255.0 blue:0x0F/255.0 alpha:1]; }
static NSString *fmtNum(double v) {
    if (fabs(v) >= 100000) return [NSString stringWithFormat:@"%.0fk", v / 1000];
    if (fabs(v) >= 10000) return [NSString stringWithFormat:@"%.1fk", v / 1000];
    return v == floor(v) ? [NSString stringWithFormat:@"%.0f", v] : [NSString stringWithFormat:@"%.1f", v];
}
static NSString *fmtGrouped(double v) {   // 12,400
    NSNumberFormatter *f = [[[NSNumberFormatter alloc] init] autorelease]; [f setNumberStyle:NSNumberFormatterDecimalStyle]; [f setMaximumFractionDigits:0];
    return [f stringFromNumber:[NSNumber numberWithDouble:v]];
}
static NSString *fmtDay(double t) { NSDateFormatter *f = [[[NSDateFormatter alloc] init] autorelease]; [f setDateFormat:@"MMM d"]; return [f stringFromDate:[NSDate dateWithTimeIntervalSince1970:t]]; }
static NSString *fmtSigned(double d) { return d == 0 ? @"±0" : [NSString stringWithFormat:@"%@%@", d > 0 ? @"+" : @"−", fmtNum(fabs(d))]; }

#define CHART_H 170

@implementation LFChartView
- (id)initWithFrame:(CGRect)f { if ((self = [super initWithFrame:f])) { self.backgroundColor = [UIColor whiteColor]; self.contentMode = UIViewContentModeRedraw; } return self; }
- (void)dealloc { [xs release]; [ys release]; [unitStr release]; [super dealloc]; }
- (void)setXs:(NSArray *)x ys:(NSArray *)y bars:(BOOL)b unit:(NSString *)u { [xs release]; xs = [x retain]; [ys release]; ys = [y retain]; bars = b; [unitStr release]; unitStr = [u retain]; [self setNeedsDisplay]; }
- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect b = self.bounds;
    NSUInteger n = [ys count];
    if (n < (bars ? 1 : 2)) {
        [[UIColor colorWithWhite:0.6 alpha:1] set];
        [(n == 1 ? @"One entry so far. Log another to see a line." : @"Not enough data yet.") drawInRect:CGRectMake(10, b.size.height / 2 - 10, b.size.width - 20, 20) withFont:[UIFont systemFontOfSize:14] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
        return;
    }
    CGFloat L = 44, R = 12, T = 18, B = 20;
    CGRect plot = CGRectMake(L, T, b.size.width - L - R, b.size.height - T - B);
    double ymin = 1e300, ymax = -1e300;
    for (NSNumber *v in ys) { double d = [v doubleValue]; if (d < ymin) ymin = d; if (d > ymax) ymax = d; }
    if (bars) ymin = 0;
    if (ymax - ymin < 1e-9) { ymin -= 1; ymax += 1; }
    double pad = (ymax - ymin) * 0.1; if (!bars) ymin -= pad; ymax += pad;
    // gridlines + y labels
    UIFont *small = [UIFont systemFontOfSize:10];
    CGContextSetLineWidth(c, 1);
    for (int i = 0; i <= 2; i++) {
        double v = ymin + (ymax - ymin) * i / 2.0;
        CGFloat py = floorf(CGRectGetMaxY(plot) - (v - ymin) / (ymax - ymin) * plot.size.height) + 0.5;
        [[UIColor colorWithWhite:0.88 alpha:1] set];
        CGContextMoveToPoint(c, plot.origin.x, py); CGContextAddLineToPoint(c, CGRectGetMaxX(plot), py); CGContextStrokePath(c);
        [[UIColor colorWithWhite:0.5 alpha:1] set];
        [fmtNum(v) drawInRect:CGRectMake(0, py - 6, L - 6, 12) withFont:small lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
    }
    // x mapping
    double xmin = [[xs objectAtIndex:0] doubleValue], xmax = [[xs lastObject] doubleValue];
    if (bars || xmax - xmin < 1e-9) { xmin = 0; xmax = n - 1; }
    CGFloat (^px)(NSUInteger) = ^CGFloat(NSUInteger i) {
        if (bars) return plot.origin.x + plot.size.width * (i + 0.5) / n;
        double x = (xmax - xmin) > 0 ? [[xs objectAtIndex:i] doubleValue] : i;
        return plot.origin.x + (CGFloat)((x - xmin) / (xmax - xmin)) * plot.size.width;
    };
    CGFloat (^py)(NSUInteger) = ^CGFloat(NSUInteger i) { return CGRectGetMaxY(plot) - (CGFloat)(([[ys objectAtIndex:i] doubleValue] - ymin) / (ymax - ymin)) * plot.size.height; };
    if (bars) {
        CGFloat bw = floorf(plot.size.width / n * 0.62);
        for (NSUInteger i = 0; i < n; i++) {
            double v = [[ys objectAtIndex:i] doubleValue];
            CGFloat x = floorf(px(i) - bw / 2), top = py(i);
            if (v <= 0) { [[UIColor colorWithWhite:0.85 alpha:1] set]; CGContextFillRect(c, CGRectMake(x, CGRectGetMaxY(plot) - 2, bw, 2)); continue; }
            [(i == n - 1 ? green() : [UIColor colorWithRed:0x8A/255.0 green:0xB8/255.0 blue:0x3A/255.0 alpha:1]) set];
            CGContextFillRect(c, CGRectMake(x, top, bw, CGRectGetMaxY(plot) - top));
        }
    } else {
        // fill under the line
        CGContextSaveGState(c);
        CGContextMoveToPoint(c, px(0), CGRectGetMaxY(plot));
        for (NSUInteger i = 0; i < n; i++) CGContextAddLineToPoint(c, px(i), py(i));
        CGContextAddLineToPoint(c, px(n - 1), CGRectGetMaxY(plot)); CGContextClosePath(c);
        [[green() colorWithAlphaComponent:0.14] set]; CGContextFillPath(c);
        CGContextRestoreGState(c);
        // line
        [green() set]; CGContextSetLineWidth(c, 2); CGContextSetLineJoin(c, kCGLineJoinRound); CGContextSetLineCap(c, kCGLineCapRound);
        CGContextMoveToPoint(c, px(0), py(0));
        for (NSUInteger i = 1; i < n; i++) CGContextAddLineToPoint(c, px(i), py(i));
        CGContextStrokePath(c);
        if (n <= 40) for (NSUInteger i = 0; i < n; i++) {
            CGRect d = CGRectMake(px(i) - 3, py(i) - 3, 6, 6);
            [[UIColor whiteColor] set]; CGContextFillEllipseInRect(c, d);
            [green() set]; CGContextSetLineWidth(c, 1.5); CGContextStrokeEllipseInRect(c, d);
        }
    }
    // last value callout, top right above the plot so it never sits on the data
    NSString *last = [NSString stringWithFormat:@"%@ %@", bars ? @"this week" : @"latest", fmtNum([[ys lastObject] doubleValue])];
    last = [NSString stringWithFormat:@"%@ %@", last, unitStr ?: @""];
    [green() set];
    [last drawInRect:CGRectMake(plot.origin.x, 3, plot.size.width, 13) withFont:[UIFont boldSystemFontOfSize:11] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
    // x labels: first and last
    [[UIColor colorWithWhite:0.5 alpha:1] set];
    double t0 = [[xs objectAtIndex:0] doubleValue], t1 = [[xs lastObject] doubleValue];
    [fmtDay(t0) drawInRect:CGRectMake(plot.origin.x, CGRectGetMaxY(plot) + 5, plot.size.width / 2, 12) withFont:small lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
    [(bars ? @"this week" : fmtDay(t1)) drawInRect:CGRectMake(CGRectGetMidX(plot), CGRectGetMaxY(plot) + 5, plot.size.width / 2, 12) withFont:small lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
}
@end

static UITableViewCell *chartCell(UITableView *tv, LFChartView **chart) {
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
    c.selectionStyle = UITableViewCellSelectionStyleNone;
    if (!*chart) *chart = [[LFChartView alloc] initWithFrame:CGRectMake(0, 0, 300, CHART_H)];
    (*chart).frame = CGRectMake(0, 0, c.contentView.bounds.size.width, CHART_H); (*chart).autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [c.contentView addSubview:*chart];
    return c;
}
static UITableViewCell *valueCell(UITableView *tv, NSString *t, NSString *d) {
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease];
    c.textLabel.text = t; c.detailTextLabel.text = d; c.selectionStyle = UITableViewCellSelectionStyleNone; return c;
}

@implementation LFProgressViewController
- (id)init { if ((self = [super initWithStyle:UITableViewStyleGrouped])) { self.title = @"Progress"; self.tabBarItem.title = @"Progress"; } return self; }
- (void)dealloc { [weights release]; [weekly release]; [exerciseIds release]; [weightChart release]; [volumeChart release]; [super dealloc]; }
- (void)viewWillAppear:(BOOL)a {
    [super viewWillAppear:a];
    [weights release]; weights = [[LFStore bodyWeights] retain];
    [weekly release]; weekly = [[LFStore weeklyVolume:10] retain];
    [exerciseIds release]; exerciseIds = [[LFStore exerciseIdsInHistory] retain];
    NSMutableArray *xs = [NSMutableArray array], *ys = [NSMutableArray array];
    for (NSDictionary *e in weights) { [xs addObject:[e objectForKey:@"t"]]; [ys addObject:[e objectForKey:@"w"]]; }
    if (!weightChart) weightChart = [[LFChartView alloc] initWithFrame:CGRectMake(0, 0, 300, CHART_H)];
    [weightChart setXs:xs ys:ys bars:NO unit:unitS()];
    xs = [NSMutableArray array]; ys = [NSMutableArray array];
    for (NSDictionary *e in weekly) { [xs addObject:[e objectForKey:@"t"]]; [ys addObject:[e objectForKey:@"volume"]]; }
    if (!volumeChart) volumeChart = [[LFChartView alloc] initWithFrame:CGRectMake(0, 0, 300, CHART_H)];
    [volumeChart setXs:xs ys:ys bars:YES unit:unitS()];
    [self.tableView reloadData];
}
- (void)viewDidAppear:(BOOL)a {
    [super viewDidAppear:a];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];   // test hooks driven from the Mac
    if ([d objectForKey:@"lf_scroll"]) { [self.tableView setContentOffset:CGPointMake(0, [d floatForKey:@"lf_scroll"]) animated:NO]; [d removeObjectForKey:@"lf_scroll"]; [d synchronize]; }
    NSString *o = [d stringForKey:@"lf_open"];
    if (o) { [d removeObjectForKey:@"lf_open"]; [d synchronize];
        if ([o isEqualToString:@"bw"]) { [d setBool:YES forKey:@"lf_test_bw"]; [d synchronize]; [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]]; }
        else if ([o isEqualToString:@"ex"] && [exerciseIds count]) [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    }
}
- (NSString *)weightSummary {
    if (![weights count]) return @"Not logged yet";
    NSDictionary *last = [weights lastObject]; double lw = [[last objectForKey:@"w"] doubleValue], lt = [[last objectForKey:@"t"] doubleValue];
    NSDictionary *ref = nil;
    for (NSDictionary *e in weights) { if (lt - [[e objectForKey:@"t"] doubleValue] >= 25 * 86400.0) ref = e; else break; }
    NSString *s = [NSString stringWithFormat:@"%@ %@", fmtNum(lw), unitS()];
    if (ref) return [NSString stringWithFormat:@"%@ · %@ in 30 days", s, fmtSigned(lw - [[ref objectForKey:@"w"] doubleValue])];
    if ([weights count] > 1) return [NSString stringWithFormat:@"%@ · %@ since %@", s, fmtSigned(lw - [[[weights objectAtIndex:0] objectForKey:@"w"] doubleValue]), fmtDay([[[weights objectAtIndex:0] objectForKey:@"t"] doubleValue])];
    return s;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 3; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return s == 0 ? 2 : s == 1 ? 4 : MAX(1, (NSInteger)[exerciseIds count]); }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return s == 0 ? @"Body Weight" : s == 1 ? @"Volume per Week" : @"Exercises"; }
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s { return s == 2 && [exerciseIds count] ? @"Estimated one-rep max from your best set each workout, and how it has moved since your first." : nil; }
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip { return ip.row == 0 && ip.section < 2 ? CHART_H : 44; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section == 0) {
        if (ip.row == 0) return chartCell(tv, &weightChart);
        UITableViewCell *c = valueCell(tv, @"Log Weight", [self weightSummary]); c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.selectionStyle = UITableViewCellSelectionStyleBlue;
        c.detailTextLabel.font = [UIFont systemFontOfSize:13]; c.detailTextLabel.adjustsFontSizeToFitWidth = YES; c.detailTextLabel.minimumFontSize = 10; return c;
    }
    if (ip.section == 1) {
        if (ip.row == 0) return chartCell(tv, &volumeChart);
        NSDictionary *tw = [weekly lastObject]; int n = [[tw objectForKey:@"count"] intValue];
        if (ip.row == 1) return valueCell(tv, @"This Week", n ? [NSString stringWithFormat:@"%d workout%@ · %@ %@", n, n == 1 ? @"" : @"s", fmtGrouped([[tw objectForKey:@"volume"] doubleValue]), unitS()] : @"Nothing yet");
        if (ip.row == 2) { NSInteger st = [LFStore weekStreak]; return valueCell(tv, @"Streak", [NSString stringWithFormat:@"%ld week%@", (long)st, st == 1 ? @"" : @"s"]); }
        NSUInteger all = [[LFStore workouts] count]; return valueCell(tv, @"All Time", [NSString stringWithFormat:@"%lu workout%@", (unsigned long)all, all == 1 ? @"" : @"s"]);
    }
    if (![exerciseIds count]) { UITableViewCell *c = valueCell(tv, @"Finish a workout to see progress here.", nil); c.textLabel.font = [UIFont systemFontOfSize:14]; c.textLabel.textColor = [UIColor grayColor]; return c; }
    NSString *eid = [exerciseIds objectAtIndex:ip.row];
    NSArray *p = [LFStore exerciseProgress:eid];
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"ex"];
    if (!c) { c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ex"] autorelease]; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1]; }
    c.textLabel.text = [[LFStore exercise:eid] objectForKey:@"name"];
    double first = [[[p objectAtIndex:0] objectForKey:@"e1rm"] doubleValue], last = [[[p lastObject] objectForKey:@"e1rm"] doubleValue];
    c.detailTextLabel.text = [p count] > 1 ? [NSString stringWithFormat:@"%lu sessions · est. 1RM %@ %@ (%@)", (unsigned long)[p count], fmtNum(last), unitS(), fmtSigned(last - first)]
                                           : [NSString stringWithFormat:@"1 session · est. 1RM %@ %@", fmtNum(last), unitS()];
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section == 0 && ip.row == 1) { LFBodyWeightViewController *b = [[LFBodyWeightViewController alloc] init]; [self.navigationController pushViewController:b animated:YES]; [b release]; }
    else if (ip.section == 2 && [exerciseIds count]) { LFExerciseProgressViewController *e = [[LFExerciseProgressViewController alloc] initWithExercise:[exerciseIds objectAtIndex:ip.row]]; [self.navigationController pushViewController:e animated:YES]; [e release]; }
}
@end

#define BW_STEP 0.5
static int bwRows(void) { return [LFStore useKg] ? 501 : 1001; }   // 0..250 kg or 0..500 lb in halves

@implementation LFBodyWeightViewController
- (id)init { if ((self = [super initWithStyle:UITableViewStylePlain])) { self.title = @"Body Weight"; self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Log" style:UIBarButtonItemStyleDone target:self action:@selector(openDrum)] autorelease]; } return self; }
- (void)dealloc { [entries release]; [drum release]; [picker release]; [super dealloc]; }
- (void)reload { [entries release]; entries = [[[[LFStore bodyWeights] reverseObjectEnumerator] allObjects] retain]; [self.tableView reloadData]; }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self reload]; }
- (void)viewDidAppear:(BOOL)a {
    [super viewDidAppear:a];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d boolForKey:@"lf_test_bw"]) { [d removeObjectForKey:@"lf_test_bw"]; [d synchronize]; [self performSelector:@selector(openDrum) withObject:nil afterDelay:0.4]; }
    else if (![entries count]) [self performSelector:@selector(openDrum) withObject:nil afterDelay:0.3];
}
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [self closeDrum]; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return [entries count]; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"bw"];
    if (!c) { c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"bw"] autorelease]; c.selectionStyle = UITableViewCellSelectionStyleNone; c.detailTextLabel.textColor = [UIColor blackColor]; c.detailTextLabel.font = [UIFont boldSystemFontOfSize:17]; }
    NSDictionary *e = [entries objectAtIndex:ip.row];
    NSDateFormatter *f = [[[NSDateFormatter alloc] init] autorelease]; [f setDateFormat:@"EEEE, MMM d"];
    c.textLabel.text = [f stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[e objectForKey:@"t"] doubleValue]]];
    double w = [[e objectForKey:@"w"] doubleValue], prev = ip.row + 1 < (NSInteger)[entries count] ? [[[entries objectAtIndex:ip.row + 1] objectForKey:@"w"] doubleValue] : w;
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", fmtNum(w), unitS()];
    c.textLabel.font = [UIFont systemFontOfSize:15];
    c.detailTextLabel.text = w == prev || ip.row + 1 >= (NSInteger)[entries count] ? c.detailTextLabel.text : [NSString stringWithFormat:@"%@   %@", fmtSigned(w - prev), c.detailTextLabel.text];
    return c;
}
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)st forRowAtIndexPath:(NSIndexPath *)ip {
    if (st != UITableViewCellEditingStyleDelete) return;
    [LFStore deleteBodyWeightAt:[entries count] - 1 - ip.row]; [self reload];
}
#pragma mark drum
- (void)openDrum {
    UIView *host = self.tabBarController.view ?: self.navigationController.view;
    CGRect b = host.bounds;
    if (!drum) {
        drum = [[UIView alloc] initWithFrame:CGRectMake(0, b.size.height, b.size.width, 260)];
        drum.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        UIToolbar *bar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, b.size.width, 44)] autorelease]; bar.barStyle = UIBarStyleBlack; bar.translucent = NO;
        NSDateFormatter *f = [[[NSDateFormatter alloc] init] autorelease]; [f setDateFormat:@"'Today,' MMM d"];
        UILabel *t = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 44)] autorelease]; t.text = [f stringFromDate:[NSDate date]]; t.font = [UIFont boldSystemFontOfSize:14]; t.textColor = [UIColor whiteColor]; t.backgroundColor = [UIColor clearColor]; t.textAlignment = UITextAlignmentCenter;
        UIBarButtonItem *flex = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
        bar.items = [NSArray arrayWithObjects:[[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(closeDrum)] autorelease], flex, [[[UIBarButtonItem alloc] initWithCustomView:t] autorelease], flex, [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)] autorelease], nil];
        [drum addSubview:bar];
        picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 44, b.size.width, 216)];
        picker.dataSource = self; picker.delegate = self; picker.showsSelectionIndicator = YES; picker.autoresizingMask = UIViewAutoresizingFlexibleWidth; picker.backgroundColor = [UIColor blackColor];
        [drum addSubview:picker];
    }
    [drum removeFromSuperview]; [host addSubview:drum];
    [picker reloadAllComponents];
    double start = [entries count] ? [[[entries objectAtIndex:0] objectForKey:@"w"] doubleValue] : ([LFStore useKg] ? 70 : 150);
    [picker selectRow:MIN(bwRows() - 1, MAX(0, (int)floor(start / BW_STEP + 0.5))) inComponent:0 animated:NO];
    drum.frame = CGRectMake(0, b.size.height, b.size.width, 260);
    [UIView beginAnimations:nil context:NULL]; [UIView setAnimationDuration:0.3];
    drum.frame = CGRectMake(0, b.size.height - 260, b.size.width, 260);
    [UIView commitAnimations];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 260 - 49, 0);
}
- (void)closeDrum {
    if (!drum || !drum.superview) return;
    CGRect b = drum.superview.bounds;
    [UIView beginAnimations:nil context:NULL]; [UIView setAnimationDuration:0.3];
    drum.frame = CGRectMake(0, b.size.height, b.size.width, 260);
    [UIView commitAnimations];
    self.tableView.contentInset = UIEdgeInsetsZero;
}
- (void)save { [LFStore logBodyWeight:[picker selectedRowInComponent:0] * BW_STEP]; [self closeDrum]; [self reload]; }
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pv { return 1; }
- (NSInteger)pickerView:(UIPickerView *)pv numberOfRowsInComponent:(NSInteger)c { return bwRows(); }
- (NSString *)pickerView:(UIPickerView *)pv titleForRow:(NSInteger)row forComponent:(NSInteger)c { return [NSString stringWithFormat:@"%@ %@", fmtNum(row * BW_STEP), unitS()]; }
- (CGFloat)pickerView:(UIPickerView *)pv widthForComponent:(NSInteger)c { return 200; }
@end

@implementation LFExerciseProgressViewController
- (id)initWithExercise:(NSString *)e { if ((self = [super initWithStyle:UITableViewStyleGrouped])) { eid = [e copy]; self.title = [[LFStore exercise:e] objectForKey:@"name"]; } return self; }
- (void)dealloc { [eid release]; [sessions release]; [mode release]; [chart release]; [super dealloc]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    mode = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Est. 1RM", @"Top Weight", @"Volume", nil]];
    mode.segmentedControlStyle = UISegmentedControlStyleBar; mode.selectedSegmentIndex = 0; mode.tintColor = [UIColor colorWithWhite:0.35 alpha:1];
    [mode addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    UIView *hdr = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
    mode.frame = CGRectMake(10, 10, 300, 30); mode.autoresizingMask = UIViewAutoresizingFlexibleWidth; [hdr addSubview:mode];
    self.tableView.tableHeaderView = hdr;
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [sessions release]; sessions = [[LFStore exerciseProgress:eid] retain]; [self refresh]; }
- (NSString *)key { NSArray *k = [NSArray arrayWithObjects:@"e1rm", @"weight", @"volume", nil]; return [k objectAtIndex:MAX(0, mode.selectedSegmentIndex)]; }
- (void)refresh {
    NSMutableArray *xs = [NSMutableArray array], *ys = [NSMutableArray array];
    for (NSDictionary *s in sessions) { [xs addObject:[s objectForKey:@"t"]]; [ys addObject:[s objectForKey:[self key]]]; }
    if (!chart) chart = [[LFChartView alloc] initWithFrame:CGRectMake(0, 0, 300, CHART_H)];
    [chart setXs:xs ys:ys bars:NO unit:unitS()];
    [self.tableView reloadData];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return s == 0 ? 1 : [sessions count]; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return s == 1 ? @"Sessions" : nil; }
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    if (s != 0 || ![sessions count]) return nil;
    double best = 0; for (NSDictionary *x in sessions) best = MAX(best, [[x objectForKey:[self key]] doubleValue]);
    NSArray *names = [NSArray arrayWithObjects:@"Best estimated one-rep max", @"Heaviest set", @"Biggest session", nil];
    return [NSString stringWithFormat:@"%@: %@ %@", [names objectAtIndex:mode.selectedSegmentIndex], fmtGrouped(best), unitS()];
}
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip { return ip.section == 0 ? CHART_H : 44; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section == 0) return chartCell(tv, &chart);
    NSDictionary *s = [sessions objectAtIndex:[sessions count] - 1 - ip.row];
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"s"];
    if (!c) { c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"s"] autorelease]; c.selectionStyle = UITableViewCellSelectionStyleNone; c.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1]; }
    c.textLabel.text = [NSString stringWithFormat:@"%g %@ × %d", [[s objectForKey:@"weight"] doubleValue], unitS(), [[s objectForKey:@"reps"] intValue]];
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@ · %d sets · est. 1RM %@", fmtDay([[s objectForKey:@"t"] doubleValue]), [s objectForKey:@"workout"], [[s objectForKey:@"sets"] intValue], fmtNum([[s objectForKey:@"e1rm"] doubleValue])];
    return c;
}
@end
