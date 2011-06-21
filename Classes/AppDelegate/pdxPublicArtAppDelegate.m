//
//  pdxPublicArtAppDelegate.m
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

#import "pdxPublicArtAppDelegate.h"
#import "MapViewController.h"
#import "Art.h"
#import "Place.h"
#import "NSString+SBJSON.h"

// for data refresh code
#import "ASIHTTPRequest.h"
#import "Reachability.h"
#import "databaseConstants.h"
#import "MBProgressHUD.h"

@implementation pdxPublicArtAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize identifierRequest, databaseRequest, identifierForDatabaseDownload;

#pragma mark -
#pragma mark Application lifecycle

- (void)awakeFromNib {    
    
	// Used on dev machine to read JSON and create a new datastore
	datastoreCreationMode = NO;
	
	// To replace RVC in template's MainWindow.xib, select it under Navigation Controller, and:
	// 1. Change Nib name
	// 2. Change class under the info section
	
    MapViewController *mapViewController = (MapViewController *)[navigationController topViewController];
    mapViewController.managedObjectContext = self.managedObjectContext;

}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.

    // Add the navigation controller's view to the window and display.
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];

	
	// run imports, as needed 
	
	if (datastoreCreationMode) {
		
		[self importPlacesToCoreData];
		[self importArtToCoreData];
		
		// find the app dir easily on the simulator:
		NSLog(@"The Application Documents Directory is: %@", [self applicationDocumentsDirectory]);
	}
		
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	
	[self killRequest];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    [self saveContext];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
		
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	*/
	
	// check how long since the last update:
	
	//NSLog(@"Determining whether to refresh data from the web...");
	
	NSDate *lastRefreshDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastDataRefreshDate]; 
	
	// NSLog(@"The last update date is %@", lastRefreshDate);
	
	// DEV Note: need to check for nil, because this will be undefined on first run if PSC isn't installing a db
	if (!lastRefreshDate) {
		
		// Should not be current datestamp. It should be older than a day to force update.
		lastRefreshDate = [NSDate dateWithTimeInterval:-90000.0 sinceDate:[NSDate date]];
		NSLog(@"The last update date re-set to %@", lastRefreshDate);
	}
	
	// NSLog(@"lastRefreshID is a %@", [[NSUserDefaults standardUserDefaults] objectForKey:kLastDataRefreshIdentifier]);
	
	NSTimeInterval timeDiff = [[NSDate date] timeIntervalSinceDate:lastRefreshDate]; // should yield a positive number...
	
	// NSLog(@"The last data refresh was %f seconds ago.", timeDiff);
	
	// TESTING ONLY!!! Force an update:
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:101010.0] forKey:kLastDataRefreshIdentifier];
	
	if (timeDiff > 86400.0) { // 60 seconds x 60 minutes x 24 hours = 86,400   
		
		if (datastoreCreationMode) {
			NSLog(@"Data Refresh blocked by database generation mode. UNBLOCK BEFORE SHIPPING!!!!");
		}
		else {
			// check for the update	
			[self fetchDataRefreshIdentifier];
		}
		
	}
	
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {

	[self killRequest];
    
	[self saveContext];
	
	// remove notifications related to Reachability
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}


