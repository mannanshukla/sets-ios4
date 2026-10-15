#import "LFWorkoutViewController.h"
#import "LFStore.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

static NSString *fmtTime(NSTimeInterval t) { int s = (int)t; return s >= 3600 ? [NSString stringWithFormat:@"%d:%02d:%02d", s/3600, (s/60)%60, s%60] : [NSString stringWithFormat:@"%d:%02d", s/60, s%60]; }
static NSString *unit(void) { return [LFStore useKg] ? @"kg" : @"lb"; }
static double weightStep(void) { return [LFStore useKg] ? 1.0 : 2.5; }
#define WEIGHT_ROWS 241   /* 0 .. 600 lb in 2.5s, or 0 .. 240 kg in 1s */
#define REPS_ROWS 51

@implementation LFWorkoutViewController
+ (void)startFromRoutine:(NSDictionary *)routine {
    NSMutableArray *exs = [NSMutableArray array];
    for (NSDictionary *x in [routine objectForKey:@"exercises"]) {
        NSMutableArray *sets = [NSMutableArray array];
        NSDictionary *best = [LFStore bestSetFor:[x objectForKey:@"id"]];
        for (int i = 0; i < [[x objectForKey:@"sets"] intValue]; i++)
            [sets addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:best ? [[best objectForKey:@"weight"] doubleValue] : 0], @"weight", [NSNumber numberWithInt:0], @"reps", [NSNumber numberWithBool:NO], @"done", nil]];
        [exs addObject:[NSDictionary dictionaryWithObjectsAndKeys:[x objectForKey:@"id"], @"id", sets, @"sets", ([x objectForKey:@"reps"] ?: @""), @"target", nil]];
    }
    NSDictionary *w = [NSDictionary dictionaryWithObjectsAndKeys:[LFStore newId], @"id", ([routine objectForKey:@"name"] ?: @"Workout"), @"name", [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]], @"start", exs, @"exercises", nil];
    [LFStore saveActiveWorkout:w];
}
+ (void)startEmpty { [self startFromRoutine:[NSDictionary dictionaryWithObjectsAndKeys:@"Workout", @"name", [NSArray array], @"exercises", nil]]; }

- (id)init { if ((self = [super initWithStyle:UITableViewStyleGrouped])) { self.title = @"Workout"; self.tabBarItem.title = @"Workout"; } return self; }
- (void)dealloc { [tick invalidate]; [active release]; [exercises release]; [routines release]; [drum release]; [picker release]; [drumTitle release]; [super dealloc]; }
- (void)load {
    NSDictionary *a = [LFStore activeWorkout];
    [active release]; active = a ? [[NSMutableDictionary alloc] initWithDictionary:a] : nil;
    [exercises release]; exercises = a ? [[NSMutableArray alloc] initWithArray:[a objectForKey:@"exercises"]] : nil;
    [routines release]; routines = [[LFStore routines] retain];
    if (active) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStyleBordered target:self action:@selector(discard)] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Finish" style:UIBarButtonItemStyleDone target:self action:@selector(finish)] autorelease];
    } else {
        self.navigationItem.leftBarButtonItem = nil; self.navigationItem.rightBarButtonItem = nil; self.navigationItem.title = @"Workout";
    }
    [self.tableView reloadData];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self load]; if (!tick) tick = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(ticked) userInfo:nil repeats:YES] retain]; [self ticked]; }
- (void)viewDidAppear:(BOOL)a {
    [super viewDidAppear:a];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:@"lf_test_pick"] && active) { NSInteger t = [d integerForKey:@"lf_test_pick"]; [d removeObjectForKey:@"lf_test_pick"]; [d synchronize]; UIButton *b = [[[UIButton alloc] init] autorelease]; b.tag = t; [self performSelector:@selector(openDrum:) withObject:b afterDelay:0.4]; }
}
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [self closeDrum]; [tick invalidate]; [tick release]; tick = nil; }
- (void)ticked {
    if (!active) return;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (restEnds > now) self.navigationItem.title = [NSString stringWithFormat:@"Rest %@", fmtTime(restEnds - now)];
    else { if (restEnds > 0) { restEnds = 0; AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); AudioServicesPlaySystemSound(1007); } self.navigationItem.title = fmtTime(now - [[active objectForKey:@"start"] doubleValue]); }
}
- (void)persist { if (!active) return; [active setObject:exercises forKey:@"exercises"]; [LFStore saveActiveWorkout:active]; }

