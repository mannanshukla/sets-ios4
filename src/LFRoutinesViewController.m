#import "LFSkin.h"
#import "LFRoutinesViewController.h"
#import "LFExercisesViewController.h"
#import "LFStore.h"
#import "LFAI.h"
#import "LFWorkoutViewController.h"

@implementation LFRoutinesViewController
- (id)init { if ((self = [super initWithStyle:UITableViewStylePlain])) { self.title = @"Routines"; self.tabBarItem.title = @"Routines"; routines = [[NSMutableArray alloc] init]; } return self; }
- (void)dealloc { [routines release]; [super dealloc]; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.tableView.rowHeight = 56;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Generate" style:UIBarButtonItemStyleBordered target:self action:@selector(generate)] autorelease];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self reload]; }
- (void)reload { [routines setArray:[LFStore routines]]; [self.tableView reloadData]; }
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a]; NSUserDefaults *d = [NSUserDefaults standardUserDefaults]; if ([d boolForKey:@"lf_open_routine"] && [routines count]) { [d removeObjectForKey:@"lf_open_routine"]; [d synchronize]; [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]; } }
- (void)add { LFRoutineEditViewController *e = [[LFRoutineEditViewController alloc] initWithRoutine:nil]; [self.navigationController pushViewController:e animated:YES]; [e release]; }
- (void)generate { LFGenerateViewController *g = [[LFGenerateViewController alloc] init]; [self.navigationController pushViewController:g animated:YES]; [g release]; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return [routines count]; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"r"];
    if (!c) { c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"r"] autorelease]; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.textLabel.font = [UIFont boldSystemFontOfSize:17]; c.detailTextLabel.font = [UIFont systemFontOfSize:12]; c.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1]; }
    NSDictionary *r = [routines objectAtIndex:ip.row];
    c.textLabel.text = [r objectForKey:@"name"];
    NSMutableArray *names = [NSMutableArray array];
    for (NSDictionary *x in [r objectForKey:@"exercises"]) { NSDictionary *e = [LFStore exercise:[x objectForKey:@"id"]]; if (e) [names addObject:[e objectForKey:@"name"]]; }
    c.detailTextLabel.text = [NSString stringWithFormat:@"%lu exercises · %@", (unsigned long)[names count], [names componentsJoinedByString:@", "]];
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    LFRoutineEditViewController *e = [[LFRoutineEditViewController alloc] initWithRoutine:[routines objectAtIndex:ip.row]];
    [self.navigationController pushViewController:e animated:YES]; [e release];
}
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)st forRowAtIndexPath:(NSIndexPath *)ip {
    if (st != UITableViewCellEditingStyleDelete) return;
    [routines removeObjectAtIndex:ip.row]; [LFStore saveRoutines:routines];
    [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationFade];
}
@end

static NSArray *holdPresets(void) { static NSArray *h = nil; if (!h) h = [[NSArray arrayWithObjects:@"15s", @"20s", @"30s", @"45s", @"60s", @"90s", nil] retain]; return h; }
static NSArray *repsPresets(void) { static NSArray *r = nil; if (!r) r = [[NSArray arrayWithObjects:@"3", @"5", @"6", @"8", @"10", @"12", @"15", @"20", @"5-8", @"6-10", @"8-12", @"10-15", @"12-20", @"AMRAP", nil] retain]; return r; }

