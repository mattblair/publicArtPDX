//
//  MapViewController.m
//  pdxPublicArt
//
//  Created by Matt Blair on 11/21/10.
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

#import "MapViewController.h"
#import "ArtAnnotation.h"
#import "LegendViewController.h"
#import "ArtDetailViewController.h"
#import "LocationListViewController.h"
#import "Place.h"
#import "Art.h"
#import "AboutViewController.h"
#import "databaseConstants.h"

#pragma mark -
#pragma mark constants	



// region for default view
#define kDefaultRegionLatitude 45.520764 //45.518978
#define kDefaultRegionLongitude -122.674987 //-122.676001

#define kDefaultRegionLatitudeDelta 0.020743 // 0.013832
#define kDefaultRegionLongitudeDelta 0.026834// 0.013733

// should be a walkable distance:
#define kCurrentLocationLatitudeDelta 0.011
#define kCurrentLocationLongitudeDelta 0.014

#define kSearchResultsLatitudeDeltaMultiplier 1.15
#define kSearchResultsLongitudeDeltaMultiplier 1.2

#define kLatitudeDeltaThreshold 0.03
#define kWidenMapViewIncrement 1.2


@implementation MapViewController

@synthesize artMapView, infoButton, refreshButton, locationButton, theSearchBar, locationManager, currentSearchString, filteredBySearch;
@synthesize managedObjectContext=managedObjectContext_;


#pragma mark -
#pragma mark User-initiated actions

- (IBAction)showAboutPage:(id)sender {
	
	AboutViewController *aboutVC = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
	
	aboutVC.hidesBottomBarWhenPushed = YES;
	
	[self.navigationController pushViewController:aboutVC animated:YES];
	
	[aboutVC release];
	
}

- (IBAction)refreshTheMap:(id)sender {
	
	// Is this the best place to clear the search?
	// Note: removeSearchFilter calls refreshArtOnMap
    [self removeSearchFilter];

	refreshButton.enabled = NO;
	
}

- (IBAction)showMapLegend:(id)sender {
	
	LegendViewController *legendVC = [[LegendViewController alloc] initWithNibName:@"LegendViewController" bundle:nil];
	
	legendVC.delegate = self;
	
	legendVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self presentModalViewController:legendVC animated:YES];
	
	[legendVC release];
	
}

- (void)legendViewControllerDidFinish:(LegendViewController *)controller {
	
	[self dismissModalViewControllerAnimated:YES];
	
}

