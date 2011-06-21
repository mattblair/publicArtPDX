//
//  ArtLocationFixViewController.m
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

#import "ArtLocationFixViewController.h"
#import "ASIHTTPRequest.h"
#import "Reachability.h"
#import "NSObject+SBJSON.h"  // category on NSDictionary to get JSON 
#import "databaseConstants.h"
#import "MBProgressHUD.h"


@implementation ArtLocationFixViewController

@synthesize theArt, thePhoto, newLatitude, newLongitude, delegate, locationSubmitRequest;

// UI
@synthesize  thumbnail, fixMapView, cancelButton, saveButton, uploadHUD;

#pragma mark - 
#pragma mark View Management

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	//NSLog(@"ArtLocationFixVC: About to show an editable map for art with id %@", [[self theArt] couchID]);
	
	
	// setup the UI
	
	thumbnail.contentMode = UIViewContentModeScaleAspectFit;
	
	thumbnail.image = thePhoto; // this is set by the Art Detail VC before prsentation
	
	
	// setup the map
	
	self.fixMapView.delegate = self;
	
	self.fixMapView.showsUserLocation = YES;  // need to double-check Location availability here?
	
    
	// Create region with center on art's original location
	
	CLLocationCoordinate2D originalLocation;
	
	// have to convert from NSNumber to doubles
	originalLocation.latitude = [[[self theArt] latitude] doubleValue]; 
	originalLocation.longitude = [[[self theArt] longitude] doubleValue];
	
	// 250 meters sqaure region centered on original location
	MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(originalLocation, 250.0, 250.0);
	
	//[[self fixMapView] setCenterCoordinate:originalLocation animated:YES];
	
	[[self fixMapView] setRegion:newRegion animated:YES];

	// add the annotation
	MKPointAnnotation *draggableAnnotation = [[MKPointAnnotation alloc] init];
	
	draggableAnnotation.coordinate = originalLocation;
	
	[[self fixMapView] addAnnotation:draggableAnnotation];
	
	[draggableAnnotation release];
	
}

#pragma mark -
#pragma mark User-Initiated Actions

- (IBAction)cancelSubmission:(id)sender {
	
	[self killRequest];
	
	[delegate artLocationFixViewControllerDidFinish:self withSubmission:NO];
	
}

- (IBAction)submitLocation:(id)sender {
	
	// disable button to prevent multi-tappage
	
	self.saveButton.enabled = NO;
	

	// Check the internet connection
	
	NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
	
	if (status == kReachableViaWiFi || status == kReachableViaWWAN) { 
		
		self.uploadHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		self.uploadHUD.labelText = @"Sending new location...";
		

		// configure the request
		
		NSURL *theURL = [NSURL URLWithString:kURLForUpdates];
		
		self.locationSubmitRequest = [ASIHTTPRequest requestWithURL:theURL];
		
		[[self locationSubmitRequest] setRequestMethod:@"POST"];
		
		[[self locationSubmitRequest] addRequestHeader:@"Content-Type" value:@"application/json"];
		
		// Testing:
		
		//NSString *geometryJSON = [NSString stringWithFormat:@"{\"coordinates\": [%f, %f], \"type\": \"Point\"}", [self newLongitude], [self newLatitude]];
		
		//NSString *jsonToSubmit = [NSString stringWithFormat:@"[\"geometry\": %@]", geometryJSON];
		
		NSArray *coordinateArray = [NSArray arrayWithObjects:self.newLongitude,self.newLatitude,nil];
		
		NSDictionary *geometryDict = [NSDictionary dictionaryWithObjectsAndKeys:
											coordinateArray,@"coordinates",
											@"Point",@"type",
											nil];
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		
		// changed to ISO 8601, as described here: http://www.w3.org/TR/NOTE-datetime
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
		
		NSString *versionNumber =[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
		
		NSDictionary *locationUpdateDict = [NSDictionary dictionaryWithObjectsAndKeys:
											[theArt latitude],@"originalLatitude",
											[theArt longitude],@"originalLongitude",
											geometryDict,@"geometry",
											[theArt couchID],@"publicArtID",
											[theArt recordID],@"recordID",
											[theArt title],@"title",
                                            [theArt dataSource],@"dataSource", // new in 1.1, untested
											@"reported-location",@"type",
											@"submitted",@"reviewStatus",
											[NSString stringWithFormat:@"PublicArtPDX v%@ iOS app user", versionNumber],@"submittedBy",
											[dateFormatter stringFromDate:[NSDate date]],@"submittedDate",
											nil];
		
        //NSLog(@"Dictionary: %@", [locationUpdateDict description]);
        
		NSString *jsonToSubmit = [locationUpdateDict JSONRepresentation];
		
		//NSLog(@"The JSON Representation looks like: %@", jsonToSubmit);
		
		[[self locationSubmitRequest] appendPostData:[jsonToSubmit dataUsingEncoding:NSUTF8StringEncoding]];
		
		// Don't need to release the dictionaries b/c switched to class methods
		
		[dateFormatter release];


		// authentication
		
		//NSLog(@"the username and password are %@, %@", kUpdateUsername, kUpdatePassword);
		
		[[self locationSubmitRequest] setUsername:kUpdateUsername];
		[[self locationSubmitRequest] setPassword:kUpdatePassword];
		
		[[self locationSubmitRequest] setDelegate:self];
		
		//NSLog(@"Starting the async upload");
		
		[[self locationSubmitRequest] startAsynchronous];
		
		
	}  //end of reachability = true
	
	else {  // no internet
		
		// add email submit here?
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Connection" 
														message:@"Sorry, there's no internet at the moment. Please try again later." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		
	}

	
	
	
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark MKMapView Delegate Methods

- (void)mapView:(MKMapView *)map regionDidChangeAnimated:(BOOL)animated {
	// is there a reason to care about this here?
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
	
	//NSLog(@"Creating a movable pin for the artwork...");
	
	
	// don't need to dequeue since we know this map will only have one pin
	
	//MKPinAnnotationView *pinView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"FixPinAnnotationView"] autorelease];
	
	MKPinAnnotationView *pinView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil] autorelease];
	pinView.pinColor = MKPinAnnotationColorPurple;  // changed from red to purple re: Justin's comment that purple pins are the adjustable ones.
	pinView.animatesDrop = YES;
	pinView.draggable = YES;
	
	return pinView;
	
	
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	
	MKPointAnnotation *theAnnotation = annotationView.annotation;
	
	//NSLog(@"The lat is %f and the long is %f", theAnnotation.coordinate.latitude, theAnnotation.coordinate.longitude);
	
	// handle the changes as the pin gets dragged
	
	if (newState == MKAnnotationViewDragStateEnding) {
	
		//NSLog(@"The drag ended.");

		[self setNewLatitude:[NSNumber numberWithDouble:theAnnotation.coordinate.latitude]];
		[self setNewLongitude:[NSNumber numberWithDouble:theAnnotation.coordinate.longitude]];
	}
	
	/*
	if (newState == MKAnnotationViewDragStateStarting) {
		NSLog(@"The drag is starting");
	}
	*/
	
}


