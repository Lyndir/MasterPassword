//
//  mpw-types.c
//  MasterPassword
//
//  Created by Maarten Billemont on 2012-02-01.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#ifdef COLOR
#include <curses.h>
#include <term.h>
#endif

#include "mpw-types.h"
#include "mpw-util.h"

const MPSiteType mpw_typeWithName(const char *typeName) {

    size_t stdTypeNameSize = strlen( typeName );
    char stdTypeName[strlen( typeName )];
    if (stdTypeNameSize > strlen( "generated" ))
        strcpy( stdTypeName, typeName + strlen( "generated" ) );
    else
        strcpy( stdTypeName, typeName );
    for (char *tN = stdTypeName; *tN; ++tN)
        *tN = (char)tolower( *tN );

    if (0 == strcmp( stdTypeName, "x" ) || 0 == strcmp( stdTypeName, "max" ) || 0 == strcmp( stdTypeName, "maximum" ))
        return MPSiteTypeGeneratedMaximum;
    if (0 == strcmp( stdTypeName, "l" ) || 0 == strcmp( stdTypeName, "long" ))
        return MPSiteTypeGeneratedLong;
    if (0 == strcmp( stdTypeName, "m" ) || 0 == strcmp( stdTypeName, "med" ) || 0 == strcmp( stdTypeName, "medium" ))
        return MPSiteTypeGeneratedMedium;
    if (0 == strcmp( stdTypeName, "b" ) || 0 == strcmp( stdTypeName, "basic" ))
        return MPSiteTypeGeneratedBasic;
    if (0 == strcmp( stdTypeName, "s" ) || 0 == strcmp( stdTypeName, "short" ))
        return MPSiteTypeGeneratedShort;
    if (0 == strcmp( stdTypeName, "i" ) || 0 == strcmp( stdTypeName, "pin" ))
        return MPSiteTypeGeneratedPIN;
    if (0 == strcmp( stdTypeName, "n" ) || 0 == strcmp( stdTypeName, "name" ))
        return MPSiteTypeGeneratedName;
    if (0 == strcmp( stdTypeName, "p" ) || 0 == strcmp( stdTypeName, "phrase" ))
        return MPSiteTypeGeneratedPhrase;

    fprintf( stderr, "Not a generated type name: %s", stdTypeName );
    abort();
}

const char *mpw_templateForType(MPSiteType type, uint8_t seedByte) {

    if (!(type & MPSiteTypeClassGenerated)) {
        fprintf( stderr, "Not a generated type: %d", type );
        abort();
    }

    switch (type) {
        case MPSiteTypeGeneratedMaximum: {
            const char *templates[] = { "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" };
            return templates[seedByte % 2];
        }
        case MPSiteTypeGeneratedLong: {
            const char *templates[] = { "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno",
                                        "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno",
                                        "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno",
                                        "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno",
                                        "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno",
                                        "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno",
                                        "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" };
            return templates[seedByte % 21];
        }
        case MPSiteTypeGeneratedMedium: {
            const char *templates[] = { "CvcnoCvc", "CvcCvcno" };
            return templates[seedByte % 2];
        }
        case MPSiteTypeGeneratedBasic: {
            const char *templates[] = { "aaanaaan", "aannaaan", "aaannaaa" };
            return templates[seedByte % 3];
        }
        case MPSiteTypeGeneratedShort: {
            return "Cvcn";
        }
        case MPSiteTypeGeneratedPIN: {
            return "nnnn";
        }
        case MPSiteTypeGeneratedName: {
            return "cvccvcvcv";
        }
        case MPSiteTypeGeneratedPhrase: {
            const char *templates[] = { "cvcc cvc cvccvcv cvc", "cvc cvccvcvcv cvcv", "cv cvccv cvc cvcvccv" };
            return templates[seedByte % 3];
        }
        default: {
            fprintf( stderr, "Unknown generated type: %d", type );
            abort();
        }
    }
}

const MPSiteVariant mpw_variantWithName(const char *variantName) {

    char stdVariantName[strlen( variantName )];
    strcpy( stdVariantName, variantName );
    for (char *vN = stdVariantName; *vN; ++vN)
        *vN = (char)tolower( *vN );

    if (0 == strcmp( stdVariantName, "p" ) || 0 == strcmp( stdVariantName, "password" ))
        return MPSiteVariantPassword;
    if (0 == strcmp( stdVariantName, "l" ) || 0 == strcmp( stdVariantName, "login" ))
        return MPSiteVariantLogin;
    if (0 == strcmp( stdVariantName, "a" ) || 0 == strcmp( stdVariantName, "answer" ))
        return MPSiteVariantAnswer;

    fprintf( stderr, "Not a variant name: %s", stdVariantName );
    abort();
}

const char *mpw_scopeForVariant(MPSiteVariant variant) {

    switch (variant) {
        case MPSiteVariantPassword: {
            return "com.lyndir.masterpassword";
        }
        case MPSiteVariantLogin: {
            return "com.lyndir.masterpassword.login";
        }
        case MPSiteVariantAnswer: {
            return "com.lyndir.masterpassword.answer";
        }
        default: {
            fprintf( stderr, "Unknown variant: %d", variant );
            abort();
        }
    }
}

const char mpw_characterFromClass(char characterClass, uint8_t seedByte) {

    const char *classCharacters;
    switch (characterClass) {
        case 'V': {
            classCharacters = "AEIOU";
            break;
        }
        case 'C': {
            classCharacters = "BCDFGHJKLMNPQRSTVWXYZ";
            break;
        }
        case 'v': {
            classCharacters = "aeiou";
            break;
        }
        case 'c': {
            classCharacters = "bcdfghjklmnpqrstvwxyz";
            break;
        }
        case 'A': {
            classCharacters = "AEIOUBCDFGHJKLMNPQRSTVWXYZ";
            break;
        }
        case 'a': {
            classCharacters = "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz";
            break;
        }
        case 'n': {
            classCharacters = "0123456789";
            break;
        }
        case 'o': {
            classCharacters = "@&%?,=[]_:-+*$#!'^~;()/.";
            break;
        }
        case 'x': {
            classCharacters = "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz0123456789!@#$%^&*()";
            break;
        }
        case ' ': {
            classCharacters = " ";
            break;
        }
        default: {
            fprintf( stderr, "Unknown character class: %c", characterClass );
            abort();
        }
    }

    return classCharacters[seedByte % strlen( classCharacters )];
}
