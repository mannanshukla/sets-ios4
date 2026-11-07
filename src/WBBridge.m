#import "WBBridge.h"
#import "ORJSON.h"
#import <TargetConditionals.h>
#include <math.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif
#ifndef WB_BOARD_NAME
#define WB_BOARD_NAME @"com.mshukla.sets.meals.weights.v1"
#endif
static BOOL num(id v,double low,double high) { return [v isKindOfClass:[NSNumber class]]&&isfinite([v doubleValue])&&[v doubleValue]>=low&&[v doubleValue]<=high; }
static NSDateFormatter *dateFormat(void) { NSMutableDictionary *d=[[NSThread currentThread] threadDictionary];NSDateFormatter *f=[d objectForKey:@"WBDateFormatter"];if(!f) { f=[[[NSDateFormatter alloc] init] autorelease];f.locale=[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];f.calendar=[[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];f.dateFormat=@"yyyy-MM-dd";f.lenient=NO;[d setObject:f forKey:@"WBDateFormatter"]; }f.timeZone=[NSTimeZone localTimeZone];return f; }
NSString *WBDay(NSDate *date) { return [dateFormat() stringFromDate:date]; }
BOOL WBValidDay(id value) { if(![value isKindOfClass:[NSString class]]||[value length]!=10)return NO;NSDate *date=[dateFormat() dateFromString:value];return date&&[WBDay(date) isEqual:value]; }
NSArray *WBCanonicalRows(id rows,BOOL useKg) {
 if(![rows isKindOfClass:[NSArray class]]||[rows count]>10000)return nil;NSMutableArray *out=[NSMutableArray array];
 for(id r in rows) { if(![r isKindOfClass:[NSDictionary class]]||!num([r objectForKey:@"t"],0,4102444800)||!num([r objectForKey:@"w"],0,10000))return nil;
  id kg=[r objectForKey:@"kg"];if(!kg)kg=[NSNumber numberWithDouble:[[r objectForKey:@"w"] doubleValue]*(useKg?1:.45359237)];if(!num(kg,0,5000))return nil;
  NSString *day=[r objectForKey:@"day"]?:WBDay([NSDate dateWithTimeIntervalSince1970:[[r objectForKey:@"t"] doubleValue]]);if(!WBValidDay(day))return nil;
  NSMutableDictionary *c=[NSMutableDictionary dictionaryWithDictionary:r];[c setObject:kg forKey:@"kg"];[c setObject:day forKey:@"day"];[out addObject:c];
 }return out;
}
NSDictionary *WBSnapshot(NSArray *rows,BOOL enabled,NSDate *now) {
 if(!rows)return nil;NSMutableDictionary *days=[NSMutableDictionary dictionary];NSString *today=WBDay(now);NSUInteger skipped=0;
 if(enabled)for(NSDictionary *r in rows) { NSString *day=[r objectForKey:@"day"];if(!WBValidDay(day)||!num([r objectForKey:@"kg"],20,500)||[day compare:today]==NSOrderedDescending) { skipped++;continue; }
  NSDictionary *old=[days objectForKey:day];if(!old||[[r objectForKey:@"t"] doubleValue]>=[[old objectForKey:@"t"] doubleValue])[days setObject:@{@"day":day,@"kg":[r objectForKey:@"kg"],@"t":[r objectForKey:@"t"]} forKey:day];
 }
 NSArray *weights=[[days allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"day" ascending:YES]]];
 return @{@"version":@1,@"source":@"com.mshukla.sets",@"enabled":[NSNumber numberWithBool:enabled],@"updated":[NSNumber numberWithDouble:[now timeIntervalSince1970]],@"weights":weights,@"skipped":[NSNumber numberWithUnsignedInteger:skipped]};
}
BOOL WBValidSnapshot(id v) {
 if(![v isKindOfClass:[NSDictionary class]]||![[v objectForKey:@"source"] isEqual:@"com.mshukla.sets"]||!num([v objectForKey:@"version"],1,1)||!num([v objectForKey:@"enabled"],0,1)||!num([v objectForKey:@"updated"],0,4102444800)||!num([v objectForKey:@"skipped"],0,10000))return NO;
 id rows=[v objectForKey:@"weights"];if(![rows isKindOfClass:[NSArray class]]||[rows count]>10000||(![[v objectForKey:@"enabled"] boolValue]&&[rows count]))return NO;NSMutableSet *seen=[NSMutableSet set];
 for(id r in rows) { if(![r isKindOfClass:[NSDictionary class]]||!WBValidDay([r objectForKey:@"day"])||!num([r objectForKey:@"kg"],20,500)||!num([r objectForKey:@"t"],0,4102444800)||[seen containsObject:[r objectForKey:@"day"]])return NO;[seen addObject:[r objectForKey:@"day"]]; }return YES;
}
void WBPublish(NSDictionary *snapshot) {
#if TARGET_OS_IPHONE
 if(!WBValidSnapshot(snapshot))return;NSData *data=[[ORJSON stringify:snapshot] dataUsingEncoding:NSUTF8StringEncoding];if([data length]>2*1024*1024)return;
 UIPasteboard *board=[UIPasteboard pasteboardWithName:WB_BOARD_NAME create:YES];board.persistent=YES;[board setData:data forPasteboardType:@"com.mshukla.weight-snapshot-v1"];
#endif
}
NSDictionary *WBRead(void) {
#if TARGET_OS_IPHONE
 NSData *data=[[UIPasteboard pasteboardWithName:WB_BOARD_NAME create:NO] dataForPasteboardType:@"com.mshukla.weight-snapshot-v1"];if(![data length]||[data length]>2*1024*1024)return nil;id value=[ORJSON parse:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];return WBValidSnapshot(value)?value:nil;
#else
 return nil;
#endif
}