// In future versions this will show a view controller for adding art, with photos	
- (IBAction)addNewArtwork:(id)sender {	
	
	if ([MFMailComposeViewController canSendMail]) {
		
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
		
		mailVC.mailComposeDelegate = self;
		
		NSString *messageBody = [NSString stringWithFormat:@"\n\n\n(Please describe the art you'd like to see added to this app, including its location. Thanks!)%@", 
								 kEmailFooter];
		
		[mailVC setSubject:@"Art to Add to the Collection"];
		[mailVC setToRecipients:[NSArray arrayWithObject:kSubmissionEmailAddress]];
		[mailVC setMessageBody:messageBody isHTML:NO];
		
		[self presentModalViewController:mailVC animated:YES];
		
	}
	else {
        
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail Not Available" 
														message:@"Please configure your device to send email and try again." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
}

- (IBAction)showSearch:(id)sender {
	
	if (!self.theSearchBar) {
		
		// init here, don't autorelease
		self.theSearchBar = [[UISearchBar alloc] initWithFrame:CGRectZero]; // will animate in...
		self.theSearchBar.delegate = self;
		
		self.theSearchBar.showsCancelButton = YES;
		self.theSearchBar.placeholder = @"Title or Artist";
		self.theSearchBar.barStyle = UIBarStyleBlack;

		// add it to the view
		[self.view addSubview:self.theSearchBar];

		
	}
	
	// add scope, if you can get it to change color:
	
	/*
	self.theSearchBar.showsScopeBar = YES;
	self.theSearchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"Title", @"Artists",@"Medium", nil];
	self.theSearchBar.selectedScopeButtonIndex = 1;
	*/
	
    
    // Display moved to this method in a previous design.
    // Might make sense to refactor and combine showSearch and displaySearchBar.
	[self displaySearchBar];
	
}

- (IBAction)goToLocation:(id)sender {

	// Retest on 4.3. I copied it from Trees, it seems to test fine in 4.0, 4.1 and 4.2
	
	
	// Tests for a truly valid current location. 
	// If available, sets newRegion to center on the current location. If not, sets newRegion to default.
	// Moves map to newRegion, and requests a re-population of the tree placemarks.
	

	MKCoordinateRegion newRegion;
	
	// set defaults for the current location criteria
	BOOL locationTurnedOn = [CLLocationManager locationServicesEnabled];  // not reliable in iOS 4.1? check locationReallyEnabled
	BOOL locationAccurateEnough = NO;
	BOOL locationInDataRadius = NO;
	
	if (locationTurnedOn) {
		
		
		// NSLog(@"Location services on...");
		
		// test and test the other two criteria
		
		CLLocation *currentLocation = [[self locationManager] location];
		
		NSDate *newLocationDate = currentLocation.timestamp;
		NSTimeInterval timeDiff = [newLocationDate timeIntervalSinceNow];
		
		
		// NSLog(@"Current location has an accuracy radius of %f meters.", currentLocation.horizontalAccuracy);
		
		// horizontal accuracy is a radius in meters. Is 100 too much? 
		// a negative value indicates an invalid coordinate
		
		// changed this to >= 2.0 because it is returning 0.0 on failure in iOS 4.1, not a negative number
		if ((abs(timeDiff) < 15.0) && (currentLocation.horizontalAccuracy < 201.0) && (currentLocation.horizontalAccuracy >= 2.0)) {
			
			locationAccurateEnough = YES;
			// NSLog(@"Current location is accurate enough.");
			
		}
		
		
		// Check whether it is in Portland area. Need to adjust as collection expands.
		
		// use CLLocation method: - (CLLocationDistance)distanceFromLocation:(const CLLocation *)location
		// returns a CLLocationDistance, which is meters as a double
		
		// TESTING ONLY -- since I can't go there, I'm testing with a center location well south of here
		//CLLocation *pdxCenterLocation = [[CLLocation alloc] initWithLatitude:40.530675 longitude:-122.626691];
		
		// production
		CLLocation *pdxCenterLocation = [[CLLocation alloc] initWithLatitude:45.530675 longitude:-122.626691];
		
		CLLocationDistance locationDiff = [currentLocation distanceFromLocation:pdxCenterLocation];
		
		// NSLog(@"Location difference is %f meters", locationDiff);
		
		if (locationDiff < 14000.0) {
			
			// they are less than 14k from rough center of Portland data
			locationInDataRadius = YES;
			
			// NSLog(@"Location is within 14km of data set's center.");
			
		}
		
		[pdxCenterLocation release];
		
		
		
		// added because of CL behavior in 4.1
		
		CLLocationCoordinate2D currentCoordinate = [currentLocation coordinate];
		
		// Series of crude bounds tests for far-away locations that return 0.0 from distanceFromLocation method
		// These should also be future-proof for when CL returns expected values
		
		if (currentCoordinate.latitude < 45.0 ) {  //i.e. if it is zero...
			locationInDataRadius = NO;
			// NSLog(@"Latitude was less than 45 degrees!");
		}
		
		if (currentCoordinate.latitude > 46.0 ) {  
			locationInDataRadius = NO;
			// NSLog(@"Latitude was more than 46 degrees!");
		}
		
		if (currentCoordinate.longitude < -123.0 ) {  
			locationInDataRadius = NO;
			// NSLog(@"Longitude was less than -123 degrees!");
		}
		
		if (currentCoordinate.longitude > -122.0 ) {  //i.e. if it is zero...
			locationInDataRadius = NO;
			// NSLog(@"Longitude was greater than -122 degrees!");
		}
		
	}
	
	
	// The locationReallyEnabled BOOL set to true if Core Location is on
	//   but then resets to False if Core Location fails with domain kCLErrorDomain
	// This was recommended in the dev forums as a way to handle CL behavior in 4.1
	
	if (locationTurnedOn && locationReallyEnabled && locationAccurateEnough && locationInDataRadius) {
		
		// NSLog(@"All criteria met to base region on User Location");
		
		// define region based on user location
		
		newRegion.center = [[[self locationManager] location] coordinate]; // handles lat/long
		
		newRegion.span.latitudeDelta = kCurrentLocationLatitudeDelta;  // originally 0.011
		
		newRegion.span.longitudeDelta = kCurrentLocationLongitudeDelta; // originally 0.014
		
	}
	
	else {		

		// NSLog(@"No acceptable/local location found. Using default region.");

		// default region

		newRegion.center.latitude = kDefaultRegionLatitude;
		
		newRegion.center.longitude = kDefaultRegionLongitude;
		
		newRegion.span.latitudeDelta = kDefaultRegionLatitudeDelta;
		
		newRegion.span.longitudeDelta = kDefaultRegionLongitudeDelta;
		
	}
	
	
	// NSLog(@"Moving to new region");
	
	// correct the aspect ratio -- is this the best way?
	MKCoordinateRegion fitRegion = [self.artMapView regionThatFits:newRegion];
	
    [self.artMapView setRegion:fitRegion animated:YES];
	
	// get rid of any text-based search filters
	[self removeSearchFilter];
	
	// commented because it is covered by removeSearchFilter -- add back in if you alter that method
	//[self refreshArtOnMap];
	
	// Disable location button

	self.locationButton.enabled = NO;
	self.refreshButton.enabled = NO;

}

#pragma mark -
#pragma mark UISearchBarDelegate and related methods
	
-(void)displaySearchBar {
	
	self.theSearchBar.showsCancelButton = YES;
	self.theSearchBar.hidden = NO;
	
	// animate in - unless that is still causing problems with the text field showing half itself below the nav bar
	
	//NSLog(@"about to animate in the search bar");
	
	[UIView animateWithDuration:0.8 animations:^ {
		self.theSearchBar.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 44.0); // 88 if scope bar added
	}];
		
	[self.theSearchBar becomeFirstResponder];
	
}

-(void)hideSearchBar {
	
	// ditch cancel button, or else it is left over the map?!
	
	self.theSearchBar.showsCancelButton = NO;
	
	// or animate to oblivion, but text field is half in view, so I'm just going to hide it for now
	/*
	[UIView animateWithDuration:0.5 animations:^ {
		self.theSearchBar.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 0.0);
	}];
	*/
	
	self.theSearchBar.hidden = YES;
	
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self.theSearchBar resignFirstResponder];
	
	//NSLog(@"the search term is: %@", self.theSearchBar.text);
	
	self.currentSearchString = self.theSearchBar.text;
	
	self.filteredBySearch = YES;
	
	[self hideSearchBar];
	
	[self refreshArtOnMap];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self.theSearchBar resignFirstResponder];
	
	[self removeSearchFilter];  // will also call refreshArtOnMap
	
	[self hideSearchBar];
}

