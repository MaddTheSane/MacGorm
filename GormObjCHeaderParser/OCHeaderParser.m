/* OCHeaderParser.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2002
 *
 * This file is part of GNUstep.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */


#import <Foundation/Foundation.h>
#import <GormObjCHeaderParser/OCHeaderParser.h>
#import <GormObjCHeaderParser/OCClass.h>
#import <GormObjCHeaderParser/NSScanner+OCHeaderParser.h>
#import <GNUstepBase/GNUstep.h>

@implementation OCHeaderParser
+(void) initialize
{
  if(self == [OCHeaderParser class])
    {
      //
    }
}


- (id) initWithContentsOfFile: (NSString *)file
{
	if ((self = [super init]) != nil) {
		fileData = [[NSString alloc] initWithContentsOfFile: file usedEncoding: NULL error: NULL];
		classes = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
  RELEASE(classes);
  RELEASE(fileData);
  [super dealloc];
}

- (NSMutableArray *)classes
{
  return classes;
}

- (void) _stripComments
{
	NSScanner *scanner = [NSScanner scannerWithString: fileData];
	NSString *resultString = @"";
	NSString *finalString = @"";
	
	// strip all of the one line comments out...
	[scanner setCharactersToBeSkipped: nil];
	while (![scanner isAtEnd]) {
		NSString *tempString = nil;
		[scanner scanUpToString: @"//" intoString: &tempString];
		[scanner scanUpToString: @"\n" intoString: NULL];
		resultString = [resultString stringByAppendingString: tempString];
	}
	
	// strip all of the multiline comments out...
	scanner = [NSScanner scannerWithString: resultString];
	[scanner setCharactersToBeSkipped: nil];
	while (![scanner isAtEnd]) {
		NSString *tempString = nil;
		[scanner scanUpToString: @"/*" intoString: &tempString];
		[scanner scanUpToAndIncludingString: @"*/" intoString: NULL];
		finalString = [finalString stringByAppendingString: tempString];
	}
	
	// make this our new fileData...
	ASSIGNCOPY(fileData, finalString);
}

- (void) _stripPreProcessor
{
  NSScanner *scanner = [NSScanner scannerWithString: fileData];
  NSString *resultString = @""; // [NSString stringWithString: @""];

  // strip all of the one line comments out...
  [scanner setCharactersToBeSkipped: nil];
  while (![scanner isAtEnd]) {
      NSString *tempString = @"";
      [scanner scanUpToString: @"#" intoString: &tempString];
      [scanner scanUpToAndIncludingString: @"\n" intoString: NULL];
      resultString = [resultString stringByAppendingString: tempString];
    }

  // make this our new fileData...
  ASSIGNCOPY(fileData, resultString);
}

- (void) _stripRedundantStatements
{
  NSScanner *scanner = [NSScanner scannerWithString: fileData];
  NSString *resultString = @""; // [NSString stringWithString: @""];

  // strip all of the one line comments out...
  [scanner setCharactersToBeSkipped: nil];
  while (![scanner isAtEnd]) {
      NSString *tempString = nil, *aString = nil;
      // [scanner scanUpToString: @";" intoString: &tempString];
      // [scanner scanString: @";" intoString: &tempString2];
      [scanner scanUpToAndIncludingString: @";" intoString: &tempString];
      
      // Scan any redundant ";" characters into aString... once it
      // returns nil we know we're done.
      do {
		  aString = nil;
		  [scanner scanString: @";" intoString: &aString];
      } while([aString isEqualToString:@";"]);
	
      [scanner scanUpToAndIncludingString: @"\n" intoString: NULL];
      resultString = [resultString stringByAppendingString: tempString];
    }

  // make this our new fileData...
  ASSIGNCOPY(fileData, resultString);
}

- (void) _preProcessFile
{
  [self _stripComments];
  [self _stripPreProcessor];
  [self _stripRedundantStatements];
}

- (BOOL) _processClasses
{
	NSScanner *scanner = [NSScanner scannerWithString: fileData];
	BOOL result = YES;
	
	@try {
		// get all of the classes...
		while (![scanner isAtEnd]) {
			NSString *classString = nil;
			OCClass *cls = nil;
			
			[scanner scanUpToString: @"@interface" intoString: NULL];
			[scanner scanUpToAndIncludingString: @"@end" intoString: &classString];
			
			if (classString != nil && [classString length] != 0) {
				cls = AUTORELEASE([[OCClass alloc] initWithString: classString]);
				[cls parse];
				[classes addObject: cls];
			}
		}
		
		// if we got zero classes, return NO.
		if ([classes count] == 0) {
			result = NO;
		}
	} @catch (NSException *localException) {
		NSLog(@"%@",localException);
		result = NO;
	}
	
	return result;
}

- (BOOL) parse
{
	BOOL result = NO;
	[self _preProcessFile];
	
	@try {
		// parse the header here...
		result = [self _processClasses];
	} @catch (NSException *localException) {
		// exception while processing...
		NSLog(@"%@",localException);
		result = NO;
	}
	
	
	return result;
}

@end
