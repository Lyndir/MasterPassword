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

MPMasterKey mpw_master_key(const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion) {

    if (fullName && !strlen( fullName ))
        fullName = NULL;
    if (masterPassword && !strlen( masterPassword ))
        masterPassword = NULL;

    trc( "-- mpw_master_key (algorithm: %u)", algorithmVersion );
    trc( "fullName: %s", fullName );
    trc( "masterPassword.id: %s", masterPassword? mpw_id_buf( masterPassword, strlen( masterPassword ) ): NULL );
    if (!fullName || !masterPassword)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_master_key_v0( fullName, masterPassword );
        case MPAlgorithmVersion1:
            return mpw_master_key_v1( fullName, masterPassword );
        case MPAlgorithmVersion2:
            return mpw_master_key_v2( fullName, masterPassword );
        case MPAlgorithmVersion3:
            return mpw_master_key_v3( fullName, masterPassword );
        default:
            err( "Unsupported version: %d", algorithmVersion );
            return NULL;
    }
}

MPSiteKey mpw_site_key(
        MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext, const MPAlgorithmVersion algorithmVersion) {

    if (keyContext && !strlen( keyContext ))
        keyContext = NULL;

    trc( "-- mpw_site_key (algorithm: %u)", algorithmVersion );
    trc( "siteName: %s", siteName );
    trc( "siteCounter: %d", siteCounter );
    trc( "keyPurpose: %d (%s)", keyPurpose, mpw_purpose_name( keyPurpose ) );
    trc( "keyContext: %s", keyContext );
    if (!masterKey || !siteName)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_site_key_v0( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersion1:
            return mpw_site_key_v1( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersion2:
            return mpw_site_key_v2( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersion3:
            return mpw_site_key_v3( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        default:
            err( "Unsupported version: %d", algorithmVersion );
            return NULL;
    }
}

const char *mpw_site_result(
        MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext,
        const MPResultType resultType, const char *resultParam,
        const MPAlgorithmVersion algorithmVersion) {

    if (keyContext && !strlen( keyContext ))
        keyContext = NULL;
    if (resultParam && !strlen( resultParam ))
        resultParam = NULL;

    MPSiteKey siteKey = mpw_site_key( masterKey, siteName, siteCounter, keyPurpose, keyContext, algorithmVersion );
    if (!siteKey)
        return NULL;

    trc( "-- mpw_site_result (algorithm: %u)", algorithmVersion );
    trc( "resultType: %d (%s)", resultType, mpw_type_short_name( resultType ) );
    trc( "resultParam: %s", resultParam );

    char *sitePassword = NULL;
    if (resultType & MPResultTypeClassTemplate) {
        switch (algorithmVersion) {
            case MPAlgorithmVersion0:
                return mpw_site_template_password_v0( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion1:
                return mpw_site_template_password_v1( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion2:
                return mpw_site_template_password_v2( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion3:
                return mpw_site_template_password_v3( masterKey, siteKey, resultType, resultParam );
            default:
                err( "Unsupported version: %d", algorithmVersion );
                return NULL;
        }
    }
    else if (resultType & MPResultTypeClassStateful) {
        switch (algorithmVersion) {
            case MPAlgorithmVersion0:
                return mpw_site_crypted_password_v0( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion1:
                return mpw_site_crypted_password_v1( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion2:
                return mpw_site_crypted_password_v2( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion3:
                return mpw_site_crypted_password_v3( masterKey, siteKey, resultType, resultParam );
            default:
                err( "Unsupported version: %d", algorithmVersion );
                return NULL;
        }
    }
    else if (resultType & MPResultTypeClassDerive) {
        switch (algorithmVersion) {
            case MPAlgorithmVersion0:
                return mpw_site_derived_password_v0( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion1:
                return mpw_site_derived_password_v1( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion2:
                return mpw_site_derived_password_v2( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersion3:
                return mpw_site_derived_password_v3( masterKey, siteKey, resultType, resultParam );
            default:
                err( "Unsupported version: %d", algorithmVersion );
                return NULL;
        }
    }
    else {
        err( "Unsupported password type: %d", resultType );
    }

    return sitePassword;
}

const char *mpw_site_state(
        MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext,
        const MPResultType resultType, const char *resultParam,
        const MPAlgorithmVersion algorithmVersion) {

    if (keyContext && !strlen( keyContext ))
        keyContext = NULL;
    if (resultParam && !strlen( resultParam ))
        resultParam = NULL;

    MPSiteKey siteKey = mpw_site_key( masterKey, siteName, siteCounter, keyPurpose, keyContext, algorithmVersion );
    if (!siteKey)
        return NULL;

    trc( "-- mpw_site_state (algorithm: %u)", algorithmVersion );
    trc( "resultType: %d (%s)", resultType, mpw_type_short_name( resultType ) );
    trc( "resultParam: %zu bytes = %s", sizeof( resultParam ), resultParam );
    if (!masterKey || !resultParam)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_site_state_v0( masterKey, siteKey, resultType, resultParam );
        case MPAlgorithmVersion1:
            return mpw_site_state_v1( masterKey, siteKey, resultType, resultParam );
        case MPAlgorithmVersion2:
            return mpw_site_state_v2( masterKey, siteKey, resultType, resultParam );
        case MPAlgorithmVersion3:
            return mpw_site_state_v3( masterKey, siteKey, resultType, resultParam );
        default:
            err( "Unsupported version: %d", algorithmVersion );
            return NULL;
    }
}

MPIdenticon mpw_identicon(const char *fullName, const char *masterPassword) {

    const char *leftArm[] = { "╔", "╚", "╰", "═" };
    const char *rightArm[] = { "╗", "╝", "╯", "═" };
    const char *body[] = { "█", "░", "▒", "▓", "☺", "☻" };
    const char *accessory[] = {
            "◈", "◎", "◐", "◑", "◒", "◓", "☀", "☁", "☂", "☃", "", "★", "☆", "☎", "☏", "⎈", "⌂", "☘", "☢", "☣",
            "☕", "⌚", "⌛", "⏰", "⚡", "⛄", "⛅", "☔", "♔", "♕", "♖", "♗", "♘", "♙", "♚", "♛", "♜", "♝", "♞", "♟",
            "♨", "♩", "♪", "♫", "⚐", "⚑", "⚔", "⚖", "⚙", "⚠", "⌘", "⏎", "✄", "✆", "✈", "✉", "✌"
    };

    const uint8_t *identiconSeed = NULL;
    if (fullName && strlen( fullName ) && masterPassword && strlen( masterPassword ))
        identiconSeed = mpw_hash_hmac_sha256(
                (const uint8_t *)masterPassword, strlen( masterPassword ),
                (const uint8_t *)fullName, strlen( fullName ) );
    if (!identiconSeed)
        return (MPIdenticon){
                .leftArm = "",
                .body = "",
                .rightArm = "",
                .accessory = "",
                .color = MPIdenticonColorBlack,
        };

    MPIdenticon identicon = {
            .leftArm = leftArm[identiconSeed[0] % (sizeof( leftArm ) / sizeof( leftArm[0] ))],
            .body = body[identiconSeed[1] % (sizeof( body ) / sizeof( body[0] ))],
            .rightArm = rightArm[identiconSeed[2] % (sizeof( rightArm ) / sizeof( rightArm[0] ))],
            .accessory = accessory[identiconSeed[3] % (sizeof( accessory ) / sizeof( accessory[0] ))],
            .color = (uint8_t)(identiconSeed[4] % (MPIdenticonColorLast - MPIdenticonColorFirst + 1) + MPIdenticonColorFirst),
    };
    mpw_free( &identiconSeed, 32 );

    return identicon;
}
