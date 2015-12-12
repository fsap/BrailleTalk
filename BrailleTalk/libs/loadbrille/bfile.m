#import <Foundation/Foundation.h>    
#import "bfile.h"
#import "bbrlbuf.h"
#include <string.h>
@implementation File
- (void)DataSet:(id)Bufid {
	m_EditBuffer = Bufid;
	strcpy((char *)ntob, "\x20\xee\x90\xfc\xeb\xe9\xef\x84\xf7\xfe\xe1\xec\xe0\xe4\xe8\x8c\xf4\x82\x86\x92\xf2\xe2\x96\xf6\xe6\x94\xf1\xf0\xe3\xff\x9c\xf9\x88\x81\x83\x89\x99\x91\x8b\x9b\x93\x8a\x9a\x85\x87\x8d\x9d\x95\x8f\x9f\x97\x8e\x9e\xe5\xe7\xfa\xed\xfd\xf5\xea\xf3\xfb\x98\xf8");
}

- (int)LoadBetFile:(const char *)filename Form:(int)iFMode ReadMode:(int)RMode {
 FILE *fp;
	FILE *InFp;
	unsigned char TmpDat[256];
	int BookFast = 0;
	int Format = iFMode;
	int MaxLine;
	int ColChg;
	if((InFp = fopen(filename, "rb")) == NULL) {
		return(-1);
	}
	if(!fread(TmpDat,256,1,InFp)) {	// ヘッダサイズ以下のファイル
		fclose(InFp);
		return(4);
	}
	unsigned char Buf[4];
	if (!RMode) {
		[m_EditBuffer Remove];
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+24, 2);
		MaxLine = atoi((char *)Buf);
		m_EditHeadder.DatHead.MaxLine = atoi((char *)Buf);
		ColChg = 1;
		m_EditHeadder.DatHead.InitPage = 1;
		m_EditHeadder.DatHead.Col = 1;
		m_EditHeadder.DatHead.Line = 1+(m_EditHeadder.DatHead.InitPage?1:0);
		m_EditHeadder.DatHead.Page = 1;
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+22, 2);
		m_EditHeadder.DatHead.MaxCol = atoi((char *)Buf);
		if(m_EditHeadder.DatHead.MaxCol > 1) {
			m_EditHeadder.DatHead.MaxCol--;
		}
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+31, 3);
		m_EditHeadder.DatHead.AllPage = atoi((char *)Buf);
		m_EditHeadder.VoiceGengo = 34;
	}
	else {
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+24, 2);
		if (m_EditHeadder.DatHead.MaxLine != atoi((char *)Buf)) {
			fclose(InFp);
			return(-1);
		}
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+22, 2);
		if (m_EditHeadder.DatHead.MaxCol != atoi((char *)Buf)-1) {
			fclose(InFp);
			return(-1);
		}
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+31, 3);
		m_EditHeadder.DatHead.AllPage += atoi((char *)Buf);
	}
