//
//  ExceptionBridging.m
//  MacGorm
//
//  Created by C.W. Betts on 4/8/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import "ExceptionBridging.h"

void tryCatchBlock(dispatch_block_t aTry, void(^catchBlock)(NSException*))
{
	@try {
		aTry();
	}
	@catch (NSException *exception) {
		if (catchBlock) {
			catchBlock(exception);
		}
	}
}

