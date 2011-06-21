//
//  pdxPublicArtAppDelegate.h
//  pdxPublicArt
//
//  Created by Matt Blair on 11/20/10.
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

@class ASIHTTPRequest;
@class Reachability;

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface pdxPublicArtAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
	
	// Managing database refresh
	NSNumber *identifierForDatabaseDownload;
	
	// Managing Requests
	ASIHTTPRequest *identifierRequest;
	ASIHTTPRequest *databaseRequest;
	
	// Managing Reachability
    Reachability* internetReach;
	
	// Managing Datastore creation - YES on dev machine only
	BOOL datastoreCreationMode;

@private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (retain) ASIHTTPRequest *identifierRequest;
@property (retain) ASIHTTPRequest *databaseRequest;

@property (nonatomic,retain) NSNumber *identifierForDatabaseDownload;


- (NSString *)applicationDocumentsDirectory;
- (void)saveContext;


// import methods - dev-use only
- (void)importArtToCoreData;
- (void)importPlacesToCoreData;


// data refresh methods

- (void)fetchDataRefreshIdentifier;
- (void)identifierRequestFinished:(ASIHTTPRequest *)request;
- (void)identifierRequestFailed:(ASIHTTPRequest *)request;
- (void)databaseRequestFinished:(ASIHTTPRequest *)request;
- (void)databaseRequestFailed:(ASIHTTPRequest *)request;
- (void)swapDatabaseFiles;
- (void)killRequest;

@end

