/*
 * Copyright 2010-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "EC2Filter.h"

#import "../AmazonServiceRequestConfig.h"



/**
 * Describe Images Request
 *
 * \ingroup EC2
 */

@interface EC2DescribeImagesRequest:AmazonServiceRequestConfig

{
    NSMutableArray *imageIds;
    NSMutableArray *owners;
    NSMutableArray *executableUsers;
    NSMutableArray *filters;
}




/**
 * Default constructor for a new  object.  Callers should use the
 * property methods to initialize this object after creating it.
 */
-(id)init;

/**
 * An optional list of the AMI IDs to describe. If not specified, all
 * AMIs will be described.
 */
@property (nonatomic, retain) NSMutableArray *imageIds;

/**
 * The optional list of owners for the described AMIs. The IDs amazon,
 * self, and explicit can be used to include AMIs owned by Amazon, AMIs
 * owned by the user, and AMIs for which the user has explicit launch
 * permissions, respectively.
 */
@property (nonatomic, retain) NSMutableArray *owners;

/**
 * The optional list of users with explicit launch permissions for the
 * described AMIs. The user ID can be a user's account ID, 'self' to
 * return AMIs for which the sender of the request has explicit launch
 * permissions, or 'all' to return AMIs with public launch permissions.
 */
@property (nonatomic, retain) NSMutableArray *executableUsers;

/**
 * A list of filters used to match properties for Images. For a complete
 * reference to the available filter keys for this operation, see the <a
 * "http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/">Amazon
 * EC2 API reference</a>.
 */
@property (nonatomic, retain) NSMutableArray *filters;

/**
 * Adds a single object to imageIds.
 * This function will alloc and init imageIds if not already done.
 */
-(void)addImageId:(NSString *)imageIdObject;

/**
 * Adds a single object to owners.
 * This function will alloc and init owners if not already done.
 */
-(void)addOwner:(NSString *)ownerObject;

/**
 * Adds a single object to executableUsers.
 * This function will alloc and init executableUsers if not already done.
 */
-(void)addExecutableUser:(NSString *)executableUserObject;

/**
 * Adds a single object to filters.
 * This function will alloc and init filters if not already done.
 */
-(void)addFilter:(EC2Filter *)filterObject;

/**
 * Returns a string representation of this object; useful for testing and
 * debugging.
 *
 * @return A string representation of this object.
 */
-(NSString *)description;


@end
