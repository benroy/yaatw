//
//  MDBusiness.h
//  MapsDirections
//
//  Created by Ben Roy on 5/31/14.
//  Copyright (c) 2014 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDBusiness : NSObject

@property NSString * name;
@property double rating;
@property unsigned long numRatings;
@property NSString * address;
@property NSString * categories;
@property double distance;
@property UInt8 price;
@end
