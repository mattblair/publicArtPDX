//
//  AboutViewController.m
//  pdxPublicArt
//
//  Created by Matt Blair on 12/8/10.
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

#import "AboutViewController.h"
#import "Reachability.h"

@implementation AboutViewController

@synthesize theWebView;

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

#pragma mark -
#pragma mark View Stuff

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.theWebView.delegate = self;
	
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	
	internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifier];
	
	
	// load the about page
	
	
	// we want these kinds of pages to scale:
	theWebView.scalesPageToFit = YES;
	
	// setup the about request here
	
	self.navigationItem.title = @"About";
	
	[self loadLocalAboutPage];
	
	// setup the nav buttons
	
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"back-dingy"],
											 [UIImage imageNamed:@"fwd-dingy"],
											 nil]];
	
	[segmentedControl addTarget:self action:@selector(navigateWebView:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0, 0, 90, 30);  // height was kCustomButtonHeight, but I'm picky
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	[segmentedControl release];
	
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[segmentBarItem release];
		
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self.theWebView stopLoading];	// in case the web view is still loading its content

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark -
#pragma mark Reachability Handling

-(void)reachabilityChanged: (NSNotification* )note {
	
	// respond to changes in reachability
	
	Reachability *currentReach = [note object];
	
	NetworkStatus status = [currentReach currentReachabilityStatus];
	
	if (status == NotReachable) {  
		[[self theWebView] stopLoading];
		
		NSLog(@"About View Controller: Connection failed in the middle of a web request.");
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Lost" 
														message:@"Please try again when an internet connection is available." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		
		
	}
	
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
	
	// check reachability here for everything except the locally loaded about page
	
	NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
	
	if (status == kReachableViaWiFi || status == kReachableViaWWAN) { 
		return YES;
	}
	else {  // no internet connection
		
		if ([[request URL] isFileURL]) { 
			return YES;
		}
		
		else {
			
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Connection" 
															message:@"Please try again when an internet connection is available." 
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			[alert show];
			[alert release];
			
			
			return NO;
		}
		
		
	}
	
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[self updateNavButtons];
	
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// load error, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	//NSLog(@"webView request failed with error: %@", [error localizedDescription]);
	

	// if the webview can go back, take them back
	
	if (theWebView.canGoBack) {
		[theWebView goBack];
	}
	else {
		//reload 
		[self loadLocalAboutPage];
	}

	// show an alertview
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Page Not Found" 
													message:@"Sorry, there was a problem with that link. Please try again in a few moments." 
												   delegate:self 
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
	
	[self updateNavButtons];
	
}



#pragma mark -
#pragma mark Handling Web Navigation

-(void)updateNavButtons {
	
	
	UISegmentedControl *segControl = (UISegmentedControl *)self.navigationItem.rightBarButtonItem.customView;
	
    // Alternate way to write this, which seems less clear...
    
    //[segControl setEnabled:self.theWebView.canGoBack forSegmentAtIndex:0];
    //[segControl setEnabled:self.theWebView.canGoForward forSegmentAtIndex:1];
    
    
	// back
	
	if (theWebView.canGoBack) {
		[segControl setEnabled:YES forSegmentAtIndex:0];
	}
	else {
		[segControl setEnabled:NO forSegmentAtIndex:0];
	}
	
	
	// forward
	
	if (theWebView.canGoForward) {
		[segControl setEnabled:YES forSegmentAtIndex:1];
	}
	else {
		[segControl setEnabled:NO forSegmentAtIndex:1];
	}
	
}


-(IBAction)navigateWebView:(id)sender {
	
	//cast and determine whether to go forward or back
	UISegmentedControl *segControl = (UISegmentedControl *)sender;
	
	// or use a switch?  could this be called with anything else but 0 or 1?
	
	if ([segControl selectedSegmentIndex] == 0) {
		//NSLog(@"Tapped Back");
		[theWebView goBack];
	}
	else {
		//NSLog(@"Tapped Forward");
		[theWebView goForward];
	}
	
	
}


-(void)loadLocalAboutPage {

	NSString *localAboutHTML = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
	NSURL *url = [NSURL fileURLWithPath:localAboutHTML];
	
	// NSLog(@"About to request the URL: %@", localAboutHTML);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	
	[theWebView loadRequest:request];
	
}



#pragma mark -
#pragma mark Memory stuff

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}



- (void)dealloc {
    
	[theWebView release];
	
	[super dealloc];
	
	
}


@end
