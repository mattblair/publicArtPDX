//
//  ArtDetailViewController.m
//  pdxPublicArt
//
//  Created by Matt Blair on 11/24/10.
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

#import "ArtDetailViewController.h"
#import "ArtLocationFixViewController.h"
#import "ASIHTTPRequest.h"
#import "Reachability.h"
#import "databaseConstants.h"


#define HORIZONTAL_PADDING 20.0
#define INDENTED_PADDING 35.0
#define SMALL_VERTICAL_PADDING 5.0
#define VERTICAL_PADDING 15.0
#define MAX_CONTENT_WIDTH 280.0
#define SMALL_LABEL_WIDTH 230.0 // shorter location lables to make room for fix pin
#define FIX_BUTTON_TAP_TARGET 44.0 // in both dimensions
#define MAX_IMAGE_HEIGHT 210.0

@implementation ArtDetailViewController

// data
@synthesize couchID, theArt, photoRequest;

// UI
@synthesize yForNextView;
@synthesize scrollView, photoCreditLabel, descripTextView, thePhotoView, fixButton;

// for Core Data
@synthesize managedObjectContext=managedObjectContext_;


#pragma mark - 
#pragma mark User-initiated Actions

- (IBAction)shareThisArt:(id)sender {

	// Future: ask them if they want to text/email/tweet/fb or cancel
	
	if ([MFMailComposeViewController canSendMail]) {  //verify that mail is configured on the device
		
		//present the mail window with boilerplate
		
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
		
		mailVC.mailComposeDelegate = self;
		
		
		// handle a null street address
		NSString *addrString;
		
		if ([[theArt addr1] respondsToSelector:@selector(length)]) { // in case it is an NSNull
			if ([[theArt addr1] length] > 0) {
				
				addrString = [NSString stringWithFormat:@"\n It's located at %@\n", [theArt addr1]];

			}
			else { // 0 length
				addrString = @"";
			}

		}
		else { // not a string
			addrString = @"";
		}
		
		
		// handle a null detailURL
		NSString *urlString;
		
		if ([[theArt detailURL] respondsToSelector:@selector(length)]) {
			if ([[theArt detailURL] length] > 0) {
				urlString = [NSString stringWithFormat:@"\nYou can find out more at: %@", [theArt detailURL]];
			}
			else {
				urlString = @"";
			}
		}
		else { //not a string
			urlString = @"";
		}
	
		
		NSString *messageBody = [NSString stringWithFormat:@"I'm visiting public art in Portland, and I thought you might like \"%@\" by %@.\n%@%@%@", 
								 [theArt title], [theArt artists], addrString, urlString, kEmailFooter];
		
		[mailVC setSubject:[NSString stringWithFormat:@"Portland Public Art: %@", [[theArt title] capitalizedString]]];
		[mailVC setMessageBody:messageBody isHTML:NO];
		
		[self presentModalViewController:mailVC animated:YES];
		
		[mailVC release];
		
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

- (IBAction)updateLocation:(id)sender {

	// make and push a ArtLocationFixViewController modally
	
	ArtLocationFixViewController *fixVC = [[ArtLocationFixViewController alloc] initWithNibName:@"ArtLocationFixViewController" bundle:nil];
	
	fixVC.theArt = [self theArt]; // pass in the entire object, since it's already fetched
	
	fixVC.thePhoto = thePhotoView.image;

	fixVC.delegate = self;
	
	[self presentModalViewController:fixVC animated:YES];
		
	[fixVC release];
	
	
}

// Moved to future, pending future datasets that might have more info online 
// than in db, or that might include artist URLs
/*
- (IBAction)showDetailURL:(id)sender {
	
	// load detailURL in WebView
	
}
*/
 
#pragma mark -
#pragma mark Delegates for Modal Display

- (void)artLocationFixViewControllerDidFinish:(ArtLocationFixViewController *)controller withSubmission:(BOOL)locationSubmitted {
	
	// thank them if needed
	
	if (locationSubmitted) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank You" 
														message:@"We've received your location information and will update the listings for everyone." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert setDelegate:self];
		[alert show];
		[alert release];
	}
	
	// close it
	
	[self dismissModalViewControllerAnimated:YES];
	
}

#pragma mark -
#pragma mark Handling response to the image request