-(void)removeSearchFilter {
	
	self.filteredBySearch = NO;
	
	// if there is a show all button or some kind of filter indicator, hide/remove it here
	
	
	// shrink the region here if it is greater than x
	
	if (artMapView.region.span.latitudeDelta > 0.02) {
		
		MKCoordinateRegion zoomedRegion;
		
		//reset latitude and longitude to standard, leaving center as is
		zoomedRegion.center.latitude = artMapView.region.center.latitude;
		zoomedRegion.center.longitude = artMapView.region.center.longitude;
		zoomedRegion.span.latitudeDelta = kCurrentLocationLatitudeDelta;
		zoomedRegion.span.longitudeDelta = kCurrentLocationLongitudeDelta;
		
		MKCoordinateRegion fitRegion = [self.artMapView regionThatFits:zoomedRegion];
		
		[self.artMapView setRegion:fitRegion animated:YES];
	
	}
	
	[self refreshArtOnMap];
	
}

/*

 NOTE: In v1.0, this method translates the artwork search results into an array
 of places based on coordinates -- which, of course, are floats, and are not 
 reliable identifiers. This is one of those quick hacks that took on a life 
 of its own. It will change in v1.1, pending changes to the data management 
 scripts and integration of other data sets.
 
*/

-(NSArray *)fetchPlaceArrayForSearch {
	
	NSArray *fetchedPlaces;
	
	// get the places for the current search and return an array of place objects
	
	NSFetchRequest *artFetchRequest = [[NSFetchRequest alloc] init];
    [artFetchRequest setEntity:[NSEntityDescription entityForName:@"Art" inManagedObjectContext:self.managedObjectContext]];
	
    // Appending [cd] makes the search case-insensitive and diacritic-insensitive
	NSPredicate *artPredicate = [NSPredicate predicateWithFormat:@"(title contains[cd] %@) OR (artists contains[cd] %@)", self.currentSearchString, self.currentSearchString];
	
	[artFetchRequest setPredicate:artPredicate];
	
	
    NSMutableArray *sortDescriptors = [NSMutableArray array];
    [sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"latitude" ascending:YES] autorelease]];
    [sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"longitude" ascending:YES] autorelease]];
    [artFetchRequest setSortDescriptors:sortDescriptors];

    // let it return the objects as faults
	//[artFetchRequest setReturnsObjectsAsFaults:NO];
	
	// added discipline and location so they don't have to be faulted
    [artFetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"latitude", @"longitude", @"title", @"discipline", @"location", @"artists", @"couchID", nil]];
    NSError *error = nil;
    NSArray *fetchedArtItems = [self.managedObjectContext executeFetchRequest:artFetchRequest error:&error];
	
	if (fetchedArtItems == nil)
    {
        // an error occurred
        NSLog(@"Fetch request for search term returned nil. Error: %@, %@", error, [error userInfo]);
    }
		
	[artFetchRequest release];
	
	if ([fetchedArtItems count] > 0) {
		
		// pull places for those items
		//NSLog(@"fetchPlaceArrayForSearch found %d artworks.", [fetchedArtItems count]);
		
		NSFetchRequest *placeFetchRequest = [[NSFetchRequest alloc] init];
		[placeFetchRequest setEntity:[NSEntityDescription entityForName:@"Place" inManagedObjectContext:self.managedObjectContext]];
		
		NSMutableArray *placesCollection = [[NSMutableArray alloc] initWithCapacity:0];
		
		for (Art *theArt in fetchedArtItems) {
			
			// search among Place entities, add any found to the list
		
			
			NSPredicate *placePredicate = [NSPredicate predicateWithFormat:@"latitude==%@ AND longitude==%@", theArt.latitude, theArt.longitude];
			
			[placeFetchRequest setPredicate:placePredicate];
			
			
			NSMutableArray *sortDescriptors = [NSMutableArray array];
			[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"latitude" ascending:YES] autorelease]];
			[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"longitude" ascending:YES] autorelease]];
			[placeFetchRequest setSortDescriptors:sortDescriptors];
			[placeFetchRequest setReturnsObjectsAsFaults:NO];
			[placeFetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"latitude", @"longitude", @"title", @"artists", @"couchID", nil]];
			NSError *error = nil;
			NSArray *somePlaces = [self.managedObjectContext executeFetchRequest:placeFetchRequest error:&error];
			
			// add somePlaces to accumulating array
			
			if ([somePlaces count] > 0) {
				
				//NSLog(@"Found %d places for lat %@ long %@", [somePlaces count], theArt.latitude, theArt.longitude); // should always be 1
				// add it to placesCollection
				[placesCollection addObjectsFromArray:somePlaces];
			}
			
		}
		

		// add to fetchedPlaces list
		fetchedPlaces = [NSArray arrayWithArray:placesCollection];
		
		
		[placesCollection release];
		[placeFetchRequest release];
		
	}
	else { // nothing fetched
		
		NSLog(@"Didn't find any art for search term");
		
		// return an empty array
		fetchedPlaces = [NSArray array];
		
	}

	//NSLog(@"fetchPlaceArrayForSearch is about to return %d places.", [fetchedPlaces count]);
	
	return fetchedPlaces;
	
}



#pragma mark -
#pragma mark MKMapView Delegate Methods