@implementation LFRoutineEditViewController
- (id)initWithRoutine:(NSDictionary *)r {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        isNew = (r == nil);
        routine = [[NSMutableDictionary alloc] initWithDictionary:(r ?: [NSDictionary dictionaryWithObjectsAndKeys:[LFStore newId], @"id", @"", @"name", nil])];
        exercises = [[NSMutableArray alloc] initWithArray:([r objectForKey:@"exercises"] ?: [NSArray array])];
        self.title = isNew ? @"New Routine" : [r objectForKey:@"name"];
    }
    return self;
}
- (void)dealloc { [routine release]; [exercises release]; [nameField release]; [drum release]; [picker release]; [drumTitle release]; [super dealloc]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    nameField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 260, 30)];
    nameField.placeholder = @"Routine name"; nameField.text = [routine objectForKey:@"name"]; nameField.font = [UIFont systemFontOfSize:16]; nameField.delegate = self;
    nameField.returnKeyType = UIReturnKeyDone; nameField.autocapitalizationType = UITextAutocapitalizationTypeWords; nameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [self closeDrum]; [self save]; }
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a]; NSUserDefaults *d = [NSUserDefaults standardUserDefaults]; if ([d boolForKey:@"lf_test_edit"] && [exercises count]) { [d removeObjectForKey:@"lf_test_edit"]; [d synchronize]; UIButton *b = [[[UIButton alloc] init] autorelease]; b.tag = 1; [self performSelector:@selector(openDrum:) withObject:b afterDelay:0.4]; } }
- (void)save {
    NSString *n = [nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![n length] && ![exercises count]) return;   // nothing to keep
    [routine setObject:([n length] ? n : @"Routine") forKey:@"name"];
    [routine setObject:exercises forKey:@"exercises"];
    NSMutableArray *all = [NSMutableArray arrayWithArray:[LFStore routines]]; BOOL replaced = NO;
    for (NSUInteger i = 0; i < [all count]; i++) if ([[[all objectAtIndex:i] objectForKey:@"id"] isEqualToString:[routine objectForKey:@"id"]]) { [all replaceObjectAtIndex:i withObject:routine]; replaced = YES; }
    if (!replaced) [all addObject:routine];
    [LFStore saveRoutines:all];
}
- (BOOL)textFieldShouldReturn:(UITextField *)tf { [tf resignFirstResponder]; return YES; }
- (void)addExercise {
    LFExercisesViewController *p = [[LFExercisesViewController alloc] init]; p.picker = self;
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:p]; n.navigationBar.tintColor = self.navigationController.navigationBar.tintColor; LFSkinNavBar(n.navigationBar);
    [self presentModalViewController:n animated:YES]; [n release]; [p release];
}
- (void)exercisesPicker:(LFExercisesViewController *)p didPick:(NSDictionary *)e {
    [exercises addObject:[NSDictionary dictionaryWithObjectsAndKeys:[e objectForKey:@"id"], @"id", [NSNumber numberWithInt:3], @"sets", @"8-12", @"reps", nil]];
    [self dismissModalViewControllerAnimated:YES]; [self.tableView reloadData];
}
- (void)startWorkout {
    [self save];
    if ([LFStore activeWorkout]) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Workout in progress" message:@"Finish or discard the current workout first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]; [a show]; [a release]; return;
    }
    [LFWorkoutViewController startFromRoutine:routine];
    self.tabBarController.selectedIndex = 0;
    [self.navigationController popToRootViewControllerAnimated:NO];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 3; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return s == 0 ? 1 : s == 1 ? [exercises count] + 1 : 1; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return s == 1 ? @"Exercises" : nil; }
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip { return (ip.section == 1 && ip.row < (NSInteger)[exercises count]) ? 62 : 44; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil] autorelease];
    if (ip.section == 0) { c.selectionStyle = UITableViewCellSelectionStyleNone; nameField.frame = CGRectMake(10, 7, c.contentView.bounds.size.width - 20, 30); nameField.autoresizingMask = UIViewAutoresizingFlexibleWidth; [c.contentView addSubview:nameField]; return c; }
    if (ip.section == 2) { c.textLabel.text = @"Start Workout"; c.textLabel.textAlignment = UITextAlignmentCenter; c.textLabel.textColor = [UIColor colorWithRed:0x5B/255.0 green:0x3F/255.0 blue:0xA6/255.0 alpha:1]; c.textLabel.font = [UIFont boldSystemFontOfSize:17]; return c; }
    if (ip.row == [exercises count]) { c.textLabel.text = @"Add Exercise..."; c.textLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1]; return c; }
    NSDictionary *x = [exercises objectAtIndex:ip.row]; NSDictionary *e = [LFStore exercise:[x objectForKey:@"id"]];
    c.selectionStyle = UITableViewCellSelectionStyleBlue;
    c.textLabel.text = [e objectForKey:@"name"] ?: [x objectForKey:@"id"]; c.textLabel.font = [UIFont boldSystemFontOfSize:15];
    NSString *pm = [[e objectForKey:@"primary"] count] ? [[[e objectForKey:@"primary"] objectAtIndex:0] capitalizedString] : @""; NSString *eq = [e objectForKey:@"equipment"] ?: @"";
    c.detailTextLabel.text = [LFStore isStretch:e] ? [NSString stringWithFormat:@"Stretch · %@", pm] : [NSString stringWithFormat:@"%@ · %@", pm, eq]; c.detailTextLabel.font = [UIFont systemFontOfSize:12]; c.detailTextLabel.textColor = [UIColor grayColor];
    // the sets button is the accessory view, so the name truncates instead of running underneath it
    UIButton *b = [UIButton buttonWithType:UIButtonTypeRoundedRect]; b.frame = CGRectMake(0, 0, 108, 32); b.tag = ip.row;
    NSString *reps = [x objectForKey:@"reps"] ?: @""; BOOL hold = [reps hasSuffix:@"s"] && [[reps substringToIndex:[reps length] - 1] intValue] > 0;
    [b setTitle:[NSString stringWithFormat:hold ? @"%@ × %@ hold" : @"%@ × %@", [x objectForKey:@"sets"], reps] forState:UIControlStateNormal]; b.titleLabel.font = [UIFont boldSystemFontOfSize:15]; b.titleLabel.adjustsFontSizeToFitWidth = YES; b.titleLabel.minimumFontSize = 11;
    [b addTarget:self action:@selector(openDrum:) forControlEvents:UIControlEventTouchUpInside]; c.accessoryView = b;
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section == 2) [self startWorkout];
    else if (ip.section == 1 && ip.row == (NSInteger)[exercises count]) [self addExercise];
    else if (ip.section == 1) {   // look at the exercise; the sets button on the right is separate
        NSDictionary *e = [LFStore exercise:[[exercises objectAtIndex:ip.row] objectForKey:@"id"]]; if (!e) return;
        LFExerciseDetailViewController *d = [[LFExerciseDetailViewController alloc] initWithExercise:e]; [self.navigationController pushViewController:d animated:YES]; [d release];
    }
}
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return ip.section == 1 && ip.row < (NSInteger)[exercises count]; }
- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath *)ip { return ip.section == 1 && ip.row < (NSInteger)[exercises count]; }
- (NSIndexPath *)tableView:(UITableView *)tv targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)s toProposedIndexPath:(NSIndexPath *)p { return (p.section == 1 && p.row < (NSInteger)[exercises count]) ? p : [NSIndexPath indexPathForRow:[exercises count]-1 inSection:1]; }
- (void)tableView:(UITableView *)tv moveRowAtIndexPath:(NSIndexPath *)s toIndexPath:(NSIndexPath *)d { id x = [[exercises objectAtIndex:s.row] retain]; [exercises removeObjectAtIndex:s.row]; [exercises insertObject:x atIndex:d.row]; [x release]; }
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)st forRowAtIndexPath:(NSIndexPath *)ip {
    if (st != UITableViewCellEditingStyleDelete) return;
    [exercises removeObjectAtIndex:ip.row]; [tv reloadData];
}

