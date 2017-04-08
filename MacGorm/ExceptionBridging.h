//
//  ExceptionBridging.h
//  MacGorm
//
//  Created by C.W. Betts on 4/8/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#ifndef ExceptionBridging_h
#define ExceptionBridging_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void tryCatchBlock(NS_NOESCAPE dispatch_block_t aTry, void(NS_NOESCAPE^ __nullable catchBlock)(NSException*)) NS_SWIFT_NAME(exceptionBlock(try:catch:));

NS_ASSUME_NONNULL_END

#endif /* ExceptionBridging_h */