- (void)mapView:(MKMapView *)map regionDidChangeAnimated:(BOOL)animated {
	
	//enable the refresh and location buttons
	
	refreshButton.enabled = YES;
	locationButton.enabled = YES;
	
	// uncomment this to see every region change in the console

	/*
	 NSLog(@"Map view changed to new region...");
	 NSLog(@"This region's latitude is: %f", map.region.center.latitude);
	 NSLog(@"This region's longitude is: %f", map.region.center.longitude);
	 NSLog(@"This region's latitude delta is: %f", map.region.span.latitudeDelta);
	 NSLog(@"This region's longitude delta is: %f", map.region.span.longitudeDelta);
	 */
	
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
	
	
	
	//NSLog(@"Creating a pin for an artwork...");
	
	// Create different annotations based on discipline
	
	// Try to dequeue an existing pin view first.
	MKAnnotationView* annoView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomAnnotationView"];
	
	if (!annoView)
	{
		// If an existing pin view was not available, create one.
		annoView = [[[MKAnnotationView alloc] initWithAnnotation:annotation
												 reuseIdentifier:@"CustomAnnotationView"] autorelease];
		
		annoView.canShowCallout = YES;
	
		// Add a detail disclosure button to the callout
		UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		
		annoView.rightCalloutAccessoryView = rightButton;
		
		// correct for the images, based on:
		// http://stackoverflow.com/questions/1185611/mkpinannotationview-are-there-more-than-three-colors-available/2945217#2945217
		annoView.centerOffset = CGPointMake(7,-15);
        annoView.calloutOffset = CGPointMake(-8,0);
		
		
	}
	
	// change image after the conditional alloc/init/config
	
	UIImage *thePin;
	
	NSString *theAccessibilityLabel;
	
	ArtAnnotation *aa = (ArtAnnotation *)annotation;
	
    // Once all the negotiation about map representation is settled for v1.1,
    //   move this into a plist keyed to a field in the Place data model, and 
    //   replace this if-else cobweb...
	
	if ([[aa discipline] isEqualToString:@"sculpture"]) {
		thePin = [UIImage imageNamed:@"pinPurple"];
		theAccessibilityLabel = @"Sculpture";
	}
	else if ([[aa discipline] isEqualToString:@"painting"]) {  // how often will this even appear?
		thePin = [UIImage imageNamed:@"pinCyanLess"];
		theAccessibilityLabel = @"Painting";
	}
	else if ([[aa discipline] isEqualToString:@"photography"]) {
		thePin = [UIImage imageNamed:@"pinDarkGray"];
		theAccessibilityLabel = @"Photograph";
	}
	else if ([[aa discipline] isEqualToString:@"ceramics"]) {
		thePin = [UIImage imageNamed:@"pinBrown"];
		theAccessibilityLabel = @"Ceramic";
	}
	else if ([[aa discipline] isEqualToString:@"fiber"]) {
		thePin = [UIImage imageNamed:@"pinLightGray"];
		theAccessibilityLabel = @"Fiber art";
	}
	else if ([[aa discipline] isEqualToString:@"architectural integration"]) {
		thePin = [UIImage imageNamed:@"pinOrange"];
		theAccessibilityLabel = @"Architectural Integration";
	}
	else if ([[aa discipline] isEqualToString:@"mural"]) {
		thePin = [UIImage imageNamed:@"pinRed"];
		theAccessibilityLabel = @"Mural";
	}
	else if ([[aa discipline] isEqualToString:@"fountain"]) {
		thePin = [UIImage imageNamed:@"pinBlue"];
		theAccessibilityLabel = @"Fountain";
	}

	else {
		thePin = [UIImage imageNamed:@"pinGreen"];
		theAccessibilityLabel = @"Multiple works of art";
	}
	
	annoView.image = thePin;
	[annoView setAccessibilityLabel:theAccessibilityLabel];
	
	
	return annoView;
	
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	
	ArtAnnotation *selectedArt = view.annotation;
	
	//NSLog(@"The discipline of the selected work is: %@", [selectedArt discipline]);
	

	if ([[selectedArt discipline] isEqualToString:@"multiple"]) {
			
		LocationListViewController *listVC = [[LocationListViewController alloc] initWithNibName:@"LocationListViewController" bundle:nil];
		
		// set the coordinates to use for searching -- will also change in 1.1
		
		listVC.latitude = [selectedArt latitude];
		listVC.longitude = [selectedArt longitude];
		
		if ([self filteredBySearch]) {  
			listVC.filteredBySearch = YES;
			listVC.currentSearchString = [self currentSearchString];
		}
		
		listVC.managedObjectContext = self.managedObjectContext;
		
		listVC.hidesBottomBarWhenPushed = YES;
		
		[self.navigationController pushViewController:listVC animated:YES];
		
		[listVC release];
		
	}
	else {
		
		//NSLog(@"The ID of the selected artwork is: %@", [selectedArt artID]);
		
		ArtDetailViewController *artVC = [[ArtDetailViewController alloc] initWithNibName:@"ArtDetailViewControllerSV" bundle:nil];
		
		// Just pass the id to the art VC. It will fetch data.
		
		artVC.couchID = [selectedArt artID];
		
		if (!self.managedObjectContext) {
			NSLog(@"The Map's moc is still nil, so it can't be passed to the art VC");
		}
		
		artVC.managedObjectContext = self.managedObjectContext;
		
		artVC.hidesBottomBarWhenPushed = YES;
		
		[self.navigationController pushViewController:artVC animated:YES];
		
		[artVC release];
	}

}


// This method added to animate pin drops only. I'm not satisfied with its performance.