//	HeadEdit();
//	m_EditBuffer.SetCurList(m_EditBuffer.GetCurList()->Start);
	fread(TmpDat, 256, 1, InFp);
	if(Format == BES_FILE_ATTR) {
		fread(TmpDat, 256, 1, InFp);
		fread(TmpDat, 256, 1, InFp);
	}
	start:
	fread(TmpDat, 1, 1, InFp);
	if (TmpDat[0] != 0xff && Format == BES_FILE_ATTR) {
		goto start;
	}
	int reply = 1;
	int NextFlg = 0;
	LineFlg = 0;
	long pl = 0;
	int Index = 0;
	unsigned char c;
	long  gl;
	while(1) {
		if (!fread(Buf, 1, 1, InFp)) {
			if (!LineFlg && !Index) {
				break;
			}
			if (!Index) {
				m_EditData.Block.Data.Dat[Index].Code = PR_MARK;
			}
			else if (m_EditData.Block.Data.Dat[Index-1].Code == CR_MARK ||
			         m_EditData.Block.Data.Dat[Index-1].Code == 0) {
				m_EditData.Block.Data.Dat[Index-1].Code = PR_MARK;
			}
			else if (m_EditData.Block.Data.Dat[Index-1].Code != PR_MARK) {
				m_EditData.Block.Data.Dat[Index].Code = PR_MARK;
			}
			[self SetLineHead];
			[m_EditBuffer Ins:m_EditData.Data];
			break;
		} else {
			c = Buf[0];
		}
		if (pl <= 0 && Format == BES_FILE_ATTR) {
			pl = fgetc(InFp);
			pl = 256 * pl + c;
			if (pl == 0) {  /* pl > 65535 */
				long pl1;
				c = fgetc(InFp);
				pl1 = fgetc(InFp);
				pl1 = 256 * pl1 + c;
				pl = fgetc(InFp);
				c = fgetc(InFp);
				pl = 256 * pl + c;
				pl = 65536l * pl + pl1;
				pl -= 4;
			}
			pl -= 2;
			continue;
		}
		else if (Format == BES_FILE_ATTR) {
			pl--;
		}
		if (c == 0xfd || c == 0xfe || c == '\f' || c == 0x0d) {
			if(c == 0xfd) {
				if (!LineFlg) {
					continue;
				}
				else {
					m_EditData.Block.Data.Dat[Index].Code = PR_MARK;
					NextFlg = 1;
					LineFlg = MaxLine;
				}
			}
			else if (c == 0x0d || c == '\f') {
				if (c == 0x0d) {
					m_EditData.Block.Data.Dat[Index].Code = CR_MARK;
				}
				else {
					m_EditData.Block.Data.Dat[Index].Code = PR_MARK;
					if (Format == BET_FILE_ATTR) {
						fgetc(InFp);
					}
					NextFlg = 1;
				}
			}
			else {	// c == 0xfe のとき
				if (!Index) {
					m_EditData.Block.Data.Dat[Index].Code = CR_MARK;
				}
				else {
					m_EditData.Block.Data.Dat[Index].Code = 0x00;
				}
				NextFlg = 1;
				if (Format == BET_FILE_ATTR) {
					long FilePtr = ftell(InFp);
					c = fgetc(InFp);
					c = fgetc(InFp);
					if (c > 10) {
						fseek(InFp, FilePtr, SEEK_SET);
					}
				}
			}
		}
		else if (c == 0xf4) {
			/* 見出 */
			m_EditData.Block.SubAttr.Map.Index = 1;
			continue;
		}
		else if (c == 0xf5 || c == 0xf6) {
			/* ｲﾝﾃﾞﾝﾄ */
			c = fgetc(InFp);
			m_EditData.Block.SubAttr.Map.IndentCnt = c - 0xa0;
			pl--;
			continue;
		}
		else if (c == 0xfc && Format == BES_FILE_ATTR) {
			/* ｸﾞﾗﾌｨｯｸ */
			c = fgetc(InFp);
			gl = fgetc(InFp);
			gl = gl * 256 + c;
			fseek(InFp, gl *32, SEEK_CUR);
			pl -= gl * 32 + 2;
			continue;
		}
		else if (c == 0xfc && Format == BET_FILE_ATTR) {
			/* ﾖｸ ﾜｶﾗﾅｲ */
			c = fgetc(InFp);
			continue;
		}
		else if (c == 0x1a) {
			/* ﾖｸ ﾜｶﾗﾅｲ */
			continue;
		}
		else if (c == 0xa0) {
			m_EditData.Block.Data.Dat[Index].Code = 0x20;
		}
		else if (c >= 0xa1 && c <= 0xdf) {
			if (c >= 0xa1 && c <= 0xbf) {
				m_EditData.Block.Data.Dat[Index].Code = (unsigned char)c-0x20;
			}
			else if (c >= 0xc0 && c <= 0xdf) {
				m_EditData.Block.Data.Dat[Index].Code = (unsigned char)c+0x20;
			}
		}
		else {
			continue;
		}
		Index++;
		if(NextFlg) {	// カレント行をバッファに保存
			if(m_EditHeadder.DatHead.InitPage && !LineFlg) {	// 頁行処理
				m_EditData.Block.LineAttr.Map.LineAttr |= PAGE_LINE_ATTR;
				if (!BookFast) {
					m_EditData.Block.LineAttr.Map.LineAttr |= TOC_LINE_ATTR;
					BookFast = 1;
				}
				Index = [self EditDataLen];
				if(!(Index&0xff00)) {
					m_EditData.Block.Data.Dat[Index].Code = CR_MARK;
				}
			}
			LineFlg++;
			if(LineFlg >= MaxLine || c == '\f') {
				LineFlg = 0;
				if (Format == BES_FILE_ATTR) {
					if(pl && (c == '\f' || c == 0x0d)) {
						fgetc(InFp);
						pl--;
					}
				}
			}
			NextFlg = 0;
			Index = 0;
			[self SetLineHead];
			[m_EditBuffer Ins:m_EditData.Data];
			memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
		}
	}
	fclose(InFp);
	[m_EditBuffer SetMaxLine:MaxLine];
	[m_EditBuffer SetAllPage:m_EditHeadder.DatHead.AllPage];
	return 0;
}

