/*
 Copyright (c) 2017-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLicenseTemplate.h"

#import "PKGFilePath.h"

NSString * const PKGLicenseTemplateFileName=@"License.rtf";
NSString * const PKGLicenseTemplateKeywordsFileName=@"Keywords.plist";
NSString * const PKGLicenseTemplateSLAFileName=@"sla.plist";

@interface PKGLicenseTemplate ()

	@property (readwrite) NSDictionary * localizations;

	@property (readwrite) NSArray * keywords;

	@property (readwrite,copy) NSString * slaReference;

@end

@implementation PKGLicenseTemplate

- (instancetype)initWithContentsOfDirectory:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		
		// Localizations
		
		NSMutableDictionary * tLocalizations=[NSMutableDictionary dictionary];
		
		NSArray * tComponents=[tFileManager contentsOfDirectoryAtPath:inPath error:NULL];
		
		if (tComponents==nil)
			return nil;
		
		for(NSString * tLanguageName in tComponents)
		{
			NSString * tLicensePath=[[inPath stringByAppendingPathComponent:tLanguageName] stringByAppendingPathComponent:PKGLicenseTemplateFileName];
			BOOL isDirectory;
			
			if ([tFileManager fileExistsAtPath:tLicensePath isDirectory:&isDirectory]==YES && isDirectory==NO)
				tLocalizations[[tLanguageName stringByDeletingPathExtension]]=[PKGFilePath filePathWithAbsolutePath:tLicensePath];
		}
		
		_localizations=[tLocalizations copy];
		
		// Keywords
		
		_keywords=[NSArray arrayWithContentsOfFile:[inPath stringByAppendingPathComponent:PKGLicenseTemplateKeywordsFileName]];
		
		// Software License Agreement Reference (only used by Apple)
		
		NSDictionary * tSLADictionary=[NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:PKGLicenseTemplateSLAFileName]];
		_slaReference=[tSLADictionary[@"sla"] copy];
	}
	
	return self;
}

#pragma mark -

- (NSUInteger)hash
{
	return [_localizations hash];
}

@end