/*

// http://stackoverflow.com/questions/1857160/how-can-i-create-a-custom-pin-drop-animation-using-mkannotationview/2087253#2087253

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views { 
	MKAnnotationView *aV; 
	NSTimeInterval increasingDelay = 0.0;
	
	for (aV in views) {
		CGRect endFrame = aV.frame;
		
		aV.frame = CGRectMake(aV.frame.origin.x, aV.frame.origin.y - 230.0, aV.frame.size.width, aV.frame.size.height);
		
		// this is the code as I found it, which uses old-style animation to drop all pins at once time.
		
		//[UIView beginAnimations:nil context:NULL];
		//[UIView setAnimationDuration:0.45];
		//[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		//[aV setFrame:endFrame];
		//[UIView commitAnimations];
		
		
		
		[UIView animateWithDuration:0.35 delay:increasingDelay options:UIViewAnimationCurveEaseInOut animations:^{
			[aV setFrame:endFrame];
		} completion:NULL];
		
		increasingDelay += 0.06; // add 60 ms delay to each annotation view, or make it proportional to the total pin count?
		
	}
}

 */

#pragma mark -
#pragma mark Map-related

- (void)setInitialMapRegion { // because CL might not have a valid location yet
	
	MKCoordinateRegion newRegion;
	
	newRegion.center.latitude = kDefaultRegionLatitude;
	newRegion.center.longitude = kDefaultRegionLongitude;
	
	newRegion.span.latitudeDelta = kDefaultRegionLatitudeDelta;
	newRegion.span.longitudeDelta = kDefaultRegionLongitudeDelta;
	
	
	// correct the aspect ratio
	MKCoordinateRegion fitRegion = [self.artMapView regionThatFits:newRegion];
	
    [self.artMapView setRegion:fitRegion animated:YES];
	
	// Reload the art for the newly-set region
	[self refreshArtOnMap];
	
	// make sure refresh button is disabled
	refreshButton.enabled = NO;
	
}

- (void)refreshArtOnMap {
	
	// fetch art from Core Data

	NSArray *placeList;
	
	
	if (self.filteredBySearch) {
        
        //NSLog(@"Using a text-based predicate");

		NSArray *fetchedItems = [self fetchPlaceArrayForSearch];
		
		// This array passing is from a legacy design. It will change with search refactor.
		
		placeList = [self createArtAnnotationArray:fetchedItems];
		
	}
	else {

		//NSLog(@"Using a map-based predicate");
		
		MKCoordinateRegion region = artMapView.region;

		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Place" inManagedObjectContext:self.managedObjectContext]];
		
		NSPredicate *predicate;
	
		NSNumber *southernEdge = [NSNumber numberWithDouble:region.center.latitude - region.span.latitudeDelta/2.0];
		NSNumber *northernEdge = [NSNumber numberWithDouble:region.center.latitude + region.span.latitudeDelta/2.0];
		NSNumber *westernEdge = [NSNumber numberWithDouble:region.center.longitude - region.span.longitudeDelta/2.0];
		NSNumber *easternEdge = [NSNumber numberWithDouble:region.center.longitude + region.span.longitudeDelta/2.0];
		predicate = [NSPredicate predicateWithFormat:@"latitude>%@ AND latitude<%@ AND longitude>%@ AND longitude<%@", southernEdge, northernEdge, westernEdge, easternEdge];		
		
		[fetchRequest setPredicate:predicate];
		
		
		NSMutableArray *sortDescriptors = [NSMutableArray array];
		[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"latitude" ascending:YES] autorelease]];
		[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"longitude" ascending:YES] autorelease]];
		[fetchRequest setSortDescriptors:sortDescriptors];
		
		// let it return faults
		//[fetchRequest setReturnsObjectsAsFaults:NO];
		// added location to this, so it won't have to fetch any faulted items in createArtAnnotationArray
		[fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"latitude", @"longitude", @"title", @"discipline", @"location", @"artists", @"couchID", nil]];
		NSError *error = nil;
		NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		
		if (fetchedItems == nil)  
		{
			// an error occurred
			placeList = [NSArray array]; // return an empty array
			NSLog(@"fetch request resulted in an error %@, %@", error, [error userInfo]);
		}
		else
		{
			
			placeList = [self createArtAnnotationArray:fetchedItems];
			
		}	
		
		
		[fetchRequest release];
		
	}
	

	// Handle results from either text search or map search
	
	
	if ([placeList count] > 0) {
		
		//NSLog(@"%d artworks found...", [placeList count]);
		
		// if this is a text-based search, need to adjust the map region here...
		
		if (self.filteredBySearch) {
			
			MKCoordinateRegion theCalculatedRegion = [self makeRegionForAnnotationArray:placeList];
			
			/*
			NSLog(@"Calculated region for artworks found is...");
			NSLog(@"This region's latitude is: %f", theCalculatedRegion.center.latitude);
			NSLog(@"This region's longitude is: %f", theCalculatedRegion.center.longitude);
			NSLog(@"This region's latitude delta is: %f", theCalculatedRegion.span.latitudeDelta);
			NSLog(@"This region's longitude delta is: %f", theCalculatedRegion.span.longitudeDelta);
			*/
			
			[self.artMapView setRegion:theCalculatedRegion animated:YES];
			
			// add the show all button to rightBarButton position?
			
		}
		
		
		NSArray *oldAnnotations = artMapView.annotations;
		
		// want to wipe out all the artworks but keep the user's location, because it can take a while to come back
		NSPredicate *userLocationPredicate = [NSPredicate predicateWithFormat:@"!(self isKindOfClass: %@)", [MKUserLocation class]];
		
		NSArray *annotationsToRemove = [oldAnnotations filteredArrayUsingPredicate:userLocationPredicate];
		[artMapView removeAnnotations:annotationsToRemove];
		
		[artMapView addAnnotations:placeList];
		
		
		// since artwork was fetched, there'd be no point running the geo-search again for the same region
		self.refreshButton.enabled = NO;
		
	}
	else {
		
		// NSLog(@"No artworks found. Need to let user know...");
		
		
		if (self.filteredBySearch) {
			// search found nothing... report as missing?
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Art Found" 
															message:@"There are not any works of art that match this search. Would you like to report a missing artwork?" 
														   delegate:self 
												  cancelButtonTitle:@"No" 
												  otherButtonTitles:@"Yes", nil];
			[alert show];
			
			[alert release];
			
			// re-enable the refresh button so they can do a geo-search w/o moving map, regardless of their choice in alertview
			
			self.refreshButton.enabled = YES;
		}
		
		else { // no results for geo-search
			
			// test span values here, and it they are too big, offer to move them closer to the city instead?
			
			double currentLatitudeDelta = self.artMapView.region.span.latitudeDelta;
			
			if (currentLatitudeDelta > kLatitudeDeltaThreshold) {  // test this value
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Art Found" 
																message:@"There don't seem to be any works of art nearby, and you're already looking at a wide view. Would you like to go to the default view?" 
															   delegate:self 
													  cancelButtonTitle:@"No" 
													  otherButtonTitles:@"Yes", nil];
				[alert show];
				
				[alert release];
			}
			
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Art Found" 
																message:@"There don't seem to be any works of art nearby. Would you like to widen the search of this area?" 
															   delegate:self 
													  cancelButtonTitle:@"No" 
													  otherButtonTitles:@"Yes", nil];
				[alert show];
				
				[alert release];
			}
			
		}

	}
	
	
	// Don't set refreshButton.enabled = NO here
	// Use case: No art found for search, and refresh is a way to clear search and view art for current region
	
}


