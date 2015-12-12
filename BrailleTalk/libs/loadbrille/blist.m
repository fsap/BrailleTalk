#import <Foundation/Foundation.h>    
#import "blist.h"
@implementation BrlList 
- (void)SetAttr:(unsigned char)Dat {
	Attr = Dat;
}

- (unsigned char)GetAttr {
	return Attr;
}

- (void)SetUserInfo:(unsigned char)Dat {
	UserInfo = Dat;
}

- (unsigned char)GetUserInfo {
	return UserInfo;
}
- (void)SetData:(unsigned char *)Dat {
	*Data = *Dat;
	*(Data + 1) = *(Dat + 1);
	strcpy(Data+2, Dat+2);
}

- (unsigned char *)GetData {
	return Data;
}

- (void)SetStart:(id)Dat {
	Start = Dat;
}

- (id)GetStart {
	return Start;
}

- (void)SetNext:(id)Dat {
	Next = Dat;
}

- (id)GetNext {
	return Next;
}

- (void)SetBefore:(id)Dat {
	Before = Dat;
}

- (id)GetBefore {
	return Before;
}

@end
