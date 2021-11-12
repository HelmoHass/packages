/*
 Copyright (c) 2017-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

#include <sys/stat.h>

#import "PKGUsersAndGroupsMonitor.h"

#import "NSArray+UniqueName.h"

@implementation PKGPayloadTreeNode (UI)

+ (PKGPayloadTreeNode *)newFolderNodeWithParentNode:(PKGPayloadTreeNode *)inParentNode siblings:(NSArray *)inSiblings
{
	if (inSiblings==nil)
		return nil;
	
	uid_t tUid=0;
	uid_t tGid=0;
	
	if (inParentNode!=nil)
	{
		PKGFileItem * tParentFileItem=inParentNode.representedObject;
		
		if (tParentFileItem==nil)
			return nil;
		
		tUid=tParentFileItem.uid;
		tGid=tParentFileItem.gid;
	}
	
	NSString * tFolderName=[inSiblings uniqueNameWithBaseName:NSLocalizedString(@"untitled folder",@"No comment") options:NSCaseInsensitiveSearch usingNameExtractor:^NSString *(PKGPayloadTreeNode * bPayloadTreeNode,NSUInteger bIndex){
	
		PKGFileItem * tFileItem=bPayloadTreeNode.representedObject;
		
		return tFileItem.fileName;
	}];
	
	PKGFileItem * nFileItem=[PKGFileItem newFolderWithName:tFolderName uid:tUid gid:tGid permissions:0775];
	
	if (nFileItem==nil)
		return nil;
	
	return [PKGPayloadTreeNode treeNodeWithRepresentedObject:nFileItem children:nil];
}

+ (PKGPayloadTreeNode *)newElasticFolderNodeWithParentNode:(PKGPayloadTreeNode *)inParentNode siblings:(NSArray *)inSiblings
{
    if (inSiblings==nil)
        return nil;
    
    uid_t tUid=0;
    uid_t tGid=0;
    
    if (inParentNode!=nil)
    {
        PKGFileItem * tParentFileItem=inParentNode.representedObject;
        
        if (tParentFileItem==nil)
            return nil;
        
        tUid=tParentFileItem.uid;
        tGid=tParentFileItem.gid;
    }
    
    NSString * tFolderName=[inSiblings uniqueNameWithBaseName:NSLocalizedString(@"untitled folder",@"No comment") options:NSCaseInsensitiveSearch usingNameExtractor:^NSString *(PKGPayloadTreeNode * bPayloadTreeNode,NSUInteger bIndex){
        
        PKGFileItem * tFileItem=bPayloadTreeNode.representedObject;
        
        return tFileItem.fileName;
    }];
    
    PKGFileItem * nFileItem=[PKGFileItem newElasticFolderWithName:tFolderName uid:tUid gid:tGid permissions:0775];
    
    if (nFileItem==nil)
        return nil;
    
    return [PKGPayloadTreeNode treeNodeWithRepresentedObject:nFileItem children:nil];
}

#pragma mark -

+ (BOOL)validateFolderName:(NSString *)inFolderName
{
	if (inFolderName==nil)
		return NO;
	
	NSUInteger tLength=inFolderName.length;
	
	if (tLength==0 || tLength>256)
		return NO;
	
	if ([inFolderName isEqualToString:@".."]==YES ||
		[inFolderName isEqualToString:@"."]==YES ||
		[inFolderName rangeOfString:@"/"].location!=NSNotFound)
		return NO;
	
	return YES;
}

+ (BOOL)validateElasticFolderName:(NSString *)inElasticFolderName
{
    if (inElasticFolderName==nil)
        return NO;
    
    NSUInteger tLength=inElasticFolderName.length;
    
    if (tLength==0 || tLength>256)
        return NO;
    
    if ([inElasticFolderName isEqualToString:@".."]==YES ||
        [inElasticFolderName isEqualToString:@"."]==YES)
        return NO;
    
    return YES;
}

- (NSComparisonResult)compareName:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	if (inPayloadTreeNode==nil)
		return NSOrderedDescending;
	
    PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
    NSString * tName=nil;
    
    if (tFileItem.type==PKGFileItemTypeNewElasticFolder)
        tName=[tFileItem.fileName componentsSeparatedByString:@"/"].firstObject;
    else
        tName=tFileItem.fileName;
    
    PKGFileItem * tOtherFileItem=(PKGFileItem *)inPayloadTreeNode.representedObject;
    NSString * tOtherName=nil;
    
    if (tOtherFileItem.type==PKGFileItemTypeNewElasticFolder)
        tOtherName=[tOtherFileItem.fileName componentsSeparatedByString:@"/"].firstObject;
    else
        tOtherName=tOtherFileItem.fileName;
    
	return [tName compare:tOtherName options:NSCaseInsensitiveSearch|NSNumericSearch|NSForcedOrderingSearch];
}

- (void)rename:(NSString *)inNewName
{
	if (inNewName==nil)
		return;
	
	PKGFileItem * tFileItem=self.representedObject;
	
	switch(tFileItem.type)
	{
		case PKGFileItemTypeNewFolder:
        case PKGFileItemTypeNewElasticFolder:
			tFileItem.filePath.string=inNewName;
			
			break;
			
		case PKGFileItemTypeFileSystemItem:
			
			tFileItem.payloadFileName=inNewName;
			
			break;
			
		default:
			
			break;
	}
}

#pragma mark -

- (NSString *)fileName
{
	return ((PKGFileItem *)self.representedObject).fileName;
}

- (NSString *)filePathWithSeparator:(NSString *)inSeparator
{
	if (self.parent==nil)
	{
		PKGFileItem * tFileItem=[self representedObject];

		return tFileItem.fileName;
	}
	
	PKGPayloadTreeNode * tPayloadTreeNode=self;
	NSMutableString * tMutableString=[NSMutableString string];
	
	do
	{
		PKGFileItem * tFileItem=[tPayloadTreeNode representedObject];
		
		NSString * tFileName=tFileItem.fileName;
		
		if (tFileName==nil)
			break;
		
		if ([tFileName isEqualToString:@"/"]==YES)
        {
            if ([inSeparator isEqualToString:@"/"]==NO)
            {
                [tMutableString insertString:@"/" atIndex:0];
            }
            
			break;
        }
        
		[tMutableString insertString:tFileName atIndex:0];
		[tMutableString insertString:inSeparator atIndex:0];
		
		tPayloadTreeNode=(PKGPayloadTreeNode *) tPayloadTreeNode.parent;
	}
	while (tPayloadTreeNode!=nil);
	
	return [tMutableString copy];
}

- (BOOL)isHiddenTemplateNode
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeHiddenFolderTemplate);
}

- (BOOL)isTemplateNode
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeHiddenFolderTemplate || tFileItem.type==PKGFileItemTypeFolderTemplate);
}

- (BOOL)isFileSystemItemNode
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeFileSystemItem);
}

- (BOOL)isElasticFolder
{
    PKGFileItem * tFileItem=self.representedObject;
    
    return (tFileItem.type==PKGFileItemTypeNewElasticFolder);
}

- (BOOL)isExcluded
{
	PKGPayloadTreeNode * tTreeNode=self;
	
	while (tTreeNode!=nil)
	{
		PKGFileItem * tFileItem=tTreeNode.representedObject;
		
		if (tFileItem.isExcluded==YES)
			return YES;
		
		tTreeNode=(PKGPayloadTreeNode *)tTreeNode.parent;
	}
	
	return NO;
}

- (BOOL)isContentsDisclosed
{
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem.type!=PKGFileItemTypeFileSystemItem)
		return YES;
	
	return tFileItem.isContentsDisclosed;
}

- (BOOL)isReferencedItemMissing
{
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem.type!=PKGFileItemTypeFileSystemItem)
		return NO;
	
	return tFileItem.isReferencedItemMissing;
}

- (BOOL)isSelectableAsInstallationLocation
{
	PKGFileItem * tFileItem=self.representedObject;
	
	switch(tFileItem.type)
	{
		case PKGFileItemTypeHiddenFolderTemplate:
		case PKGFileItemTypeFolderTemplate:
		case PKGFileItemTypeNewFolder:
        case PKGFileItemTypeNewElasticFolder:
            
			return YES;
        
		case PKGFileItemTypeFileSystemItem:
			
			break;	// It's a bit more complicated
			
		default:
			
			break;
	}
	
	return NO;
}

@end

@implementation PKGPayloadTreeNodeAttributedImage

- (id)copy
{
	PKGPayloadTreeNodeAttributedImage * tAttributedImage=[PKGPayloadTreeNodeAttributedImage new];
	
	tAttributedImage.image=self.image;
	tAttributedImage.alpha=self.alpha;
	tAttributedImage.drawsTargetCross=self.drawsTargetCross;
	tAttributedImage.drawsSymbolicLinkArrow=self.drawsSymbolicLinkArrow;
    tAttributedImage.elasticFolder=self.isElasticFolder;
	
	return tAttributedImage;
}

@end


@implementation PKGPayloadTreeNode (PKGFileHierarchy)

- (PKGPayloadTreeNodeAttributedImage *)nameAttributedIcon
{
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem==nil)
		return nil;
	
	PKGPayloadTreeNodeAttributedImage * tAttributedImage=[PKGPayloadTreeNodeAttributedImage new];
	
	tAttributedImage.image=tFileItem.icon;
	tAttributedImage.alpha=(tFileItem.type<PKGFileItemTypeNewFolder && [self containsNoTemplateDescendantNodes]==NO) ? 0.5 : 1.0;
	tAttributedImage.drawsSymbolicLinkArrow=tFileItem.isSymbolicLink;
    tAttributedImage.elasticFolder=(tFileItem.type==PKGFileItemTypeNewElasticFolder);
	
	return tAttributedImage;
}

- (NSAttributedString *)nameAttributedTitle
{
	PKGFileItem * tFileItem=self.representedObject;
	
	NSMutableDictionary * tAttributesDictionary=[NSMutableDictionary dictionaryWithObject:(tFileItem.isReferencedItemMissing==YES) ? [NSColor redColor] : [NSColor controlTextColor]
																				   forKey:NSForegroundColorAttributeName];
	
	if (self.isExcluded==YES)
		tAttributesDictionary[NSStrikethroughStyleAttributeName]=@(NSUnderlineStyleSingle);
	
	return [[NSAttributedString alloc] initWithString:tFileItem.fileName
										   attributes:tAttributesDictionary];
}

- (BOOL)isNameTitleEditable
{
	PKGFileItem * tFileItem=self.representedObject;
	
    return tFileItem.isNameEditable;
}

- (NSString *)ownerTitle
{
	PKGFileItem * tFileItem=self.representedObject;
	
	NSString * tTitle=[[PKGUsersAndGroupsMonitor sharedMonitor] posixNameForUserAccountID:tFileItem.uid];
	
	return (tTitle!=nil) ? tTitle : [NSString stringWithFormat:@"%u",tFileItem.uid];
}

- (NSString *)groupTitle
{
	PKGFileItem * tFileItem=self.representedObject;
	
	NSString * tTitle=[[PKGUsersAndGroupsMonitor sharedMonitor] posixNameForGroupAccountID:tFileItem.gid];
	
	return (tTitle!=nil) ? tTitle : [NSString stringWithFormat:@"%u",tFileItem.gid];
}

- (NSString *)posixPermissionsTitle
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return tFileItem.posixPermissionsRepresentation;
}

#pragma mark -

- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter
{
	PKGFileItem * tFileItem=self.representedObject;
	
	switch(tFileItem.type)
	{
		case PKGFileItemTypeHiddenFolderTemplate:
		case PKGFileItemTypeRoot:
		case PKGFileItemTypeFolderTemplate:
		case PKGFileItemTypeNewFolder:
        case PKGFileItemTypeNewElasticFolder:
			
			return [self filePathWithSeparator:@"/"];
			
		case PKGFileItemTypeFileSystemItem:
			
			return [inPathConverter absolutePathForFilePath:tFileItem.filePath];
	}
	
	return nil;
}

#pragma mark -

- (BOOL)needsRefresh:(NSTimeInterval)inTimeMark
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.refreshTimeMark<inTimeMark);
}

- (void)refreshWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters
{
	
	
	PKGFileItem * tFileItem=self.representedObject;
	
	if (inAbsolutePath==nil)
	{
		[tFileItem refreshAuxiliaryAsMissingFileItem];
		
		return;
	}
	
	
	
	[tFileItem refreshAuxiliaryWithAbsolutePath:inAbsolutePath fileFilters:inFileFilters];
}

@end