#pragma mark sets × reps wheel
- (void)buildDrum {
    if (drum) return;
    UIView *host = self.tabBarController.view ?: self.navigationController.view; CGRect b = host.bounds;
    drum = [[UIView alloc] initWithFrame:CGRectMake(0, b.size.height, b.size.width, 260)]; drum.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    UIToolbar *bar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, b.size.width, 44)] autorelease]; bar.barStyle = UIBarStyleBlack; bar.translucent = NO;
    drumTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 190, 44)]; drumTitle.font = [UIFont boldSystemFontOfSize:14]; drumTitle.adjustsFontSizeToFitWidth = YES; drumTitle.minimumFontSize = 10; drumTitle.textColor = [UIColor whiteColor]; drumTitle.backgroundColor = [UIColor clearColor]; drumTitle.textAlignment = UITextAlignmentCenter;
    UIBarButtonItem *flex = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    bar.items = [NSArray arrayWithObjects:flex, [[[UIBarButtonItem alloc] initWithCustomView:drumTitle] autorelease], flex, [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeDrum)] autorelease], nil];
    [drum addSubview:bar];
    picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 44, b.size.width, 216)]; picker.dataSource = self; picker.delegate = self; picker.showsSelectionIndicator = YES; picker.backgroundColor = [UIColor blackColor]; picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [drum addSubview:picker]; [host addSubview:drum];
}
- (void)openDrum:(UIButton *)b {
    [self.view endEditing:YES]; [self buildDrum]; pickRow = b.tag;
    NSDictionary *x = [exercises objectAtIndex:pickRow];
    drumTitle.text = [[LFStore exercise:[x objectForKey:@"id"]] objectForKey:@"name"] ?: @"Sets × reps";
    [picker reloadAllComponents];
    [picker selectRow:MAX(0, MIN(9, [[x objectForKey:@"sets"] integerValue] - 1)) inComponent:0 animated:NO];
    NSArray *pr = [self presetsAt:pickRow]; NSInteger ri = [pr indexOfObject:[x objectForKey:@"reps"]]; [picker selectRow:ri == NSNotFound ? (pr == holdPresets() ? 2 : 10) : ri inComponent:1 animated:NO];
    CGRect b2 = drum.superview.bounds; [drum.superview bringSubviewToFront:drum];
    [UIView beginAnimations:nil context:NULL]; [UIView setAnimationDuration:0.3]; drum.frame = CGRectMake(0, b2.size.height - 260, b2.size.width, 260); [UIView commitAnimations];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 260 - 49, 0);
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pickRow inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}
- (void)closeDrum {
    if (!drum) return; CGRect b2 = drum.superview.bounds;
    [UIView beginAnimations:nil context:NULL]; [UIView setAnimationDuration:0.3]; drum.frame = CGRectMake(0, b2.size.height, b2.size.width, 260); [UIView commitAnimations];
    self.tableView.contentInset = UIEdgeInsetsZero;
}
- (NSArray *)presetsAt:(NSInteger)row { if (row < 0 || row >= (NSInteger)[exercises count]) return repsPresets(); NSDictionary *x = [exercises objectAtIndex:row]; NSString *r = [x objectForKey:@"reps"] ?: @""; BOOL hold = [r hasSuffix:@"s"] && [[r substringToIndex:[r length] - 1] intValue] > 0; return (hold || [LFStore isStretch:[LFStore exercise:[x objectForKey:@"id"]]]) ? holdPresets() : repsPresets(); }
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pv { return 2; }
- (NSInteger)pickerView:(UIPickerView *)pv numberOfRowsInComponent:(NSInteger)c { return c == 0 ? 10 : [[self presetsAt:pickRow] count]; }
- (NSString *)pickerView:(UIPickerView *)pv titleForRow:(NSInteger)row forComponent:(NSInteger)c { return c == 0 ? [NSString stringWithFormat:@"%ld set%@", (long)row + 1, row ? @"s" : @""] : ([self presetsAt:pickRow] == holdPresets() ? [NSString stringWithFormat:@"hold %@", [holdPresets() objectAtIndex:row]] : [NSString stringWithFormat:@"%@ reps", [repsPresets() objectAtIndex:row]]); }
- (CGFloat)pickerView:(UIPickerView *)pv widthForComponent:(NSInteger)c { return c == 0 ? 130 : 160; }
- (void)pickerView:(UIPickerView *)pv didSelectRow:(NSInteger)row inComponent:(NSInteger)c {
    if (pickRow < 0 || pickRow >= (NSInteger)[exercises count]) return;
    NSMutableDictionary *x = [NSMutableDictionary dictionaryWithDictionary:[exercises objectAtIndex:pickRow]];
    if (c == 0) [x setObject:[NSNumber numberWithInteger:row + 1] forKey:@"sets"]; else [x setObject:[[self presetsAt:pickRow] objectAtIndex:row] forKey:@"reps"];
    [exercises replaceObjectAtIndex:pickRow withObject:x];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:pickRow inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}
