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

const MPSiteType mpw_typeWithName(const char *typeName) {
    char lowerTypeName[strlen(typeName)];
    strcpy(lowerTypeName, typeName);
    for (char *tN = lowerTypeName; *tN; ++tN)
        *tN = (char)tolower(*tN);

    if (0 == strcmp(lowerTypeName, "x") || 0 == strcmp(lowerTypeName, "max") || 0 == strcmp(lowerTypeName, "maximum"))
        return MPSiteTypeGeneratedMaximum;
    if (0 == strcmp(lowerTypeName, "l") || 0 == strcmp(lowerTypeName, "long"))
        return MPSiteTypeGeneratedLong;
    if (0 == strcmp(lowerTypeName, "m") || 0 == strcmp(lowerTypeName, "med") || 0 == strcmp(lowerTypeName, "medium"))
        return MPSiteTypeGeneratedMedium;
    if (0 == strcmp(lowerTypeName, "b") || 0 == strcmp(lowerTypeName, "basic"))
        return MPSiteTypeGeneratedBasic;
    if (0 == strcmp(lowerTypeName, "s") || 0 == strcmp(lowerTypeName, "short"))
        return MPSiteTypeGeneratedShort;
    if (0 == strcmp(lowerTypeName, "i") || 0 == strcmp(lowerTypeName, "pin"))
        return MPSiteTypeGeneratedPIN;
    if (0 == strcmp(lowerTypeName, "n") || 0 == strcmp(lowerTypeName, "name"))
        return MPSiteTypeGeneratedName;
    if (0 == strcmp(lowerTypeName, "p") || 0 == strcmp(lowerTypeName, "phrase"))
        return MPSiteTypeGeneratedPhrase;

    fprintf(stderr, "Not a generated type name: %s", lowerTypeName);
    abort();
}

const char *mpw_templateForType(MPSiteType type, uint8_t seedByte) {
    if (!(type & MPSiteTypeClassGenerated)) {
        fprintf(stderr, "Not a generated type: %d", type);
        abort();
    }

    switch (type) {
        case MPSiteTypeGeneratedMaximum: {
            const char *templates[] = { "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" };
            return templates[seedByte % 2];
        }
        case MPSiteTypeGeneratedLong: {
            const char *templates[] = { "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno", "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno", "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno", "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno", "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno", "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno", "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" };
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
            fprintf(stderr, "Unknown generated type: %d", type);
            abort();
        }
    }
}

const MPSiteVariant mpw_variantWithName(const char *variantName) {
    char lowerVariantName[strlen(variantName)];
    strcpy(lowerVariantName, variantName);
    for (char *vN = lowerVariantName; *vN; ++vN)
        *vN = (char)tolower(*vN);

    if (0 == strcmp(lowerVariantName, "p") || 0 == strcmp(lowerVariantName, "password"))
        return MPSiteVariantPassword;
    if (0 == strcmp(lowerVariantName, "l") || 0 == strcmp(lowerVariantName, "login"))
        return MPSiteVariantLogin;
    if (0 == strcmp(lowerVariantName, "a") || 0 == strcmp(lowerVariantName, "answer"))
        return MPSiteVariantAnswer;

    fprintf(stderr, "Not a variant name: %s", lowerVariantName);
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
            fprintf(stderr, "Unknown variant: %d", variant);
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
            fprintf(stderr, "Unknown character class: %c", characterClass);
            abort();
         }
    }

    return classCharacters[seedByte % strlen(classCharacters)];
}
