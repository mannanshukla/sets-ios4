#import "LFExercisesViewController.h"
#import "LFStore.h"

@implementation LFExercisesViewController
@synthesize picker;
- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) { self.title = @"Exercises"; self.tabBarItem.title = @"Exercises"; groups = [[LFStore muscleGroups] retain]; rows = [[NSMutableArray alloc] init]; [self rebuild]; }
    return self;
}
- (void)dealloc { [groups release]; [rows release]; [search release]; [query release]; [super dealloc]; }
- (void)rebuild {
    [rows removeAllObjects];
    for (NSString *g in groups) {
        NSMutableArray *r = [NSMutableArray array];
        for (NSDictionary *e in [LFStore exercisesForMuscle:g]) if (![query length] || [[e objectForKey:@"name"] rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound) [r addObject:e];
        [rows addObject:r];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 56;
    search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 44)];
    search.delegate = self; search.placeholder = @"Search exercises"; search.tintColor = [UIColor colorWithRed:0x4D/255.0 green:0x7C/255.0 blue:0x0F/255.0 alpha:1];
    self.tableView.tableHeaderView = search;
    if (picker) self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
}
- (void)cancel { [self dismissModalViewControllerAnimated:YES]; }
- (void)searchBar:(UISearchBar *)sb textDidChange:(NSString *)t { [query release]; query = [t copy]; [self rebuild]; [self.tableView reloadData]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)sb { [sb resignFirstResponder]; }
- (void)scrollViewWillBeginDragging:(UIScrollView *)sv { [search resignFirstResponder]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return [groups count]; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return [[rows objectAtIndex:s] count]; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return [[rows objectAtIndex:s] count] ? [[groups objectAtIndex:s] capitalizedString] : nil; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *rid = @"ex";
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:rid];
    if (!c) { c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:rid] autorelease]; c.textLabel.font = [UIFont boldSystemFontOfSize:15]; c.detailTextLabel.font = [UIFont systemFontOfSize:12]; c.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1]; c.imageView.contentMode = UIViewContentModeScaleAspectFill; c.imageView.clipsToBounds = YES; }
    NSDictionary *e = [[rows objectAtIndex:ip.section] objectAtIndex:ip.row];
    c.textLabel.text = [e objectForKey:@"name"];
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", [e objectForKey:@"equipment"] ?: @"", [e objectForKey:@"level"] ?: @""];
    UIImage *img = [UIImage imageWithContentsOfFile:[LFStore imagePath:[e objectForKey:@"id"] frame:0]];
    // crop to a 64x44 thumbnail
    if (img) { UIGraphicsBeginImageContextWithOptions(CGSizeMake(66, 44), YES, 0); [img drawInRect:CGRectMake(0, 0, 66, 44)]; c.imageView.image = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); } else c.imageView.image = nil;
    c.accessoryType = picker ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary *e = [[rows objectAtIndex:ip.section] objectAtIndex:ip.row];
    if (picker) { [tv deselectRowAtIndexPath:ip animated:YES]; [picker exercisesPicker:self didPick:e]; return; }
    LFExerciseDetailViewController *d = [[LFExerciseDetailViewController alloc] initWithExercise:e];
    [self.navigationController pushViewController:d animated:YES]; [d release];
}
@end

@implementation LFExerciseDetailViewController
- (id)initWithExercise:(NSDictionary *)e { if ((self = [super initWithNibName:nil bundle:nil])) { exercise = [e retain]; self.title = [e objectForKey:@"name"]; } return self; }
- (void)dealloc { [flip invalidate]; [exercise release]; [frame release]; [text release]; [super dealloc]; }
- (void)loadView {
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    root.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1]; self.view = root; [root release];
    CGRect b = root.bounds;
    CGFloat h = floorf(b.size.width * 567.0 / 850.0);
    frame = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, b.size.width, h)];
    frame.contentMode = UIViewContentModeScaleAspectFit; frame.backgroundColor = [UIColor whiteColor];
    frame.image = [UIImage imageWithContentsOfFile:[LFStore imagePath:[exercise objectForKey:@"id"] frame:0]];
    [root addSubview:frame];
    NSMutableString *t = [NSMutableString string];
    NSString *eq = [exercise objectForKey:@"equipment"], *lv = [exercise objectForKey:@"level"], *mech = [exercise objectForKey:@"mechanic"];
    [t appendFormat:@"%@ · %@ · %@\n", [[[exercise objectForKey:@"primary"] componentsJoinedByString:@", "] capitalizedString], eq ?: @"", lv ?: @""];
    if ([[exercise objectForKey:@"secondary"] count]) [t appendFormat:@"Also: %@\n", [[exercise objectForKey:@"secondary"] componentsJoinedByString:@", "]];
    if ([mech isKindOfClass:[NSString class]]) [t appendFormat:@"%@\n", [mech capitalizedString]];
    NSDictionary *best = [LFStore bestSetFor:[exercise objectForKey:@"id"]];
    if (best) [t appendFormat:@"Your best: %g %@ x %@\n", [[best objectForKey:@"weight"] doubleValue], [LFStore useKg] ? @"kg" : @"lb", [best objectForKey:@"reps"]];
    [t appendString:@"\n"];
    int i = 1; for (NSString *s in [exercise objectForKey:@"instructions"]) { [t appendFormat:@"%d. %@\n\n", i++, s]; }
    text = [[UITextView alloc] initWithFrame:CGRectMake(0, h, b.size.width, b.size.height - h)];
    text.editable = NO; text.font = [UIFont systemFontOfSize:14]; text.text = t; text.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    [root addSubview:text];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; flip = [[NSTimer scheduledTimerWithTimeInterval:1.2 target:self selector:@selector(flipFrame) userInfo:nil repeats:YES] retain]; }
- (void)viewWillDisappear:(BOOL)a { [flip invalidate]; [flip release]; flip = nil; [super viewWillDisappear:a]; }
- (void)flipFrame {
    frameIndex = (frameIndex + 1) % 2;
    NSString *p = [LFStore imagePath:[exercise objectForKey:@"id"] frame:frameIndex];
    if (p) frame.image = [UIImage imageWithContentsOfFile:p];
}
@end
