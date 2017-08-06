/* ====================================================================
* Copyright (c) 1995-1999 The Apache Group.  All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* 1. Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in
*    the documentation and/or other materials provided with the
*    distribution.
*
* 3. All advertising materials mentioning features or use of this
*    software must display the following acknowledgment:
*    "This product includes software developed by the Apache Group
*    for use in the Apache HTTP server project (http://www.apache.org/)."
*
* 4. The names "Apache Server" and "Apache Group" must not be used to
*    endorse or promote products derived from this software without
*    prior written permission. For written permission, please contact
*    apache@apache.org.
*
* 5. Products derived from this software may not be called "Apache"
*    nor may "Apache" appear in their names without prior written
*    permission of the Apache Group.
*
* 6. Redistributions of any form whatsoever must retain the following
*    acknowledgment:
*    "This product includes software developed by the Apache Group
*    for use in the Apache HTTP server project (http://www.apache.org/)."
*
* THIS SOFTWARE IS PROVIDED BY THE APACHE GROUP ``AS IS'' AND ANY
* EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
* PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE APACHE GROUP OR
* ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
* ====================================================================
*
* This software consists of voluntary contributions made by many
* individuals on behalf of the Apache Group and was originally based
* on public domain software written at the National Center for
* Supercomputing Applications, University of Illinois, Urbana-Champaign.
* For more information on the Apache Group and the Apache HTTP server
* project, please see <http://www.apache.org/>.
*/

#include "base64.h"

/* aaaack but it's fast and const should make it shared text page. */
static const unsigned char pr2six[256] =
        {
                /* ASCII table */
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
                52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
                64, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
                15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
                64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
                41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
                64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
        };

size_t mpw_base64_decode_max(const char *b64Text) {

    register const uint8_t *bufin;
    register int nprbytes;

    bufin = (uint8_t *)b64Text;
    while (pr2six[*(bufin++)] <= 63);

    nprbytes = (int)(bufin - (uint8_t *)b64Text) - 1;
    return (size_t)(((nprbytes + 3) / 4) * 3);
}

int mpw_base64_decode(uint8_t *plainBuf, size_t plainMax, const char *b64Text) {

    register const uint8_t *bufin;
    register uint8_t *bufout;
    register int nprbytes;

    bufin = (uint8_t *)b64Text;
    while (pr2six[*(bufin++)] <= 63);
    nprbytes = (int)(bufin - (uint8_t *)b64Text) - 1;

    bufout = plainBuf;
    bufin = (uint8_t *)b64Text;

    while (nprbytes > 4) {
        if (bufout + 2 >= plainBuf + plainMax)
            return -1;

        *(bufout++) = (pr2six[*bufin] << 2 | pr2six[bufin[1]] >> 4);
        *(bufout++) = (pr2six[bufin[1]] << 4 | pr2six[bufin[2]] >> 2);
        *(bufout++) = (pr2six[bufin[2]] << 6 | pr2six[bufin[3]]);
        bufin += 4;
        nprbytes -= 4;
    }

    /* Note: (nprbytes == 1) would be an error, so just ingore that case */
    if (nprbytes > 1) {
        if (bufout >= plainBuf + plainMax)
            return -1;
        *(bufout++) = (pr2six[*bufin] << 2 | pr2six[bufin[1]] >> 4);
    }
    if (nprbytes > 2) {
        if (bufout >= plainBuf + plainMax)
            return -1;
        *(bufout++) = (pr2six[bufin[1]] << 4 | pr2six[bufin[2]] >> 2);
    }
    if (nprbytes > 3) {
        if (bufout >= plainBuf + plainMax)
            return -1;
        *(bufout++) = (pr2six[bufin[2]] << 6 | pr2six[bufin[3]]);
    }

    return (int)(bufout - plainBuf);
}

static const char basis_64[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

size_t mpw_base64_encode_max(size_t plainSize) {

    // Every 3 plain bytes yield 4 b64 chars => len = 4 * ceil(plainSize / 3)
    return 4 /*chars*/ * (plainSize + 3 /*bytes*/ - 1) / 3 /*bytes*/;
}

int mpw_base64_encode(char *b64Text, size_t b64Max, const uint8_t *plainBuf, size_t plainSize) {

    int i;
    char *p;

    p = b64Text;
    for (i = 0; i < plainSize - 2; i += 3) {
        if (p >= b64Text + b64Max)
            return -1;

        *p++ = basis_64[(plainBuf[i] >> 2) & 0x3F];
        *p++ = basis_64[((plainBuf[i] & 0x3) << 4) |
                        ((plainBuf[i + 1] & 0xF0) >> 4)];
        *p++ = basis_64[((plainBuf[i + 1] & 0xF) << 2) |
                        ((plainBuf[i + 2] & 0xC0) >> 6)];
        *p++ = basis_64[plainBuf[i + 2] & 0x3F];
    }
    if (i < plainSize) {
        if (p + 3 >= b64Text + b64Max)
            return -1;

        *p++ = basis_64[(plainBuf[i] >> 2) & 0x3F];
        if (i == (plainSize - 1)) {
            *p++ = basis_64[((plainBuf[i] & 0x3) << 4)];
            *p++ = '=';
        }
        else {
            *p++ = basis_64[((plainBuf[i] & 0x3) << 4) |
                            ((plainBuf[i + 1] & 0xF0) >> 4)];
            *p++ = basis_64[((plainBuf[i + 1] & 0xF) << 2)];
        }
        *p++ = '=';
    }

    *p = '\0';
    return (int)(p - b64Text);
}