- (int)LoadBsFile:(const char *)filename  ReadMode:(int)RMode {
	int BookFast = 0;
	FILE *fp;
	FILE *InFp;
	if((InFp = fopen(filename,"rb")) == NULL) {
		NSString* nsfilename = [NSString stringWithCString: filename encoding:NSUTF8StringEncoding];
		return(-1);
	}
	unsigned char TmpDat[256];
	memset(TmpDat,0x00,sizeof(TmpDat));
	if(!fread(TmpDat,256,1,InFp)) {
		fclose(InFp);
		return(4);
	}
	if (!RMode || RMode == 2) {
		[m_EditBuffer Remove];
		memcpy(&m_EditHeadder,TmpDat,BRLDOC_HEAD_SIZE);
		if (!RMode) {
			m_EditHeadder.VoiceGengo = 34;
		}
	}
	else {
		memcpy(&TempHeadder,TmpDat,BRLDOC_HEAD_SIZE);
		if (m_EditHeadder.DatHead.MaxLine != TempHeadder.DatHead.MaxLine ||
		    m_EditHeadder.DatHead.MaxCol != TempHeadder.DatHead.MaxCol) {
			fclose(InFp);
			return -1;
		}
		m_EditHeadder.DatHead.AllPage = m_EditHeadder.DatHead.AllPage + TempHeadder.DatHead.AllPage;
		[m_EditBuffer End];
	}
	int reply = 1;
	short IpLen = 0;
	while(1) {
		if(!fread(&IpLen,2,1,InFp)) {
			break;
		}
		memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
/*
		if(IpLen > BRLDOC_MAX_DAT_INDEX) {
			if(!fread(m_EditData.Data,BRLDOC_DAT_SIZE,1,InFp)) {
				break;
			}
			[self SetLineHead];
			[m_EditBuffer Ins:m_EditData.Data];
		}
*/
		char ReadBuf[BRLDOC_DAT_SIZE];
		memset(ReadBuf,0x00,BRLDOC_DAT_SIZE);
		if(!fread(ReadBuf,IpLen*2,1,InFp)) {
			break;
		}
		memcpy(m_EditData.Data,ReadBuf,BRLDOC_DAT_SIZE);
		if (!BookFast) {
			m_EditData.Block.LineAttr.Map.LineAttr |= TOC_LINE_ATTR;
			m_EditData.Block.LineAttr.Map.LineAttr |= PAGE_LINE_ATTR;
			BookFast = 1;
		}
		[self SetLineHead];
		[m_EditBuffer Ins:m_EditData.Data];
	}
	fclose(InFp);
	char *tenstr = [m_EditBuffer GetDat];
	tenstr += 2;
	if (!*tenstr) {
		*tenstr = PR_MARK;
	}
	else if (tenstr[strlen(tenstr)-1] != PR_MARK) {
		tenstr[strlen(tenstr)-1] = PR_MARK;
	}
	[m_EditBuffer SetMaxLine:m_EditHeadder.DatHead.MaxLine];
	[m_EditBuffer SetAllPage:m_EditHeadder.DatHead.AllPage];
	if (!RMode) {
		[m_EditBuffer SetCur:m_EditHeadder.DatHead.Page line:m_EditHeadder.DatHead.Line];
	}
	else {
		[m_EditBuffer Top];
	}
	return(reply);
}

