//
//  main.m
//  Test111
//
//  Created by erlich wang on 2022/7/27.
//

#import <Foundation/Foundation.h>

enum {
  HMAP_HeaderMagicNumber = ('h' << 24) | ('m' << 16) | ('a' << 8) | 'p',
  HMAP_HeaderVersion = 1,
  HMAP_EmptyBucketKey = 0
};

struct HMapBucket {
  uint32_t Key;    // Offset (into strings) of key.
  uint32_t Prefix; // Offset (into strings) of value prefix.
  uint32_t Suffix; // Offset (into strings) of value suffix.
};

struct HMapHeader {
  uint32_t Magic;          // Magic word, also indicates byte order.
  uint16_t Version;        // Version number -- currently 1.
  uint16_t Reserved;       // Reserved for future use - zero for now.
  uint32_t StringsOffset;  // Offset to start of string pool.
  uint32_t NumEntries;     // Number of entries in the string table.
  uint32_t NumBuckets;     // Number of buckets (always a power of 2).
  uint32_t MaxValueLength; // Length of longest result path (excluding nul).
  struct HMapBucket buckets[8]; // An array of 'NumBuckets' HMapBucket objects follows this header.
  char *mString;                // Strings follow the buckets, at StringsOffset.
};

/// This function returns a byte-swapped representation of the 32-bit argument.
uint32_t ByteSwap_32(uint32_t value) {
  uint32_t Byte0 = value & 0x000000FF;
  uint32_t Byte1 = value & 0x0000FF00;
  uint32_t Byte2 = value & 0x00FF0000;
  uint32_t Byte3 = value & 0xFF000000;
  return (Byte0 << 24) | (Byte1 << 8) | (Byte2 >> 8) | (Byte3 >> 24);
}

void read_hmap(void) {
    // test_hmap/Test111-all-non-framework-target-headers.hmap
    // test_hmap/Test111-all-target-headers.hmap
    // test_hmap/Test111-own-target-headers.hmap
    // test_hmap/Test111-project-headers.hmap
    // test_hmap/IFLTestSymbol-all-target-headers.hmap
    // test_hmap/IFLTestSymbol-generated-files.hmap
    // test_hmap/IFLTestSymbol-own-target-headers.hmap
    // test_hmap/IFLTestSymbol-project-headers.hmap
//    char *path = "/Users/erlich/Developer/workspace/ios/test/test_symbol/Test111/HMap/Test111.build/Debug-macosx/Test111.build/Test111-project-headers.hmap";
    char *path = "/Users/erlich/Developer/workspace/ios/test/test_symbol/Test111/Test111/test_hmap/Test111-project-headers.hmap";
    int file = open(path, O_RDONLY|O_CLOEXEC);
    if (file < 0) {
        printf("cannot open file %s", path);
        return;
    }
    struct HMapHeader *header = malloc(100 * sizeof(struct HMapHeader));
    ssize_t headerRead = read(file, header, 100 * sizeof(struct HMapHeader));
    if (headerRead < 0 || (size_t)headerRead < sizeof(struct HMapHeader)) {
        printf("read %s fail", path);
        close(file);
        return;
    }
    close(file);
    
    // Sniff it to see if it's a headermap by checking the magic number and version.
    bool needsByteSwap = false;
    if (header->Magic == ByteSwap_32(HMAP_HeaderMagicNumber) && header->Version == ByteSwap_32(HMAP_HeaderVersion)) {
        // 高低位变换
        needsByteSwap = true;
    }
    
    uint32_t NumBuckets = needsByteSwap ? ByteSwap_32(header->NumBuckets) : header->NumBuckets;
    uint32_t StringsOffset = needsByteSwap ? ByteSwap_32(header->StringsOffset) : header->StringsOffset;
    
    const void *raw = (const void *)header;
    
    // HMapBucket 数组
    const void *buckets = raw + 24;
    // 长字符串
    const void *string_table = raw + 24 + 8 + header->StringsOffset;

    printf("buckets 初始化了: %i\n\n", NumBuckets);
//    printf("长字符串：%s\n\n", string_table);
    
    int mBucketsCount = 0;
    for (uint32_t i = 0; i < NumBuckets; i++) {
        struct HMapBucket *bucket = (struct HMapBucket *)(buckets + i * sizeof(struct HMapBucket));
        bucket->Key = needsByteSwap ? ByteSwap_32(bucket->Key) : bucket->Key;
        bucket->Prefix = needsByteSwap ? ByteSwap_32(bucket->Prefix) : bucket->Prefix;
        bucket->Suffix = needsByteSwap ? ByteSwap_32(bucket->Suffix) : bucket->Suffix;
        
        if (bucket->Key == 0 && bucket->Prefix == 0 && bucket->Suffix == 0) {
            continue;
        }
        mBucketsCount++;
        const char *key = string_table + bucket->Key;
        const char *prefix = string_table + bucket->Prefix;
        const char *suffix = string_table + bucket->Suffix;

        printf("key: %s, offset: %i \nprefix: %s, offset: %i, \nsuffix: %s, offset: %i\n\n", key, bucket->Key, prefix, bucket->Prefix, suffix, bucket->Suffix);
    }
    
    printf("buckets 初始化了%i个，实际使用了%i个\n\n", NumBuckets, mBucketsCount);
    
    free(header);
}

int main(int argc, const char * argv[]) {
    
    read_hmap();
    
    return 0;
}
