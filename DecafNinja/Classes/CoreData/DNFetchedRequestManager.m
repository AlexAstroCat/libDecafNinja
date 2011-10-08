//
//  DNFetchedRequestManager.m
//  libDecafNinja
//
//  Created by Michael Nachbaur on 11-01-22.
//  Copyright 2011 Decaf Ninja Software. All rights reserved.
//

#import "DNFetchedRequestManager.h"

/** Utility class for creating and interacting with NSFetchedRequests.
 The DNFetchedRequestManager is a singleton / factory class that simplifies the
 process for creating, among other things:
 
 • NSFetchRequest objects
 • NSFetchedRequestController objects
 • Returning the raw results of a predicate request
 • Returning the number of objects returned for a predicate request
 
 */
@implementation DNFetchedRequestManager

#pragma mark -
#pragma mark Singleton Methods

+ (DNFetchedRequestManager*)sharedInstance {
    static dispatch_once_t pred;
    static DNFetchedRequestManager *sharedInstance = nil;
    
    dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

#pragma mark -
#pragma mark Factory Methods

/** Creates a fetch request.
 This creates an NSFetchRequest for the supplied arguments, allowing you to
 augment or execute the request yourself if you need to.
 @param context The managed object context.
 @param entityName The name of the entity you wish to fetch.
 @param predicate An NSPredicate objects representing the query you wish to perform. If nil, no predicate is used.
 @param sectionName The optional keyPath to use as a section name.
 @param cacheName The cache name to use for this request.
 @param sortDescriptors An array of sort descriptors. If nil then the results will not be sorted. If not an array,
 then a single value is used to sort by. The values of the array are expected to be NSSortDescriptor or NSString objects.
 @returns A preconfigured NSFetchRequest object for the supplied parameters.
 */
- (NSFetchRequest*)fetchRequestInContext:(NSManagedObjectContext*)context
						   forEntityName:(NSString*)entityName
						   withPredicate:(NSPredicate*)predicate
					  withSectionKeyPath:(NSString*)sectionName
						  usingCacheName:(NSString*)cacheName
								sortedBy:(id)sortDescriptors {
	
	// Setup fetch request object
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[fetchRequest setFetchBatchSize:20];
	
	if (predicate)
		[fetchRequest setPredicate:predicate];
	
	// Set the requested entity description
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
											  inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
	// Create our sort descriptors
	if (sortDescriptors) {
		if (![sortDescriptors isKindOfClass:[NSArray class]]) {
			sortDescriptors = [NSArray arrayWithObject:sortDescriptors];
		}
		
		NSMutableArray *sortDescriptorObjects = [NSMutableArray arrayWithCapacity:[sortDescriptors count]];
		for (NSObject *sort in sortDescriptors) {
			if ([sort isKindOfClass:[NSSortDescriptor class]]) {
				[sortDescriptorObjects addObject:sort];
			}
			
			else if ([sort isKindOfClass:[NSString class]]) {
				NSSortDescriptor *sortObj = [NSSortDescriptor sortDescriptorWithKey:(NSString*)sort ascending:YES];
				[sortDescriptorObjects addObject:sortObj];
			}
			
			else {
				NSLog(@"Error constructing fetched request: sort descriptor \"%@\" is not an NSString or NSSortDescriptor",
                      sort);
				abort();
			}
		}

		[fetchRequest setSortDescriptors:sortDescriptorObjects];
	}
	
	return fetchRequest;
}

/** Creates a fetch results controller.
 This creates an NSFetchedResultsController for the supplied arguments. It takes the same arguments
 as fetchRequestInContext:forEntityName:withPredicate:withSectionKeyPath:usingCacheName:sortedBy:, but
 lets you skip a step in creating a fetched results controller.
 @param context The managed object context.
 @param entityName The name of the entity you wish to fetch.
 @param predicate An NSPredicate objects representing the query you wish to perform. If nil, no predicate is used.
 @param sectionName The optional keyPath to use as a section name.
 @param cacheName The cache name to use for this request.
 @param sortDescriptors An array of sort descriptors. If nil then the results will not be sorted. If not an array,
 then a single value is used to sort by. The values of the array are expected to be NSSortDescriptor or NSString objects.
 @returns A preconfigured NSFetchRequest object for the supplied parameters.
 @see fetchRequestInContext:forEntityName:withPredicate:withSectionKeyPath:usingCacheName:sortedBy:
 */
- (NSFetchedResultsController*)resultsControllerInContext:(NSManagedObjectContext*)context
											forEntityName:(NSString*)entityName
											withPredicate:(NSPredicate*)predicate
									   withSectionKeyPath:(NSString*)sectionName
										   usingCacheName:(NSString*)cacheName
												 sortedBy:(id)sortDescriptors {
	
	// Setup fetch request object
	NSFetchRequest *fetchRequest = [self fetchRequestInContext:context
												 forEntityName:entityName
												 withPredicate:predicate
											withSectionKeyPath:sectionName
												usingCacheName:cacheName
													  sortedBy:sortDescriptors];
	
	// Create our fetched results controller
    NSFetchedResultsController *fetchedResults = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																					  managedObjectContext:context
																						sectionNameKeyPath:sectionName
																								 cacheName:cacheName] autorelease];
	return fetchedResults;
}

#pragma mark -
#pragma mark Convenience methods

/** Returns the result of a fetch request.
 This performs a fetch request on your behalf and returns the results as an NSArray.
 @param context The managed object context.
 @param entityName The name of the entity you wish to fetch.
 @param predicate An NSPredicate objects representing the query you wish to perform. If nil, no predicate is used.
 @param cacheName The cache name to use for this request.
 @returns The results of a fetch request.
 @see fetchRequestInContext:forEntityName:withPredicate:withSectionKeyPath:usingCacheName:sortedBy:
 */
- (NSArray*)resultsInContext:(NSManagedObjectContext*)context
			   forEntityName:(NSString*)entityName
			   withPredicate:(NSPredicate*)predicate
			  usingCacheName:(NSString*)cacheName {
	NSFetchRequest *fetchRequest = [self fetchRequestInContext:context
												 forEntityName:entityName
												 withPredicate:predicate
											withSectionKeyPath:nil
												usingCacheName:cacheName
													  sortedBy:nil];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
	return results;
}

/** Returns the number of results matching a fetch request.
 This performs a fetch request on your behalf and returns the number of results found.
 @param context The managed object context.
 @param entityName The name of the entity you wish to fetch.
 @param predicate An NSPredicate objects representing the query you wish to perform. If nil, no predicate is used.
 @param cacheName The cache name to use for this request.
 @returns The number of results.
 @see resultsInContext:forEntityName:withPredicate:usingCacheName:
 */
- (NSInteger)resultCountInContext:(NSManagedObjectContext*)context
					forEntityName:(NSString*)entityName
					withPredicate:(NSPredicate*)predicate
				   usingCacheName:(NSString*)cacheName {
	NSArray *results = [self resultsInContext:context
								forEntityName:entityName
								withPredicate:predicate
							   usingCacheName:cacheName];
	return [results count];
}

@end