- (void)requestFinished:(ASIHTTPRequest *)request {
	
	NSData *responseData = [request responseData];
	
	// Since the image arrives after the layout has been determined, 
    //   adjust the width based on aspect ratio instead of height 
	//   so we don't push everything down and disrupt the reader...
	
	if ([request responseStatusCode] == 200) {
		
		UIImage *thePhoto = [UIImage imageWithData:responseData];
		
		CGFloat aspectRatio = thePhoto.size.width / thePhoto.size.height;
		
		CGFloat newWidth = aspectRatio * MAX_IMAGE_HEIGHT; // was 210.0
		
		CGFloat newX = (320.0 - newWidth)/2;
		
		thePhotoView.image = thePhoto;
		
		// without this option set, it will freeze UI while animating...
		
		[UIView animateWithDuration:0.8 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		
			photoCreditLabel.alpha = 0.8;
			
			thePhotoView.alpha = 1.0;
			thePhotoView.frame = CGRectMake(newX, 0.0, newWidth, 210.0);
			
		} completion:NULL];
		
	}
	else {
		NSLog(@"The HTTP Status code for the photo request was: %d", [request responseStatusCode]);
		
		//NSLog(@"The data returned was %d bytes and looks like: %@", [responseData length], responseData);
		
		
		// update UI about failure
		
		thePhotoView.image = [UIImage imageNamed:@"photoFailedTextured"];
		
		[UIView animateWithDuration:0.7 animations:^{
			
			thePhotoView.alpha = 0.7;
			
		}];
		
		/*
		//  or add a label
		CGRect failureFrame = CGRectMake(20.0, 50.0, 280.0, 50.0);
		
		UILabel *failureLabel = [[[UILabel alloc] initWithFrame:failureFrame] autorelease];
		
		failureLabel.text = @"(Image Temporarily Unavailable)";
		failureLabel.textAlignment = UITextAlignmentCenter;
		failureLabel.textColor = [UIColor grayColor];
		failureLabel.backgroundColor = [UIColor clearColor];	
		failureLabel.alpha = 0.0;
		
		[self.view addSubview:failureLabel];
		
		// animate chages to frame and alpha of the photo
		
		[UIView animateWithDuration:0.6 animations:^{
			
			thePhotoView.alpha = 0.0;
			failureLabel.alpha = 1.0;
			
		}];		
		*/
		
		
	}	
    
    self.photoRequest = nil;
	
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	
	NSError *error = [request error];
	
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {  // not an error
		NSLog(@"Image Request cancellation initiated by killRequest method in Art Detail VC's viewWillDisappear.");
		
	}
	else {
		
		NSLog(@"Photo Request HTTP Status code was: %d", [request responseStatusCode]);
		NSLog(@"Photo Request Error: %@", [error description]);			
		NSLog(@"Photo Request: Failure of request to: %@", [request url]);
		
		
		// update UI -- use image for now, label code preserved below if you decide to use that instead
		
		thePhotoView.image = [UIImage imageNamed:@"photoFailedTextured"];  // was photo-failed
		
		[UIView animateWithDuration:0.8 animations:^{
			
			thePhotoView.alpha = 0.6;
			
		}];
		
		/*
		
		
		// add a label
		CGRect failureFrame = CGRectMake(20.0, 50.0, 280.0, 50.0);
		
		UILabel *failureLabel = [[[UILabel alloc] initWithFrame:failureFrame] autorelease];
		
		failureLabel.text = @"Image Temporarily Unavailable";
		failureLabel.textAlignment = UITextAlignmentCenter;
		failureLabel.textColor = [UIColor grayColor];
		failureLabel.backgroundColor = [UIColor clearColor];	
		failureLabel.alpha = 0.0;
		
		[self.view addSubview:failureLabel];

		// animate chages to frame and alpha of the photo
		
		[UIView animateWithDuration:0.6 animations:^{
			
			thePhotoView.alpha = 0.0;
			failureLabel.alpha = 1.0;
			
		}];
		*/
	}
    
    self.photoRequest = nil;
	
}


- (void)killRequest {
	
	if ([[self photoRequest] inProgress]) {
		
		[[self photoRequest] cancel];
		
		//NSLog(@"Request cancelled.");
		
	}
	
}

