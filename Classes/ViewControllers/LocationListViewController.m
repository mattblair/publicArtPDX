//
//  LocationListViewController.m
//  pdxPublicArt
//
//  Created by Matt Blair on 11/28/10.
//  Copyright 2010 Elsewise LLC.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this 
//     list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, 
//     this list of conditions and the following disclaimer in the documentation 
//     and/or other materials provided with the distribution.
//  * Neither the name of Elsewise LLC nor the names of its contributors may be 
//     used to endorse or promote products derived from this software without 
//     specific prior written permission.
// 
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR 
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "LocationListViewController.h"
#import "Art.h"
#import "ArtDetailViewController.h"


@implementation LocationListViewController

@synthesize latitude, longitude, artworkArray, currentSearchString, filteredBySearch;

// for Core Data
@synthesize managedObjectContext=managedObjectContext_;


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
 
	// Add Show All button if needed
	
	if ([self filteredBySearch]) {

		// config show all button
		UIBarButtonItem *showAllButton = [[[UIBarButtonItem alloc] initWithTitle:@"Show All" 
																		   style:UIBarButtonItemStyleBordered
																		  target:self
																		  action:@selector(removeSearchFilter:)] autorelease];
		
		self.navigationItem.rightBarButtonItem = showAllButton;
		
	}
	
	
	[self fetchArtList];
	
	
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark List Management

// will change in v1.1
- (void)fetchArtList {
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Art" inManagedObjectContext:self.managedObjectContext]];
	
	NSPredicate *predicate;
	
	// conditionally set the predicate
	
	if ([self filteredBySearch]) {
		
		// search predicate based on location and search term
		
		//NSLog(@"Will run a search for %@ at %@ and %@", self.currentSearchString, self.latitude, self.longitude);
		
		predicate = [NSPredicate predicateWithFormat:@"latitude=%@ AND longitude=%@ AND ((title contains[cd] %@) OR (artists contains[cd] %@))", 
					 self.latitude, self.longitude, self.currentSearchString, self.currentSearchString];
		
	}
	else {
		
		// build a list based on the coordinates
		
		//NSLog(@"Will run a search for %@ and %@", self.latitude, self.longitude);
		
		predicate = [NSPredicate predicateWithFormat:@"latitude=%@ AND longitude=%@", self.latitude, self.longitude];
		
	}
	
	[fetchRequest setPredicate:predicate];
	
	NSMutableArray *sortDescriptors = [NSMutableArray array];
    [sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease]];
    [fetchRequest setSortDescriptors:sortDescriptors];

	
	[fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"latitude", @"longitude", @"title", @"discipline", @"location", @"artists", @"couchID", nil]];
	
	NSError *error = nil;
    self.artworkArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (self.artworkArray == nil)
    {
        // an error occurred
        NSLog(@"Fetch request returned nil. Error: %@, %@", error, [error userInfo]);
    }
	
	//NSLog(@"Found %d works of art to add to the list", [self.artworkArray count]);
	
	[fetchRequest release];
	
}


- (IBAction)removeSearchFilter:(id)sender {
	
	self.filteredBySearch = NO;
	
	// update UI (can't animate because it is not a UIView subclass...)
	
	self.navigationItem.rightBarButtonItem = nil;
	
	// re-run the search 
	[self fetchArtList];
	
	// reload data
	[self.tableView reloadData];
	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;  // do sections by discipline?
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.artworkArray count];
}


// These two functions added to provide visual indication of search filtering

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	if ([self filteredBySearch]) {
		return [NSString stringWithFormat:@"Filtered by \"%@\"", [self currentSearchString]];
	}
	else {
		return nil;
	}

}

// Might put count here in the future, but it would require running another Core Data fetch, sans search term. 
// Is it really worth it?

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

	if ([self filteredBySearch]) {
		return @"Put count here?";
	}
	else {
		return nil;
	}

	
}
 */


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	
	Art *theArt = [artworkArray objectAtIndex:indexPath.row];
	
	cell.textLabel.text = [theArt title];
	cell.detailTextLabel.text = [theArt artists];

	
	// Add either pin image or artwork thumbnail here
	// NOTE: Thumbnails will not ship in v1.0, and may never, for IP reasons...
	
	// Copied directly from Map VC's mapView:viewForAnnotation, and needs to be kept in sync manually for now.
	// Refactor to use plist in v1.1.
	
	UIImage *thePin;
	
	NSString *theAccessibilityLabel;
	
	
	if ([[theArt discipline] isEqualToString:@"sculpture"]) {
		thePin = [UIImage imageNamed:@"pinPurple"];
		theAccessibilityLabel = @"Sculpture";
	}
	else if ([[theArt discipline] isEqualToString:@"painting"]) {  // how often will this even appear?
		thePin = [UIImage imageNamed:@"pinCyanLess"];
		theAccessibilityLabel = @"Painting";
	}
	else if ([[theArt discipline] isEqualToString:@"photography"]) {
		thePin = [UIImage imageNamed:@"pinDarkGray"];
		theAccessibilityLabel = @"Photograph";
	}
	else if ([[theArt discipline] isEqualToString:@"ceramics"]) {
		thePin = [UIImage imageNamed:@"pinBrown"];
		theAccessibilityLabel = @"Ceramic";
	}
	else if ([[theArt discipline] isEqualToString:@"fiber"]) {
		thePin = [UIImage imageNamed:@"pinLightGray"];
		theAccessibilityLabel = @"Fiber art";
	}
	else if ([[theArt discipline] isEqualToString:@"architectural integration"]) {
		thePin = [UIImage imageNamed:@"pinOrange"];
		theAccessibilityLabel = @"Architectural Integration";
	}
	else if ([[theArt discipline] isEqualToString:@"mural"]) {
		thePin = [UIImage imageNamed:@"pinRed"];
		theAccessibilityLabel = @"Mural";
	}
	else if ([[theArt discipline] isEqualToString:@"fountain"]) {
		thePin = [UIImage imageNamed:@"pinBlue"];
		theAccessibilityLabel = @"Fountain";
	}
	
	else { //an individual work in a nonstandard disicipline, NOT a multiple!
		thePin = [UIImage imageNamed:@"pinGreen"];
		theAccessibilityLabel = @"Other discipline";
	}
	

	cell.imageView.image = thePin;
	[cell.imageView setAccessibilityLabel:theAccessibilityLabel];
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	
	ArtDetailViewController *artVC = [[ArtDetailViewController alloc] initWithNibName:@"ArtDetailViewControllerSV" bundle:nil];
	
	// Art VC will fetch data based on ID
	
	artVC.couchID = [[[self artworkArray] objectAtIndex:indexPath.row] couchID];
	
	artVC.managedObjectContext = self.managedObjectContext;
	
	artVC.hidesBottomBarWhenPushed = YES;
	
	[self.navigationController pushViewController:artVC animated:YES];
	
	[artVC release];
	
	
	// boilerplate. Can be deleted.
	
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	
	[latitude release];
	[longitude release];
	
	[artworkArray release];
	
	[currentSearchString release];
	
	[managedObjectContext_ release];
	
    [super dealloc];
}


@end