#pragma mark start / finish
- (void)startRest {
    restEnds = [[NSDate date] timeIntervalSince1970] + [LFStore restSeconds];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    UILocalNotification *n = [[UILocalNotification alloc] init];
    n.fireDate = [NSDate dateWithTimeIntervalSince1970:restEnds]; n.alertBody = @"Rest is over. Next set."; n.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:n]; [n release];
    [self ticked];
}
- (void)discard {
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard Workout" otherButtonTitles:nil]; as.tag = 1; [as showInView:self.view]; [as release];
}
- (void)finish {
    [self.view endEditing:YES]; [self closeDrum];
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Finish Workout", nil]; as.tag = 2; [as showInView:self.view]; [as release];
}
- (void)actionSheet:(UIActionSheet *)as clickedButtonAtIndex:(NSInteger)i {
    if (i == as.cancelButtonIndex) return;
    [[UIApplication sharedApplication] cancelAllLocalNotifications]; restEnds = 0;
    if (as.tag == 2) {
        [self persist];
        NSMutableDictionary *w = [NSMutableDictionary dictionaryWithDictionary:active];
        [w setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"end"];
        // drop sets never done, and exercises with none
        NSMutableArray *kept = [NSMutableArray array];
        for (NSDictionary *ex in exercises) { NSMutableArray *ds = [NSMutableArray array]; for (NSDictionary *s in [ex objectForKey:@"sets"]) if ([[s objectForKey:@"done"] boolValue]) [ds addObject:s]; if ([ds count]) { NSMutableDictionary *e2 = [NSMutableDictionary dictionaryWithDictionary:ex]; [e2 setObject:ds forKey:@"sets"]; [kept addObject:e2]; } }
        [w setObject:kept forKey:@"exercises"];
        if ([kept count]) { NSMutableArray *all = [NSMutableArray arrayWithArray:[LFStore workouts]]; [all insertObject:w atIndex:0]; [LFStore saveWorkouts:all]; }
        double vol = [LFStore volumeOf:w]; NSTimeInterval dur = [[w objectForKey:@"end"] doubleValue] - [[w objectForKey:@"start"] doubleValue];
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:[kept count] ? @"Nice work" : @"Nothing logged" message:[kept count] ? [NSString stringWithFormat:@"%@ · %lu exercises · %.0f %@ moved", fmtTime(dur), (unsigned long)[kept count], vol, unit()] : @"No completed sets, so this workout was not saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]; [a show]; [a release];
    }
    [LFStore saveActiveWorkout:nil]; [self load];
}
- (void)addExercise { LFExercisesViewController *p = [[LFExercisesViewController alloc] init]; p.picker = self; UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:p]; n.navigationBar.tintColor = self.navigationController.navigationBar.tintColor; [self presentModalViewController:n animated:YES]; [n release]; [p release]; }
- (void)exercisesPicker:(LFExercisesViewController *)p didPick:(NSDictionary *)e {
    NSDictionary *best = [LFStore bestSetFor:[e objectForKey:@"id"]];
    NSMutableArray *sets = [NSMutableArray array];
    for (int i = 0; i < 3; i++) [sets addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:best ? [[best objectForKey:@"weight"] doubleValue] : 0], @"weight", [NSNumber numberWithInt:0], @"reps", [NSNumber numberWithBool:NO], @"done", nil]];
    [exercises addObject:[NSDictionary dictionaryWithObjectsAndKeys:[e objectForKey:@"id"], @"id", sets, @"sets", @"", @"target", nil]];
    [self persist]; [self dismissModalViewControllerAnimated:YES]; [self.tableView reloadData];
}

#pragma mark set editing
- (NSMutableArray *)setsAt:(NSInteger)sec { return [NSMutableArray arrayWithArray:[[exercises objectAtIndex:sec] objectForKey:@"sets"]]; }
- (void)replaceSets:(NSArray *)sets at:(NSInteger)sec { NSMutableDictionary *e = [NSMutableDictionary dictionaryWithDictionary:[exercises objectAtIndex:sec]]; [e setObject:sets forKey:@"sets"]; [exercises replaceObjectAtIndex:sec withObject:e]; [self persist]; }
- (BOOL)textFieldShouldReturn:(UITextField *)tf { [tf resignFirstResponder]; return YES; }
- (void)toggleDone:(UIButton *)b {
    NSInteger sec = b.tag / 1000, row = b.tag % 1000;
    [self.view endEditing:YES]; [self closeDrum];
    NSMutableArray *sets = [self setsAt:sec]; if (row >= (NSInteger)[sets count]) return;
    NSMutableDictionary *s = [NSMutableDictionary dictionaryWithDictionary:[sets objectAtIndex:row]];
    BOOL done = ![[s objectForKey:@"done"] boolValue];
    [s setObject:[NSNumber numberWithBool:done] forKey:@"done"];
    [sets replaceObjectAtIndex:row withObject:s]; [self replaceSets:sets at:sec];
    if (done) [self startRest];
    [self.tableView reloadData];
}