#pragma mark -
#pragma mark View-Lifecycle

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
	
	// add the share button
	UIBarButtonItem *shareButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																				  target:self
																				  action:@selector(shareThisArt:)] autorelease];
	
	[shareButton setAccessibilityLabel:@"Share this art"];
	[shareButton setAccessibilityHint:@"Prepares an email with details about this work of art."];
	
	self.navigationItem.rightBarButtonItem = shareButton;
	

	///NSLog(@"ArtVC: About to load art with id %@", self.couchID);
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Art" 
                                        inManagedObjectContext:self.managedObjectContext]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"couchID=%@", self.couchID];
    [fetchRequest setPredicate:predicate];
	
	[fetchRequest setReturnsObjectsAsFaults:NO];
	
	NSError *error = nil;
    NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedItems == nil)
    {
        // an error occurred
        NSLog(@"Fetch request returned nil. Error: %@, %@", error, [error userInfo]);

    }
    else  {
		
		self.theArt = [fetchedItems objectAtIndex:0];

		// NSLog(@"Title is %@", [theArt title]);
		
	}
	
	[fetchRequest release];
	
	
	
	// Setup the UI
    
	self.scrollView.frame = CGRectMake(0.0, 0.0, 320.0, 416.0);  // nav bar is 44 and status bar is 20
    
	// yForNextView keeps a running sum of heights and spacers, used to position each subsequent view
	// init value for default case where an image is available
	self.yForNextView = 218.0;
	
	// standard constraint size to be re-used. Was 280.
	CGSize constraintSize = CGSizeMake(MAX_CONTENT_WIDTH, MAXFLOAT);
    
	
	// Logic for request photo, handle missing photo, or show no net:
	
	// if [theArt imageURL] is not defined, show image coming soon message	
	// else: if internet, start image request
    //       else images not available offline
	
	/*
    // For testing a string in Core Data, this works:
	if ([[theArt imageURL] isKindOfClass:[NSString class]]) {
		NSLog(@"image URL is a string that looks like: %@", [theArt imageURL]);
	}
	
	// this also works:
	if ([theArt imageURL] == nil) {
		NSLog(@"image URL is nil");
	}
     
	// Testing for NSNull class does not work.
    */
    
	// Switch to testling for nil and/or length -- class isn't enough for 
	//   collections where you don't control the data.
	if (![[theArt imageURL] isKindOfClass:[NSString class]]) {  
		
		// coming soon handling
		
        // was 20 and 280
		CGRect noPhotoFrame = CGRectMake(HORIZONTAL_PADDING, 20.0, MAX_CONTENT_WIDTH, 50.0); 
		
		UILabel *noPhotoLabel = [[[UILabel alloc] initWithFrame:noPhotoFrame] autorelease];
		
		noPhotoLabel.text = @"(Image Coming Soon)";
		noPhotoLabel.font = [UIFont italicSystemFontOfSize:17.0];
		noPhotoLabel.textAlignment = UITextAlignmentCenter;
		noPhotoLabel.textColor = [UIColor grayColor];
		noPhotoLabel.backgroundColor = [UIColor clearColor];	
		noPhotoLabel.alpha = 1.0;
		
		// hide anything related to the photo
		photoCreditLabel.alpha = 0.0;
		
		// set the image to the placeholder for location fix, if needed
		thePhotoView.image = [UIImage imageNamed:@"location-fix-placeholder"];
		thePhotoView.frame = CGRectMake(HORIZONTAL_PADDING, 20.0, MAX_CONTENT_WIDTH, 10.0);
		thePhotoView.hidden = YES;
		
		[scrollView addSubview:noPhotoLabel];
		
		// Re-define the initial y. The coming soon label needs less room than a photo
		self.yForNextView = 80.0;
		
	}
	
	else { // request the photo
		
		NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
		
		if (status == kReachableViaWiFi || status == kReachableViaWWAN) { 
			
			thePhotoView.image = [UIImage imageNamed:@"photo-placeholder"]; 
			
			thePhotoView.alpha = 0.2;
						
			NSString *urlString = [theArt imageURL];
			
			//NSLog(@"Requesting image at: %@", urlString);
			
			NSURL *url = [NSURL URLWithString:urlString];
			
			self.photoRequest = [ASIHTTPRequest requestWithURL:url];
			
			[[self photoRequest] setDelegate:self];
			[[self photoRequest] startAsynchronous];

			
			// position the photo credit 
			
			photoCreditLabel.lineBreakMode = UILineBreakModeWordWrap;
			photoCreditLabel.baselineAdjustment = UIBaselineAdjustmentNone;
			photoCreditLabel.numberOfLines = 0;
			
            // may need to change with future collections...
			NSString *photoCreditString = [NSString stringWithFormat:@"Image courtesy of %@", [theArt photoCredit]];
			
			CGSize photoCreditSize = [photoCreditString sizeWithFont:photoCreditLabel.font constrainedToSize:constraintSize];
			
			photoCreditLabel.frame = CGRectMake(HORIZONTAL_PADDING, self.yForNextView, constraintSize.width, photoCreditSize.height);
			
			photoCreditLabel.text = photoCreditString;
			
			// not made visible until the photo arrives successfully
			photoCreditLabel.alpha = 0.0; 
			
			self.yForNextView += photoCreditSize.height + 5.0;
			
		}
		else { // no connection

			// NSLog(@"No Internet. No Picture!");
			
			CGRect noNetFrame = CGRectMake(HORIZONTAL_PADDING, 20.0, MAX_CONTENT_WIDTH, 50.0);
			
			UILabel *noNetLabel = [[[UILabel alloc] initWithFrame:noNetFrame] autorelease];
			
			noNetLabel.text = @"(Images not available offline)";
			noNetLabel.font = [UIFont italicSystemFontOfSize:17.0];
			noNetLabel.textAlignment = UITextAlignmentCenter;
			noNetLabel.textColor = [UIColor grayColor];
			noNetLabel.backgroundColor = [UIColor clearColor];	
			noNetLabel.alpha = 1.0;
			
			// hide anything photo-related
			photoCreditLabel.hidden = YES;
	
			thePhotoView.frame = CGRectMake(HORIZONTAL_PADDING, 20.0, MAX_CONTENT_WIDTH, 10.0);
			thePhotoView.hidden = YES;
			
			[scrollView addSubview:noNetLabel];
			
			self.yForNextView = 80.0; // label needs less vertical space than photo
			
		}
		
	}
	
    // At this point, value of yForNextView has been defined conditionally 
    //    based on photo availability.
	
    // Setup Fonts (layout constants defined above implementation)
    
    UIFont *titleFont = [UIFont boldSystemFontOfSize:14.0];
    UIFont *artistFont = [UIFont italicSystemFontOfSize:14.0];
    
    UIFont *locationFont = [UIFont boldSystemFontOfSize:12.0];
    UIFont *detailFont = [UIFont systemFontOfSize:12.0];
	
    // Fonts from original XIB-based Design -- too many sizes!
    // Title: Helvetica Bold Oblique 16
    // Artists: Helvetica Bold 16
    // Details: Helvetica 12
    // Location: Helvetica Bold 14
    // Address: Helvetica 14
    // Desc: Helvetica 17

    // Add labels

    [self addLabelFor:self.theArt.title withPrefix:nil 
            shortened:NO withFont:titleFont sectionBreak:NO];
    
    [self addLabelFor:self.theArt.artists withPrefix:nil 
            shortened:NO withFont:artistFont sectionBreak:YES];
    
    
    NSString *combinedTextForDiscipline = [NSString stringWithFormat:@"%@  %@: %@", 
                                           theArt.artDate, 
                                           [theArt.discipline capitalizedString], 
                                           theArt.medium];
    
    [self addLabelFor:combinedTextForDiscipline withPrefix:nil shortened:NO 
             withFont:detailFont sectionBreak:NO];
    
    
    [self addLabelFor:self.theArt.dimensions withPrefix:@"Dimensions: " 
            shortened:NO withFont:detailFont sectionBreak:YES];
    

    [self addLabelFor:self.theArt.fundingSource withPrefix:@"Funded by " 
            shortened:NO withFont:detailFont sectionBreak:YES];
    
	
	// Location section

    // Position the top of the button even with the location
	// NOTE: locationFix button and VC are not Accessible yet, so they are 
    // intentionally not given label/hint. Might move to action sheet in v1.1.
	
	if ([[theArt locationVerified] boolValue]) {
		self.fixButton.hidden = YES;
	}
	else {
		self.fixButton.hidden = NO;
		self.fixButton.frame = CGRectMake(254.0, self.yForNextView, 
                                     FIX_BUTTON_TAP_TARGET, FIX_BUTTON_TAP_TARGET);
		
		UIImage *fixImage = [UIImage imageNamed:@"72-pin"];
		self.fixButton.imageView.image = fixImage;
		
	}
    
	// location labels need to be narrower to accomodate the button
	
    [self addLabelFor:self.theArt.location withPrefix:nil 
            shortened:YES withFont:locationFont sectionBreak:NO];
    
    // TEST: might need to add an extra 21 in here if it's location is empty

	NSString *combinedAddrCityText;
	
	if ([[theArt location] isEqualToString:[theArt addr1]]) {
		// omit address from 2nd label to leave spacing the same for button
		//NSLog(@"Printing just city here, because address is the same as the location");  
		combinedAddrCityText = [[theArt city] capitalizedString]; // sometimes lowercase in data
	}
	else {
		// print both
		//NSLog(@"Printing both address and city");
		combinedAddrCityText = [NSString stringWithFormat:@"%@, %@", theArt.addr1, [theArt.city capitalizedString]]; // sometimes lowercase in data
	}

    [self addLabelFor:combinedAddrCityText withPrefix:nil 
            shortened:YES withFont:detailFont sectionBreak:YES];
	
	
    // descrip
	
	// resize based on:
	// http://stackoverflow.com/questions/50467/how-do-i-size-a-uitextview-to-its-content/2487402#2487402
	

	if ([[theArt descrip] respondsToSelector:@selector(length)]) {
		
        if ([[theArt descrip] length] > 0) {
			
			descripTextView.text = theArt.descrip;
			
			descripTextView.frame = CGRectMake(HORIZONTAL_PADDING, self.yForNextView, constraintSize.width, descripTextView.contentSize.height);
			
			self.yForNextView += descripTextView.contentSize.height + VERTICAL_PADDING; // spacer at bottom. 40 was too much
		}
		else {
			
			//NSLog(@"Empty description");
			descripTextView.hidden = YES;
			
			self.yForNextView += VERTICAL_PADDING;
		}
	}
	else {
		//NSLog(@"Descrip is not stringy...");
		
		descripTextView.hidden = YES;
		
		self.yForNextView += VERTICAL_PADDING;
	}
	
    
	// Layout complete. Finalize scrollView content size.
    
	scrollView.contentSize = CGSizeMake(320.0, self.yForNextView);
	
}