- (int)LoadBseFile:(const char *)filename  ReadMode:(int)RMode {
	int BookFast = 0;
	char *tenstr;
	FILE *InFp;
	if((InFp = fopen(filename,"r")) == NULL) {
		return(-1);
	}
	int MaxLine;
	int MaxPage;
	unsigned char TmpDat[1024];
	if(!fread(TmpDat,256,1,InFp)) {
		fclose(InFp);
		return(4);
	}
	if (fgets((char *)TmpDat, 1024, InFp) == NULL) {
		fclose(InFp);
		return(4);
	}
	char Buf[5];
	memset(Buf, 0x00, sizeof(Buf));
	if (!RMode) {
		[m_EditBuffer Remove];
		memcpy(Buf, TmpDat+248, 4);
		m_EditHeadder.DatHead.AllPage = atoi(Buf);
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+252, 2);
		m_EditHeadder.DatHead.MaxCol = atoi(Buf);
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+254, 2);
		m_EditHeadder.DatHead.MaxLine = atoi(Buf);
		m_EditHeadder.DatHead.InitPage = 1;
		MaxPage = m_EditHeadder.DatHead.AllPage;
		m_EditHeadder.VoiceGengo = 34;
	}
	else {
		memcpy(Buf, TmpDat+252, 2);
		if (m_EditHeadder.DatHead.MaxCol != atoi(Buf)) {
			return -1;
		}
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+254, 2);
		if (m_EditHeadder.DatHead.MaxLine != atoi(Buf)) {
			return -1;
		}
		memset(Buf, 0x00, sizeof(Buf));
		memcpy(Buf, TmpDat+248, 4);
		m_EditHeadder.DatHead.AllPage += atoi(Buf);
		MaxPage = atoi(Buf);
		[m_EditBuffer End];
	}
	MaxLine = m_EditHeadder.DatHead.MaxLine;
	int reply = 1;
	int PageFlg = 0;
	int Ip = 0;
	int Il = 0;
	for (Ip = 0; Ip <= MaxPage; Ip++) {
		for (Il = 0; Il < MaxLine; Il++) {
			if (fgets((char *)TmpDat, 256, InFp) == NULL) {
				reply = 3;
				break;
			}
			unsigned char *Sp = (unsigned char *)strchr((char *)TmpDat,'\f');
			if (Sp != NULL) {
				PageFlg = 1;
			}
			if (!Il) {
				m_EditData.Block.LineAttr.Map.LineAttr |= PAGE_LINE_ATTR;
				if (!BookFast) {
					m_EditData.Block.LineAttr.Map.LineAttr |= TOC_LINE_ATTR;
					BookFast = 1;
				}
			}
			TmpDat[strlen((char *)TmpDat)-1] = 0;
			TmpDat[strlen((char *)TmpDat)-1] = 0;
			int Ix = strlen((char *)TmpDat);
			int Ic = 0;
			for (Ic = 0; Ic < Ix; Ic++) {
				m_EditData.Block.Data.Dat[Ic].Code = ntob[TmpDat[Ic] - 0x20];
			}
			if (!Ix) {
				if (PageFlg) {
					m_EditData.Block.Data.Dat[Ic].Code = PR_MARK;
				}
				else {
					m_EditData.Block.Data.Dat[Ic].Code = CR_MARK;
				}
			}
			else if (PageFlg) {
				m_EditData.Block.Data.Dat[Ic].Code = PR_MARK;
			}
			else if (!Il && Ic) {
				m_EditData.Block.Data.Dat[Ic].Code = CR_MARK;
			}
			if (Il &&
			    (!Ix ||
			     (m_EditData.Block.Data.Dat[0].Code == 0x20 &&
			      m_EditData.Block.Data.Dat[1].Code == 0x20))) {
				tenstr = [m_EditBuffer GetDat];
				tenstr += 2;
				if (tenstr[strlen(tenstr)-1] != CR_MARK) {
					tenstr[strlen(tenstr)] = CR_MARK;
				}
			}
			[self SetLineHead];
			[m_EditBuffer Ins:m_EditData.Data];
			memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
			if (PageFlg) {
				Il = MaxLine;
			}
		}
	}
	fclose(InFp);
	tenstr = [m_EditBuffer GetDat];
	tenstr += 2;
	if (!*tenstr) {
		*tenstr = PR_MARK;
	}
	else if (tenstr[strlen(tenstr)-1] != PR_MARK) {
		tenstr[strlen(tenstr)] = PR_MARK;
	}
	[m_EditBuffer Top];
	return(0);
}

