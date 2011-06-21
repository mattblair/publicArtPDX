//
//  ArtDetailViewController.h
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

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>  // for email sharing
#import "Art.h"
#import "ArtLocationFixViewController.h"

@class ASIHTTPRequest;

@interface ArtDetailViewController : UIViewController <ArtLocationFixDelegate, MFMailComposeViewControllerDelegate> {
	
	// data
	
	NSString *couchID; //the Couch ID, set before push by either MapVC or LocationListVC
	
	Art *theArt;  // the object retrieved in viewDidLoad
	
	// getting the image
	ASIHTTPRequest *photoRequest;
	
	// UI
	
    CGFloat yForNextView;
    
  	UIScrollView *scrollView;
	UILabel *photoCreditLabel;	
	UITextView *descripTextView;
	UIImageView *thePhotoView;
	UIButton *fixButton;
	
@private

    NSManagedObjectContext *managedObjectContext_;	

}


// data
@property(nonatomic,retain) NSString *couchID;
@property(nonatomic,retain) Art *theArt;

@property(retain) ASIHTTPRequest *photoRequest;

// UI

@property (nonatomic) CGFloat yForNextView;

@property(nonatomic,retain) IBOutlet UIScrollView *scrollView;
@property(nonatomic,retain) IBOutlet UILabel *photoCreditLabel;
@property(nonatomic,retain) IBOutlet UITextView *descripTextView;
@property(nonatomic,retain) IBOutlet UIImageView *thePhotoView;
@property(nonatomic,retain) IBOutlet UIButton *fixButton;

// Core Data
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

// layout
- (void)addLabelFor:(NSString *)theLabelText withPrefix:(NSString *)prefix shortened:(BOOL)isShortened withFont:(UIFont *)labelFont sectionBreak:(BOOL)bigBreak;

// user-initiated 
- (IBAction)shareThisArt:(id)sender;
- (IBAction)updateLocation:(id)sender;

// moved to the future, in case other collections have more online than in db
//- (IBAction)showDetailURL:(id)sender;



// mail delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;


// delegate for modal display
- (void)artLocationFixViewControllerDidFinish:(ArtLocationFixViewController *)controller withSubmission:(BOOL)locationSubmitted;

// request management
- (void)killRequest;

@end





