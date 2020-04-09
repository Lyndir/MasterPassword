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
#include "mpw-algorithm_v0.h"
#include "mpw-algorithm_v1.h"
#include "mpw-algorithm_v2.h"
#include "mpw-algorithm_v3.h"
#include "mpw-util.h"

MP_LIBS_BEGIN
#include <string.h>
MP_LIBS_END

const MPMasterKey mpw_master_key(const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion) {

    if (fullName && !strlen( fullName ))
        fullName = NULL;
    if (masterPassword && !strlen( masterPassword ))
        masterPassword = NULL;

    trc( "-- mpw_master_key (algorithm: %u)", algorithmVersion );
    trc( "fullName: %s", fullName );
    trc( "masterPassword.id: %s", masterPassword? mpw_id_buf( masterPassword, strlen( masterPassword ) ): NULL );
    if (!fullName) {
        err( "Missing fullName" );
        return NULL;
    }
    if (!masterPassword) {
        err( "Missing masterPassword" );
        return NULL;
    }

    switch (algorithmVersion) {
        case MPAlgorithmVersionV0:
            return mpw_master_key_v0( fullName, masterPassword );
        case MPAlgorithmVersionV1:
            return mpw_master_key_v1( fullName, masterPassword );
        case MPAlgorithmVersionV2:
            return mpw_master_key_v2( fullName, masterPassword );
        case MPAlgorithmVersionV3:
            return mpw_master_key_v3( fullName, masterPassword );
        default:
            err( "Unsupported version: %d", algorithmVersion );
            return NULL;
    }
}

