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

#include <string.h>
#include <ctype.h>

#include "mpw-types.h"
#include "mpw-util.h"

const size_t MPMasterKeySize = 64;
const size_t MPSiteKeySize = 256 / 8; // Size of HMAC-SHA-256

const MPResultType mpw_typeWithName(const char *typeName) {

    // Find what password type is represented by the type letter.
    if (strlen( typeName ) == 1) {
        if ('x' == typeName[0])
            return MPResultTypeTemplateMaximum;
        if ('l' == typeName[0])
            return MPResultTypeTemplateLong;
        if ('m' == typeName[0])
            return MPResultTypeTemplateMedium;
        if ('b' == typeName[0])
            return MPResultTypeTemplateBasic;
        if ('s' == typeName[0])
            return MPResultTypeTemplateShort;
        if ('i' == typeName[0])
            return MPResultTypeTemplatePIN;
        if ('n' == typeName[0])
            return MPResultTypeTemplateName;
        if ('p' == typeName[0])
            return MPResultTypeTemplatePhrase;
        if ('P' == typeName[0])
            return MPResultTypeStatefulPersonal;
        if ('D' == typeName[0])
            return MPResultTypeStatefulDevice;
        if ('K' == typeName[0])
            return MPResultTypeDeriveKey;
    }

    // Find what password type is represented by the type name.
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeTemplateMaximum ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeTemplateMaximum;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeTemplateLong ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeTemplateLong;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeTemplateMedium ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeTemplateMedium;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeTemplateBasic ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeTemplateBasic;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeTemplateShort ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeTemplateShort;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeTemplatePIN ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeTemplatePIN;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeTemplateName ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeTemplateName;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeTemplatePhrase ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeTemplatePhrase;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeStatefulPersonal ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeStatefulPersonal;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeStatefulDevice ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeStatefulDevice;
    if (mpw_strncasecmp( mpw_nameForType( MPResultTypeDeriveKey ), typeName, strlen( typeName ) ) == 0)
        return MPResultTypeDeriveKey;

    dbg( "Not a generated type name: %s", typeName );
    return (MPResultType)ERR;
}

const char *mpw_nameForType(MPResultType resultType) {

    switch (resultType) {
        case MPResultTypeTemplateMaximum:
            return "maximum";
        case MPResultTypeTemplateLong:
            return "long";
        case MPResultTypeTemplateMedium:
            return "medium";
        case MPResultTypeTemplateBasic:
            return "basic";
        case MPResultTypeTemplateShort:
            return "short";
        case MPResultTypeTemplatePIN:
            return "pin";
        case MPResultTypeTemplateName:
            return "name";
        case MPResultTypeTemplatePhrase:
            return "phrase";
        case MPResultTypeStatefulPersonal:
            return "personal";
        case MPResultTypeStatefulDevice:
            return "device";
        case MPResultTypeDeriveKey:
            return "key";
        default: {
            dbg( "Unknown password type: %d", resultType );
            return NULL;
        }
    }
}

const char **mpw_templatesForType(MPResultType type, size_t *count) {

    if (!(type & MPResultTypeClassTemplate)) {
        dbg( "Not a generated type: %d", type );
        return NULL;
    }

    switch (type) {
        case MPResultTypeTemplateMaximum:
            return mpw_strings( count,
                    "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno", NULL );
        case MPResultTypeTemplateLong:
            return mpw_strings( count,
                    "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno",
                    "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno",
                    "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno",
                    "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno",
                    "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno",
                    "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno",
                    "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno", NULL );
        case MPResultTypeTemplateMedium:
            return mpw_strings( count,
                    "CvcnoCvc", "CvcCvcno", NULL );
        case MPResultTypeTemplateShort:
            return mpw_strings( count,
                    "Cvcn", NULL );
        case MPResultTypeTemplateBasic:
            return mpw_strings( count,
                    "aaanaaan", "aannaaan", "aaannaaa", NULL );
        case MPResultTypeTemplatePIN:
            return mpw_strings( count,
                    "nnnn", NULL );
        case MPResultTypeTemplateName:
            return mpw_strings( count,
                    "cvccvcvcv", NULL );
        case MPResultTypeTemplatePhrase:
            return mpw_strings( count,
                    "cvcc cvc cvccvcv cvc", "cvc cvccvcvcv cvcv", "cv cvccv cvc cvcvccv", NULL );
        default: {
            dbg( "Unknown generated type: %d", type );
            return NULL;
        }
    }
}

const char *mpw_templateForType(MPResultType type, uint8_t templateIndex) {

    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    char const *template = templates && count? templates[templateIndex % count]: NULL;
    free( templates );

    return template;
}

const MPKeyPurpose mpw_purposeWithName(const char *purposeName) {

    if (mpw_strncasecmp( mpw_nameForPurpose( MPKeyPurposeAuthentication ), purposeName, strlen( purposeName ) ) == 0)
        return MPKeyPurposeAuthentication;
    if (mpw_strncasecmp( mpw_nameForPurpose( MPKeyPurposeIdentification ), purposeName, strlen( purposeName ) ) == 0)
        return MPKeyPurposeIdentification;
    if (mpw_strncasecmp( mpw_nameForPurpose( MPKeyPurposeRecovery ), purposeName, strlen( purposeName ) ) == 0)
        return MPKeyPurposeRecovery;

    dbg( "Not a purpose name: %s", purposeName );
    return (MPKeyPurpose)ERR;
}

const char *mpw_nameForPurpose(MPKeyPurpose purpose) {

    switch (purpose) {
        case MPKeyPurposeAuthentication:
            return "authentication";
        case MPKeyPurposeIdentification:
            return "identification";
        case MPKeyPurposeRecovery:
            return "recovery";
        default: {
            dbg( "Unknown purpose: %d", purpose );
            return NULL;
        }
    }
}

const char *mpw_scopeForPurpose(MPKeyPurpose purpose) {

    switch (purpose) {
        case MPKeyPurposeAuthentication:
            return "com.lyndir.masterpassword";
        case MPKeyPurposeIdentification:
            return "com.lyndir.masterpassword.login";
        case MPKeyPurposeRecovery:
            return "com.lyndir.masterpassword.answer";
        default: {
            dbg( "Unknown purpose: %d", purpose );
            return NULL;
        }
    }
}

const char *mpw_charactersInClass(char characterClass) {

    switch (characterClass) {
        case 'V':
            return "AEIOU";
        case 'C':
            return "BCDFGHJKLMNPQRSTVWXYZ";
        case 'v':
            return "aeiou";
        case 'c':
            return "bcdfghjklmnpqrstvwxyz";
        case 'A':
            return "AEIOUBCDFGHJKLMNPQRSTVWXYZ";
        case 'a':
            return "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz";
        case 'n':
            return "0123456789";
        case 'o':
            return "@&%?,=[]_:-+*$#!'^~;()/.";
        case 'x':
            return "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz0123456789!@#$%^&*()";
        case ' ':
            return " ";
        default: {
            dbg( "Unknown character class: %c", characterClass );
            return NULL;
        }
    }
}

const char mpw_characterFromClass(char characterClass, uint8_t seedByte) {

    const char *classCharacters = mpw_charactersInClass( characterClass );
    if (!classCharacters)
        return '\0';

    return classCharacters[seedByte % strlen( classCharacters )];
}