// from array of Core Data managed objects
-(NSArray *)createArtAnnotationArray:(NSArray *)placeArray {
	
	NSMutableArray *artAnnotationList = [NSMutableArray array];
	
	
	if ([placeArray count] > 0) {
		
		ArtAnnotation *aa = nil;
		
		// loop and add
		
		for (Place *aPlace in placeArray) {
			
			// create an annotation
			
			aa = [[ArtAnnotation alloc] init];
			
			[aa setTitle:[aPlace title]];
			
            // add artist name as subtitle instead of discipline? But there are 
            // so many with too many artists to fit...
			//[aa setSubtitle:[aPlace artists]];
			[aa setSubtitle:[aPlace location]];
            
			[aa setDiscipline:[aPlace discipline]];
			
			[aa setLatitude:[aPlace latitude]];
			[aa setLongitude:[aPlace longitude]];
			
			[aa setArtID:[aPlace couchID]];
			
			[artAnnotationList addObject:aa];
			
			[aa release];
			
		}
		
	}
	
	else { 
		
		// This should never appear, because the user is always notified by UIAlertView if nothing is found. 
		// If it does appear in the logs, there is a problem.
		NSLog(@"Map VC: No artwork in the array passed to createArtAnnotationArray. FIX IT!");
		//[artAnnotationList removeAllObjects]; // redundant
	}
	
	
	//NSLog(@"There are %d artworks in the annotations list.", [artAnnotationList count]);
	
	return artAnnotationList;
	
}

-(MKCoordinateRegion)makeRegionForAnnotationArray:(NSArray *)annotationArray {
	
	/* iterate through the array and find maxlat minlat maxlong minlong
	
	find a centroid by:
	
	(max - min)/2 + min
	
	for each
		
		and then set span width to 1.3 * (maxlong - minlong) and adjust region
		
		
		
	To do that calculation, pull all lats, put them in an array and then sort
			
	same thing with longitude
			
	then you can just pick the values from the start and the end and do the math
				
	look at the sortedArray fields
				
				can sort with either NSComparator or NSSortDescriptor
	
	 */
	
	/*
	NSLog(@"There are %d objects in the original array, with latitude from %@ to %@", 
		  [annotationArray count], 
		  [(ArtAnnotation *)[annotationArray objectAtIndex:0] latitude], 
		  [(ArtAnnotation *)[annotationArray objectAtIndex:[annotationArray count]-1] latitude]);
	*/
	
	NSArray *latitudeSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"latitude" ascending:YES]];
	
	NSArray *latitudeArray = [annotationArray sortedArrayUsingDescriptors:latitudeSortDescriptors];
	
	/*
	NSLog(@"There are %d objects in the array, with latitude from %@ to %@", 
		  [latitudeArray count], 
		  [(ArtAnnotation *)[latitudeArray objectAtIndex:0] latitude], 
		  [[latitudeArray objectAtIndex:[latitudeArray count]-1] latitude]);
	*/
	
	/*
	for (ArtAnnotation *aa in latitudeArray) {
		NSLog(@"lat is %@", aa.latitude);
	}
	*/
	
	CLLocationDegrees minLatitude = [[(ArtAnnotation *)[latitudeArray objectAtIndex:0] latitude] doubleValue];
	CLLocationDegrees maxLatitude = [[(ArtAnnotation *)[latitudeArray objectAtIndex:[latitudeArray count]-1] latitude] doubleValue];
	
	
	NSArray *longitudeSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"longitude" ascending:YES]];	
	
	NSArray *longitudeArray = [annotationArray sortedArrayUsingDescriptors:longitudeSortDescriptors];
	
	/*
	NSLog(@"There are %d objects in the array, with longitude from %@ to %@", 
		  [longitudeArray count], 
		  [(ArtAnnotation *)[longitudeArray objectAtIndex:0] longitude], 
		  [[longitudeArray objectAtIndex:[longitudeArray count]-1] longitude]);
	*/
	
	CLLocationDegrees minLongitude = [[(ArtAnnotation *)[longitudeArray objectAtIndex:0] longitude] doubleValue];
	CLLocationDegrees maxLongitude = [[(ArtAnnotation *)[longitudeArray objectAtIndex:[longitudeArray count]-1] longitude] doubleValue];
	
	MKCoordinateRegion inclusiveRegion;
	
	inclusiveRegion.center.latitude = (maxLatitude - minLatitude)/2 + minLatitude;
	inclusiveRegion.center.longitude = (maxLongitude - minLongitude)/2 + minLongitude;
	
	// move this test up top, and skip the math if there is only one?
	if ([annotationArray count] > 1) {
		inclusiveRegion.span.latitudeDelta = (maxLatitude - minLatitude)*kSearchResultsLatitudeDeltaMultiplier;
		inclusiveRegion.span.longitudeDelta = (maxLongitude - minLongitude)*kSearchResultsLongitudeDeltaMultiplier;
	}
	else { 
		inclusiveRegion.span.latitudeDelta = kDefaultRegionLatitudeDelta;
		inclusiveRegion.span.longitudeDelta = kDefaultRegionLongitudeDelta;
	}
	
	return inclusiveRegion;
	
}


