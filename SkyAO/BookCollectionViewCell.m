//
//  BookCollectionViewCell.m
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/15.
//

#import "BookCollectionViewCell.h"

@implementation BookCollectionViewCell
@synthesize bookCode,isInit;

-(id)init {
    self = [super init];
    if(self){
        bookCode = -1;
        isInit = false;
    }
    return self;
}

@end
