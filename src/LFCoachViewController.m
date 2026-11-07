#import "LFCoachViewController.h"
#import "LFRoutinesViewController.h"
#import "LFStore.h"
#import "LFAI.h"
#import "CLPaper.h"
#import "CLCoachViewController.h"
@implementation LFCoachViewController
- (id)init { if((self=[super initWithStyle:UITableViewStyleGrouped])) { self.title=@"Coach";self.tabBarItem.image=CLCoachIcon(); }return self; }
- (void)viewDidLoad { [super viewDidLoad];CLPaperTable(self.tableView); }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a];[self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 3; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return s==0?3:s==1?2:1; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return s==0?@"This week":s==1?@"Your training":@"Notebook"; }
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s { return s==0?@"Check in, review how training is going, and choose one useful adjustment.":s==1?@"Keep a consistent plan. A new plan is optional and always reviewed before adding.":@"Coaching offers suggestions. Your routines and logged progress change only when you edit them."; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p { UITableViewCell *c=[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil] autorelease];c.textLabel.font=[UIFont boldSystemFontOfSize:16];c.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    if(p.section==0) { c.textLabel.text=p.row==0?@"Check in":p.row==1?@"Review my week":@"Ask a question";if(p.row==0) { NSDate *date=[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"coach_checkin"] objectForKey:@"date"];c.detailTextLabel.text=date?[NSString stringWithFormat:@"Last: %@",[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle]]:@"Goal, energy, recovery & time"; }if(p.row==1)c.detailTextLabel.text=@"Progress, obstacles & next steps"; }
    else if(p.section==1) { c.textLabel.text=p.row==0?@"Your routines":@"Build a plan";c.detailTextLabel.text=p.row==0?[NSString stringWithFormat:@"%u saved routines",(unsigned)[[LFStore routines] count]]:@"Goal, experience & equipment"; }
    else { c.textLabel.text=@"Coach notes";c.detailTextLabel.text=[NSString stringWithFormat:@"%u saved notes",(unsigned)[CLCoachNotes() count]]; }return c;
}
- (CGFloat)tableView:(UITableView *)t heightForRowAtIndexPath:(NSIndexPath *)p { return 56; }
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p { [t deselectRowAtIndexPath:p animated:YES];UIViewController *vc=nil;
    if(p.section==0 && p.row==0)vc=[[[CLCheckInController alloc] initWithSource:@"Sets"] autorelease];
    else if(p.section==0) { CLCoachViewController *c=[[[CLCoachViewController alloc] initWithSource:@"Sets" context:[LFAI summary] system:[LFAI reviewSystem]] autorelease];c.questionText=p.row==1?@"Review my recent training against my goal and current routines. What is working? Choose one realistic adjustment for next week, with a fallback for a busy day.":@"Help me work through this training question: ";vc=c; }
    else if(p.section==1)vc=p.row==0?(UIViewController *)[[[LFRoutinesViewController alloc] init] autorelease]:[[[LFGenerateViewController alloc] init] autorelease];
    else vc=[[[CLNotesViewController alloc] init] autorelease];[self.navigationController pushViewController:vc animated:YES];
}
@end