- (void)saveContext {
    
    NSError *error = nil;
    if (managedObjectContext_ != nil) {
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            
			// I'm leaving this as-is in v1.0 because the shipping app will never saveContext.
			// That's only used when importing. I want to see the error, and it doesn't matter if it aborts.
            // Could change, depending on storage of favorites, etc.
			
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}    


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
	
	//NSLog(@"Creating a MOC");
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
	
	//NSLog(@"Creating a MOM");
	
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"pdxPublicArt" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
	
	//NSLog(@"Creating a PSC");
	
	// WHEN GENERATING A NEW SQLITE STORE -- DEV USE ONLY:
	// As of 110227: toggle datastoreCreationMode BOOL in awakeFromNib to enable/disable
    //  instead of the steps below
    //
    // Steps to switch to datastore creation:
    // * find documents dir on simulator
    // * delete the current database file
	// * comment out the section below that copies a new db into place if one doesn't exist
	// * uncomment the import routines in didFinishLaunching:WithOptions:
	// * comment out the check for a new database on server in applicationDidBecomeActive
	// * run the app, and copy the database file into project folders

	// Note: If prepping for an app beta or store release:
	// * copy the database file into the bundle
	// * change filename, date and identifiers below to reflect date of import


	
	if (datastoreCreationMode) {
		NSLog(@"DEV USE ONLY!!! App is in datastore creation mode. CHANGE BEFORE SHIPPING TO BETA OR STORE");
	}
	else {
		
        // Verify existence of database, copy default database if needed

		NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kActiveDatabaseFilename];
		
		// NSLog(@"The storePath is: %@", [storePath description]);
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (![fileManager fileExistsAtPath:storePath]) {
			
			NSLog(@"No database found in app's Documents directory...");
			
            NSString *databaseFromBundle = [[NSBundle mainBundle] pathForResource:kBundledDatabaseFilename ofType:@"sqlite"];
            
            
			//NSLog(@"The location of the database in the bundle is: %@", [databaseFromBundle description]);
			
			if (databaseFromBundle) {  //if default database found
				
				[fileManager copyItemAtPath:databaseFromBundle toPath:storePath error:NULL];
				
				NSLog(@"Installed default database from bundle into app's documents directory...");
				
				// set the refresh ID to the database installed, and date to the date of that database
				// IMPORTANT: these settings should force a check of id on very first run of the app
				
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:110612.0] forKey:kLastDataRefreshIdentifier];
				
				// should be set to the database build date, not app install date!!!
				
				NSDateFormatter *buildDateFormatter = [[NSDateFormatter alloc] init];
				
				[buildDateFormatter setDateFormat:@"yyyy-MM-dd"];
				
				NSDate *lastRefreshDate = [buildDateFormatter dateFromString:@"2011-06-12"];
				
				[[NSUserDefaults standardUserDefaults] setObject:lastRefreshDate forKey:kLastDataRefreshDate];  
				
				NSLog(@"lastRefreshDate set to %@", [lastRefreshDate description]);
				
				[buildDateFormatter release];
			}
		}
	}

	
	// connect to database	
	
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kActiveDatabaseFilename]];
	
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error creating PSC %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator_;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark -
#pragma mark Refresh Data

-(void)fetchDataRefreshIdentifier {
	
	// request the latest idenitifier
	//NSLog(@"Fetching the data identifier...");
	
	// Decided to use http in the constant, since https fails too frequently
	NSString *identifierURL = kURLForLatestRelease;
	
	// Check Reachability first
	// don't use a host check on the main thread because of possible DNS delays...
	
	NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
	
	if (status == kReachableViaWiFi || status == kReachableViaWWAN) {  // only do this if it is WiFi?
		
		//NSLog(@"starting request to: %@", identifierURL);
		
		// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
		// method "reachabilityChanged" will be called. 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) 
													 name: kReachabilityChangedNotification 
												   object: nil];
		
		internetReach = [[Reachability reachabilityForInternetConnection] retain];
		[internetReach startNotifier];
		
		// initialize this as nil, so it only has value if identifierRequestFinished decides to download db
		self.identifierForDatabaseDownload = nil;
		
		NSURL *url = [NSURL URLWithString:identifierURL];
		
		//start request
		self.identifierRequest = [ASIHTTPRequest requestWithURL:url];
		
		[[self identifierRequest] setDidFinishSelector:@selector(identifierRequestFinished:)];
		[[self identifierRequest] setDidFailSelector:@selector(identifierRequestFailed:)];
		
		// After auth failures, I moved the datastores to a public, read-only couch to reduce complexity
		//[[self identifierRequest] setUsername:kUpdateUsername];
		//[[self identifierRequest] setPassword:kUpdatePassword];
		
		[[self identifierRequest] setDelegate:self];
		[[self identifierRequest] startAsynchronous];
		
		
	} // if reachable by wifi or wwan
	
	else {
		
		// Fail quietly. Just log it for now, or omit altogether?
		NSLog(@"No connection to check for latest database identifier...");
		
	}

}