#pragma mark -
#pragma mark - Response to No Art Found aka UIAlertViewDelegate

// This method screams: REFACTOR ME!!! Pending finalization of 1.1 features
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
	// widen search if requested...
	
	if (buttonIndex == 1) {  // if they tapped yes
		
		if (self.filteredBySearch) {
			
            // display the missing artwork template
			
			if ([MFMailComposeViewController canSendMail]) {
								
				MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
				
				mailVC.mailComposeDelegate = self;
				
				NSString *messageBody = [NSString stringWithFormat:@"I ran a search on \"%@\" and didn't find anything. I expected to find...\n\n%@", 
										 self.currentSearchString, kEmailFooter];
				
				[mailVC setSubject:[NSString stringWithFormat:@"Missing Art: %@", self.currentSearchString]];
				[mailVC setToRecipients:[NSArray arrayWithObject:kSubmissionEmailAddress]];
				[mailVC setMessageBody:messageBody isHTML:NO];
				
				[self presentModalViewController:mailVC animated:YES];
				
			}
			else {

				NSString *alertMessage = [NSString stringWithFormat:@"Please configure your device to send email and try again, or use another computer to email: %@", kSubmissionEmailAddress];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail Not Available" 
																message:alertMessage 
															   delegate:self 
													  cancelButtonTitle:@"OK" 
													  otherButtonTitles:nil];
				[alert show];
				[alert release];
			}
			
			
		}
		else {  // zoom/shift the map

			// get the current region
			
			MKCoordinateRegion newRegion = self.artMapView.region;
			
			double oldLatitudeDelta = newRegion.span.latitudeDelta;
			double oldLongitudeDelta = newRegion.span.longitudeDelta;
			
			if (oldLatitudeDelta > kLatitudeDeltaThreshold) {
				
				// go to default view
				
				newRegion.center.latitude = kDefaultRegionLatitude;
				newRegion.center.longitude = kDefaultRegionLongitude;
				
				newRegion.span.latitudeDelta = kDefaultRegionLatitudeDelta;
				newRegion.span.longitudeDelta = kDefaultRegionLongitudeDelta;
				
				
			}
			else {
				double newLatitudeDelta = oldLatitudeDelta * kWidenMapViewIncrement; //1.2
				double newLongitudeDelta = oldLongitudeDelta * kWidenMapViewIncrement; //1.2
				
				newRegion.span.latitudeDelta = newLatitudeDelta;
				newRegion.span.longitudeDelta = newLongitudeDelta;
			}
			
			
			
			MKCoordinateRegion fitRegion = [self.artMapView regionThatFits:newRegion];
			
			[[self artMapView] setRegion:fitRegion animated:YES];
			
			[self refreshArtOnMap];
			
			// need to call here to make sure button is disabled. See note in the setInitialMapRegion method.
			
			refreshButton.enabled = NO;
			
		}

	}
	
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	
	
	
	 // log the results during testing
	 /*
	 switch (result)
	 {
	 case MFMailComposeResultCancelled:
	 NSLog(@"Email result: canceled");
	 break;
	 case MFMailComposeResultSaved:
	 NSLog(@"Email result: saved");
	 break;
	 case MFMailComposeResultSent:
	 NSLog(@"Email result: sent");
	 break;
	 case MFMailComposeResultFailed:
	 NSLog(@"Email result: failed");
	 break;
	 default:
	 NSLog(@"Email result: not sent");
	 break;
	 }
	 */
	
	
	// dismiss the controller
	
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark View setup

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
		
	self.navigationItem.title = @"Portland Public Art";
	
	// setup custom buttons here

	[self addToolbarItems];
	
	
	// Which of these is better?
	
	// this is in the apple docs, but throws a warning in Xcode and an NSException at run-time!
	// [self setToolbarHidden:NO animated:YES];
	
	// this makes sense, and works
	[[self navigationController] setToolbarHidden:NO animated:YES];
	
	
	// Start the location manager and put the user on the map
	
	if ([CLLocationManager locationServicesEnabled]) {
		// NSLog(@"About to turn Location on...");
		[[self locationManager] startUpdatingLocation];  		
		artMapView.showsUserLocation = YES;
		locationReallyEnabled = YES;  // to handle CL behavior in iOS 4.1
	}
	else {
		// NSLog(@"Location not available, turning it off for the map.");
		artMapView.showsUserLocation = NO;
		locationReallyEnabled = NO;  // to handle CL behavior in iOS 4.1
		
		// Add alert here encouraging them to turn location on? Is that against HIG?
		
	}
	
	
	// And zoom to default view of Portland
	[self setInitialMapRegion]; 
	
}



