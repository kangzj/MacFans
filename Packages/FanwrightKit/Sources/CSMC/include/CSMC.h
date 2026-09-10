#ifndef CSMC_H
#define CSMC_H
#include <stdint.h>

typedef struct { char major; char minor; char build; char reserved; uint16_t release; } SMCVersion;
typedef struct { uint16_t version; uint16_t length; uint32_t cpuPLimit; uint32_t gpuPLimit; uint32_t memPLimit; } SMCPLimitData;
typedef struct { uint32_t dataSize; uint32_t dataType; char dataAttributes; } SMCKeyInfoData;
typedef struct {
    uint32_t key;
    SMCVersion vers;
    SMCPLimitData pLimitData;
    SMCKeyInfoData keyInfo;
    char result;
    char status;
    char data8;
    uint32_t data32;
    uint8_t bytes[32];
} SMCParamStruct;

enum { kSMCUserClientOpen = 0, kSMCUserClientClose = 1, kSMCHandleYPCEvent = 2 };
enum { kSMCReadKey = 5, kSMCWriteKey = 6, kSMCGetKeyFromIndex = 8, kSMCGetKeyInfo = 9 };
#endif
