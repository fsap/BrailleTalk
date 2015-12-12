//
//  BridgeHeader.h
//  TdTalk2Dev
//
//  Created by 藤原修市 on 2015/07/30.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

#ifndef EpubTalk_BridgeHeader_h
#define EpubTalk_BridgeHeader_h

#define EnableBraille 1

#import "SSZipArchive.h"

#ifdef EnableEpub
#import "file.h"
#import "brlbuf.h"
#endif

#ifdef EnableBraille
#import "bfile.h"
#import "bbrlbuf.h"
#endif

#endif