- (void)addToolbarItems {
	
	// Refresh (system)
	
	self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																	   target:self
																	   action:@selector(refreshTheMap:)]; // keep reference
	
	self.refreshButton.accessibilityLabel = @"Refresh";


	// re-usable flex space (system)
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																				   target:nil
																				   action:nil];
		
	// key

    UIBarButtonItem *legendButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"30-key"] 
																	 style:UIBarButtonItemStylePlain 
																	target:self 
																	action:@selector(showMapLegend:)];
	[legendButton setAccessibilityLabel:@"Map legend"];
		
	
	// Add (system)
	
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																			   target:self
																			   action:@selector(addNewArtwork:)];
	
	[addButton setAccessibilityLabel:@"Add new artwork"];
	
	// Search (system)
	
	UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
																				  target:self
																				  action:@selector(showSearch:)];
	
	[searchButton setAccessibilityLabel:@"Search"];

	
	// location
	
	self.locationButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"74-location-invert"] 
																	 style:UIBarButtonItemStylePlain 
																	target:self 
																	action:@selector(goToLocation:)];
	
	[locationButton setAccessibilityLabel:@"Re-center map"];
	[locationButton setAccessibilityHint:@"Centers on your location, or downtown Portland."];
	
	// add it to the nav controller
	
	// This method bunches them all together at the left, so I added spaces
	self.toolbarItems = [NSArray arrayWithObjects: 
						 self.refreshButton, 
						 flexibleSpace,
						 legendButton, 
						 flexibleSpace,
						 addButton,
						 flexibleSpace,
						 searchButton, 
						 flexibleSpace,
						 self.locationButton, 
						 nil];
	
	
	// Release all except the refresh and location buttons, which you need to be able to enable/disable. They're released in dealloc.
	
	[flexibleSpace release];
	[legendButton release];
	[addButton release];
	[searchButton release];
	
}

-(void)viewWillAppear:(BOOL)animated {
	
	//NSLog(@"Map VC: viewWillAppear");
	
	if ([[self navigationController] isToolbarHidden]) {
		NSLog(@"Tool bar was hidden. Unhiding...");
		[[self navigationController] setToolbarHidden:NO animated:YES];
	}
	
}


#pragma mark -
#pragma mark Location Manager Delegate


// based on Photo Locations sample code and Location Awareness PG

/**
 Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager {
	
    if (locationManager != nil) {
		return locationManager;
	}
	
	locationManager = [[CLLocationManager alloc] init];
	[locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters]; // or kCLLocationAccuracyNearestTenMeters
	[locationManager setDelegate:self];
	
	return locationManager;
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
	// check how recent the location is
	
	NSDate *newLocationDate = newLocation.timestamp;
	NSTimeInterval timeDiff = [newLocationDate timeIntervalSinceNow];
	
	// For Troubleshooting
	// NSLog(@"Coordinate received with accuracy radius of %f meters.", newLocation.horizontalAccuracy);
	
	// Horizontal accuracy is a radius in meters. Is 100 too wide? 
	// A negative value indicates an invalid coordinate.
	
	// Added greater than 2 test because of behavior in 4.1, where accuracy can be reported as 0.0.
	
	if ((abs(timeDiff) < 15.0) && (newLocation.horizontalAccuracy < 100.0) && (newLocation.horizontalAccuracy >= 2.0))
	{
		
		
		// turn this on as needed for troubleshooting
		//NSLog(@"Recent and accurate location received...");
		//NSLog(@"The new location's latitude is: %f", newLocation.coordinate.latitude);
		//NSLog(@"The new location's longitude is: %f", newLocation.coordinate.longitude);
		
		
		locationReallyEnabled = YES;  // to handle CL behavior in iOS 4.1
		
		
	}	
	
	
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
	// handle location failure silently (primarily for 4.1)
	
	/*
	 NSLog(@"Location Failure.");
	 NSLog(@"Error: %@", [error localizedDescription]);
	 NSLog(@"Error code %d in domain: %@", [error code], [error domain]);
	 */
	
	
	// Need to handle this because locationServicesEnabled class method is erratic in 4.1.
	
	
	// set a bool on the VC that tells it location has failed.
	
	if (([error code] == 1) && ([[error domain] isEqualToString:@"kCLErrorDomain"])) {
		locationReallyEnabled = NO;  // to handle CL behavior in iOS 4.1
		
		// does it stop updating automatically after the error? Just in case...
		
		[[self locationManager] stopUpdatingLocation];
		
	}
	
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark Memory-related methods

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;

	
}


- (void)dealloc {
	
	[artMapView release];
	[infoButton release];
	[refreshButton release];
	[locationButton release];
	
	[theSearchBar release];
	[currentSearchString release];
	
	[locationManager release];
		
    [super dealloc];
}


@end