- (int)LoadBrfFile:(const char *)filename  ReadMode:(int)RMode {
	int BookFast = 0;
	char *tenstr;
	FILE *InFp;
	if((InFp = fopen(filename,"r")) == NULL) {
		return(-1);
	}
	unsigned char TmpDat[64];
	if (!RMode) {
		[m_EditBuffer Remove];
		m_EditHeadder.DatHead.InitPage = 0;
		m_EditHeadder.DatHead.MaxCol = 40;
		m_EditHeadder.DatHead.MaxLine = 25;
		m_EditHeadder.VoiceGengo = 1;
	}
	else {
		[m_EditBuffer End];
	}
	int Ip = 0;
	int Il = 0;
	int reply = 0;
	for (Ip = 0; Ip <= 4096; Ip++) {
		for (Il = 0; Il < 25; Il++) {
			if (fgets((char *)TmpDat, 64, InFp) == NULL) {
				reply = 1;
				break;
			}
			if (!BookFast) {
				m_EditData.Block.LineAttr.Map.LineAttr |= TOC_LINE_ATTR;
				m_EditData.Block.LineAttr.Map.LineAttr |= PAGE_LINE_ATTR;
				BookFast = 1;
			}
			TmpDat[strlen((char *)TmpDat)-1] = 0;
			TmpDat[strlen((char *)TmpDat)-1] = 0;
			int Ix = strlen((char *)TmpDat);
			int Ic = 0;
			for (Ic = 0; Ic < Ix; Ic++) {
				m_EditData.Block.Data.Dat[Ic].Code = ntob[TmpDat[Ic] - 0x20];
			}
			if (!Ix) {
				m_EditData.Block.Data.Dat[Ic].Code = CR_MARK;
			}
			if (!(!Ip && !Il) &&
			    (!Ix ||
			     (m_EditData.Block.Data.Dat[0].Code == 0x20 &&
			      m_EditData.Block.Data.Dat[1].Code == 0x20))) {
				tenstr = [m_EditBuffer GetDat];
				tenstr += 2;
				if (tenstr[strlen(tenstr)-1] != CR_MARK) {
					tenstr[strlen(tenstr)] = CR_MARK;
				}
			}
			[self SetLineHead];
			[m_EditBuffer Ins:m_EditData.Data];
			memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
		}
		if (reply) {
			break;
		}
	}
	fclose(InFp);
	tenstr = [m_EditBuffer GetDat];
	tenstr += 2;
	if (!*tenstr) {
		*tenstr = PR_MARK;
	}
	else if (tenstr[strlen(tenstr)-1] != PR_MARK) {
		tenstr[strlen(tenstr)] = PR_MARK;
	}
	if (!RMode) {
		m_EditHeadder.DatHead.AllPage = Ip && !Il ? Ip : Ip+1;
	}
	else {
		m_EditHeadder.DatHead.AllPage += Ip && !Il ? Ip : Ip+1;
	}
	[m_EditBuffer Top];
	return(0);
}