#pragma mark drum picker
- (void)buildDrum {
    if (drum) return;
    UIView *host = self.tabBarController.view ?: self.view.superview;
    CGRect b = host.bounds;
    drum = [[UIView alloc] initWithFrame:CGRectMake(0, b.size.height, b.size.width, 260)];
    drum.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    UIToolbar *bar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, b.size.width, 44)] autorelease];
    bar.barStyle = UIBarStyleBlack; bar.translucent = NO; bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    drumTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
    drumTitle.font = [UIFont boldSystemFontOfSize:14]; drumTitle.adjustsFontSizeToFitWidth = YES; drumTitle.minimumFontSize = 10; drumTitle.textColor = [UIColor whiteColor]; drumTitle.backgroundColor = [UIColor clearColor]; drumTitle.textAlignment = UITextAlignmentCenter;
    UIBarButtonItem *title = [[[UIBarButtonItem alloc] initWithCustomView:drumTitle] autorelease];
    UIBarButtonItem *flex = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem *done = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeDrum)] autorelease];
    UIBarButtonItem *next = [[[UIBarButtonItem alloc] initWithTitle:@"Next Set" style:UIBarButtonItemStyleBordered target:self action:@selector(drumNext)] autorelease];
    bar.items = [NSArray arrayWithObjects:next, flex, title, flex, done, nil];
    [drum addSubview:bar];
    picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 44, b.size.width, 216)];
    picker.dataSource = self; picker.delegate = self; picker.showsSelectionIndicator = YES; picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [drum addSubview:picker];
    picker.backgroundColor = [UIColor blackColor];
    [host addSubview:drum];
}
- (NSDictionary *)pickedSet { if (pickSection >= (NSInteger)[exercises count]) return nil; NSArray *sets = [[exercises objectAtIndex:pickSection] objectForKey:@"sets"]; return pickRow < (NSInteger)[sets count] ? [sets objectAtIndex:pickRow] : nil; }
- (void)syncDrumToSet {
    NSDictionary *s = [self pickedSet]; if (!s) return;
    NSDictionary *e = [LFStore exercise:[[exercises objectAtIndex:pickSection] objectForKey:@"id"]];
    NSString *nm = [e objectForKey:@"name"] ?: @"";
    NSRange dash = [nm rangeOfString:@" - "]; if (dash.location != NSNotFound) nm = [nm substringToIndex:dash.location];
    drumTitle.text = [NSString stringWithFormat:@"Set %ld · %@", (long)pickRow + 1, nm];
    NSInteger wrow = (NSInteger)([[s objectForKey:@"weight"] doubleValue] / weightStep() + 0.5);
    [picker selectRow:MIN(WEIGHT_ROWS-1, MAX(0, wrow)) inComponent:0 animated:NO];
    [picker selectRow:MIN(REPS_ROWS-1, MAX(0, [[s objectForKey:@"reps"] intValue])) inComponent:1 animated:NO];
}
- (void)openDrum:(UIButton *)b {
    [self.view endEditing:YES];
    [self buildDrum];
    pickSection = b.tag / 1000; pickRow = b.tag % 1000;
    [self syncDrumToSet];
    CGRect b2 = drum.superview.bounds;
    CGFloat covered = 260 - (self.tabBarController ? self.tabBarController.tabBar.bounds.size.height : 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, covered, 0); self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pickRow inSection:pickSection] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [UIView beginAnimations:nil context:NULL]; [UIView setAnimationDuration:0.3]; [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    drum.frame = CGRectMake(0, b2.size.height - 260, b2.size.width, 260);
    [UIView commitAnimations];
}
- (void)closeDrum {
    if (!drum) return;
    CGRect b2 = drum.superview.bounds;
    [UIView beginAnimations:nil context:NULL]; [UIView setAnimationDuration:0.3]; [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    drum.frame = CGRectMake(0, b2.size.height, b2.size.width, 260);
    [UIView commitAnimations];
    self.tableView.contentInset = UIEdgeInsetsZero; self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}
- (void)drumNext {
    // move to the next set, adding one if this was the last
    NSMutableArray *sets = [self setsAt:pickSection];
    if (pickRow + 1 >= (NSInteger)[sets count]) {
        NSDictionary *last = [sets lastObject];
        [sets addObject:[NSDictionary dictionaryWithObjectsAndKeys:([last objectForKey:@"weight"] ?: [NSNumber numberWithInt:0]), @"weight", ([last objectForKey:@"reps"] ?: [NSNumber numberWithInt:0]), @"reps", [NSNumber numberWithBool:NO], @"done", nil]];
        [self replaceSets:sets at:pickSection]; [self.tableView reloadData];
    }
    pickRow++;
    [self syncDrumToSet];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pickRow inSection:pickSection] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pv { return 2; }
- (NSInteger)pickerView:(UIPickerView *)pv numberOfRowsInComponent:(NSInteger)c { return c == 0 ? WEIGHT_ROWS : REPS_ROWS; }
- (NSString *)pickerView:(UIPickerView *)pv titleForRow:(NSInteger)row forComponent:(NSInteger)c {
    return c == 0 ? [NSString stringWithFormat:@"%g %@", row * weightStep(), unit()] : [NSString stringWithFormat:@"%ld reps", (long)row];
}
- (CGFloat)pickerView:(UIPickerView *)pv widthForComponent:(NSInteger)c { return c == 0 ? 170 : 120; }
- (void)pickerView:(UIPickerView *)pv didSelectRow:(NSInteger)row inComponent:(NSInteger)c {
    NSMutableArray *sets = [self setsAt:pickSection]; if (pickRow >= (NSInteger)[sets count]) return;
    NSMutableDictionary *s = [NSMutableDictionary dictionaryWithDictionary:[sets objectAtIndex:pickRow]];
    if (c == 0) [s setObject:[NSNumber numberWithDouble:row * weightStep()] forKey:@"weight"]; else [s setObject:[NSNumber numberWithInt:(int)row] forKey:@"reps"];
    [sets replaceObjectAtIndex:pickRow withObject:s]; [self replaceSets:sets at:pickSection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:pickRow inSection:pickSection]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return active ? [exercises count] + 1 : 2; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    if (!active) return s == 0 ? 1 : [routines count];
    return s < (NSInteger)[exercises count] ? [[[exercises objectAtIndex:s] objectForKey:@"sets"] count] + 1 : 1;
}
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    if (!active) return s == 1 ? ([routines count] ? @"Start from a routine" : nil) : nil;
    if (s >= (NSInteger)[exercises count]) return nil;
    NSDictionary *ex = [exercises objectAtIndex:s]; NSDictionary *e = [LFStore exercise:[ex objectForKey:@"id"]];
    NSString *t = [ex objectForKey:@"target"];
    return [t length] ? [NSString stringWithFormat:@"%@  (%@ reps)", [e objectForKey:@"name"], t] : [e objectForKey:@"name"];
}
- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s {
    NSString *t = [self tableView:tv titleForHeaderInSection:s]; if (![t length]) return 10;
    CGSize sz = [t sizeWithFont:[UIFont boldSystemFontOfSize:16] constrainedToSize:CGSizeMake(tv.bounds.size.width - 40, 60) lineBreakMode:UILineBreakModeWordWrap];
    return sz.height + 18;
}
- (UIView *)tableView:(UITableView *)tv viewForHeaderInSection:(NSInteger)s {
    NSString *t = [self tableView:tv titleForHeaderInSection:s]; if (![t length]) return nil;
    CGFloat h = [self tableView:tv heightForHeaderInSection:s];
    UIView *v = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, h)] autorelease];
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(20, 8, tv.bounds.size.width - 40, h - 12)] autorelease];
    l.text = t; l.font = [UIFont boldSystemFontOfSize:16]; l.numberOfLines = 0; l.lineBreakMode = UILineBreakModeWordWrap;
    l.textColor = [UIColor colorWithRed:0.30 green:0.34 blue:0.42 alpha:1]; l.shadowColor = [UIColor whiteColor]; l.shadowOffset = CGSizeMake(0, 1); l.backgroundColor = [UIColor clearColor];
    l.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [v addSubview:l];
    return v;
}
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    if (!active && s == 1 && ![routines count]) return @"Make a routine in the Routines tab, or let OpenRelay write one.";
    if (active && s == (NSInteger)[exercises count]) return @"Tap the circle when a set is done. The rest timer starts on its own.";
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil] autorelease];
    UIColor *olive = [UIColor colorWithRed:0x5B/255.0 green:0x3F/255.0 blue:0xA6/255.0 alpha:1];
    if (!active) {
        if (ip.section == 0) { c.textLabel.text = @"Start Empty Workout"; c.textLabel.textAlignment = UITextAlignmentCenter; c.textLabel.textColor = olive; c.textLabel.font = [UIFont boldSystemFontOfSize:17]; }
        else { NSDictionary *r = [routines objectAtIndex:ip.row]; c.textLabel.text = [r objectForKey:@"name"]; c.detailTextLabel.text = [NSString stringWithFormat:@"%lu exercises", (unsigned long)[[r objectForKey:@"exercises"] count]]; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; }
        return c;
    }
    if (ip.section == (NSInteger)[exercises count]) { c.textLabel.text = @"Add Exercise..."; c.textLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1]; return c; }
    NSArray *sets = [[exercises objectAtIndex:ip.section] objectForKey:@"sets"];
    if (ip.row == (NSInteger)[sets count]) { c.textLabel.text = @"Add Set"; c.textLabel.font = [UIFont systemFontOfSize:15]; c.textLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1]; return c; }
    NSDictionary *s = [sets objectAtIndex:ip.row]; BOOL done = [[s objectForKey:@"done"] boolValue];
    c.selectionStyle = UITableViewCellSelectionStyleNone;
    c.textLabel.text = [NSString stringWithFormat:@"Set %ld", (long)ip.row + 1]; c.textLabel.font = [UIFont boldSystemFontOfSize:15]; c.textLabel.textColor = done ? olive : [UIColor blackColor];
    CGFloat w = c.contentView.bounds.size.width;
    // tappable values that open the drum picker
    UIButton *wt = [UIButton buttonWithType:UIButtonTypeCustom]; wt.frame = CGRectMake(w - 190, 7, 66, 30);
    UIButton *rp = [UIButton buttonWithType:UIButtonTypeCustom]; rp.frame = CGRectMake(w - 118, 7, 54, 30);
    double wv = [[s objectForKey:@"weight"] doubleValue]; int rv = [[s objectForKey:@"reps"] intValue];
    [wt setTitle:(wv > 0 ? [NSString stringWithFormat:@"%g", wv] : unit()) forState:UIControlStateNormal];
    [rp setTitle:(rv > 0 ? [NSString stringWithFormat:@"%d", rv] : @"reps") forState:UIControlStateNormal];
    for (UIButton *b in [NSArray arrayWithObjects:wt, rp, nil]) {
        BOOL placeholder = (b == wt) ? wv <= 0 : rv <= 0;
        b.titleLabel.font = [UIFont systemFontOfSize:16];
        [b setTitleColor:(placeholder ? [UIColor colorWithWhite:0.6 alpha:1] : [UIColor blackColor]) forState:UIControlStateNormal];
        b.backgroundColor = done ? [UIColor colorWithWhite:0.96 alpha:1] : [UIColor whiteColor];
        b.layer.cornerRadius = 6; b.layer.borderWidth = 1; b.layer.borderColor = [UIColor colorWithWhite:0.72 alpha:1].CGColor;
        b.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin; b.alpha = done ? 0.6 : 1; b.enabled = !done;
        b.tag = ip.section*1000 + ip.row;
        [b addTarget:self action:@selector(openDrum:) forControlEvents:UIControlEventTouchUpInside];
        [c.contentView addSubview:b];
    }
    UIButton *chk = [UIButton buttonWithType:UIButtonTypeCustom];
    chk.frame = CGRectMake(w - 52, 4, 44, 36); chk.tag = ip.section*1000 + ip.row; chk.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [chk setTitle:done ? @"✓" : @"○" forState:UIControlStateNormal]; chk.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [chk setTitleColor:done ? olive : [UIColor colorWithWhite:0.6 alpha:1] forState:UIControlStateNormal];
    [chk addTarget:self action:@selector(toggleDone:) forControlEvents:UIControlEventTouchUpInside];
    [c.contentView addSubview:chk];
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (!active) {
        if (ip.section == 0) [LFWorkoutViewController startEmpty]; else [LFWorkoutViewController startFromRoutine:[routines objectAtIndex:ip.row]];
        [self load]; return;
    }
    if (ip.section == (NSInteger)[exercises count]) { [self addExercise]; return; }
    NSMutableArray *sets = [self setsAt:ip.section];
    if (ip.row == (NSInteger)[sets count]) {
        NSDictionary *last = [sets lastObject];
        [sets addObject:[NSDictionary dictionaryWithObjectsAndKeys:([last objectForKey:@"weight"] ?: [NSNumber numberWithInt:0]), @"weight", ([last objectForKey:@"reps"] ?: [NSNumber numberWithInt:0]), @"reps", [NSNumber numberWithBool:NO], @"done", nil]];
        [self replaceSets:sets at:ip.section]; [tv reloadData];
    }
}
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return active && ip.section < (NSInteger)[exercises count] && ip.row < (NSInteger)[[[exercises objectAtIndex:ip.section] objectForKey:@"sets"] count]; }
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)st forRowAtIndexPath:(NSIndexPath *)ip {
    if (st != UITableViewCellEditingStyleDelete) return;
    NSMutableArray *sets = [self setsAt:ip.section]; [sets removeObjectAtIndex:ip.row];
    if ([sets count]) [self replaceSets:sets at:ip.section]; else { [exercises removeObjectAtIndex:ip.section]; [self persist]; }
    [tv reloadData];
}
@end

