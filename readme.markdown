Last updated: 2011-06-21

About the project: [Public Art PDX](http://publicartpdx.com)

## Running the app

If you have Xcode, you can run it in the simulator.

If you want to run it on a device, you need a developer account with Apple.

The latest release is available on the [app store](http://itunes.apple.com/us/app/public-art-pdx/id416967691?mt=8).

## Known Issues

* The Portland, Oregon sign in the original app code is used with permission of the City of Portland, and I can't release it with the source. The app should build and without one, though you might need to change the icon settings in the project's main plist file. Or you could add an app icon file with the name Icon.png, and any other sizes you want to include.
* Delegate code for alert views and action sheets is very spaghetti-esque. There was a lot of last minute fiddling befor the initial release. I'll address this when features are finalized for v1.1.
* Project specific database names, URLs and passwords are defined in a file called databaseConstants.m. You'll need to create this file to buld. There's a template of what it should look like in databaseConstants.h. In this release, the only feature that uses authentication is location adjustment. Contact me for details or an API account if needed.

## Dependencies

This project uses [json-framework](http://code.google.com/p/json-framework/) and [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/) and [MBProgressHUD](https://github.com/matej/MBProgressHUD), which are included in the project for convenience.

## License and Copyright for Code

**Modified BSD:**
http://opensource.org/licenses/bsd-license

Copyright (c) 2011, Elsewise LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Elsewise LLC nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Terms of Use For Data

This app and its supporting APIs use data from several sources, indicated by the "dataSource" field of each record. 

I have modified the original data, both in structure and content, to facilitate data management and display. Elsewise LLC makes no claims as to the completeness or accuracy of any data contained in this project, and provides no warranty of the accuracy or fitness for any particular use, nor are any such warranties to be implied or inferred.

Terms of use may change as I integrate data from different collections and sources, so please check this document regularly for the lastest details.

## Source-specific details

### RACC

The [Regional Arts & Culture Council](http://racc.org/public-art/overview-opportunities) and the City of Portland's Bureau of Technology Services provided the original dataset, which is available via the [Civic Apps website](http://www.civicapps.org/datasets/public-art).

I used that dataset to populate the following fields:

* addrCity
* addrState
* addrStreet
* addrZip
* artists
* date
* dateModified
* description
* detailPageURL
* dimensions
* discipline
* fundingSource
* thumbnailURL
* location
* medium
* recordID
* title
* geometry

The dataSource value for records sourced from this data is "RACC". 

Use of that data binds you to the Civic Apps Terms of Use. (see attached)

Additional requirements for any project that integrates or displays records sourced from RACC (indicated by a "dataSource" field with the value "RACC"):

1. Any "photoCredit" fields with the value "RACC" should be presented in any user-facing display as "Image courtesy of RACC".
2. RACC makes no representations about current copyright status of any artwork.
3. Prominently display the following notice:

```
"Copyrights for artworks depicted typically remain with the artists, individual circumstances may vary. RACC does not assume responsibility for determining copyrights for any of the work in the City of Portland/Multnomah County public art collection.

Original dataset copyright RACC, 2011. All images provided by RACC are intended to be used as a guide for public art in the Portland Metropolitan Region, they are for educational purposes only and are not intended for any other use. For more information, visit www.racc.org."
```
Some data has changed since the original import. RACC is not responsible for these changes.

#### My modifications

In addition to reformatting the original data, I added the following fields:

* dataSource
* collection
* mappableDiscipline
* photoCredit
* artCopyright
* locationVerified

I try to keep the data current and accurate, but there are no guarantees. RACC is not responsible for data in these fields, regardless of the value stored in the collection or dataSource fields. If you have a question about these fields, or an error to report, email me.

Notes about specific fields:

* If the value for artCopyright is "TBD", the copyright owner is unknown. See note above.
* The value in "photoCredit" does not imply a copyright on the photo or the artwork.
* The "mappableDiscipline" is a flattened subset of "discipline" values, reducing the number of categories represented with different pins. Compare to "discipline" in the original data.
* The value of "locationVerified" is false by default. If the value is False, you are encouraged to submit location adjustments through the API. If the value is True, location adjustments will be ignored. If you discover a problem with a location listed as verified, please contact me directly.

### Submissions

Suggestions and submissions of art to add to the collection are assumed to be under a Creative Commons license. This will be clarified in the near future.

## Contact 

Questions? Ideas? Add an issue or email me.