- (void)identifierRequestFinished:(ASIHTTPRequest *)request {
	
	// test id against local and init data download if needed
	
	NSString *responseString = [request responseString];
	
	if ([request responseStatusCode] == 200) {
		
		if ([[responseString JSONValue] isKindOfClass:[NSDictionary class]]) {
					
			// fake value for testing
			//NSNumber *webIdentifier = [NSNumber numberWithDouble:101208];
			
			NSDictionary *releaseDict = [responseString JSONValue];
			
			NSNumber *webIdentifier = [releaseDict objectForKey:@"dataVersion"];  // changed from data_version
			
			NSNumber *localIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:kLastDataRefreshIdentifier];
			
			NSLog(@"The web identifier is: %@", webIdentifier);
			NSLog(@"The local identifier is: %@", localIdentifier);
			
			// check metadata version, too, in subsequent versions!!!
			
			if ([webIdentifier doubleValue] > [localIdentifier doubleValue]) {
				
				// needs to update
				NSLog(@"Start download of %@", [releaseDict objectForKey:@"fileURL"]);
				
				// track the identifier of the database you're downloading
				self.identifierForDatabaseDownload = webIdentifier;
				
				self.databaseRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[releaseDict objectForKey:@"fileURL"]]];
				
				[[self databaseRequest] setDidFinishSelector:@selector(databaseRequestFinished:)];
				[[self databaseRequest] setDidFailSelector:@selector(databaseRequestFailed:)];
				
				// shouldn't be needed any longer...
				//[[self databaseRequest] setUsername:kUpdateUsername];
				//[[self databaseRequest] setPassword:kUpdatePassword];
				
				[[self databaseRequest] setDelegate:self];
				[[self databaseRequest] startAsynchronous];
				
				// do not change the localIdentifier here, in case the process fails further along
				
			}
			else {
				NSLog(@"No update needed.");
				
				// reset date so the request isn't made for another 24+ hours.
				[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastDataRefreshDate];
			}
			
		}
		else {
			NSLog(@"Unexpected JSON received from the server...");
			NSLog(@"It looks like this: %@", responseString);
		}
	
	}
	else {
		
        // non-200 response from the server
		NSLog(@"Identifier Request HTTP Status code was: %d", [request responseStatusCode]);
		NSLog(@"It looks like this: %@", responseString);
		
	}	
	
	self.identifierRequest = nil;
		
}


- (void)identifierRequestFailed:(ASIHTTPRequest *)request {
	
	// log the error, but fail silently

	NSLog(@"Request for new identifier failed...");
	
	NSLog(@"Identifier Request HTTP Status code was: %d", [request responseStatusCode]);
	
	// to make sure the authentication faiilure doesn't cause subsequent requests to fail
	[ASIHTTPRequest clearSession];
	
    self.identifierRequest = nil;
    
}


- (void)databaseRequestFinished:(ASIHTTPRequest *)request {
	
	// handle the arrival of the data
	
	NSData *responseData = [request responseData];
	
	if ([request responseStatusCode] == 200) {
		
        // save the data and do the swap
		
		NSString *newDatabasePath = [NSString stringWithFormat:@"%@/%@", [self applicationDocumentsDirectory], kNewDatabaseFilename];
		
		//NSLog(@"Database download successful. Saving to: %@", newDatabasePath);
		
		[responseData writeToFile:newDatabasePath atomically:YES];
		
		// call the swap method if Map VC is on top -- freeze UI here for notification?
		
		if ([[navigationController topViewController] isKindOfClass:[MapViewController class]]) {
			
			NSLog(@"Map VC is on top. Going to call swapDatabaseFiles...");
			[self swapDatabaseFiles];
			
		}
				
	}
	else {
        
		NSLog(@"Database Request HTTP Status code was: %d", [request responseStatusCode]);
		//NSLog(@"It looks like this: %@", responseString);
        
	}

	self.databaseRequest = nil;
	
}


