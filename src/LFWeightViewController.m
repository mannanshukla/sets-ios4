#import "LFWeightViewController.h"
#import "CLPaper.h"
BOOL LFParseWeight(NSString *text,double *value) {
    NSString *s=[[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@"."];
    if(![s length] || [s length]>12)return NO;int dots=0,digits=0;for(NSUInteger i=0;i<[s length];i++) { unichar c=[s characterAtIndex:i];if(c=='.')dots++;else if(c>='0' && c<='9')digits++;else return NO; }if(dots>1 || !digits)return NO;double v=[s doubleValue];if(!isfinite(v) || v<0 || v>10000)return NO;if(value)*value=v;return YES;
}
@implementation LFWeightViewController
- (id)initWithWeight:(double)v unit:(NSString *)u delegate:(id<LFWeightDelegate>)d { if((self=[super initWithStyle:UITableViewStyleGrouped])) { initial=v;unit=[u copy];delegate=d;self.title=@"Exact Weight"; }return self; }
- (void)viewDidLoad { [super viewDidLoad];CLPaperTable(self.tableView);field=[[UITextField alloc] initWithFrame:CGRectZero];field.text=[NSString stringWithFormat:@"%g",initial];field.keyboardType=UIKeyboardTypeDecimalPad;field.font=[UIFont systemFontOfSize:20];field.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;field.delegate=self;self.navigationItem.rightBarButtonItem=[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)] autorelease];self.navigationItem.leftBarButtonItem=[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease]; }
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a];[field becomeFirstResponder]; }
- (void)viewDidUnload { double v;if(LFParseWeight(field.text,&v))initial=v;field.delegate=nil;[field release];field=nil;[super viewDidUnload]; }
- (void)dealloc { field.delegate=nil;[field release];[unit release];[super dealloc]; }
- (void)cancel { [self dismissModalViewControllerAnimated:YES]; }
- (void)save { double v;if(!LFParseWeight(field.text,&v)) { [[[[UIAlertView alloc] initWithTitle:@"Weight" message:@"Enter a weight from 0 to 10,000, such as 13 or 13.25." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];return; }[delegate weightSaved:v];[self dismissModalViewControllerAnimated:YES]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return 1; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return [NSString stringWithFormat:@"Weight (%@)",unit]; }
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s { return @"Enter the weight you actually used. Save changes only this set."; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p { UITableViewCell *c=[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];c.selectionStyle=UITableViewCellSelectionStyleNone;field.frame=CGRectMake(12,0,c.contentView.bounds.size.width-24,44);field.autoresizingMask=UIViewAutoresizingFlexibleWidth;[c.contentView addSubview:field];return c; }
@end
