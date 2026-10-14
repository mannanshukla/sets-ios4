#import <QuartzCore/QuartzCore.h>
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
    search.delegate = self; search.placeholder = @"Search exercises"; search.tintColor = [UIColor colorWithRed:0x5B/255.0 green:0x3F/255.0 blue:0xA6/255.0 alpha:1];
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
    if (!c) { c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:rid] autorelease]; c.textLabel.font = [UIFont boldSystemFontOfSize:16]; c.imageView.layer.borderWidth = 1; c.imageView.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1].CGColor; c.detailTextLabel.font = [UIFont systemFontOfSize:12]; c.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1]; c.imageView.contentMode = UIViewContentModeScaleAspectFill; c.imageView.clipsToBounds = YES; }
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
// Grouped table on the pinstripe background, the way exercise guides of 2011 were laid out: a framed photo card you can
// page through, Settings-style fact rows with the value on the right, then numbered steps.
- (id)initWithExercise:(NSDictionary *)e {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        exercise = [e retain]; self.title = [e objectForKey:@"name"];
        NSMutableArray *f = [NSMutableArray array];
        NSString *pm = [[[e objectForKey:@"primary"] componentsJoinedByString:@", "] capitalizedString]; if ([pm length]) [f addObject:[NSArray arrayWithObjects:@"Muscle", pm, nil]];
        NSString *sec = [[[e objectForKey:@"secondary"] componentsJoinedByString:@", "] capitalizedString]; if ([sec length]) [f addObject:[NSArray arrayWithObjects:@"Also works", sec, nil]];
        if ([[e objectForKey:@"equipment"] length]) [f addObject:[NSArray arrayWithObjects:@"Equipment", [[e objectForKey:@"equipment"] capitalizedString], nil]];
        if ([[e objectForKey:@"level"] length]) [f addObject:[NSArray arrayWithObjects:@"Level", [[e objectForKey:@"level"] capitalizedString], nil]];
        if ([[e objectForKey:@"mechanic"] isKindOfClass:[NSString class]]) [f addObject:[NSArray arrayWithObjects:@"Type", [[e objectForKey:@"mechanic"] capitalizedString], nil]];
        if ([[e objectForKey:@"force"] isKindOfClass:[NSString class]]) [f addObject:[NSArray arrayWithObjects:@"Force", [[e objectForKey:@"force"] capitalizedString], nil]];
        facts = [f retain]; steps = [([e objectForKey:@"instructions"] ?: [NSArray array]) retain]; best = [[LFStore bestSetFor:[e objectForKey:@"id"]] retain];
    }
    return self;
}
- (void)dealloc { [flip invalidate]; [flip release]; [exercise release]; [pager release]; [dots release]; [steps release]; [facts release]; [best release]; [super dealloc]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    // photo card: white, rounded, 1px frame and a soft shadow, holding a paging strip of the two frames
    CGFloat w = self.tableView.bounds.size.width, cardW = w - 20, imgH = floorf((cardW - 2) * 567.0 / 850.0);
    UIView *hdr = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, w, imgH + 2 + 22 + 16)] autorelease];
    UIView *card = [[[UIView alloc] initWithFrame:CGRectMake(10, 10, cardW, imgH + 2 + 22)] autorelease];
    card.backgroundColor = [UIColor whiteColor]; card.layer.cornerRadius = 8; card.layer.borderWidth = 1; card.layer.borderColor = [UIColor colorWithWhite:0.72 alpha:1].CGColor;
    card.layer.shadowColor = [UIColor blackColor].CGColor; card.layer.shadowOpacity = 0.18; card.layer.shadowOffset = CGSizeMake(0, 1); card.layer.shadowRadius = 2;
    UIView *clip = [[[UIView alloc] initWithFrame:CGRectMake(1, 1, cardW - 2, imgH)] autorelease]; clip.clipsToBounds = YES; clip.layer.cornerRadius = 7; [card addSubview:clip];
    pager = [[UIScrollView alloc] initWithFrame:clip.bounds]; pager.pagingEnabled = YES; pager.showsHorizontalScrollIndicator = NO; pager.delegate = self; pager.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    int n = 0; for (int i = 0; i < 2; i++) { NSString *p = [LFStore imagePath:[exercise objectForKey:@"id"] frame:i]; if (!p) break;
        UIImageView *iv = [[[UIImageView alloc] initWithFrame:CGRectMake(i * (cardW - 2), 0, cardW - 2, imgH)] autorelease]; iv.contentMode = UIViewContentModeScaleAspectFit; iv.image = [UIImage imageWithContentsOfFile:p]; [pager addSubview:iv]; n++; }
    pager.contentSize = CGSizeMake((cardW - 2) * MAX(n, 1), imgH); [clip addSubview:pager];
    dots = [[UIPageControl alloc] initWithFrame:CGRectMake(0, imgH + 2, cardW, 22)]; dots.numberOfPages = n; dots.hidesForSinglePage = YES; dots.userInteractionEnabled = NO; dots.backgroundColor = [UIColor colorWithWhite:0.55 alpha:1]; dots.layer.cornerRadius = 7; [card addSubview:dots];   // grey strip so the white dots show
    [hdr addSubview:card]; self.tableView.tableHeaderView = hdr;
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; if (dots.numberOfPages > 1) flip = [[NSTimer scheduledTimerWithTimeInterval:1.6 target:self selector:@selector(flipFrame) userInfo:nil repeats:YES] retain]; }
- (void)viewWillDisappear:(BOOL)a { [flip invalidate]; [flip release]; flip = nil; [super viewWillDisappear:a]; }
- (void)flipFrame { if (pager.dragging || pager.decelerating) return; NSInteger next = (dots.currentPage + 1) % MAX(1, dots.numberOfPages); [pager setContentOffset:CGPointMake(next * pager.bounds.size.width, 0) animated:YES]; dots.currentPage = next; }
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sv { dots.currentPage = (NSInteger)(sv.contentOffset.x / sv.bounds.size.width + 0.5); }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2 + (best ? 1 : 0); }
- (NSInteger)stepsSection { return best ? 2 : 1; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { if (s == 0) return [facts count]; if (best && s == 1) return 1; return MAX(1, (NSInteger)[steps count]); }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { if (s == 0) return @"Details"; if (best && s == 1) return @"Your Best"; return @"How To"; }
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section != [self stepsSection] || ![steps count]) return 44;
    CGSize sz = [[steps objectAtIndex:ip.row] sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(tv.bounds.size.width - 20 - 20 - 34, 2000) lineBreakMode:UILineBreakModeWordWrap];
    return MAX(44, sz.height + 22);
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section == 0) {
        UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease]; c.selectionStyle = UITableViewCellSelectionStyleNone;
        NSArray *f = [facts objectAtIndex:ip.row]; c.textLabel.text = [f objectAtIndex:0]; c.detailTextLabel.text = [f objectAtIndex:1]; c.detailTextLabel.adjustsFontSizeToFitWidth = YES; c.detailTextLabel.minimumFontSize = 11; return c;
    }
    if (best && ip.section == 1) {
        UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease]; c.selectionStyle = UITableViewCellSelectionStyleNone;
        c.textLabel.text = @"Best set"; c.detailTextLabel.text = [NSString stringWithFormat:@"%g %@ × %@", [[best objectForKey:@"weight"] doubleValue], [LFStore useKg] ? @"kg" : @"lb", [best objectForKey:@"reps"]]; return c;
    }
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease]; c.selectionStyle = UITableViewCellSelectionStyleNone;
    if (![steps count]) { c.textLabel.text = @"No instructions for this one."; c.textLabel.textColor = [UIColor grayColor]; return c; }
    // step number in the tint, text beside it, like a numbered list in a 2011 guide
    UILabel *num = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, 26, 22)] autorelease]; num.text = [NSString stringWithFormat:@"%ld.", (long)ip.row + 1]; num.font = [UIFont boldSystemFontOfSize:15]; num.textColor = [UIColor colorWithRed:0x5B/255.0 green:0x3F/255.0 blue:0xA6/255.0 alpha:1]; num.backgroundColor = [UIColor clearColor]; [c.contentView addSubview:num];
    CGFloat tw = tv.bounds.size.width - 20 - 20 - 34;
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(44, 11, tw, [self tableView:tv heightForRowAtIndexPath:ip] - 22)] autorelease]; l.text = [steps objectAtIndex:ip.row]; l.font = [UIFont systemFontOfSize:15]; l.numberOfLines = 0; l.lineBreakMode = UILineBreakModeWordWrap; l.backgroundColor = [UIColor clearColor]; [c.contentView addSubview:l];   // fixed width: it must match the width the row height was measured with
    return c;
}
@end
