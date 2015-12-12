#import <Foundation/Foundation.h>

#define BUF_LIST_HEAD	'S'
#define BUF_LIST_END	'E'
#define BUF_DEL_LIST_HEAD	's'
#define BUF_DEL_LIST_END	'E'
#define BUF_LIST_DATA	'D'
#define RBUF_SIZE 1024
#define CR_MARK	0x0d
#define PR_MARK	0x0c

typedef struct {
	unsigned short AllPage;
	unsigned short Page;
	unsigned short Line;
	unsigned short Kan;
	unsigned short KanPage;
}PAGE_INFO;

@interface BrlBuffer : NSObject {
	id m_lpList;
	id m_lpDelList;
	int MaxLine;
	int AllPage;
	int NextFlg;
	NSString* Word;
	unsigned char *tenstr;
}
- (void)Setinit;
- (NSString*)Word;
- (void)PutDat:(unsigned char *)Dat;
- (unsigned char *)GetDat;
- (unsigned char)IsAttr;
- (BOOL)IsBuffer;
- (BOOL)Del;
- (void)Remove;
- (void)Ins:(unsigned char *)Dat;
// 次のリスト位置にポインタを移動
- (BOOL)NextLine;
// 前のリスト位置にポインタを移動
- (BOOL)BeforeLine;
- (void)Top;
- (void)End;
- (BOOL)BackPage;
- (BOOL)PageTop;
- (void)IsCurrent:(PAGE_INFO *)PageInfo;
- (void)SetCur:(int)Page line:(int)LIne;
- (void)SetMaxLine:(int)Line;
- (void)SetAllPage:(int)Page;
@end
