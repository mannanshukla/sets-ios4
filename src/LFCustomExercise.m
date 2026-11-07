#import "LFCustomExercise.h"
#import "LFStore.h"
#import "CLPaper.h"
@interface LFCustomChoices : UITableViewController { NSArray *choices; NSString *key; LFCustomExercise *owner; }
- (id)initWithItems:(NSArray *)items key:(NSString *)key owner:(LFCustomExercise *)owner;
@end
@implementation LFCustomChoices
- (id)initWithItems:(NSArray *)items key:(NSString *)k owner:(LFCustomExercise *)o { if((self=[super initWithStyle:UITableViewStyleGrouped])) { choices=[items copy];key=[k copy];owner=[o retain];self.title=[k capitalizedString]; }return self; }
- (void)viewDidLoad { [super viewDidLoad];CLPaperTable(self.tableView); }
- (void)dealloc { [choices release];[key release];[owner release];[super dealloc]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return [choices count]; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p { UITableViewCell *c=[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];NSString *v=[choices objectAtIndex:p.row];c.textLabel.text=[v capitalizedString];c.accessoryType=[v isEqual:[owner valueForKey:key]]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;return c; }
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p { [owner setValue:[choices objectAtIndex:p.row] forKey:key];[self.navigationController popViewControllerAnimated:YES]; }
@end
@implementation LFCustomExercise
@synthesize muscle,equipment;
- (id)init { if((self=[super initWithStyle:UITableViewStyleGrouped])) { self.title=@"New Exercise";muscle=[@"quadriceps" copy];equipment=[@"machine" copy]; }return self; }
- (UITextField *)newField:(NSString *)placeholder { UITextField *f=[[UITextField alloc] initWithFrame:CGRectZero];f.placeholder=placeholder;f.font=[UIFont systemFontOfSize:16];f.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;f.delegate=self;f.returnKeyType=UIReturnKeyDone;return f; }
- (void)viewDidLoad { [super viewDidLoad];CLPaperTable(self.tableView);if(!name)name=[self newField:@"Exercise name"];if(!aliases)aliases=[self newField:@"Other names, separated by commas"];if(!logging) { logging=[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Weight × reps",@"Timed hold",nil]];logging.segmentedControlStyle=UISegmentedControlStyleBar;logging.selectedSegmentIndex=0; }self.navigationItem.rightBarButtonItem=[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)] autorelease]; }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a];[self.tableView reloadData]; }
- (void)dealloc { name.delegate=nil;aliases.delegate=nil;[name release];[aliases release];[logging release];[muscle release];[equipment release];[super dealloc]; }
- (BOOL)textFieldShouldReturn:(UITextField *)f { [f resignFirstResponder];return YES; }
- (BOOL)textField:(UITextField *)f shouldChangeCharactersInRange:(NSRange)r replacementString:(NSString *)s { return [f.text length]-r.length+[s length]<=(f==name?80:300); }
- (void)save { [self.view endEditing:YES];NSString *n=[name.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];NSMutableArray *a=[NSMutableArray array];for(NSString *s in [aliases.text componentsSeparatedByString:@","]) { NSString *v=[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];if([v length])[a addObject:v]; }
 NSDictionary *e=[NSDictionary dictionaryWithObjectsAndKeys:n?:@"",@"name",equipment,@"equipment",[NSArray arrayWithObject:muscle],@"primary",[NSArray array],@"secondary",logging.selectedSegmentIndex?@"stretching":@"strength",@"category",@"custom",@"level",a,@"aliases",[NSArray array],@"images",[NSArray array],@"instructions",nil];NSString *error=nil;if(![LFStore addCustomExercise:e error:&error]) { [[[[UIAlertView alloc] initWithTitle:@"Exercise" message:error delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];return; }[self.navigationController popViewControllerAnimated:YES]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 3; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return s==0?3:1; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return s==0?@"Exercise":s==1?@"How you log it":@"Search aliases"; }
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s { return s==2?@"Saved on this iPod and available in workouts and routines. Existing exercise history stays unchanged.":s==1?@"Use timed holds for stretches and static positions.":nil; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p { UITableViewCell *c=[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease];c.textLabel.font=[UIFont boldSystemFontOfSize:16];if(p.section==0 && p.row) { c.textLabel.text=p.row==1?@"Muscle":@"Equipment";c.detailTextLabel.text=[(p.row==1?muscle:equipment) capitalizedString];c.accessoryType=UITableViewCellAccessoryDisclosureIndicator; }else { UIView *v=p.section==0?(UIView *)name:p.section==1?(UIView *)logging:(UIView *)aliases;v.frame=CGRectMake(10,6,c.contentView.bounds.size.width-20,32);v.autoresizingMask=UIViewAutoresizingFlexibleWidth;[c.contentView addSubview:v];c.selectionStyle=UITableViewCellSelectionStyleNone; }return c; }
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p { [t deselectRowAtIndexPath:p animated:YES];if(p.section || !p.row)return;[self.view endEditing:YES];NSArray *items=p.row==1?[NSArray arrayWithObjects:@"abdominals",@"biceps",@"calves",@"chest",@"forearms",@"glutes",@"hamstrings",@"lats",@"lower back",@"middle back",@"quadriceps",@"shoulders",@"traps",@"triceps",nil]:[NSArray arrayWithObjects:@"body only",@"barbell",@"dumbbell",@"cable",@"machine",@"kettlebells",@"bands",@"other",nil];[self.navigationController pushViewController:[[[LFCustomChoices alloc] initWithItems:items key:p.row==1?@"muscle":@"equipment" owner:self] autorelease] animated:YES]; }
@end
