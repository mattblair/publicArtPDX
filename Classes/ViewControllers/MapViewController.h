//
//  MapViewController.h
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

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>  
#import <MessageUI/MessageUI.h>
#import "LegendViewController.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, LegendViewControllerDelegate, UISearchBarDelegate, MFMailComposeViewControllerDelegate> {
	
	MKMapView *artMapView;
	UIButton *infoButton;
	UIBarButtonItem *refreshButton;
	UIBarButtonItem *locationButton;
	
	UISearchBar *theSearchBar;
	
	CLLocationManager *locationManager;		
		
	BOOL locationReallyEnabled;  // to handle CL behavior in iOS 4.1
	
	
	// Managing search
	BOOL filteredBySearch;
	NSString *currentSearchString;
	
	
@private

    NSManagedObjectContext *managedObjectContext_;	

}

@property (nonatomic, retain) IBOutlet MKMapView *artMapView;
@property (nonatomic, retain) IBOutlet UIButton *infoButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *refreshButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *locationButton;

@property (nonatomic, retain) UISearchBar *theSearchBar; // manage it all in code, not xib

@property (nonatomic, retain) CLLocationManager *locationManager;

@property (nonatomic) BOOL filteredBySearch;
@property (nonatomic, retain) NSString *currentSearchString;


@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;


-(void)addToolbarItems;

// User-initiated actions
- (IBAction)showAboutPage:(id)sender;
- (IBAction)refreshTheMap:(id)sender;
- (IBAction)showMapLegend:(id)sender;
- (IBAction)addNewArtwork:(id)sender;
- (IBAction)showSearch:(id)sender;
- (IBAction)goToLocation:(id)sender;

// search
-(void)displaySearchBar;
-(void)hideSearchBar;
-(void)removeSearchFilter;

// map management
-(void)refreshArtOnMap;
-(NSArray *)createArtAnnotationArray:(NSArray *)placeArray;
-(MKCoordinateRegion)makeRegionForAnnotationArray:(NSArray *)placeArray;


// mail delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;


// for modal presentations
- (void)legendViewControllerDidFinish:(LegendViewController *)controller;


@end
