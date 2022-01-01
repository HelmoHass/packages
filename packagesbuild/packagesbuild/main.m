/*
Copyright (c) 2004-2021, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>

#include <sys/types.h>
#include <unistd.h>
#include <getopt.h>

#import "PKGBuildDispatcher+Constants.h"
#import "PKGCommandLineBuildObserver.h"

#import "PKGBuildOrderManager.h"

#import "PKGBuildOrderErrorAuditor.h"

void usage(void);

void usage(void)
{
	(void)fprintf(stderr, "%s\n","Usage: packagesbuild [OPTIONS] file\n"
                                 "       packagesbuild --project file [OPTIONS] [buildsetting=value ...]\n"
				  "\n"
				  "Options:\n"
				  "  --verbose, -v                          provide additional status output\n"
				  "  --debug, -d                            build project in debug mode (i.e. disable locators)\n"
				  "  --temporary-build-location, -t PATH    use this folder as the temporary build folder\n"
				  "  --reference-folder, -F PATH            use this path as the reference folder\n"
				  "  --build-folder PATH                    create the build output in this folder\n"
				  "  --identity NAME                        sign the build output with this identity\n"
				  "  --keychain PATH                        look for the identity in the keychain at this path\n"
				  "  --package-version VERSION              set the version of the built raw package project to this value\n"
				  "  --no-timestamp                         do not include a trusted timestamp in the signature\n\n"
                  "  --version                              print the Packages version that the packagesbuild program came from\n\n");
	
	exit(1);
}

#pragma mark -

int main(int argc, const char * argv[])
{
	@autoreleasepool
	{
		BOOL tVerbose=NO;
		BOOL tDebug=NO;
		BOOL tNoTimestamp=NO;
		char * tCScratchPath=NULL;
		char * tCReferenceFolder=NULL;
		
		char * tCBuildFolder=NULL;
		
		char * tCIdentity=NULL;
		char * tCKeychain=NULL;
		
		char * tCPackageVersion=NULL;
		
        char * tCProjectFilePath=NULL;
        
		int c;
		
        static struct option tLongOptions[] =
        {
            {"verbose",                        no_argument,        0,    'v'},
            {"debug",                        no_argument,        0,    'd'},
            
            {"temporary-build-location",    required_argument,    0,    't'},
            {"reference-folder",            required_argument,    0,    'F'},
            
            {"build-folder",                required_argument,    0,    0},
            
            {"identity",                    required_argument,    0,    0},
            {"keychain",                    required_argument,    0,    0},
            
            {"package-version",                required_argument,    0,    0},        /* Will only work for Raw Package project */
            
            {"no-timestamp",                no_argument,        0,    0},
            
            {"project",                     required_argument,  0,  0},
            
            {"version",                no_argument,        0,    0},
            
            {0, 0, 0, 0}
        };
        
		while (1)
		{
			int tOptionIndex = 0;

			c = getopt_long (argc, (char **) argv, "vdt:F:",tLongOptions, &tOptionIndex);

			/* Detect the end of the options. */
			if (c == -1)
				break;

			switch (c)
			{
				case 0:
				{
					const char * tOptionName=tLongOptions[tOptionIndex].name;
					
					if (strncmp(tOptionName,"build-folder",strlen("build-folder"))==0)
					{
						tCBuildFolder=optarg;
					}
					else if (strncmp(tOptionName,"identity",strlen("identity"))==0)
					{
						tCIdentity=optarg;
					}
					else if (strncmp(tOptionName,"keychain",strlen("keychain"))==0)
					{
						tCKeychain=optarg;
					}
					else if (strncmp(tOptionName,"package-version",strlen("package-version"))==0)
					{
						tCPackageVersion=optarg;
					}
					else if (strncmp(tOptionName,"no-timestamp",strlen("no-timestamp"))==0)
					{
						tNoTimestamp=YES;
					}
                    else if (strncmp(tOptionName,"project",strlen("project"))==0)
                    {
                        tCProjectFilePath=optarg;
                    }
                    else if (strncmp(tOptionName,"version",strlen("version"))==0)
                    {
                        (void)fprintf(stdout, "packagesbuild version %s\n","1.2.10");
                        exit(EXIT_SUCCESS);
                    }
					
					break;
				}
					
				case 'v':
					
					tVerbose=YES;
					
					break;
					
				case 'd':
					
					tDebug=YES;
					
					break;
				
				case 't':
					
					tCScratchPath=optarg;
					
					break;
				
				case 'F':
					
					tCReferenceFolder=optarg;
					
					break;
					
				case '?':
				default:
					usage();
					
					exit(EXIT_FAILURE);
					
                    break;
			}
		}
		
		argv+=optind;
		argc-=optind;
		
		if (tCProjectFilePath==NULL && argc < 1)
		{
			usage();
			
			exit(EXIT_FAILURE);
		}
		
		NSString * tScratchFolder=nil;
		NSString * tReferenceFolder=nil;
		
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		
		NSString * tCurrentDirectory=[tFileManager currentDirectoryPath];
		
		if (tCScratchPath!=NULL)
		{
			tScratchFolder=[[NSString stringWithUTF8String:tCScratchPath] stringByStandardizingPath];
		
			if ([tScratchFolder characterAtIndex:0]!='/')
				tScratchFolder=[tCurrentDirectory stringByAppendingPathComponent:tScratchFolder];
			
			if ([tFileManager fileExistsAtPath:tScratchFolder]==NO)
			{
			   (void)fprintf(stderr, "Temporary build location \'%s\' does not exist.\n",tCScratchPath);
	
				exit(EXIT_FAILURE);
			}
		}
		
		if (tCReferenceFolder!=NULL)
		{
			tReferenceFolder=[[NSString stringWithUTF8String:tCReferenceFolder] stringByStandardizingPath];
		
			if ([tReferenceFolder characterAtIndex:0]!='/')
				tReferenceFolder=[tCurrentDirectory stringByAppendingPathComponent:tReferenceFolder];
			
			BOOL isDirectory;
			
			if ([tFileManager fileExistsAtPath:tReferenceFolder isDirectory:&isDirectory]==NO)
			{
			   (void)fprintf(stderr, "Reference folder \'%s\' does not exist.\n",tCReferenceFolder);
	
				exit(EXIT_FAILURE);
			}
			
			if (isDirectory==NO)
			{
				(void)fprintf(stderr, "Reference folder path \'%s\' is not a directory.\n",tCReferenceFolder);
	
				exit(EXIT_FAILURE);
			}
		}
		
        NSString * tProjectPath=nil;
        
        if (tCProjectFilePath==NULL)
        {
            tProjectPath=[NSString stringWithUTF8String:argv[0]];
            
            argv++;
            argc--;
            
            argc=0;
        }
        else
        {
            tProjectPath=[NSString stringWithUTF8String:tCProjectFilePath];
        }
		
        tProjectPath=tProjectPath.stringByStandardizingPath;
        
		if ([tProjectPath characterAtIndex:0]!='/')
			tProjectPath=[tCurrentDirectory stringByAppendingPathComponent:tProjectPath];
		
		if ([tFileManager fileExistsAtPath:tProjectPath]==NO)
		{
            (void)fprintf(stderr, "packagesbuild: error: '%s' does not exist.\n",tProjectPath.fileSystemRepresentation);
			
			exit(EXIT_FAILURE);
		}
	

		NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
		
		if (tReferenceFolder!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsReferenceFolderKey]=tReferenceFolder;
		
		if (tScratchFolder!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsScratchFolderKey]=tScratchFolder;
		
		if (tCBuildFolder!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsBuildFolderKey]=[NSString stringWithUTF8String:tCBuildFolder];
		
		if (tCIdentity!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsSigningIdentityKey]=[NSString stringWithUTF8String:tCIdentity];
		
		if (tCKeychain!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsKeychainKey]=[NSString stringWithUTF8String:tCKeychain];
		
		if (tCPackageVersion!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsPackageVersionKey]=[NSString stringWithUTF8String:tCPackageVersion];
		
		tMutableDictionary[PKGBuildOrderExternalSettingsEmbedTimestamp]=@(tNoTimestamp==NO);
		
		// User Defined Settings
        
        NSMutableDictionary * tUserDefinedSettings=[NSMutableDictionary dictionary];
        
        while (argc>0)
        {
            NSString * tUserDefinedSetting=[NSString stringWithUTF8String:*argv];
            
            NSRange tRange=[tUserDefinedSetting rangeOfString:@"="];
            
            if (tRange.location==NSNotFound)
            {
                (void)fprintf(stderr, "Missing '=' for build setting definition (%s).\n",*argv);
                usage();
                
                exit(EXIT_FAILURE);
            }
            
            NSString * tKey=[tUserDefinedSetting substringToIndex:tRange.location];
            NSString * tValue=[tUserDefinedSetting substringFromIndex:tRange.location+1];
            
            if (tKey.length==0)
            {
                (void)fprintf(stderr, "buildsetting can not be empty.\n");
                usage();
                
                exit(EXIT_FAILURE);
            }
            
            if (tValue==nil)
            {
                (void)fprintf(stderr, "An error occurred while parsing %s.\n",*argv);
                usage();
                
                exit(EXIT_FAILURE);
            }
            
            tUserDefinedSettings[tKey]=tValue;
            
            argv++;
            argc--;
        }
        
        tMutableDictionary[PKGBuildOrderExternalSettingsUserDefinedSettingsKey]=tUserDefinedSettings;
        
        
		
		PKGCommandLineBuildObserver * tBuildObserver=[PKGCommandLineBuildObserver new];
		tBuildObserver.verbose=tVerbose;
		
		PKGBuildOrder * tBuildOrder=[PKGBuildOrder new];
		
		tBuildOrder.projectPath=tProjectPath;
		tBuildOrder.buildOptions=(tDebug==YES) ? PKGBuildOptionDebugBuild : 0;
		tBuildOrder.externalSettings=[tMutableDictionary copy];
		
		

		
		[[PKGBuildOrderManager defaultManager] executeBuildOrder:tBuildOrder
													setupHandler:^(PKGBuildNotificationCenter * bBuildNotificationCenter){
												 
												 // Register for notifications
												 
												 [bBuildNotificationCenter addObserver:tBuildObserver selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:nil];
												 [bBuildNotificationCenter addObserver:tBuildObserver selector:@selector(processBuildDebugNotification:) name:PKGBuildDebugNotification object:nil];
														
												 [[NSDistributedNotificationCenter defaultCenter] addObserver:tBuildObserver selector:@selector(processDispatchErrorNotification:) name:PKGPackagesDispatcherErrorDidOccurNotification object:tBuildOrder.UUID suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
														
												 											 }
											   completionHandler:^(PKGBuildResult bResult){
												   
												   if (bResult==PKGBuildResultSuccessful)
													   exit(EXIT_SUCCESS);
												   
												   exit(EXIT_FAILURE);
											   }
									   communicationErrorHandler:^(NSError * bCommunicationError){
										   
                                           if ([bCommunicationError.domain isEqualToString:PKGBuildOrderErrorDomain]==YES)
                                           {
                                               switch(bCommunicationError.code)
                                               {
                                                   case PKGBuildOrderErrorDispatcherNotResponding:
                                                   {
                                                       PKGBuildOrderErrorAuditor * tAuditor=[PKGBuildOrderErrorAuditor new];
                                                       
                                                       PKGPackagesDispatcherErrorType tErrorType=tAuditor.dispatcherErrorType;
                                                       
                                                       switch(tErrorType)
                                                       {
                                                           case PKGPackagesDispatcherErrorLaunchDaemonConfigurationFileNotFoundInvalidPermissions:
                                                               
                                                               (void)fprintf(stderr, "Unable to communicate with packages_dispatcher. The permissions of the fr.whitebox.packages.build.dispatcher.plist launchd configuration file in /Library/LaunchDaemons are incorrect.");
                                                               
                                                               break;
                                                               
                                                           case PKGPackagesDispatcherErrorLaunchDaemonConfigurationFileNotFound:
                                                               
                                                               (void)fprintf(stderr, "Unable to communicate with packages_dispatcher. The fr.whitebox.packages.build.dispatcher.plist launchd configuration file is missing in /Library/LaunchDaemons.");
                                                               
                                                               break;
                                                               
                                                           case PKGPackagesDispatcherErrorPackagesDispatcherNotFound:
                                                               
                                                               (void)fprintf(stderr, "Unable to find tool '%s'","packages_dispatcher");
                                                               
                                                               break;
                                                               
                                                           case PKGPackagesDispatcherErrorPackagesDispatcherNotResponding:
                                                               
                                                               (void)fprintf(stderr, "packages_dispatcher is not responding. Have you disabled or unloaded the fr.whitebox.packages.build.dispatcher.plist launchd configuration file?");
                                                               
                                                               break;
                                                               
                                                           case PKGPackagesDispatcherErrorPackageBuilderNotFound:
                                                               
                                                               (void)fprintf(stderr, "Unable to find tool '%s'","packages_builder");
                                                               
                                                               break;
                                                       }
                                                       
                                                       break;
                                                   }
                                               }
                                           }
									   }];
		
		[[NSRunLoop mainRunLoop] run];
	}
	
    return EXIT_FAILURE;
}