- (void)databaseRequestFailed:(ASIHTTPRequest *)request {
	
	// log the error, don't take any action in production code
	
	// NSLog(@"Request for the database file failed...");
    
    self.databaseRequest = nil;
	
}


// This method is due for a major overhaul, depending on future sync design.
- (void)swapDatabaseFiles {
	
	NSLog(@"Start of swapDatabaseFiles.");
    
	// Start the HUD to prevent any interaction.
	// Need to operate it manually, because the showWhileExecuting method runs the selector on a new thread, 
	//   and it seems like that could cause problems with Core Data.
	
	// The hud will disable all input on the view.

	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];

	hud.labelText = @"Updating Art List...";

	// bring down Core Data and swap
	// databaseRequestFinished has already checked if the Map VC is at the top of the nav stack
	
	MapViewController *mapViewController = (MapViewController *)[navigationController topViewController];
    mapViewController.managedObjectContext = nil;
	//NSLog(@"Just set map.moc to nil");
	
	NSPersistentStore *theOnlyStore = [[[self persistentStoreCoordinator] persistentStores] objectAtIndex:0];
	
	[[self persistentStoreCoordinator] removePersistentStore:theOnlyStore error:nil];
	
	// Class reference says singleton is no longer the preferred way...
	//NSFileManager *fileManager = [NSFileManager defaultManager];
	// Replaced with:
	
	NSFileManager *databaseFileManager = [[NSFileManager alloc] init];
		
	NSString *activeDatabasePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kActiveDatabaseFilename];
	NSString *newDatabasePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kNewDatabaseFilename];
	NSString *oldDatabasePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kBackupDatabaseFilename];
	
	//NSLog(@"active: %@", activeDatabasePath);
	//NSLog(@"new: %@", newDatabasePath);
	
    /*
	if ([databaseFileManager fileExistsAtPath:activeDatabasePath]) {
		NSLog(@"File manager found the active database.");
	}
	
	if ([databaseFileManager fileExistsAtPath:newDatabasePath]) {
		NSLog(@"File manager found the new database.");
	}
    */
	
	/*
	This method is supposed to be the safe way to do this, but it fails every time, and returns:
	 
	Error swapping database files. Error: (null) & (null)
     
    NOTE from 110512: I bet it's a path v. URL type thing...
	
	NSError *error;
	NSURL *theResultingURL = nil;
	
	// trying without options set to NSFileManagerItemReplacementWithoutDeletingBackupItem
	
	if (![databaseFileManager replaceItemAtURL:[NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kActiveDatabaseFilename]]
						 withItemAtURL:[NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kNewDatabaseFilename]]
						backupItemName:kBackupDatabaseFilename 
							   options:0
					  resultingItemURL:&theResultingURL
								 error:&error]) {
		
		// 
		NSLog(@"Error swapping database files. Error: %@ & %@", [error localizedDescription], [error userInfo]);
		
		// clean up the mess
		
	}
	*/
	
	// Move the files around manually instead
	
	// delete .old database file if it exists
	
	if ([databaseFileManager fileExistsAtPath:oldDatabasePath]) {
		NSLog(@"Deleting old file...");
		
		NSError *removeError;
		if (![databaseFileManager removeItemAtPath:oldDatabasePath error:&removeError]) {
			
			NSLog(@"Error removing old database: %@", [removeError localizedDescription]);
		}
	}
	else {
		NSLog(@"No old file to delete...");
	}
	
	// copy current to .old
	NSError *archiveError;
	if (![databaseFileManager moveItemAtPath:activeDatabasePath toPath:oldDatabasePath error:&archiveError]) {
		NSLog(@"Error moving active database to old: %@", [archiveError localizedDescription]);
	}
	
	// copy .new to the current db name
	
	NSError *installError;
	if (![databaseFileManager moveItemAtPath:newDatabasePath toPath:activeDatabasePath error:&installError]) {
		NSLog(@"Error moving new database to active position: %@", [installError localizedDescription]);	
	}
	
	
	// bring Core Data back online directly, using boilerplate code
	
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kActiveDatabaseFilename]];
	
	NSError *error;
	if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType 
												   configuration:nil 
															 URL:storeURL 
														 options:nil 
														   error:&error]) {

		// Test when it comes back up
		
		// if there is a problem, move the old db file back in, retest
		
		// if there is still a problem, revert to db in bundle, set last_database_refresh to nil
		
		// May need to compare metadata, too?
		
		NSLog(@"Unresolved error re-creating PSC %@, %@", error, [error userInfo]);
        abort();
    }    
	
	// re-init the MOC

	[self managedObjectContext];	

	if (self.managedObjectContext == nil) {
		NSLog(@"appDelegate MOC is still nil");
	}	
	
    // hand it back to the Map VC
	mapViewController.managedObjectContext = self.managedObjectContext;
	
	// NSLog(@"Map VC's MOC set");	
	
	// Update identifier and date in userDefaults to reflect the database just installed
	[[NSUserDefaults standardUserDefaults] setObject:self.identifierForDatabaseDownload forKey:kLastDataRefreshIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastDataRefreshDate];

		
	// update UI -- need to add a pause here!
	NSLog(@"Database swap complete. Closing HUD.");
	hud.removeFromSuperViewOnHide = YES;
	
	[hud hide:YES];
	
	[databaseFileManager release];
	
}

