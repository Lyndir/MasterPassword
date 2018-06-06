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

#include <stddef.h>
#include <stdint.h>

/**
 * @return The amount of bytes needed to decode the given b64Text.
 */
size_t mpw_base64_decode_max(const char *b64Text);
/** Decodes a base-64 encoded string into a plain byte buffer.
  * @param plainBuf a byte buffer, size should be at least mpw_base64_decode_max(b64Text)
  * @return The amount of bytes that were written to plainBuf.
  */
int mpw_base64_decode(uint8_t *plainBuf, const char *b64Text);

/**
 * @return The amount of characters needed to encode a plainBuf of the given size as base-64 (excluding the terminating NUL).
 */
size_t mpw_base64_encode_max(size_t plainSize);
/** Encodes a plain byte buffer into a base-64 encoded string.
  * @param b64Text a character buffer, size should be at least mpw_base64_encode_max(plainSize) + 1
  * @return The amount of characters that were written to b64Text, excluding the terminating NUL.
  */
int mpw_base64_encode(char *b64Text, const uint8_t *plainBuf, size_t plainSize);
