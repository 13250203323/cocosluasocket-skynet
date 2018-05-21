    #define OP_ZSTRING  'z'     //空字符串
    #define OP_BSTRING  'p'     //长度小于2^8的字符串
    #define OP_WSTRING  'P'     //长度小于2^16的字符串
    #define OP_SSTRING  'a'     //长度小于2^32/64的字符串*/
    #define OP_STRING   'A'     //指定长度字符串
    #define OP_FLOAT    'f'     /* float */ -- len:4
    #define OP_DOUBLE   'd'     /* double */ -- len:8
    #define OP_NUMBER   'n'     /* Lua number */ -- len:8
    #define OP_CHAR     'c'     /* char */ -- len:1
    #define OP_BYTE     'b'     /* byte = unsigned char */ -- len:1
    #define OP_SHORT    'h'     /* short */ -- len:2
    #define OP_USHORT   'H'     /* unsigned short */ -- len:2
    #define OP_INT      'i'     /* int */ -- len:4
    #define OP_UINT     'I'     /* unsigned int */ -- len:4
    #define OP_LONG     'l'     /* long */ -- len:4
    #define OP_ULONG    'L'     /* unsigned long */ -- len:4