/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "PKGObjectProtocol.h"

#import "PKGFilePath.h"

typedef NS_ENUM(NSInteger, PKGFileItemType)
{
	PKGFileItemTypeHiddenFolderTemplate=-1,
	PKGFileItemTypeRoot=0,
	PKGFileItemTypeFolderTemplate,
	PKGFileItemTypeNewFolder,
	PKGFileItemTypeFileSystemItem,
    PKGFileItemTypeNewElasticFolder
};

@class _PKGFileItemAuxiliary;

@interface PKGFileItem : NSObject <PKGObjectProtocol,NSCopying>
{
	_PKGFileItemAuxiliary * _fileItemAuxiliary;
}

	@property (readonly) PKGFileItemType type;

	@property (copy) NSString *payloadFileName;

	@property (nonatomic,readonly,copy) NSString *fileName;

    @property (readonly) PKGFilePath * filePath;

	@property uid_t uid;

	@property gid_t gid;

	@property mode_t permissions;

	@property (getter=isContentsDisclosed) BOOL contentsDisclosed;

+ (instancetype)folderTemplateWithName:(NSString *)inName uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;

+ (instancetype)newFolderWithName:(NSString *)inName uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;

+ (instancetype)newElasticFolderWithName:(NSString *)inName uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;

+ (instancetype)fileSystemItemWithFilePath:(PKGFilePath *)inFilePath uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;

- (instancetype)initWithFileItem:(PKGFileItem *)inFileItem;

- (instancetype)initWithFilePath:(PKGFilePath *)inFilePath uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;

- (void)resetAuxiliaryData;

@end
