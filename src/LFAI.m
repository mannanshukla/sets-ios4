#import "LFAI.h"
#import "LFStore.h"
#import "ORJSON.h"

@implementation LFAI
+ (NSString *)complete:(NSString *)system user:(NSString *)user model:(NSString *)model error:(NSString **)err {
    if (![[LFStore apiKey] length]) { if (err) *err = @"Add your OpenRelay API key in Settings first."; return nil; }
    NSArray *msgs = [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:@"system", @"role", system, @"content", nil],
        [NSDictionary dictionaryWithObjectsAndKeys:@"user", @"role", user, @"content", nil], nil];
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:model, @"model", msgs, @"messages", [NSNumber numberWithBool:NO], @"stream", [NSNumber numberWithDouble:0.4], @"temperature", nil];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://inference.openrelay.inc/v1/chat/completions"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:120];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", [LFStore apiKey]] forHTTPHeaderField:@"Authorization"];
    [req setValue:@"close" forHTTPHeaderField:@"Connection"];
    [req setHTTPBody:[[ORJSON stringify:body] dataUsingEncoding:NSUTF8StringEncoding]];
    NSHTTPURLResponse *resp = nil; NSError *e = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&e];
    if (!data) { if (err) *err = [e localizedDescription]; return nil; }
    id obj = [ORJSON parse:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
    if ([resp statusCode] != 200 || ![obj isKindOfClass:[NSDictionary class]]) {
        NSString *m = [NSString stringWithFormat:@"HTTP %d", (int)[resp statusCode]];
        id er = [obj isKindOfClass:[NSDictionary class]] ? [obj objectForKey:@"error"] : nil;
        if ([er isKindOfClass:[NSDictionary class]] && [er objectForKey:@"message"]) m = [er objectForKey:@"message"];
        if (err) *err = m; return nil;
    }
    NSArray *choices = [obj objectForKey:@"choices"];
    if (![choices count]) { if (err) *err = @"Empty reply."; return nil; }
    id content = [[[choices objectAtIndex:0] objectForKey:@"message"] objectForKey:@"content"];
    return [content isKindOfClass:[NSString class]] ? content : nil;
}

+ (NSArray *)generateRoutinesForGoal:(NSString *)goal days:(NSInteger)days equipment:(NSString *)equipment level:(NSString *)level minutes:(NSInteger)minutes error:(NSString **)err {
    // candidate list: ids the model may use, filtered by equipment
    NSSet *allowed;
    if ([equipment isEqualToString:@"bodyweight"]) allowed = [NSSet setWithObjects:@"body only", nil];
    else if ([equipment isEqualToString:@"dumbbells"]) allowed = [NSSet setWithObjects:@"body only", @"dumbbell", @"kettlebells", nil];
    else allowed = [NSSet setWithObjects:@"body only", @"dumbbell", @"kettlebells", @"barbell", @"cable", @"machine", @"e-z curl bar", nil];
    NSMutableArray *cands = [NSMutableArray array];
    for (NSDictionary *e in [LFStore exercises]) {
        if (![allowed containsObject:[e objectForKey:@"equipment"] ?: @""]) continue;
        NSString *pm = [[e objectForKey:@"primary"] count] ? [[e objectForKey:@"primary"] objectAtIndex:0] : @"";
        [cands addObject:[NSString stringWithFormat:@"%@ | %@ | %@", [e objectForKey:@"id"], pm, [e objectForKey:@"equipment"]]];
    }
    NSString *system = @"You are a strength coach writing workout routines. You must reply with JSON only, no prose, no markdown fences. "
        @"Schema: {\"routines\":[{\"name\":string,\"exercises\":[{\"id\":string,\"sets\":int,\"reps\":string}]}]}. "
        @"Use ONLY exercise ids from the provided list, exactly as written. reps is a short string like \"5\", \"8-12\" or \"AMRAP\". "
        @"Each routine is one training day with 4 to 7 exercises, compounds first. Give the routines short real names like \"Push A\" or \"Lower\". Do not repeat the same exercise within a routine.";
    NSString *user = [NSString stringWithFormat:@"Goal: %@. Level: %@. Days per week: %ld. Equipment: %@. Session length: about %ld minutes. Write exactly %ld routines, one per training day, as a sensible split for that frequency.\n\nAvailable exercises (id | primary muscle | equipment):\n%@",
        goal, level, (long)days, equipment, (long)minutes, (long)days, [cands componentsJoinedByString:@"\n"]];
    NSString *text = [self complete:system user:user model:@"openrelay/gpt-oss-120b" error:err];
    if (!text) return nil;
    // tolerate stray fences or prose around the JSON
    NSRange a = [text rangeOfString:@"{"], b = [text rangeOfString:@"}" options:NSBackwardsSearch];
    if (a.location == NSNotFound || b.location == NSNotFound) { if (err) *err = @"The model did not return JSON."; return nil; }
    id obj = [ORJSON parse:[text substringWithRange:NSMakeRange(a.location, b.location - a.location + 1)]];
    NSArray *rs = [obj isKindOfClass:[NSDictionary class]] ? [obj objectForKey:@"routines"] : nil;
    if (![rs isKindOfClass:[NSArray class]] || ![rs count]) { if (err) *err = @"Could not read the routine JSON."; return nil; }
    NSMutableArray *out = [NSMutableArray array];
    for (NSDictionary *r in rs) {
        if (![r isKindOfClass:[NSDictionary class]]) continue;
        NSMutableArray *exs = [NSMutableArray array];
        for (NSDictionary *x in [r objectForKey:@"exercises"]) {
            if (![x isKindOfClass:[NSDictionary class]]) continue;
            NSString *eid = [x objectForKey:@"id"];
            if (![LFStore exercise:eid]) continue;   // hallucinated id: drop it
            NSInteger sets = [[x objectForKey:@"sets"] integerValue]; if (sets < 1 || sets > 8) sets = 3;
            NSString *reps = [[x objectForKey:@"reps"] description] ?: @"8-12";
            [exs addObject:[NSDictionary dictionaryWithObjectsAndKeys:eid, @"id", [NSNumber numberWithInteger:sets], @"sets", reps, @"reps", nil]];
        }
        if (![exs count]) continue;
        [out addObject:[NSDictionary dictionaryWithObjectsAndKeys:[LFStore newId], @"id", ([r objectForKey:@"name"] ?: @"Routine"), @"name", exs, @"exercises", nil]];
    }
    if (![out count]) { if (err) *err = @"The model picked no known exercises."; return nil; }
    return out;
}
@end
