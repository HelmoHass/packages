/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <AppKit/AppKit.h>

#import "PKGFileItem.h"

@interface PKGFileItem (UI)

	@property (nonatomic,readonly) NSTimeInterval refreshTimeMark;

	@property (nonatomic,readonly,copy) NSString *referencedItemPath;

	@property (nonatomic,readonly) unsigned char fileType;

	@property (nonatomic,readonly) NSImage * icon;

	@property (nonatomic,getter=isExcluded,readonly) BOOL excluded;

	@property (nonatomic,getter=isSymbolicLink,readonly) BOOL symbolicLink;

	@property (nonatomic,getter=isReferencedItemMissing,readonly) BOOL referencedItemMissing;

	@property (nonatomic,readonly,copy) NSString * posixPermissionsRepresentation;

    @property (nonatomic,getter=isNameEditable,readonly) BOOL nameEditable;

+ (NSString *)representationOfPOSIXPermissions:(mode_t)inPermissions fileType:(unsigned char)inFileType;

+ (NSString *)representationOfPOSIXPermissions:(mode_t)inPermissions mixedPermissions:(mode_t)inMixedPermissions fileType:(unsigned char)inFileType;

- (void)refreshAuxiliaryAsMissingFileItem;

- (void)refreshAuxiliaryWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters;

- (void)createTemporaryAuxiliaryIfNeededWithAbsolutePath:(NSString *)inAbsolutePath;

@end