@implementation LFHistoryViewController
- (id)init { if ((self = [super initWithStyle:UITableViewStylePlain])) { self.title = @"History"; self.tabBarItem.title = @"History"; } return self; }
- (void)dealloc { [workouts release]; [super dealloc]; }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [workouts release]; workouts = [[LFStore workouts] retain]; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return [workouts count]; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"h"];
    if (!c) { c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"h"] autorelease]; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1]; }
    NSDictionary *w = [workouts objectAtIndex:ip.row];
    NSDateFormatter *f = [[[NSDateFormatter alloc] init] autorelease]; [f setDateFormat:@"EEE, MMM d  h:mm a"];
    c.textLabel.text = [NSString stringWithFormat:@"%@", [w objectForKey:@"name"]];
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@ · %.0f %@", [f stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[w objectForKey:@"start"] doubleValue]]], fmtTime([[w objectForKey:@"end"] doubleValue] - [[w objectForKey:@"start"] doubleValue]), [LFStore volumeOf:w], unit()];
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip { LFWorkoutDetailViewController *d = [[LFWorkoutDetailViewController alloc] initWithWorkout:[workouts objectAtIndex:ip.row]]; [self.navigationController pushViewController:d animated:YES]; [d release]; }
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)st forRowAtIndexPath:(NSIndexPath *)ip {
    if (st != UITableViewCellEditingStyleDelete) return;
    NSMutableArray *all = [NSMutableArray arrayWithArray:workouts]; [all removeObjectAtIndex:ip.row]; [LFStore saveWorkouts:all]; [workouts release]; workouts = [all retain];
    [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationFade];
}
@end

@implementation LFWorkoutDetailViewController
- (id)initWithWorkout:(NSDictionary *)w { if ((self = [super initWithStyle:UITableViewStyleGrouped])) { workout = [w retain]; self.title = [w objectForKey:@"name"]; } return self; }
- (void)dealloc { [workout release]; [super dealloc]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return [[workout objectForKey:@"exercises"] count]; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return [[[[workout objectForKey:@"exercises"] objectAtIndex:s] objectForKey:@"sets"] count]; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return [[LFStore exercise:[[[workout objectForKey:@"exercises"] objectAtIndex:s] objectForKey:@"id"]] objectForKey:@"name"]; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease];
    c.selectionStyle = UITableViewCellSelectionStyleNone;
    NSDictionary *s = [[[[workout objectForKey:@"exercises"] objectAtIndex:ip.section] objectForKey:@"sets"] objectAtIndex:ip.row];
    c.textLabel.text = [NSString stringWithFormat:@"Set %ld", (long)ip.row + 1];
    c.detailTextLabel.text = [NSString stringWithFormat:@"%g %@ × %d", [[s objectForKey:@"weight"] doubleValue], unit(), [[s objectForKey:@"reps"] intValue]];
    return c;
}
@end


