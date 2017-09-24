/*

Source: https://github.com/kokke/tiny-AES-c

This is an implementation of the AES algorithm, specifically ECB and CBC mode.

*/

#ifndef _AES_H_
#define _AES_H_

#include <stdint.h>


// #define the macros below to 1/0 to enable/disable the mode of operation.
//
// AES_CBC enables AES encryption in CBC-mode of operation.
// AES_ECB enables the basic ECB 16-byte block algorithm. Both can be enabled simultaneously.

// The #ifndef-guard allows it to be configured before #include'ing or at compile time.
#ifndef AES_CBC
  #define AES_CBC 1
#endif

#ifndef AES_ECB
  #define AES_ECB 1
#endif

#define AES_128 1
//#define AES_192 1
//#define AES_256 1
#define AES_BLOCKLEN 16 //Block length in bytes AES is 128b block only

#if defined(AES_ECB) && (AES_ECB == 1)

void AES_ECB_encrypt(uint8_t *output, const uint8_t *input, const uint32_t length, const uint8_t *key);
void AES_ECB_decrypt(uint8_t *output, const uint8_t *input, const uint32_t length, const uint8_t *key);

#endif // #if defined(AES_ECB) && (AES_ECB == !)


#if defined(AES_CBC) && (AES_CBC == 1)

void AES_CBC_encrypt_buffer(uint8_t* output, uint8_t* input, const uint32_t length, const uint8_t* key, const uint8_t* iv);
void AES_CBC_decrypt_buffer(uint8_t* output, uint8_t* input, const uint32_t length, const uint8_t* key, const uint8_t* iv);

#endif // #if defined(AES_CBC) && (AES_CBC == 1)


#endif //_AES_H_
