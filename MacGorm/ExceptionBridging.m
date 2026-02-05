//
//  ExceptionBridging.m
//  MacGorm
//
//  Created by C.W. Betts on 4/8/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import "ExceptionBridging.h"

void tryCatchBlock(dispatch_block_t aTry, void(^catchBlock)(NSException*), dispatch_block_t aFinal)
{
	@try {
		aTry();
	}
	@catch (NSException *exception) {
		if (catchBlock) {
			catchBlock(exception);
		}
	}
	@finally {
		if (aFinal) {
			aFinal();
		}
	}
}

void registerNameWithRootObject(NSString *aname, id aRootObject)
{
	static NSConnection *connection;
	connection = [NSConnection new];
	[connection registerName:aname];
	[connection setRootObject:aRootObject];
}

