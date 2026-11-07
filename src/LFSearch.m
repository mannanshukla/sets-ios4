#import "LFSearch.h"
#import "LFStore.h"
static NSString *normalized(NSString *s) {
    s=[[s stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]] lowercaseString];
    return [[[s componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]] componentsJoinedByString:@" "];
}
static NSInteger distance(NSString *a,NSString *b,NSInteger limit) {
    NSUInteger n=[a length],m=[b length];if(n>48 || m>48 || labs((long)n-(long)m)>limit)return limit+1;
    unsigned char d[49][49];for(NSUInteger i=0;i<=n;i++)d[i][0]=i;for(NSUInteger j=0;j<=m;j++)d[0][j]=j;
    for(NSUInteger i=1;i<=n;i++)for(NSUInteger j=1;j<=m;j++) {
        int cost=[a characterAtIndex:i-1]!=[b characterAtIndex:j-1];
        d[i][j]=MIN(MIN(d[i-1][j]+1,d[i][j-1]+1),d[i-1][j-1]+cost);
        if(i>1 && j>1 && [a characterAtIndex:i-1]==[b characterAtIndex:j-2] && [a characterAtIndex:i-2]==[b characterAtIndex:j-1])d[i][j]=MIN(d[i][j],d[i-2][j-2]+1);
    }
    return d[n][m];
}
@implementation LFSearch
- (id)initWithExercises:(NSArray *)exercises {
    if((self=[super init])) { NSMutableArray *items=[NSMutableArray array];
        for(NSDictionary *e in exercises) { NSMutableArray *phrases=[NSMutableArray arrayWithObject:normalized([e objectForKey:@"name"])];for(NSString *a in [e objectForKey:@"aliases"])[phrases addObject:normalized(a)];
            NSMutableSet *words=[NSMutableSet set];for(NSString *p in phrases)[words addObjectsFromArray:[p componentsSeparatedByString:@" "]];
            NSString *tags=normalized([NSString stringWithFormat:@"%@ %@ %@",[[e objectForKey:@"primary"] componentsJoinedByString:@" "],[[e objectForKey:@"secondary"] componentsJoinedByString:@" "],[e objectForKey:@"equipment"]?:@""]);
            [items addObject:[NSDictionary dictionaryWithObjectsAndKeys:e,@"exercise",phrases,@"phrases",[words allObjects],@"words",[tags componentsSeparatedByString:@" "],@"tags",nil]];
        }index=[items copy];
    }return self;
}
- (void)dealloc { [index release];[super dealloc]; }
- (NSArray *)resultsForQuery:(NSString *)q kind:(NSInteger)kind {
    if([q length]>120)q=[q substringToIndex:120];q=normalized(q?:@"");NSArray *tokens=[q componentsSeparatedByString:@" "];
    if([tokens count]>12)return [NSArray array];NSMutableArray *ranked=[NSMutableArray array];
    for(NSDictionary *item in index) { NSDictionary *e=[item objectForKey:@"exercise"];BOOL stretch=[LFStore isStretch:e];if((kind==1 && stretch)||(kind==2 && !stretch))continue;
        NSInteger score=0;NSArray *phrases=[item objectForKey:@"phrases"];NSString *name=[phrases objectAtIndex:0];
        if(![q length])score=1;
        else if([name isEqual:q])score=10000;
        else if([phrases containsObject:q])score=9500;
        else { BOOL all=YES;for(NSString *token in tokens) { NSInteger best=0;for(NSString *word in [item objectForKey:@"words"]) {
                    NSInteger v=0;if([word isEqual:token])v=100;else if([token length]>=2 && [word hasPrefix:token])v=85;
                    else if([token length]>=3) { NSInteger limit=[token length]>=7?2:1;NSInteger d=distance(token,word,limit);if(d<=limit)v=65-d*10; }best=MAX(best,v);
                }
                for(NSString *tag in [item objectForKey:@"tags"])if([tag isEqual:token] || ([token length]>=3 && [tag hasPrefix:token]))best=MAX(best,35);
                if(!best) { all=NO;break; }score+=best;
            }if(!all)continue;if([name hasPrefix:q])score+=1000;
        }
        if(score)[ranked addObject:[NSDictionary dictionaryWithObjectsAndKeys:e,@"exercise",[NSNumber numberWithInteger:score],@"score",[e objectForKey:@"name"],@"name",nil]];
    }
    [ranked sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)],nil]];
    NSMutableArray *out=[NSMutableArray array];for(NSDictionary *r in ranked)[out addObject:[r objectForKey:@"exercise"]];return out;
}
@end