- (void)killRequest {
	
	if ([[self identifierRequest] inProgress]) {
		
		// NSLog(@"Request is in progress, about to cancel.");		
		
		[[self identifierRequest] cancel];
		
		// NSLog(@"Request cancelled.");
		
	}
	
	if ([[self databaseRequest] inProgress]) {
		
		// NSLog(@"Database request is in progress, about to cancel.");		
		
		[[self databaseRequest] cancel];
		
		// NSLog(@"Database request cancelled.");
		
	}
	
}


#pragma mark -
#pragma mark Reachability Handling

-(void)reachabilityChanged: (NSNotification* )note {
	
	// respond to changes in reachability
	
	Reachability *currentReach = [note object];
	
	NetworkStatus status = [currentReach currentReachabilityStatus];
	
	if (status == NotReachable) {  
		
		[self killRequest];
		
		NSLog(@"App Delegate notified by Reachability that the app has lost internet connectivity.");
		
	}
	
}


#pragma mark -
#pragma mark Import Data from JSON (Dev-use only)

// Eventually this whole section should go in an OS X helper app that generates 
// the replacement SQLite databases automatically.
// Or Binary plists, whichever is better.

- (void)importArtToCoreData {
	
	// This one is just an array of objects (unlike the docs key in the geoindex place JSON)
	
	// Performance: almost 2 seconds to import 373 art documents in my iMac
	
	NSString *filepath = [[NSBundle mainBundle] pathForResource:kPublicArtJSONFilename ofType:@"json"];
	
	NSError *fileLoadError;
	
	NSString *artJSON = [NSString stringWithContentsOfFile:filepath 
													encoding:NSUTF8StringEncoding 
													   error:&fileLoadError];
	
	NSArray *artArray = [artJSON JSONValue];
	
	NSLog(@"There are %d art objects to process", [artArray count]);
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	
	for (NSDictionary *artDict in artArray) {
		
		Art *newArt = nil;
		
		newArt = (Art *)[NSEntityDescription insertNewObjectForEntityForName:@"Art" 
														  inManagedObjectContext:[self managedObjectContext]];
		
		// collection
		if (![[artDict valueForKey:@"collection"] isKindOfClass:[NSNull class]]) {
			[newArt setCollection:[artDict valueForKey:@"collection"]];
		}
		
		
		// title
		if (![[artDict valueForKey:@"title"] isKindOfClass:[NSNull class]]) {
			[newArt setTitle:[artDict valueForKey:@"title"]];
		}
		
		// medium
		if (![[artDict valueForKey:@"medium"] isKindOfClass:[NSNull class]]) {
			[newArt setMedium:[artDict valueForKey:@"medium"]];
		}
		
		// fundingSource
		if (![[artDict valueForKey:@"fundingSource"] isKindOfClass:[NSNull class]]) {
			[newArt setFundingSource:[artDict valueForKey:@"fundingSource"]];
		}
		
		// artDate -- note: this is not necessarily a number in the original data
		if (![[artDict valueForKey:@"date"] isKindOfClass:[NSNull class]]) {
			[newArt setArtDate:[artDict valueForKey:@"date"]];
		}
		
		// couchID
		if (![[artDict valueForKey:@"_id"] isKindOfClass:[NSNull class]]) {
			[newArt setCouchID:[artDict valueForKey:@"_id"]];
		}
		
		// recordID
		if (![[artDict valueForKey:@"recordID"] isKindOfClass:[NSNull class]]) {
			[newArt setRecordID:[artDict valueForKey:@"recordID"]];
		}
		
		// location
		if (![[artDict valueForKey:@"location"] isKindOfClass:[NSNull class]]) {
			[newArt setLocation:[artDict valueForKey:@"location"]];
		}
		
		// Reach into the geometry key
		
		NSDictionary *geometryDict = [artDict valueForKey:@"geometry"];
		
		NSArray *coordArray = [geometryDict valueForKey:@"coordinates"];
		
		// NSNumber *latitude;
        // Explainer: The value returned by artDict for latitude is a string.
        // Take the doubleValue of that, then convert it into an NSNumber to set the entity attribute.
		[newArt setLatitude:[NSNumber numberWithDouble:[[coordArray objectAtIndex:1] doubleValue]]];
		
		// NSNumber *longitude;
		[newArt setLongitude:[NSNumber numberWithDouble:[[coordArray objectAtIndex:0] doubleValue]]];
		
		// city
		if (![[artDict valueForKey:@"addrCity"] isKindOfClass:[NSNull class]]) {
			[newArt setCity:[artDict valueForKey:@"addrCity"]];
		}
		
		// addr1
		if (![[artDict valueForKey:@"addrStreet"] isKindOfClass:[NSNull class]]) {
			[newArt setAddr1:[artDict valueForKey:@"addrStreet"]];
		}
		
		// state
		if (![[artDict valueForKey:@"addrState"] isKindOfClass:[NSNull class]]) {
			[newArt setState:[artDict valueForKey:@"addrState"]];
		}
		
		// zip
		if (![[artDict valueForKey:@"addrZip"] isKindOfClass:[NSNull class]]) {
			[newArt setZip:[artDict valueForKey:@"addrZip"]];
		}
		
		
		// modifiedDate -- convert to a real date
		if (![[artDict valueForKey:@"dateModified"] isKindOfClass:[NSNull class]]) {
			
			// convert the string to a date
			// format in JSON: 
			//    "Date_Modified": "2010-09-24 00:00:00"
			
			// set date formatter to nil? if not, move this up top so you aren't setting it over and over
            // this is simulator-only utility code, so it will never run on the device anyway.
			[dateFormatter setDateFormat:@"YYYY-MM-DD HH:mm:ss"];
			
			
			if ([[dateFormatter dateFromString:[artDict valueForKey:@"dateModified"]] isKindOfClass:[NSDate class]]) {
				[newArt setModifiedDate:[dateFormatter dateFromString:[artDict valueForKey:@"dateModified"]]];
			}
			
		}
		
		
		// descrip
		if (![[artDict valueForKey:@"description"] isKindOfClass:[NSNull class]]) {
			[newArt setDescrip:[artDict valueForKey:@"description"]];
		}
		
		// dimensions
		if (![[artDict valueForKey:@"dimensions"] isKindOfClass:[NSNull class]]) {
			[newArt setDimensions:[artDict valueForKey:@"dimensions"]];
		}
		
		
		// discipline
		if (![[artDict valueForKey:@"discipline"] isKindOfClass:[NSNull class]]) {
			[newArt setDiscipline:[artDict valueForKey:@"discipline"]];
		}
		
		// mappableDiscipline
		if (![[artDict valueForKey:@"mappableDiscipline"] isKindOfClass:[NSNull class]]) {
			[newArt setMappableDiscipline:[artDict valueForKey:@"mappableDiscipline"]];
		}
		
		// imageURL	
		if (![[artDict valueForKey:@"imageURL"] isKindOfClass:[NSNull class]]) {
			[newArt setImageURL:[artDict valueForKey:@"imageURL"]];
		}
		
		// detailURL
		if (![[artDict valueForKey:@"detailPageURL"] isKindOfClass:[NSNull class]]) {
			[newArt setDetailURL:[artDict valueForKey:@"detailPageURL"]];
		}
		
		// artists
		if (![[artDict valueForKey:@"artists"] isKindOfClass:[NSNull class]]) {
			[newArt setArtists:[artDict valueForKey:@"artists"]];
		}
		
		// dataSource
		if (![[artDict valueForKey:@"dataSource"] isKindOfClass:[NSNull class]]) {
			[newArt setDataSource:[artDict valueForKey:@"dataSource"]];
		}
		
		
		// Metadata version 101207
        
		// newWork defaults to NO, the other two are null
		
		// newWork (BOOL stored as NSNumber by Core Data)
		
		// newWorkUntilDate (date)
		
		// audioURL (NSString)
		
		
		
		
		// Metadata version 101220
		
		
		// strings:
		
		// artCopyright  (default: "The Artists")
		if (![[artDict valueForKey:@"artCopyright"] isKindOfClass:[NSNull class]]) {
			[newArt setArtCopyright:[artDict valueForKey:@"artCopyright"]];
		}		
		
		// photoCredit (in v1.0, defaults to RACC)
		if (![[artDict valueForKey:@"photoCredit"] isKindOfClass:[NSNull class]]) {
			[newArt setPhotoCredit:[artDict valueForKey:@"photoCredit"]];
		}
		
		// originalThumbnailURL (defaults to RACC location of thumbnail, as listed in RACC/BTS data)
		if (![[artDict valueForKey:@"originalThumbnailURL"] isKindOfClass:[NSNull class]]) {
			[newArt setOriginalThumbnailURL:[artDict valueForKey:@"originalThumbnailURL"]];
		}
		
		// thumbnailURL (current location, i.e. CouchOne)
		if (![[artDict valueForKey:@"thumbnailURL"] isKindOfClass:[NSNull class]]) {
			[newArt setThumbnailURL:[artDict valueForKey:@"thumbnailURL"]];
		}		
				
		// locationVerified (default: NO)
		if (![[artDict valueForKey:@"locationVerified"] isKindOfClass:[NSNull class]]) {
			if ([[artDict valueForKey:@"locationVerified"] isEqualToString:@"YES"]) {
				[newArt setLocationVerified:[NSNumber numberWithBool:YES]];
			}
			else {
				[newArt setLocationVerified:[NSNumber numberWithBool:NO]];
			}
			
		}	
		
		
		// save
		NSError *error;
		if (![[self managedObjectContext] save:&error]) {
			NSLog(@"Error adding place - error:%@",error);
			break;
		}
		
	}
	
	[dateFormatter release];
	
	NSLog(@"All art imported...");
	
}

