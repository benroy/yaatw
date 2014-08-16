//
//  MDViewController.m
//  MapsDirections
//
//  Created by Mano Marks on 4/8/13.
//  Copyright (c) 2013 Google. All rights reserved.
//

#import "MDViewController.h"
#import "MDDirectionService.h"
#import "MDBusiness.h"
#import "MDBusinessesTableViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import <YAJL/YAJL.h>
#import "OAConsumer.h"
#import "OAToken.h"
#import "OAHMAC_SHA1SignatureProvider.h"
#import "OAMutableURLRequest.h"

@interface MDBox : NSObject
@property int point;
@property NSMutableData * responseData;
@end
@implementation MDBox
@end

@interface MDViewController () {
    GMSMapView *mapView_;
    NSMutableArray *waypoints_;
    NSMutableArray *waypointStrings_;
//    NSMutableData *_responseData;
    NSMutableArray * businesses_;
    __weak IBOutlet UIBarButtonItem *listButton;
    __weak IBOutlet UIBarButtonItem *clearButton;
    NSMutableDictionary * boxes_;
}
@end



@implementation MDViewController

- (IBAction)clearButton:(id)sender {
    [waypoints_ removeAllObjects];
    [waypointStrings_ removeAllObjects];
    [businesses_ removeAllObjects];
    [mapView_ clear];
    [listButton setEnabled:NO];
    [clearButton setEnabled:NO];
}

- (void)loadView {
    waypoints_ = [[NSMutableArray alloc]init];
    waypointStrings_ = [[NSMutableArray alloc]init];
    boxes_ = [[NSMutableDictionary alloc] init];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:31.9196101
                                                            longitude:-95.3287019
                                                                 zoom:7];
    mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView_.delegate = self;
    self.view = mapView_;
    
    businesses_ = [[NSMutableArray alloc] init];
    [listButton setEnabled:NO];
    [clearButton setEnabled:NO];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MDBusinessesTableViewController * mbtvc = [segue destinationViewController];
    mbtvc.busninesses = businesses_;
    
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:
(CLLocationCoordinate2D)coordinate {
    
    if ([waypoints_ count] >= 2) {
        return;
    }

    [clearButton setEnabled:YES];

    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(
                                                                 coordinate.latitude,
                                                                 coordinate.longitude);
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.map = mapView_;
    [waypoints_ addObject:marker];
    NSString *positionString = [[NSString alloc] initWithFormat:@"%f,%f",
                                coordinate.latitude,coordinate.longitude];
    [waypointStrings_ addObject:positionString];
    if([waypoints_ count]>1){
        NSString *sensor = @"false";
        NSArray *parameters = [NSArray arrayWithObjects:sensor, waypointStrings_,
                               nil];
        NSArray *keys = [NSArray arrayWithObjects:@"sensor", @"waypoints", nil];
        NSDictionary *query = [NSDictionary dictionaryWithObjects:parameters
                                                          forKeys:keys];
        MDDirectionService *mds=[[MDDirectionService alloc] init];
        SEL selector = @selector(addDirections:);
        [mds setDirectionsQuery:query
                   withSelector:selector
                   withDelegate:self];
    }
}

/**
 This is the callback that handles the results from the query to the direction service. The results contain a route which is a series of points.
 We loop through the points until we find a pair that are at least 0.1 degree (~6 miles) apart. Then we create a box that is atleast
 0.1 degrees square, centered on the two (aforementioned) points. Then we use this box for the bounding coordinates of a yelp search.
 Repeat until we run out of points in the path.
 */