#pragma mark -
#pragma mark Handling the response from location post request


- (void)requestFinished:(ASIHTTPRequest *)request {
	
	// check status
	
	
	// Dev only:
	//NSString *responseString = [request responseString];
	//NSLog(@"The Location Submit HTTP Status code was: %d", [request responseStatusCode]);
	//NSLog(@"The Location Submit response was: %@", responseString);
	
	// Update UI
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	
	if ([request responseStatusCode] == 201) {  // means Created
		
		//NSLog(@"Change Accepted. Say thank you and dismiss this.");
		
		[delegate artLocationFixViewControllerDidFinish:self withSubmission:YES];
		
	}
	
	else {
		// handle the error by offering email in the future?
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Server Problem" 
														message:@"Sorry, the server didn't respond as expected. Please try again later." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		
	}
    
    self.locationSubmitRequest = nil;
	
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	
	// update UI
	
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	
	// Handle the error
	
	NSError *error = [request error];
	
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {  // not an error
		NSLog(@"Location upload cancellation initiated by Reachability notification or directly by user.");
		
	}
	else {

		// Should offer email as an alternative?
		
		NSLog(@"Location Submit POST request failed.");
		
		NSLog(@"The HTTP Status code was: %d", [request responseStatusCode]);
		
		NSLog(@"Error submitting location: %@", [error description]);	
		

		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Connection Problem" 
														message:@"Sorry, the server didn't respond as expected. Please try again later." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
	// to make sure the authentication faiilure doesn't cause subsequent requests to fail
	[ASIHTTPRequest clearSession];
    
    self.locationSubmitRequest = nil;
	
}

- (void)killRequest {
	
	if ([[self locationSubmitRequest] inProgress]) {
		
		//NSLog(@"Request is in progress, about to cancel.");		
		
		[[self locationSubmitRequest] cancel];
		
		//NSLog(@"Request cancelled.");
		
		[MBProgressHUD hideHUDForView:self.view animated:YES];
		
	}
	
}


#pragma mark -
#pragma mark UIAlertView delegate method

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

	// handle the tap of okay, and return:

	[delegate artLocationFixViewControllerDidFinish:self withSubmission:NO];
	
}



#pragma mark -
#pragma mark Memory Clean-up

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.thumbnail = nil;
    self.cancelButton = nil;
    self.saveButton = nil;
    self.fixMapView = nil;
    
}


- (void)dealloc {
	
	[theArt release];
	[thePhoto release];
	[newLatitude release];
	[newLongitude release];
	
	[locationSubmitRequest release];
	
	[thumbnail release];
	[cancelButton release];
	[saveButton release];
	[fixMapView	release];
	[uploadHUD release];
	
	
    [super dealloc];
}


@end
