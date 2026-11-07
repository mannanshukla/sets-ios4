#import "LFSkin.h"
#import <QuartzCore/QuartzCore.h>
#import "LFExercisesViewController.h"
#import "LFStore.h"
#import "LFSearch.h"
#import "LFCustomExercise.h"

@implementation LFExercisesViewController
@synthesize picker;
- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) { self.title = @"Exercises"; self.tabBarItem.title = @"Exercises"; indexedExercises=[[LFStore exercises] retain];searchIndex=[[LFSearch alloc] initWithExercises:indexedExercises]; rows = [[NSMutableArray alloc] init]; [self rebuild];
        UISegmentedControl *seg = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"All", @"Lifts", @"Stretches", nil]] autorelease]; seg.segmentedControlStyle = UISegmentedControlStyleBar; seg.selectedSegmentIndex = 0; [seg addTarget:self action:@selector(kindChanged:) forControlEvents:UIControlEventValueChanged]; self.navigationItem.titleView = seg; }
    return self;
}
- (void)dealloc { [NSObject cancelPreviousPerformRequestsWithTarget:self];search.delegate=nil;[searchIndex release];[indexedExercises release];[groups release];[rows release];[search release];[query release];[super dealloc]; }
- (void)kindChanged:(UISegmentedControl *)seg { kind=seg.selectedSegmentIndex;[self updateResults]; }
- (void)rebuild {
    NSArray *found=[searchIndex resultsForQuery:query kind:kind];[rows removeAllObjects];[groups release];
    if([query length]) { groups=[[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%u matches",(unsigned)[found count]],nil];[rows addObject:found]; }
    else { NSMutableDictionary *by=[NSMutableDictionary dictionary];for(NSDictionary *e in found) { NSString *g=[[e objectForKey:@"primary"] count]?[[e objectForKey:@"primary"] objectAtIndex:0]:@"Other";if(![by objectForKey:g])[by setObject:[NSMutableArray array] forKey:g];[[by objectForKey:g] addObject:e]; }groups=[[[by allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] retain];for(NSString *g in groups)[rows addObject:[by objectForKey:g]]; }
}
- (void)updateResults { [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateResults) object:nil];[self rebuild];[self.tableView reloadData]; }
- (void)viewWillDisappear:(BOOL)a { [NSObject cancelPreviousPerformRequestsWithTarget:self];[search resignFirstResponder];[super viewWillDisappear:a]; }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a];NSArray *current=[LFStore exercises];if(current!=indexedExercises) { [indexedExercises release];indexedExercises=[current retain];[searchIndex release];searchIndex=[[LFSearch alloc] initWithExercises:indexedExercises]; }[self updateResults]; }
- (void)viewDidUnload { search.delegate=nil;[search release];search=nil;[super viewDidUnload]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem=[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCustom)] autorelease];
    self.tableView.rowHeight = 56;
    search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 44)];
    search.delegate = self; search.text=query;search.placeholder = @"Name, muscle, equipment…"; search.tintColor = [UIColor colorWithRed:0x5B/255.0 green:0x3F/255.0 blue:0xA6/255.0 alpha:1];
    self.tableView.tableHeaderView = search;
    if (picker) self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
}
- (void)addCustom { [self.navigationController pushViewController:[[[LFCustomExercise alloc] init] autorelease] animated:YES]; }
- (void)cancel { [self dismissModalViewControllerAnimated:YES]; }
- (void)searchBar:(UISearchBar *)sb textDidChange:(NSString *)t { [query release]; query = [t copy]; [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateResults) object:nil];[self performSelector:@selector(updateResults) withObject:nil afterDelay:0.12]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)sb { [sb resignFirstResponder]; }
- (void)scrollViewWillBeginDragging:(UIScrollView *)sv { [search resignFirstResponder]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return [groups count]; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return [query length]?MAX(1,[[rows objectAtIndex:s] count]):[[rows objectAtIndex:s] count]; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return ([query length] || [[rows objectAtIndex:s] count]) ? [[groups objectAtIndex:s] capitalizedString] : nil; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    if(![[rows objectAtIndex:ip.section] count]) { UITableViewCell *empty=[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];empty.textLabel.text=@"No matches. Try a shorter name.";empty.textLabel.font=[UIFont systemFontOfSize:15];empty.selectionStyle=UITableViewCellSelectionStyleNone;return empty; }
    static NSString *rid = @"ex";
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:rid];
    if (!c) { c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:rid] autorelease]; c.textLabel.font = [UIFont boldSystemFontOfSize:16]; c.imageView.layer.borderWidth = 1; c.imageView.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1].CGColor; c.detailTextLabel.font = [UIFont systemFontOfSize:12]; c.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1]; c.imageView.contentMode = UIViewContentModeScaleAspectFill; c.imageView.clipsToBounds = YES; }
    NSDictionary *e = [[rows objectAtIndex:ip.section] objectAtIndex:ip.row];
    c.textLabel.text = [e objectForKey:@"name"];
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", [e objectForKey:@"equipment"] ?: @"", [e objectForKey:@"level"] ?: @""];
    NSString *path=[LFStore imagePath:[e objectForKey:@"id"] frame:0];UIImage *img = path?[UIImage imageWithContentsOfFile:path]:nil;
    // crop to a 64x44 thumbnail
    if (img) { UIGraphicsBeginImageContextWithOptions(CGSizeMake(66, 44), YES, 0); [img drawInRect:CGRectMake(0, 0, 66, 44)]; c.imageView.image = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); } else c.imageView.image = nil;
    c.accessoryType = picker ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    if(![[rows objectAtIndex:ip.section] count])return;
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
        exercise = [e retain]; LFFitTitle(self, [e objectForKey:@"name"]);
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
- (void)dealloc { [exercise release]; [frame release]; [steps release]; [facts release]; [best release]; [super dealloc]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    if(![[exercise objectForKey:@"images"] count])return;
    // photo card: white, rounded, 1px frame and a soft shadow; the two frames play like a GIF
    CGFloat w = self.tableView.bounds.size.width, cardW = w - 20, imgH = floorf((cardW - 2) * 567.0 / 850.0);
    UIView *hdr = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, w, imgH + 2 + 16)] autorelease];
    UIView *card = [[[UIView alloc] initWithFrame:CGRectMake(10, 10, cardW, imgH + 2)] autorelease];
    card.backgroundColor = [UIColor whiteColor]; card.layer.cornerRadius = 8; card.layer.borderWidth = 1; card.layer.borderColor = [UIColor colorWithWhite:0.72 alpha:1].CGColor;
    card.layer.shadowColor = [UIColor blackColor].CGColor; card.layer.shadowOpacity = 0.18; card.layer.shadowOffset = CGSizeMake(0, 1); card.layer.shadowRadius = 2;
    UIView *clip = [[[UIView alloc] initWithFrame:CGRectMake(1, 1, cardW - 2, imgH)] autorelease]; clip.clipsToBounds = YES; clip.layer.cornerRadius = 7; [card addSubview:clip];
    frame = [[UIImageView alloc] initWithFrame:clip.bounds]; frame.contentMode = UIViewContentModeScaleAspectFit; frame.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    NSMutableArray *imgs = [NSMutableArray array];
    for (int i = 0; i < 2; i++) { NSString *p = [LFStore imagePath:[exercise objectForKey:@"id"] frame:i]; UIImage *im = p ? [UIImage imageWithContentsOfFile:p] : nil; if (im) [imgs addObject:im]; }
    if ([imgs count]) frame.image = [imgs objectAtIndex:0];
    if ([imgs count] > 1) { frame.animationImages = imgs; frame.animationDuration = 2.4; frame.animationRepeatCount = 0; }
    [clip addSubview:frame]; [hdr addSubview:card]; self.tableView.tableHeaderView = hdr;
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; if (frame.animationImages) [frame startAnimating]; }
- (void)viewWillDisappear:(BOOL)a { [frame stopAnimating]; [super viewWillDisappear:a]; }
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
