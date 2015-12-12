#import <Foundation/Foundation.h>    
#import "bbrlbuf.h"
#import "blist.h"
@implementation BrlBuffer 
- (void)Setinit {
	tenstr = NULL;
	NextFlg = 0;
	m_lpList = [[BrlList alloc] init];
	m_lpList = [m_lpList autorelease];
	id lpTmpList = [[BrlList alloc] init];
	lpTmpList = [lpTmpList autorelease];
	m_lpDelList = [[BrlList alloc] init];
	m_lpDelList = [m_lpDelList autorelease];
	id lpTmpDelList = [[BrlList alloc] init];
	lpTmpDelList = [lpTmpDelList autorelease];
	// リストのデータを編集し、接続します
	[m_lpList SetAttr:BUF_LIST_HEAD];
	[m_lpList SetStart:m_lpList];
	[m_lpList SetNext:lpTmpList];
	[m_lpList SetBefore:lpTmpList];
	[lpTmpList SetAttr:BUF_LIST_END];
	[lpTmpList SetStart:m_lpList];
	[lpTmpList SetNext:m_lpList];
	[lpTmpList SetBefore:m_lpList];
	// 削除リストの構築
	[m_lpDelList SetAttr:BUF_DEL_LIST_HEAD];
	[m_lpDelList SetStart:m_lpDelList];
	[m_lpDelList SetNext:lpTmpDelList];
	[m_lpDelList SetBefore:lpTmpDelList];
	[lpTmpDelList SetAttr:BUF_DEL_LIST_END];
	[lpTmpDelList SetStart:m_lpDelList];
	[lpTmpDelList SetNext:m_lpDelList];
	[lpTmpDelList SetBefore:m_lpDelList];
/*
FILE *fp = fopen("log.txt", "a");
fprintf(fp, "setinit\n");
fclose(fp);
*/
}

- (NSString*)Word {
//	Word = [NSString stringWithCString: str encoding:NSUTF8StringEncoding];
	return Word;
}
- (void)PutDat:(unsigned char *)Dat {
	[m_lpList SetData:Dat];
}

- (unsigned char *)GetDat {
	char* str = [m_lpList GetData];
//	Word = [NSString stringWithCString: str encoding:NSUTF8StringEncoding];
	return str;
}

- (unsigned char)IsAttr {
	return [m_lpList GetAttr];
}

- (BOOL)IsBuffer {
	id TmpList = [m_lpList GetStart];
	if ([[TmpList GetNext] GetAttr] == BUF_LIST_END) {
		return FALSE;
	}
	return TRUE;
}

- (BOOL)Del {
	if (![self IsBuffer]) {
		return FALSE;
	}
	id TmpList = m_lpList;
	m_lpList = [m_lpList GetBefore];
	[[TmpList GetNext] SetBefore:m_lpList];
	[m_lpList SetNext:[TmpList GetNext]];
	id DelTmpList = [m_lpDelList GetStart];
	id DelTmpNextList = [[m_lpDelList GetStart] GetNext];
	[TmpList SetStart:[DelTmpList GetStart]];
	[TmpList SetNext:[DelTmpList GetNext]];
	[TmpList SetBefore:[DelTmpList GetStart]];
	[DelTmpList SetNext:TmpList];
	[DelTmpNextList SetBefore:TmpList];
	return TRUE;
}

- (void)Remove {
	if (![self IsBuffer]) {
		return;
	}
	[self End];
	while ([self IsBuffer]) {
		[self Del];
		if ([m_lpList GetAttr] == BUF_LIST_HEAD) {
			break;
		}
	}
}

- (void)Ins:(unsigned char *)Dat {
	id TmpList;
	m_lpDelList = [m_lpDelList GetStart];
	if ([[m_lpDelList GetNext] GetAttr] != BUF_LIST_END) {	// ストックオブジェクトから拾う
		TmpList = [m_lpDelList GetNext];
		[[TmpList GetNext] SetBefore:m_lpDelList];
		[m_lpDelList SetNext:[TmpList GetNext]];
	} else {	// ストックが存在しないので新しいオブジェクトを作成
		TmpList = [[BrlList alloc] init];
		TmpList = [TmpList autorelease];
		[TmpList SetAttr:BUF_LIST_DATA];
	}
	[TmpList SetStart:[m_lpList GetStart]];
	[TmpList SetNext:[m_lpList GetNext]];
	[TmpList SetBefore:m_lpList];
	[[m_lpList GetNext] SetBefore:TmpList];
	[m_lpList SetNext:TmpList];
	m_lpList = TmpList;
	[m_lpList SetData:Dat];
	[m_lpList SetUserInfo:*Dat];
}

- (BOOL)NextLine {
	if ([[m_lpList GetNext] GetAttr] == BUF_LIST_END)
		return FALSE;
	m_lpList = [m_lpList GetNext];
	tenstr = NULL;
	NextFlg = 0;
	return TRUE;
}

- (BOOL)BeforeLine {
	if ([[m_lpList GetBefore] GetAttr] == BUF_LIST_HEAD)
		return FALSE;
	m_lpList = [m_lpList GetBefore];
	tenstr = NULL;
	NextFlg = 0;
	return TRUE;
}

- (void)Top {
	m_lpList = [[m_lpList GetStart] GetNext];
	tenstr = NULL;
	NextFlg = 0;
}

- (void)End {
	m_lpList = [[[m_lpList GetStart] GetBefore] GetBefore];
	tenstr = NULL;
	NextFlg = 0;
}

- (void)SetMaxLine:(int)Line {
	MaxLine = Line;
}

- (void)SetAllPage:(int)Page {
	AllPage = Page;
}
- (void)IsCurrent:(PAGE_INFO *)PageInfo {
	int PageCount = 1;
	int LineCount = 1;
	int KanCount = 1;
	int KanPageCount = 1;
	id Temp = m_lpList;
	int PageFlg = 0;
	[self Top];
	tenstr = [self GetDat];
	while (1) {
		if (Temp == m_lpList) {
			break;
		}
		if (*tenstr & 0x20) {
			PageFlg = 1;
		}
		if (![self NextLine]) {
			break;
		}
		tenstr = [self GetDat];
		if (PageFlg) {
			PageCount++;
			LineCount = 1;
			KanPageCount++;
			PageFlg = 0;
			if (*tenstr & 0x40 && *tenstr & 0x10) {
				KanCount++;
				KanPageCount = 1;
			}
		}
		else {
			LineCount++;
			if (LineCount > MaxLine) {
				PageCount++;
				KanPageCount++;
				LineCount = 1;
				if (*tenstr & 0x40 && *tenstr & 0x10) {
					KanCount++;
					KanPageCount = 1;
				}
			}
		}
	}
	PageInfo->Page = PageCount;
	PageInfo->Line = LineCount;
	PageInfo->Kan = KanCount;
	PageInfo->KanPage = KanPageCount;
	PageInfo->AllPage = AllPage;
}

- (void)SetCur:(int)Page line:(int)Line {
	int PageCount = 1;
	int LineCount = 1;
	int PageFlg = 0;
	[self Top];
	tenstr = [self GetDat];
	while (1) {
		if (Page == PageCount &&
		    Line == LineCount) {
			break;
		}
		if (*tenstr & 0x20) {
			PageFlg = 1;
		}
		if (![self NextLine]) {
			[self Top];
			break;
		}
		tenstr = [self GetDat];
		if (PageFlg) {
			PageCount++;
			LineCount = 1;
			PageFlg = 0;
		}
		else {
			LineCount++;
			if (LineCount > MaxLine) {
				PageCount++;
				LineCount = 1;
			}
		}
	}
}
@end