#pragma mark - Label Generation

- (void)addLabelFor:(NSString *)theLabelText withPrefix:(NSString *)prefix shortened:(BOOL)isShortened withFont:(UIFont *)labelFont sectionBreak:(BOOL)bigBreak {
    
    
    if ([theLabelText length] > 0) { // or test for class or responds to selector?
        
        UILabel *newLabel = [[UILabel alloc] init]; // don't auto release if you store labels in ivars
        
        // pre-sizing configuration
        
        newLabel.lineBreakMode = UILineBreakModeWordWrap;
        newLabel.baselineAdjustment = UIBaselineAdjustmentNone;
        newLabel.numberOfLines = 0; // 0 = it will use as many lines as needed to diplay the text
        
        CGSize constraintSize;
        
        if (isShortened) {
            constraintSize = CGSizeMake(SMALL_LABEL_WIDTH, MAXFLOAT);
        }
        else {
            constraintSize = CGSizeMake(MAX_CONTENT_WIDTH, MAXFLOAT);
        }
        
        // add prefix if needed -- doing this here so it only happens if there is text to display
        
        NSString *prefixedLabelText = nil;
        
        if (prefix) {
            prefixedLabelText = [[NSString alloc] initWithFormat:@"%@%@", prefix, theLabelText];
        }
        else {
            prefixedLabelText = [[NSString alloc] initWithString:theLabelText];
        }
        
        // sizing
        
        CGSize labelSize = [prefixedLabelText sizeWithFont:labelFont constrainedToSize:constraintSize];
        
        newLabel.frame = CGRectMake(HORIZONTAL_PADDING, self.yForNextView, constraintSize.width, labelSize.height);
        
        // other standard configuration
        
        newLabel.text = prefixedLabelText;
        
        newLabel.accessibilityLabel = prefixedLabelText;
        
        newLabel.font = labelFont;
        
        newLabel.textAlignment = UITextAlignmentLeft;
        
        newLabel.textColor = [UIColor blackColor];
        
        newLabel.backgroundColor = [UIColor whiteColor];
        
        newLabel.opaque = YES;
        
        self.yForNextView += newLabel.frame.size.height;
        
        [self.scrollView addSubview:newLabel];
        
        [newLabel release]; // it is retained by scrollView
        
        [prefixedLabelText release];
        
    }
    
    if (bigBreak) {
        self.yForNextView += VERTICAL_PADDING;
    }
    else {
        self.yForNextView += SMALL_VERTICAL_PADDING;
    }
    
    
    
}

-(void)viewWillDisappear:(BOOL)animated {
	
	// kill the request to prevent crashes
	
	[self killRequest];
	
}

#pragma mark -
#pragma mark Memory Stuff

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
    self.photoCreditLabel = nil;
    self.descripTextView = nil;
    self.thePhotoView = nil;
    self.fixButton = nil;
    self.scrollView = nil;
}


- (void)dealloc {
	
	
	[couchID release];
	[theArt release];
	
	[photoRequest release];
    
	[photoCreditLabel release];
	[descripTextView release];
	[thePhotoView release];
	[fixButton release];
	
	// Core Data
	[managedObjectContext_ release];
	
    [super dealloc];
}


@end
