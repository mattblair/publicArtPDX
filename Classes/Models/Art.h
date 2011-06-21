//
//  Art.h
//  pdxPublicArt
//
//  Created by Matt Blair on 11/30/10.
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

#import <CoreData/CoreData.h>


@interface Art :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * collection;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * zip;
@property (nonatomic, retain) NSString * mappableDiscipline;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * medium;
@property (nonatomic, retain) NSString * fundingSource;
@property (nonatomic, retain) NSString * artDate;
@property (nonatomic, retain) NSString * couchID;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * addr1;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSDate * modifiedDate;
@property (nonatomic, retain) NSString * descrip;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * recordID;
@property (nonatomic, retain) NSString * dimensions;
@property (nonatomic, retain) NSString * discipline;
@property (nonatomic, retain) NSString * detailURL;
@property (nonatomic, retain) NSString * artists;
@property (nonatomic, retain) NSString * dataSource;

// added 101207

@property (nonatomic, retain) NSNumber * newWork;   // stored as a BOOL
@property (nonatomic, retain) NSDate * newWorkUntilDate;
@property (nonatomic, retain) NSString * audioURL;

// added 101220

@property (nonatomic, retain) NSString * artCopyright;
@property (nonatomic, retain) NSString * photoCredit;
@property (nonatomic, retain) NSString * originalThumbnailURL;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSNumber * locationVerified; // stored as a BOOL

@end



