
#import "PKGPayloadTreeNode.h"

#import "PKGPayloadBundleItem.h"

#include <sys/stat.h>

@implementation PKGPayloadTreeNode

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation
{
	if (inRepresentation!=nil)
	{
		if ([PKGPayloadBundleItem isRepresentationOfBundleItem:inRepresentation])
			return PKGPayloadBundleItem.class;
	}
	
	return PKGFileItem.class;
}

+ (Class)representedObjectClassForFileSystemItemAtPath:(NSString *)inPath
{
	NSError * tError=nil;
	NSDictionary * tAttributesDictionary=[[NSFileManager defaultManager] attributesOfItemAtPath:inPath error:&tError];
	
	if (tAttributesDictionary==nil)
		return PKGFileItem.class;
	
	if ([tAttributesDictionary[NSFileType] isEqualToString:NSFileTypeDirectory]==NO)
		return PKGFileItem.class;
	
	// Check whether there is a Info.plist file with a bundle identifier if the directory's contents is not disclosed
	
	NSBundle * tBundle=[NSBundle bundleWithPath:inPath];
	
	if (tBundle.bundleIdentifier.length==0)
		return PKGFileItem.class;
	
	return PKGPayloadBundleItem.class;
}

#pragma mark -

- (BOOL)isLeaf
{
	PKGFileItem * tFileItem=[self representedObject];
	
	if (tFileItem.type!=PKGFileItemTypeFileSystemItem)
		return NO;
	
	return ([tFileItem isContentsDisclosed]==NO);
}

#pragma mark -

- (void)contract
{
	[self removeAllChildren];
	
	PKGFileItem * tFileItem=self.representedObject;
	tFileItem.contentsDisclosed=NO;
}

#pragma mark -

- (PKGPayloadTreeNode *)createMissingDescendantsForPath:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	PKGPayloadTreeNode * tParentTreeNode=self;
	
	NSArray * tPathComponents=[inPath componentsSeparatedByString:@"/"];
	NSString * tDirectoryPath=@"/";
	NSUInteger tIndex,tCount=tPathComponents.count;
	
	for(tIndex=0;tIndex<tCount;tIndex++)
	{
		NSString * tComponent=tPathComponents[tIndex];
		
		if (tComponent.length==0)
			continue;
		
		BOOL tFound=NO;
		
		for(PKGPayloadTreeNode * tChildTreeNode in tParentTreeNode.children)
		{
			PKGFileItem * tFileItem=tChildTreeNode.representedObject;
			
			if ([tFileItem.filePath.lastPathComponent isEqualToString:tComponent]==YES)
			{
				tParentTreeNode=tChildTreeNode;
				tFound=YES;
				
				tDirectoryPath=[tDirectoryPath stringByAppendingPathComponent:tComponent];
				
				break;
			}
		}
		
		if (tFound==NO)
			break;
	}
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	for(;tIndex<tCount;tIndex++)
	{
		NSString * tComponent=tPathComponents[tIndex];
		
		if (tComponent.length==0)
			continue;
		
		NSError * tError=nil;
		NSDictionary * tAttributes=[tFileManager attributesOfItemAtPath:tDirectoryPath error:&tError];
		
		if (tAttributes==nil)
		{
			NSLog(@"Unable to retrieve attributes of item at path \"%@\": %@",tDirectoryPath,tError);
			
			// A COMPLETER
		}
		
		PKGFileItem * tFileItem=[PKGFileItem newFolderWithName:tComponent
														   uid:(uid_t)[tAttributes[NSFileOwnerAccountID] integerValue]
														   gid:(gid_t)[tAttributes[NSFileGroupOwnerAccountID] integerValue]
												   permissions:([tAttributes[NSFilePosixPermissions] integerValue]&UF_SETTABLE)];
		
		PKGPayloadTreeNode * tPayloadTreeNode=[PKGPayloadTreeNode treeNodeWithRepresentedObject:tFileItem children:nil];
		
		[tParentTreeNode insertChild:tPayloadTreeNode sortedUsingSelector:@selector(compareName:)];
		
		tParentTreeNode=tPayloadTreeNode;
		
		tDirectoryPath=[tDirectoryPath stringByAppendingPathComponent:tComponent];
	}
	
	return tParentTreeNode;
}

- (PKGPayloadTreeNode *)descendantNodeAtPath:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	PKGPayloadTreeNode * tPayloadTreeNode=self;
	
	NSArray * tPathComponents=[inPath componentsSeparatedByString:@"/"];
	
	for(NSString * tComponent in tPathComponents)
	{
		if (tComponent.length==0)
			continue;
		
		PKGPayloadTreeNode * tChildTreeNode=nil;
		
		for(tChildTreeNode in tPayloadTreeNode.children)
		{
			PKGFileItem * tFileItem=tChildTreeNode.representedObject;
			
			if ([tFileItem.filePath.lastPathComponent isEqualToString:tComponent]==YES)
			{
				tPayloadTreeNode=tChildTreeNode;
				break;
			}
		}
		
		if (tChildTreeNode==nil)
			return nil;
	}
	
	return tPayloadTreeNode;
}

- (NSUInteger)optimizePayloadHierarchy
{
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem.type==PKGFileItemTypeFileSystemItem ||
		tFileItem.type==PKGFileItemTypeNewFolder ||
        tFileItem.type==PKGFileItemTypeNewElasticFolder)
		return 1;
	
	NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
	
	[[self children] enumerateObjectsUsingBlock:^(PKGPayloadTreeNode * bChildNode,NSUInteger bIndex,__attribute__((unused))BOOL * bOutStop){
		
		if ([bChildNode optimizePayloadHierarchy]==0)
			[tIndexSet addIndex:bIndex];
	}];
	
	[self removeChildrenAtIndexes:tIndexSet];
	
	NSUInteger tNumberOfChildren=[self numberOfChildren];
	
	if (tNumberOfChildren>0)
		return tNumberOfChildren;
	
	if (tFileItem.type!=PKGFileItemTypeRoot)
		return 0;
	
	return 1;
}

- (BOOL)containsNoTemplateDescendantNodes;
{
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem.type>=PKGFileItemTypeNewFolder)
		return YES;
	
	NSUInteger tCount=[self numberOfChildren];
	
	for(NSUInteger tIndex=0;tIndex<tCount;tIndex++)
	{
		if ([((PKGPayloadTreeNode *)[self childNodeAtIndex:tIndex]) containsNoTemplateDescendantNodes]==YES)
			return YES;
	}
	
	return NO;
}

@end
