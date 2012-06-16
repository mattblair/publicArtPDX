//
//  ArtLocationFixViewController.h
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

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>  // I don't think you need core location...
#import "Art.h"

@class ASIHTTPRequest;
@class MBProgressHUD;

@protocol ArtLocationFixDelegate;

@interface ArtLocationFixViewController : UIViewController <MKMapViewDelegate> {
	
	//data
	
	Art *theArt;  // set by ArtDetailVC so this VC doesn't need Core Data
	
	UIImage *thePhoto; // set by ArtDetailVC, which has already downloaded it. Hopefully...
	
	NSNumber *suggestedLatitude;
	NSNumber *suggestedLongitude;

	
	id <ArtLocationFixDelegate> delegate;
	
	// to directly manage the request
	
	ASIHTTPRequest *locationSubmitRequest;
	
	// managing Reachability -- needed if you add a notification, which seems overkill for such a small POST
    // Reachability* internetReach;
	
	
	
	// UI
	
	UIImageView *thumbnail;
	
	UIBarButtonItem *cancelButton;
	UIBarButtonItem *saveButton;
	
	MKMapView *fixMapView;
	
	MBProgressHUD *uploadHUD; 

}

// data

@property(nonatomic,retain) Art *theArt;
@property(nonatomic,retain) UIImage *thePhoto;
@property(nonatomic,retain) NSNumber *suggestedLatitude;
@property(nonatomic,retain) NSNumber *suggestedLongitude;

@property(nonatomic, retain) id <ArtLocationFixDelegate> delegate;

@property(retain) ASIHTTPRequest *locationSubmitRequest;


// UI

@property(nonatomic,retain) IBOutlet UIImageView *thumbnail;
@property(nonatomic,retain) IBOutlet UIBarButtonItem *cancelButton;
@property(nonatomic,retain) IBOutlet UIBarButtonItem *saveButton;

@property(nonatomic,retain) IBOutlet MKMapView *fixMapView;

@property(nonatomic,retain) MBProgressHUD *uploadHUD;

- (IBAction)submitLocation:(id)sender;
- (IBAction)cancelSubmission:(id)sender;

- (void)killRequest;

@end

@protocol ArtLocationFixDelegate

	// handle return from this VC
	- (void)artLocationFixViewControllerDidFinish:(ArtLocationFixViewController *)controller withSubmission:(BOOL)locationSubmitted;

@end