- (void)importPlacesToCoreData {
	
	// Reads the JSON file generated for public_art_geoindex.
	// This file has a dictionary with one pair: docs as key, value is an array of place objects
	
	// Performance: Took ~600ms for 146 records on iMac
	
	NSString *filepath = [[NSBundle mainBundle] pathForResource:kPublicArtGeoIndexJSONFilename ofType:@"json"];
	
	NSError *fileLoadError;
	
	NSString *placeJSON = [NSString stringWithContentsOfFile:filepath 
													encoding:NSUTF8StringEncoding 
													   error:&fileLoadError];
	
	
	NSArray *placeArray = [[placeJSON JSONValue] objectForKey:@"docs"];
	
	NSLog(@"There are %d place objects to process", [placeArray count]);
	
	
	for (NSDictionary *placeDict in placeArray) {
		
		Place *newPlace = nil;
		
		newPlace = (Place *)[NSEntityDescription insertNewObjectForEntityForName:@"Place" 
														  inManagedObjectContext:[self managedObjectContext]];
		
		// location
		if (![[placeDict valueForKey:@"location"] isKindOfClass:[NSNull class]]) {
			[newPlace setLocation:[placeDict valueForKey:@"location"]];
		}
		 
		// Reach into the geometry key
		
		NSDictionary *geometryDict = [placeDict valueForKey:@"geometry"];
		
		NSArray *coordArray = [geometryDict valueForKey:@"coordinates"];
		
		[newPlace setLatitude:[NSNumber numberWithDouble:[[coordArray objectAtIndex:1] doubleValue]]];
		
		[newPlace setLongitude:[NSNumber numberWithDouble:[[coordArray objectAtIndex:0] doubleValue]]];
		
        
		if (![[placeDict valueForKey:@"_id"] isKindOfClass:[NSNull class]]) {
			[newPlace setCouchID:[placeDict valueForKey:@"_id"]];
		}
		
		if (![[placeDict valueForKey:@"title"] isKindOfClass:[NSNull class]]) {
			[newPlace setTitle:[placeDict valueForKey:@"title"]];
		}
		
		if (![[placeDict valueForKey:@"discipline"] isKindOfClass:[NSNull class]]) {
			[newPlace setDiscipline:[placeDict valueForKey:@"discipline"]];
		}
		
		if (![[placeDict valueForKey:@"recordID"] isKindOfClass:[NSNull class]]) {
			[newPlace setRecordID:[placeDict valueForKey:@"recordID"]];
		}
		
		if (![[placeDict valueForKey:@"artists"] isKindOfClass:[NSNull class]]) {
			[newPlace setArtists:[placeDict valueForKey:@"artists"]];
		}
		
		// Metadata version 101207
		// newWork defaults to NO, so I'm not specifying it yet
		
		// newWork (BOOL stored as NSNumber by Core Data)
		
		
		
		// Metadata version 101220
		
		
		// thumbnailURL
		if (![[placeDict valueForKey:@"thumbnailURL"] isKindOfClass:[NSNull class]]) {
			[newPlace setThumbnailURL:[placeDict valueForKey:@"thumbnailURL"]];
		}		

		
		// save it
		
		NSError *error;
		if (![[self managedObjectContext] save:&error]) {
			NSLog(@"Error adding place - error:%@",error);
			break;
		}
	}
	
	NSLog(@"Places imported...");
	
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
	
	[self killRequest];
}


- (void)dealloc {
    
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    
	[identifierRequest release];
	[databaseRequest release];
	
	[identifierForDatabaseDownload release];
	
    [navigationController release];
    [window release];
    [super dealloc];
}


@end