- (void)addDirections:(NSDictionary *)json {
    
    // Pull the results out
    NSDictionary *routes         = [json   objectForKey:@"routes"][0];
    NSDictionary *route          = [routes objectForKey:@"overview_polyline"];
    NSString     *overview_route = [route  objectForKey:@"points"];
    

    // Draw the directions on the map
    GMSPath *path = [GMSPath pathFromEncodedPath:overview_route];
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeWidth = 2;
    polyline.map = mapView_;
    
    
    // Initialize the array of yelp search boxes and businesses
    [boxes_ removeAllObjects];
    [businesses_ removeAllObjects];
    
    
    // Each yelp search box is defined by two points (opposite corners of the box)
    CLLocationCoordinate2D first = {0,0}, last = {0,0};
    

    // I'm not sure why I made the condition iPoint+1, or futher down why last = ... iPoint+1
    // But if I do what seems correct (remove the +1 in both cases), the boxes are no longer tightly packed
    // right next to each other (?!). I need to spend some time to figure out why. For now it works.
    for (int iPoint = 0; iPoint + 1 < path.count; iPoint++) {
        
        // The first corner is just the first point we come across.
        // We know this is the first (i.e. we haven't come across one yet) if it still has it's initial value of (0,0)
        if (first.latitude == 0 && first.longitude == 0) {
            first = [path coordinateAtIndex:iPoint];
        }
        
        // If we already have a first point, consider this one the last
        last  = [path coordinateAtIndex:iPoint+1];
        
        // If first and last are too close, keep searching for a more distant last
        if (ABS(first.longitude - last.longitude) < 0.1 &&
            ABS(first.latitude - last.latitude) < 0.1) {
            continue;
        }
        
        // Expand the box so that it's at least 0.1 degrees (~6 miles) on both sides
        CLLocationCoordinate2D topLeft, topRight, botLeft, botRight;
        topLeft.latitude   = MIN(first.latitude,  last.latitude);
        topLeft.longitude  = MIN(first.longitude, last.longitude);
        botRight.latitude  = MAX(first.latitude,  last.latitude);
        botRight.longitude = MAX(first.longitude, last.longitude);
        
        double height = botRight.latitude - topLeft.latitude;
        if (height < 0.1) {
            topLeft.latitude -= (0.1 - height) / 2.0;
            botRight.latitude += (0.1 - height) / 2.0;
        }
        
        double width = botRight.longitude - topLeft.longitude;
        if (width < 0.1) {
            topLeft.longitude -= (0.1 - width) / 2.0;
            botRight.longitude += (0.1 - width) / 2.0;
        }
        
        topRight.latitude  = topLeft.latitude;
        topRight.longitude = botRight.longitude;
        botLeft.latitude   = botRight.latitude;
        botLeft.longitude  = topLeft.longitude;
        
        // Draw the box on the map
        GMSPolygon *polygon = [[GMSPolygon alloc] init];
        GMSMutablePath *polyPath = [GMSMutablePath path];
        [polyPath addCoordinate:topRight];
        [polyPath addCoordinate:topLeft];
        [polyPath addCoordinate:botLeft];
        [polyPath addCoordinate:botRight];
        polygon.path = polyPath;
        polygon.fillColor = [UIColor colorWithRed:0.25 green:0 blue:0 alpha:0.2f];
        polygon.strokeColor = [UIColor blackColor];
        polygon.strokeWidth = 1;
        polygon.map = mapView_;
        
        // Make a yelp query with the box coordinates and the bounds
        NSString *bounds = [NSString stringWithFormat:@"bounds=%f,%f|%f,%f",
                            topLeft.latitude,
                            topLeft.longitude,
                            botRight.latitude,
                            botRight.longitude];
        
        NSString *url = [NSString stringWithFormat:@"http://api.yelp.com/v2/search?term=food&sort=2&%@", bounds];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *URL = [NSURL URLWithString:url];
        
        OAConsumer *consumer = [[OAConsumer alloc]
                                initWithKey:@"cUwnjo94ZS_izMC-G6Ustg"
                                     secret:@"_Buh6xBNIfn4V1jB6yg77JXrZpY"];
        
        OAToken *token = [[OAToken alloc]
                          initWithKey:@"3cQhT-kzaRhsFIUZ3ey0Huuxr9ie7RKm"
                            secret:@"DkonrAZa-nb7GFo_S7WF2qXP1RI"];
        
        id<OASignatureProviding, NSObject> provider = [[OAHMAC_SHA1SignatureProvider alloc] init];
        NSString *realm = nil;
        
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:URL
                                                                       consumer:consumer
                                                                          token:token
                                                                          realm:realm
                                                              signatureProvider:provider];
        [request prepare];
        
        MDBox * box = [[MDBox alloc] init];
        box.responseData = [[NSMutableData alloc] init];
        box.point = iPoint;
        
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        [boxes_ setObject:box forKey:request];
        
        // reset first to sentinel value
        first.longitude = 0;
        first.latitude = 0;
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    MDBox * box = [boxes_ objectForKey:[connection originalRequest]];
    
    if (box == nil) {
        NSLog(@"Could not find box for %@", [[connection originalRequest] URL]);
        return;
    }
                   
    NSLog(@"%04d - did receive response", box.point);
    [box.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    MDBox * box = [boxes_ objectForKey:[connection originalRequest]];
    
    if (box == nil) {
        NSLog(@"Could not find box for %@", [[connection originalRequest] URL]);
        return;
    }
    
    [box.responseData appendData:data];

    NSLog(@"%04d - received %lu bytes of data (%lu total)",
          box.point,
          [data length],
          [box.responseData length]);
    
    NSError* error = nil;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:box.responseData
                          options:kNilOptions
                          error:&error];
    
    
    if (error) {
        NSLog(@"%04d - Bad json: %@",
              box.point,
              [error.userInfo objectForKey:@"NSDebugDescription"]);
    }
    
    else if (json == nil) {
        NSLog(@"%04d - json is nil",
              box.point);
    }
    
    else if (json != nil) {
        NSLog(@"%04d - json is fine",
              box.point);
        NSDictionary *region = [json objectForKey:@"region"];
        NSDictionary *regionCenter = [region objectForKey:@"center"];
        NSArray * businesses = [json objectForKey:@"businesses"];
        unsigned long busCount = [businesses count];
        
        if (busCount == 0) {
            return;
        }
        
        [listButton setEnabled:YES];
        
        CLLocationDegrees rcLat = [(NSString *)[regionCenter objectForKey:@"latitude"] doubleValue];
        CLLocationDegrees rcLon = [(NSString *)[regionCenter objectForKey:@"longitude"] doubleValue];
        
        GMSMarker *marker;
        marker = [[GMSMarker alloc] init];
        marker.title = [NSString stringWithFormat:@"%lu restaurants", busCount];
        marker.position = CLLocationCoordinate2DMake(rcLat, rcLon);
        marker.snippet = @"";
        
        for (int iBus = 0; iBus < [businesses count]; iBus++) {
            NSDictionary *business   = [businesses objectAtIndex:iBus];
            NSDictionary *location   = [business objectForKey:@"location"];
            NSMutableArray *address = [[location objectForKey:@"display_address"] mutableCopy];
            NSMutableArray *categories = [[business objectForKey:@"categories"] mutableCopy];
            
            for (int iCat = 0; iCat < [categories count]; iCat++) {
                NSArray * nvPair = [categories objectAtIndex:iCat];
                NSString * name = nil;
                if (nvPair) {
                    name = [nvPair objectAtIndex:0];
                }
                [categories setObject:name atIndexedSubscript:iCat];
            }
            
            
            
            MDBusiness * bus = [[MDBusiness alloc] init];
            bus.name       = [business   objectForKey:@"name"];
            bus.rating     = [[business  objectForKey:@"rating"] doubleValue];
            bus.numRatings = [[business  objectForKey:@"review_count"] unsignedLongValue];
            bus.distance   = [[business  objectForKey:@"distance"] doubleValue];
            bus.price      = [[business  objectForKey:@"price"] integerValue];
            bus.address    = [address    componentsJoinedByString:@", "];
            bus.categories = [categories componentsJoinedByString:@", "];
            
            [businesses_ addObject:bus];
            
            NSString * busInfo = [NSString stringWithFormat:@"%@ - %.1f (%lu)\n",
                                  bus.name,
                                  bus.rating,
                                  bus.numRatings];
            
            marker.snippet = [marker.snippet stringByAppendingString:busInfo];
        }
        marker.map = mapView_;
        
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    MDBox * box = [boxes_ objectForKey:[connection originalRequest]];
    
    if (box == nil) {
        NSLog(@"Could not find box for %@", [[connection originalRequest] URL]);
        return;
    }

    NSLog(@"%04d - Error: %@, %@",
          box.point,
          [error localizedDescription],
          [error localizedFailureReason]);
    //[self notify:kGHUnitWaitStatusFailure forSelector:@selector(test)];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    MDBox * box = [boxes_ objectForKey:[connection originalRequest]];
    
    if (box == nil) {
        NSLog(@"Could not find box for %@", [[connection originalRequest] URL]);
        return;
    }

    NSLog(@"%04d - did finish loading",
          box.point);
    //[self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
