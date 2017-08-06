//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#include "mpw-algorithm.h"
#include "mpw-algorithm_v0.c"
#include "mpw-algorithm_v1.c"
#include "mpw-algorithm_v2.c"
#include "mpw-algorithm_v3.c"

MPMasterKey mpw_masterKey(const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion) {

    trc( "-- mpw_masterKey (algorithm: %u)\n", algorithmVersion );
    trc( "fullName: %s\n", fullName );
    trc( "masterPassword.id: %s\n", mpw_id_buf( masterPassword, strlen( masterPassword ) ) );
    if (!fullName || !masterPassword)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_masterKey_v0( fullName, masterPassword );
        case MPAlgorithmVersion1:
            return mpw_masterKey_v1( fullName, masterPassword );
        case MPAlgorithmVersion2:
            return mpw_masterKey_v2( fullName, masterPassword );
        case MPAlgorithmVersion3:
            return mpw_masterKey_v3( fullName, masterPassword );
        default:
            err( "Unsupported version: %d\n", algorithmVersion );
            return NULL;
    }
}

MPSiteKey mpw_siteKey(
        MPMasterKey masterKey, const char *siteName, const uint32_t siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext, const MPAlgorithmVersion algorithmVersion) {

    trc( "-- mpw_siteKey (algorithm: %u)\n", algorithmVersion );
    trc( "siteName: %s\n", siteName );
    trc( "siteCounter: %d\n", siteCounter );
    trc( "keyPurpose: %d (%s)\n", keyPurpose, mpw_nameForPurpose( keyPurpose ) );
    trc( "keyContext: %s\n", keyContext );
    if (!masterKey || !siteName)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_siteKey_v0( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersion1:
            return mpw_siteKey_v1( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersion2:
            return mpw_siteKey_v2( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersion3:
            return mpw_siteKey_v3( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        default:
            err( "Unsupported version: %d\n", algorithmVersion );
            return NULL;
    }
}

const char *mpw_sitePassword(
        MPSiteKey siteKey, const MPPasswordType passwordType, const MPAlgorithmVersion algorithmVersion) {

    trc( "-- mpw_sitePassword (algorithm: %u)\n", algorithmVersion );
    trc( "passwordType: %d (%s)\n", passwordType, mpw_nameForType( passwordType ) );
    if (!siteKey)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_sitePassword_v0( siteKey, passwordType );
        case MPAlgorithmVersion1:
            return mpw_sitePassword_v1( siteKey, passwordType );
        case MPAlgorithmVersion2:
            return mpw_sitePassword_v2( siteKey, passwordType );
        case MPAlgorithmVersion3:
            return mpw_sitePassword_v3( siteKey, passwordType );
        default:
            err( "Unsupported version: %d\n", algorithmVersion );
            return NULL;
    }
}

const char *mpw_encrypt(
        MPMasterKey masterKey, const char *plainText, const MPAlgorithmVersion algorithmVersion) {

    trc( "-- mpw_encrypt (algorithm: %u)\n", algorithmVersion );
    trc( "plainText: %s = %s\n", plainText, mpw_hex( plainText, sizeof( plainText ) ) );
    if (!masterKey || !plainText)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_encrypt_v0( masterKey, plainText );
        case MPAlgorithmVersion1:
            return mpw_encrypt_v1( masterKey, plainText );
        case MPAlgorithmVersion2:
            return mpw_encrypt_v2( masterKey, plainText );
        case MPAlgorithmVersion3:
            return mpw_encrypt_v3( masterKey, plainText );
        default:
            err( "Unsupported version: %d\n", algorithmVersion );
            return NULL;
    }
}

const char *mpw_decrypt(
        MPMasterKey masterKey, const char *cipherText, const MPAlgorithmVersion algorithmVersion) {

    trc( "-- mpw_decrypt (algorithm: %u)\n", algorithmVersion );
    trc( "cipherText: %s = %s\n", cipherText, mpw_hex( cipherText, sizeof( cipherText ) ) );
    if (!masterKey || !cipherText)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_decrypt_v0( masterKey, cipherText );
        case MPAlgorithmVersion1:
            return mpw_decrypt_v1( masterKey, cipherText );
        case MPAlgorithmVersion2:
            return mpw_decrypt_v2( masterKey, cipherText );
        case MPAlgorithmVersion3:
            return mpw_decrypt_v3( masterKey, cipherText );
        default:
            err( "Unsupported version: %d\n", algorithmVersion );
            return NULL;
    }
}
