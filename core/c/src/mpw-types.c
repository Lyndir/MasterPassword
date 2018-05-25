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

    // Lower-case typeName to standardize it.
    size_t stdTypeNameSize = strlen( typeName );
    char stdTypeName[stdTypeNameSize + 1];
    for (size_t c = 0; c < stdTypeNameSize; ++c)
        stdTypeName[c] = (char)tolower( typeName[c] );
    stdTypeName[stdTypeNameSize] = '\0';

    // Find what password type is represented by the type name.
    if (strncmp( mpw_nameForType( MPResultTypeTemplateMaximum ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeTemplateMaximum;
    if (strncmp( mpw_nameForType( MPResultTypeTemplateLong ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeTemplateLong;
    if (strncmp( mpw_nameForType( MPResultTypeTemplateMedium ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeTemplateMedium;
    if (strncmp( mpw_nameForType( MPResultTypeTemplateBasic ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeTemplateBasic;
    if (strncmp( mpw_nameForType( MPResultTypeTemplateShort ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeTemplateShort;
    if (strncmp( mpw_nameForType( MPResultTypeTemplatePIN ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeTemplatePIN;
    if (strncmp( mpw_nameForType( MPResultTypeTemplateName ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeTemplateName;
    if (strncmp( mpw_nameForType( MPResultTypeTemplatePhrase ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeTemplatePhrase;
    if (strncmp( mpw_nameForType( MPResultTypeStatefulPersonal ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeStatefulPersonal;
    if (strncmp( mpw_nameForType( MPResultTypeStatefulDevice ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeStatefulDevice;
    if (strncmp( mpw_nameForType( MPResultTypeDeriveKey ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPResultTypeDeriveKey;

    dbg( "Not a generated type name: %s", stdTypeName );
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
            return mpw_alloc_array( count, const char *,
                    "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" );
        case MPResultTypeTemplateLong:
            return mpw_alloc_array( count, const char *,
                    "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno",
                    "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno",
                    "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno",
                    "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno",
                    "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno",
                    "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno",
                    "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" );
        case MPResultTypeTemplateMedium:
            return mpw_alloc_array( count, const char *,
                    "CvcnoCvc", "CvcCvcno" );
        case MPResultTypeTemplateShort:
            return mpw_alloc_array( count, const char *,
                    "Cvcn" );
        case MPResultTypeTemplateBasic:
            return mpw_alloc_array( count, const char *,
                    "aaanaaan", "aannaaan", "aaannaaa" );
        case MPResultTypeTemplatePIN:
            return mpw_alloc_array( count, const char *,
                    "nnnn" );
        case MPResultTypeTemplateName:
            return mpw_alloc_array( count, const char *,
                    "cvccvcvcv" );
        case MPResultTypeTemplatePhrase:
            return mpw_alloc_array( count, const char *,
                    "cvcc cvc cvccvcv cvc", "cvc cvccvcvcv cvcv", "cv cvccv cvc cvcvccv" );
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

    // Lower-case and trim optionally leading "generated" string from typeName to standardize it.
    size_t stdPurposeNameSize = strlen( purposeName );
    char stdPurposeName[stdPurposeNameSize + 1];
    for (size_t c = 0; c < stdPurposeNameSize; ++c)
        stdPurposeName[c] = (char)tolower( purposeName[c] );
    stdPurposeName[stdPurposeNameSize] = '\0';

    if (strncmp( mpw_nameForPurpose( MPKeyPurposeAuthentication ), stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeAuthentication;
    if (strncmp( mpw_nameForPurpose( MPKeyPurposeIdentification ), stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeIdentification;
    if (strncmp( mpw_nameForPurpose( MPKeyPurposeRecovery ), stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeRecovery;

    dbg( "Not a purpose name: %s", stdPurposeName );
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