@end

@implementation LFGenerateViewController
- (id)init { if ((self = [super initWithStyle:UITableViewStyleGrouped])) { self.title = @"Generate"; } return self; }
- (void)dealloc { [goal release]; [level release]; [equipment release]; [days release]; [minutes release]; [daysLabel release]; [minutesLabel release]; [notes release]; [status release]; [super dealloc]; }
- (UISegmentedControl *)seg:(NSArray *)items sel:(NSInteger)i { UISegmentedControl *s = [[UISegmentedControl alloc] initWithItems:items]; s.segmentedControlStyle = UISegmentedControlStyleBar; s.selectedSegmentIndex = i; s.tintColor = [UIColor colorWithRed:0x5B/255.0 green:0x3F/255.0 blue:0xA6/255.0 alpha:1]; return s; }
- (void)viewDidLoad {
    [super viewDidLoad];
    goal = [self seg:[NSArray arrayWithObjects:@"Strength", @"Muscle", @"General", nil] sel:1];
    level = [self seg:[NSArray arrayWithObjects:@"Beginner", @"Intermediate", @"Advanced", nil] sel:0];
    equipment = [self seg:[NSArray arrayWithObjects:@"Full gym", @"Dumbbells", @"Bodyweight", nil] sel:0];
    days = [[UISlider alloc] initWithFrame:CGRectZero]; days.minimumValue = 1; days.maximumValue = 6; days.value = 3; [days addTarget:self action:@selector(slid) forControlEvents:UIControlEventValueChanged];
    minutes = [[UISlider alloc] initWithFrame:CGRectZero]; minutes.minimumValue = 20; minutes.maximumValue = 90; minutes.value = 45; [minutes addTarget:self action:@selector(slid) forControlEvents:UIControlEventValueChanged];
    daysLabel = [[UILabel alloc] initWithFrame:CGRectZero]; minutesLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    for (UILabel *l in [NSArray arrayWithObjects:daysLabel, minutesLabel, nil]) { l.font = [UIFont boldSystemFontOfSize:15]; l.backgroundColor = [UIColor clearColor]; l.textAlignment = UITextAlignmentRight; }
    notes = [[UITextField alloc] initWithFrame:CGRectZero]; notes.placeholder = @"Bad knee, no barbell, add stretches..."; notes.font = [UIFont systemFontOfSize:15]; notes.delegate = self; notes.returnKeyType = UIReturnKeyDone; notes.clearButtonMode = UITextFieldViewModeWhileEditing; notes.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter; notes.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [self slid];
}
- (BOOL)textFieldShouldReturn:(UITextField *)f { [f resignFirstResponder]; return YES; }
- (void)slid { daysLabel.text = [NSString stringWithFormat:@"%d", (int)(days.value + 0.5)]; minutesLabel.text = [NSString stringWithFormat:@"%d", (int)(minutes.value / 5 + 0.5) * 5]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 7; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return 1; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { NSArray *t = [NSArray arrayWithObjects:@"Goal", @"Experience", @"Equipment", @"Days per week", @"Minutes per session", @"Anything else? (optional)", nil]; return s < 6 ? [t objectAtIndex:s] : nil; }
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s { return s == 6 ? (status ?: @"OpenRelay writes one routine per training day using only exercises from this app's database. Review and edit them after.") : nil; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
    c.selectionStyle = UITableViewCellSelectionStyleNone;
    CGFloat w = c.contentView.bounds.size.width;
    if (ip.section <= 2) { UISegmentedControl *s = ip.section == 0 ? goal : ip.section == 1 ? level : equipment; s.frame = CGRectMake(8, 7, w - 16, 30); s.autoresizingMask = UIViewAutoresizingFlexibleWidth; [c.contentView addSubview:s]; }
    else if (ip.section <= 4) { UISlider *sl = ip.section == 3 ? days : minutes; UILabel *l = ip.section == 3 ? daysLabel : minutesLabel; sl.frame = CGRectMake(8, 7, w - 70, 30); sl.autoresizingMask = UIViewAutoresizingFlexibleWidth; l.frame = CGRectMake(w - 56, 7, 46, 30); l.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin; [c.contentView addSubview:sl]; [c.contentView addSubview:l]; }
    else if (ip.section == 5) { notes.frame = CGRectMake(10, 7, w - 20, 30); notes.autoresizingMask = UIViewAutoresizingFlexibleWidth; [c.contentView addSubview:notes]; }
    else { c.selectionStyle = UITableViewCellSelectionStyleBlue; c.textLabel.text = busy ? @"Writing your routines..." : @"Generate Routines"; c.textLabel.textAlignment = UITextAlignmentCenter; c.textLabel.textColor = [UIColor colorWithRed:0x5B/255.0 green:0x3F/255.0 blue:0xA6/255.0 alpha:1]; c.textLabel.font = [UIFont boldSystemFontOfSize:17]; }
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section != 6 || busy) return;
    [notes resignFirstResponder]; busy = YES; [status release]; status = nil; [tv reloadData];
    NSString *g = [[NSArray arrayWithObjects:@"strength", @"hypertrophy (build muscle)", @"general fitness", nil] objectAtIndex:goal.selectedSegmentIndex];
    NSString *l = [[NSArray arrayWithObjects:@"beginner", @"intermediate", @"advanced", nil] objectAtIndex:level.selectedSegmentIndex];
    NSString *eq = [[NSArray arrayWithObjects:@"full gym", @"dumbbells", @"bodyweight", nil] objectAtIndex:equipment.selectedSegmentIndex];
    NSInteger d = (NSInteger)(days.value + 0.5), m = (NSInteger)(minutes.value / 5 + 0.5) * 5;
    [self performSelectorInBackground:@selector(run:) withObject:[NSArray arrayWithObjects:g, l, eq, [NSNumber numberWithInteger:d], [NSNumber numberWithInteger:m], ([notes.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @""), nil]];
}
- (void)run:(NSArray *)a {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *err = nil;
    NSArray *rs = [LFAI generateRoutinesForGoal:[a objectAtIndex:0] days:[[a objectAtIndex:3] integerValue] equipment:[a objectAtIndex:2] level:[a objectAtIndex:1] minutes:[[a objectAtIndex:4] integerValue] notes:[a objectAtIndex:5] error:&err];
    [self performSelectorOnMainThread:@selector(finished:) withObject:[NSArray arrayWithObjects:(rs ?: [NSArray array]), (err ?: @""), nil] waitUntilDone:NO];
    [pool release];
}
- (void)finished:(NSArray *)r {
    busy = NO;
    NSArray *rs = [r objectAtIndex:0]; NSString *err = [r objectAtIndex:1];
    if ([rs count]) {
        NSMutableArray *all = [NSMutableArray arrayWithArray:[LFStore routines]]; [all addObjectsFromArray:rs]; [LFStore saveRoutines:all];
        [self.navigationController popViewControllerAnimated:YES];
    } else { [status release]; status = [([err length] ? err : @"No routines came back.") copy]; [self.tableView reloadData]; }
}
@end