- (int)SaveBsFile:(const char *)filename {
	FILE *OutFp;
	int reply;
	m_EditHeadder.DatHead.DatAttr = BR3_ED_MARK;
	if((OutFp = fopen(filename,"w+b")) == NULL) {
		return(-1);
	}
	m_EditHeadder.DatHead.Page = 1;
	m_EditHeadder.DatHead.Line = 1+(m_EditHeadder.DatHead.InitPage?1:0);
	m_EditHeadder.DatHead.Col = 1;
	if(!fwrite(&m_EditHeadder,BRLDOC_HEAD_SIZE,1,OutFp)) {
		fclose(OutFp);
		unlink(filename);
		return(3);
	}
	int Ix;
	for (Ix = 0; Ix < 256-BRLDOC_HEAD_SIZE; Ix++) {
		unsigned char Tmp = 0x00;
		fwrite(&Tmp,1,1,OutFp);
	}
	fflush(OutFp);
	[m_EditBuffer Top];
	while (1) {
		memcpy(m_EditData.Data, [m_EditBuffer GetDat], BRLDOC_DAT_SIZE);
		short Len = (short)([self EditDataLen] & 0x00ff);
		if(!Len) {
			Len = BRLDOC_MAX_DAT_INDEX;
		}
		if(Len%2) {
			Len++;
		}
		Len /= 2;
		Len++;
		if(!fwrite(&Len,2,1,OutFp)) {
			reply = 3;
			break;
		}
		if(!fwrite(m_EditData.Data,Len*2,1,OutFp)) {
			reply = 3;
			break;
		}
		fflush(OutFp);
		if (![m_EditBuffer NextLine]) {
			break;
		}
	}
	fflush(OutFp);
	fclose(OutFp);
	if(reply == 3) {
		unlink(filename);
	}
	return(reply);
}

- (bool)SaveCur:(char *)filename {
	FILE *OutFp;
	PAGE_INFO PageInfo;
	[m_EditBuffer IsCurrent:&PageInfo];
	if((OutFp = fopen(filename,"r+b")) == NULL) {
		return FALSE;
	}
	fseek(OutFp,2L,SEEK_SET);
	m_EditHeadder.DatHead.Page = PageInfo.Page;
	m_EditHeadder.DatHead.Line = PageInfo.Line;
	m_EditHeadder.DatHead.Col = 1;
	fwrite(&m_EditHeadder.DatHead.Page, 8, 1, OutFp);	// ヘッダ保存
	fflush(OutFp);
	fclose(OutFp);
	return TRUE;
}

// 行属性を設定する関数
- (void)SetLineHead {
	unsigned char LAttr = m_EditData.Block.LineAttr.Attr&0xdf;
	if(strchr((char *)m_EditData.Block.Data.Line,PR_MARK) != NULL) {
			LAttr += 0x20;
	}
	if(LAttr&CL_STAB_ATTR*16) {
		LAttr &= 0x3f;
	}
	m_EditData.Block.LineAttr.Attr = LAttr;
}
// 行内の最大文字取得関数
- (int)EditDataLen {
	int index = 0;
	while(1) {
		if(m_EditData.Block.Data.Dat[index & 0x00ff].Code == 0x00) {
			break;
		}
		if(m_EditData.Block.Data.Dat[index & 0x00ff].Code == CR_MARK) {
			index |= 0x0100;
		}
		if(m_EditData.Block.Data.Dat[index & 0x00ff].Code == PR_MARK) {
			index |= 0x0200;
		}
		index++;
	}
	return(index);
}

- (void)SetVoiceGengo:(char)Dat {
	m_EditHeadder.VoiceGengo = Dat;
}

- (void)SetVoiceItem:(char)Dat {
	m_EditHeadder.VoiceItem = Dat;
}

- (char)IsVoiceGengo {
	return m_EditHeadder.VoiceGengo;
}

- (char)IsVoiceItem {
	return m_EditHeadder.VoiceItem;
}
@end
