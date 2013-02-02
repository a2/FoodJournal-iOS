AZCoreRecord
------------

The active record pattern, a way to deal with relational structures through dedicated functions for insertion, updates, and deletion, has been popularized by languages like Ruby for their ease in dealing with database data in an object-oriented way.

Heavily derived from [Magical Record for Core Data](https://github.com/magicalpanda/MagicalRecord), `AZCoreRecord` strives to bring effortless fetching, saving, importing, and ubiquity to Core Data on iOS and OS X.

The primary benefits you'll get out of AZCoreRecord include:

* Cleaner Core Data-related code
* Automatic handling of contexts, stores, and models
* Clear, simple, one-line fetches, searches, and deletes
* Drop-in support for Ubiquity/iCloud - the first of its kind.

AZCoreRecord is built using ARC targetting iOS 5.0 and OS X 10.7.

## Installation

AZCoreRecord can be added to a project using [CocoaPods](https://github.com/alloy/cocoapods).

### Manual Installation

* Download or clone AZCoreRecord.
* In your Xcode Project, add all the `.h` and `.m` files from the AZCoreRecord folder into your project. 
* In the build settings of your target or project, change "Other Linker Flags" to `-ObjC -all_load`. Make sure your app is linked with Core Data.
* Insert `#import "AZCoreRecord.h"` anywhere in your project.

## Usage

### Setting up the Core Data Stack

If you don’t want auto migration, an in-memory store, or a special name for your stack, simply start working! The first time the default managed object context is accessed, the entire stack is initialized automatically.

Otherwise, somewhere in your app delegate, likely `-applicationDidFinishLaunching:withOptions:` use any combination of the following setup calls from the `AZCoreRecordManager` metaclass:

	+ (void)setStackShouldAutoMigrateStore: (BOOL) shouldMigrate;
	+ (void)setStackShouldUseInMemoryStore: (BOOL) inMemory;
	+ (void)setStackStoreName: (NSString *) name;
	+ (void)setStackStoreURL: (NSURL *) name;
	+ (void)setStackModelName: (NSString *) name;
	+ (void)setStackModelURL: (NSURL *) name;

Each call configures a piece of your Core Data stack, and will automatically get used whenever your app tries to use a AZCoreRecord method.

## Documentation

Documentation is currently not available, though it is planned for the future.
	
## License

AZCoreRecord is created and maintained by [Alexsander Akers](https://github.com/pandamonia) & [Zachary Waldowski](https://github.com/zwaldowski) under the MIT license.  **The project itself is free for use in any and all projects.**  You can use AZCoreRecord in any project, public or private, with or without attribution.

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
