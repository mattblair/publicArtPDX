//
//  databaseConstants.h
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

extern NSString * const kUpdateUsername;
extern NSString * const kUpdatePassword;
extern NSString * const kURLForUpdates;
extern NSString * const kURLForLatestRelease;

extern NSString * const kNewDatabaseFilename;
extern NSString * const kBackupDatabaseFilename;
extern NSString * const kActiveDatabaseFilename;

extern NSString * const kBundledDatabaseFilename;

// keys for user defaults
extern NSString * const kLastDataRefreshIdentifier;
extern NSString * const kLastDataRefreshDate;

// for submitting missing and new artwork
extern NSString * const kSubmissionEmailAddress;
extern NSString * const kEmailFooter;

extern NSString * const kPublicArtJSONFilename;
extern NSString * const kPublicArtGeoIndexJSONFilename;



/*

To build, you need a databaseConstants.m file that has the following:

#import "databaseConstants.h"
 
NSString * const kUpdateUsername = @"<username>";
NSString * const kUpdatePassword = @"<password>";
 
 
NSString * const kURLForUpdates = @"http://example.com/database";
 
// specific to metadata version 101220, changed to non-secure read
NSString * const kURLForLatestRelease = @"http://example.com/database/core_data_v101220"; 
 
 
NSString * const kNewDatabaseFilename = @"pdxPublicArt.sqlite.new";
NSString * const kBackupDatabaseFilename = @"pdxPublicArt.sqlite.old";
NSString * const kActiveDatabaseFilename = @"pdxPublicArt-md101220.sqlite";  
 
NSString * const kBundledDatabaseFilename = @"pdxPublicArt-r110612"; // without sqlite
 
 
// keys for user defaults
NSString * const kLastDataRefreshIdentifier = @"kLastDataRefreshIdentifier";
NSString * const kLastDataRefreshDate = @"kLastDataRefreshDate";
 
// email submissions
NSString * const kSubmissionEmailAddress = @"submissions@publicartpdx.com";
NSString * const kEmailFooter = @"\n\n\n-----\nSent via the PublicArtPDX app\nFor more info, visit: http://PublicArtPDX.com";
 
// for importing from JSON files
NSString * const kPublicArtJSONFilename = @"public_art110612-pp";
NSString * const kPublicArtGeoIndexJSONFilename = @"public_art_geoindex110612";

*/