const MPSiteKey mpw_site_key(
        const MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext, const MPAlgorithmVersion algorithmVersion) {

    if (keyContext && !strlen( keyContext ))
        keyContext = NULL;

    trc( "-- mpw_site_key (algorithm: %u)", algorithmVersion );
    trc( "siteName: %s", siteName );
    trc( "siteCounter: %d", siteCounter );
    trc( "keyPurpose: %d (%s)", keyPurpose, mpw_purpose_name( keyPurpose ) );
    trc( "keyContext: %s", keyContext );
    if (!masterKey) {
        err( "Missing masterKey" );
        return NULL;
    }
    if (!siteName) {
        err( "Missing siteName" );
        return NULL;
    }

    switch (algorithmVersion) {
        case MPAlgorithmVersionV0:
            return mpw_site_key_v0( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersionV1:
            return mpw_site_key_v1( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersionV2:
            return mpw_site_key_v2( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        case MPAlgorithmVersionV3:
            return mpw_site_key_v3( masterKey, siteName, siteCounter, keyPurpose, keyContext );
        default:
            err( "Unsupported version: %d", algorithmVersion );
            return NULL;
    }
}

const char *mpw_site_result(
        const MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext,
        const MPResultType resultType, const char *resultParam,
        const MPAlgorithmVersion algorithmVersion) {

    if (keyContext && !strlen( keyContext ))
        keyContext = NULL;
    if (resultParam && !strlen( resultParam ))
        resultParam = NULL;

    MPSiteKey siteKey = mpw_site_key( masterKey, siteName, siteCounter, keyPurpose, keyContext, algorithmVersion );

    trc( "-- mpw_site_result (algorithm: %u)", algorithmVersion );
    trc( "resultType: %d (%s)", resultType, mpw_type_short_name( resultType ) );
    trc( "resultParam: %s", resultParam );
    if (!masterKey) {
        err( "Missing masterKey" );
        return NULL;
    }
    if (!siteKey) {
        err( "Missing siteKey" );
        return NULL;
    }

    if (resultType & MPResultTypeClassTemplate) {
        switch (algorithmVersion) {
            case MPAlgorithmVersionV0:
                return mpw_site_template_password_v0( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV1:
                return mpw_site_template_password_v1( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV2:
                return mpw_site_template_password_v2( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV3:
                return mpw_site_template_password_v3( masterKey, siteKey, resultType, resultParam );
            default:
                err( "Unsupported version: %d", algorithmVersion );
                return NULL;
        }
    }
    else if (resultType & MPResultTypeClassStateful) {
        switch (algorithmVersion) {
            case MPAlgorithmVersionV0:
                return mpw_site_crypted_password_v0( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV1:
                return mpw_site_crypted_password_v1( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV2:
                return mpw_site_crypted_password_v2( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV3:
                return mpw_site_crypted_password_v3( masterKey, siteKey, resultType, resultParam );
            default:
                err( "Unsupported version: %d", algorithmVersion );
                return NULL;
        }
    }
    else if (resultType & MPResultTypeClassDerive) {
        switch (algorithmVersion) {
            case MPAlgorithmVersionV0:
                return mpw_site_derived_password_v0( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV1:
                return mpw_site_derived_password_v1( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV2:
                return mpw_site_derived_password_v2( masterKey, siteKey, resultType, resultParam );
            case MPAlgorithmVersionV3:
                return mpw_site_derived_password_v3( masterKey, siteKey, resultType, resultParam );
            default:
                err( "Unsupported version: %d", algorithmVersion );
                return NULL;
        }
    }
    else {
        err( "Unsupported password type: %d", resultType );
    }

    return NULL;
}

const char *mpw_site_state(
        const MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext,
        const MPResultType resultType, const char *resultParam,
        const MPAlgorithmVersion algorithmVersion) {

    if (keyContext && !strlen( keyContext ))
        keyContext = NULL;
    if (resultParam && !strlen( resultParam ))
        resultParam = NULL;

    MPSiteKey siteKey = mpw_site_key( masterKey, siteName, siteCounter, keyPurpose, keyContext, algorithmVersion );

    trc( "-- mpw_site_state (algorithm: %u)", algorithmVersion );
    trc( "resultType: %d (%s)", resultType, mpw_type_short_name( resultType ) );
    trc( "resultParam: %zu bytes = %s", resultParam? strlen( resultParam ): 0, resultParam );
    if (!masterKey) {
        err( "Missing masterKey" );
        return NULL;
    }
    if (!siteKey) {
        err( "Missing siteKey" );
        return NULL;
    }
    if (!resultParam) {
        err( "Missing resultParam" );
        return NULL;
    }

    switch (algorithmVersion) {
        case MPAlgorithmVersionV0:
            return mpw_site_state_v0( masterKey, siteKey, resultType, resultParam );
        case MPAlgorithmVersionV1:
            return mpw_site_state_v1( masterKey, siteKey, resultType, resultParam );
        case MPAlgorithmVersionV2:
            return mpw_site_state_v2( masterKey, siteKey, resultType, resultParam );
        case MPAlgorithmVersionV3:
            return mpw_site_state_v3( masterKey, siteKey, resultType, resultParam );
        default:
            err( "Unsupported version: %d", algorithmVersion );
            return NULL;
    }
}

static const char *mpw_identicon_leftArms[] = { "╔", "╚", "╰", "═" };
static const char *mpw_identicon_bodies[] = { "█", "░", "▒", "▓", "☺", "☻" };
static const char *mpw_identicon_rightArms[] = { "╗", "╝", "╯", "═" };
static const char *mpw_identicon_accessories[] = {
        "◈", "◎", "◐", "◑", "◒", "◓", "☀", "☁", "☂", "☃", "☄", "★", "☆", "☎", "☏", "⎈", "⌂", "☘", "☢", "☣",
        "☕", "⌚", "⌛", "⏰", "⚡", "⛄", "⛅", "☔", "♔", "♕", "♖", "♗", "♘", "♙", "♚", "♛", "♜", "♝", "♞", "♟",
        "♨", "♩", "♪", "♫", "⚐", "⚑", "⚔", "⚖", "⚙", "⚠", "⌘", "⏎", "✄", "✆", "✈", "✉", "✌"
};

const MPIdenticon mpw_identicon(const char *fullName, const char *masterPassword) {

    const uint8_t *seed = NULL;
    if (fullName && strlen( fullName ) && masterPassword && strlen( masterPassword ))
        seed = mpw_hash_hmac_sha256(
                (const uint8_t *)masterPassword, strlen( masterPassword ),
                (const uint8_t *)fullName, strlen( fullName ) );
    if (!seed)
        return MPIdenticonUnset;

    MPIdenticon identicon = {
            .leftArm = mpw_identicon_leftArms[seed[0] % (sizeof( mpw_identicon_leftArms ) / sizeof( *mpw_identicon_leftArms ))],
            .body = mpw_identicon_bodies[seed[1] % (sizeof( mpw_identicon_bodies ) / sizeof( *mpw_identicon_bodies ))],
            .rightArm = mpw_identicon_rightArms[seed[2] % (sizeof( mpw_identicon_rightArms ) / sizeof( *mpw_identicon_rightArms ))],
            .accessory = mpw_identicon_accessories[seed[3] % (sizeof( mpw_identicon_accessories ) / sizeof( *mpw_identicon_accessories ))],
            .color = (MPIdenticonColor)(seed[4] % (MPIdenticonColorLast - MPIdenticonColorFirst + 1) + MPIdenticonColorFirst),
    };
    mpw_free( &seed, 32 );

    return identicon;
}

const char *mpw_identicon_encode(
        const MPIdenticon identicon) {

    if (identicon.color == MPIdenticonColorUnset)
        return NULL;

    return mpw_str( "%hhu:%s%s%s%s",
            identicon.color, identicon.leftArm, identicon.body, identicon.rightArm, identicon.accessory );
}

const MPIdenticon mpw_identicon_encoded(
        const char *encoding) {

    MPIdenticon identicon = MPIdenticonUnset;
    if (!encoding || !strlen( encoding ))
        return identicon;

    char *string = calloc( strlen( encoding ), sizeof( *string ) ), *parser = string;
    const char *leftArm = NULL, *body = NULL, *rightArm = NULL, *accessory = NULL;
    unsigned int color;

    if (string && sscanf( encoding, "%u:%s", &color, string ) == 2) {
        if (*parser && color)
            for (int s = 0; s < sizeof( mpw_identicon_leftArms ) / sizeof( *mpw_identicon_leftArms ); ++s) {
                const char *limb = mpw_identicon_leftArms[s];
                if (strncmp( parser, limb, strlen( limb ) ) == 0) {
                    leftArm = limb;
                    parser += strlen( limb );
                    break;
                }
            }
        if (*parser && leftArm)
            for (int s = 0; s < sizeof( mpw_identicon_bodies ) / sizeof( *mpw_identicon_bodies ); ++s) {
                const char *limb = mpw_identicon_bodies[s];
                if (strncmp( parser, limb, strlen( limb ) ) == 0) {
                    body = limb;
                    parser += strlen( limb );
                    break;
                }
            }
        if (*parser && body)
            for (int s = 0; s < sizeof( mpw_identicon_rightArms ) / sizeof( *mpw_identicon_rightArms ); ++s) {
                const char *limb = mpw_identicon_rightArms[s];
                if (strncmp( parser, limb, strlen( limb ) ) == 0) {
                    rightArm = limb;
                    parser += strlen( limb );
                    break;
                }
            }
        if (*parser && rightArm)
            for (int s = 0; s < sizeof( mpw_identicon_accessories ) / sizeof( *mpw_identicon_accessories ); ++s) {
                const char *limb = mpw_identicon_accessories[s];
                if (strncmp( parser, limb, strlen( limb ) ) == 0) {
                    accessory = limb;
                    break;
                }
            }
        if (leftArm && body && rightArm && color >= MPIdenticonColorFirst && color <= MPIdenticonColorLast)
            identicon = (MPIdenticon){
                    .leftArm = leftArm,
                    .body = body,
                    .rightArm = rightArm,
                    .accessory = accessory,
                    .color = (MPIdenticonColor)color,
            };
    }

    mpw_free_string( &string );
    return identicon;
}
