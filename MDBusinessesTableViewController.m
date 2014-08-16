//
//  MDBusinessesTableViewController.m
//  MapsDirections
//
//  Created by Ben Roy on 5/31/14.
//  Copyright (c) 2014 Google. All rights reserved.
//

#import "MDBusinessesTableViewController.h"
#import "MDBusiness.h"

@interface MDBusinessesTableViewController ()

@end

@implementation MDBusinessesTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //[self loadInitialData];
  
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) loadInitialData
{
    MDBusiness * bus = [[MDBusiness alloc] init];
    bus.name = @"Torchys";
    bus.rating = 4.5;
    bus.numRatings = 10;
    [self.busninesses addObject:bus];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.busninesses count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
    
    UILabel * nameLabel       = (UILabel *)[cell viewWithTag:1];
    UIImage * cellImage       = ((UIImageView *)[cell viewWithTag:2]).image;
    UILabel * reviewsLabel    = (UILabel *)[cell viewWithTag:3];
    UILabel * addressLabel    = (UILabel *)[cell viewWithTag:4];
    UILabel * categoriesLabel = (UILabel *)[cell viewWithTag:5];
//    UILabel * distanceLabel   = (UILabel *)[cell viewWithTag:6];
//    UILabel * priceLabel      = (UILabel *)[cell viewWithTag:7];
    
    // Configure the cell...
    MDBusiness * busniness = [self.busninesses objectAtIndex:indexPath.row];
    nameLabel.text = busniness.name;
    reviewsLabel.text = [NSString stringWithFormat:@"%lu Reviews", busniness.numRatings];
    addressLabel.text = busniness.address;
    categoriesLabel.text = busniness.categories;
    
    float offset = (busniness.rating -1) * 2;
    
    
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"stars_map" ofType:@"png"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:thePath];
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    CIImage *croppedImage = [ciImage imageByCroppingToRect:CGRectMake(0, 290 - (offset * 19), 84, 16)];

    //CIImage *croppedImage = [ciImage imageByCroppingToRect:CGRectMake(0, 112 - (offset * 14), 49, 9)];

    cellImage = image;//[[UIImage alloc] initWithCIImage:croppedImage];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"i tapped that yo");
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"i was selected");
//    // Navigation logic may go here, for example:
//    // Create the next view controller.
//    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
//    
//    // Pass the selected object to the new view controller.
//    
//    // Push the view controller.
//    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end
