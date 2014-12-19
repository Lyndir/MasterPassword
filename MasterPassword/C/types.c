//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <unistd.h>

#include <scrypt/sha256.h>

#ifdef COLOR
#include <curses.h>
#include <term.h>
#endif

#include "types.h"

const MPSiteType TypeWithName(const char *typeName) {
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

const char *TemplateForType(MPSiteType type, uint8_t seedByte) {
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

const MPSiteVariant VariantWithName(const char *variantName) {
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

const char *ScopeForVariant(MPSiteVariant variant) {
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

const char CharacterFromClass(char characterClass, uint8_t seedByte) {
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

const char *IDForBuf(const void *buf, size_t length) {
    uint8_t hash[32];
    SHA256_Buf(buf, length, hash);

    char *id = (char *)calloc(65, sizeof(char));
    for (int kH = 0; kH < 32; kH++)
        sprintf(&(id[kH * 2]), "%02X", hash[kH]);

    return id;
}

const char *Hex(const void *buf, size_t length) {
    char *id = (char *)calloc(length*2+1, sizeof(char));
    for (int kH = 0; kH < length; kH++)
        sprintf(&(id[kH * 2]), "%02X", ((const uint8_t*)buf)[kH]);

    return id;
}

#ifdef COLOR
int putvari;
char *putvarc = NULL;
bool istermsetup = false;
static void initputvar() {
    if (putvarc)
        free(putvarc);
    putvarc=(char *)calloc(256, sizeof(char));
    putvari=0;

    if (!istermsetup)
        istermsetup = (OK == setupterm(NULL, STDERR_FILENO, NULL));
}
static int putvar(int c) {
    putvarc[putvari++]=c;
    return 0;
}
#endif

const char *Identicon(const char *fullName, const char *masterPassword) {
    const char *leftArm[]   = { "╔", "╚", "╰", "═" };
    const char *rightArm[]  = { "╗", "╝", "╯", "═" };
    const char *body[]      = { "█", "░", "▒", "▓", "☺", "☻" };
    const char *accessory[] = { "◈", "◎", "◐", "◑", "◒", "◓", "☀", "☁", "☂", "☃", "☄", "★", "☆", "☎", "☏", "⎈", "⌂", "☘", "☢", "☣", "☕", "⌚", "⌛", "⏰", "⚡", "⛄", "⛅", "☔", "♔", "♕", "♖", "♗", "♘", "♙", "♚", "♛", "♜", "♝", "♞", "♟", "♨", "♩", "♪", "♫", "⚐", "⚑", "⚔", "⚖", "⚙", "⚠", "⌘", "⏎", "✄", "✆", "✈", "✉", "✌" };

    uint8_t identiconSeed[32];
    HMAC_SHA256_Buf(masterPassword, strlen(masterPassword), fullName, strlen(fullName), identiconSeed);

    char *colorString, *resetString;
#ifdef COLOR
    if (isatty( STDERR_FILENO )) {
        uint8_t colorIdentifier = (uint8_t)(identiconSeed[4] % 7 + 1);
        initputvar();
        tputs(tparm(tgetstr("AF", NULL), colorIdentifier), 1, putvar);
        colorString = calloc(strlen(putvarc) + 1, sizeof(char));
        strcpy(colorString, putvarc);
        tputs(tgetstr("me", NULL), 1, putvar);
        resetString = calloc(strlen(putvarc) + 1, sizeof(char));
        strcpy(resetString, putvarc);
    } else
#endif
    {
        colorString = calloc(1, sizeof(char));
        resetString = calloc(1, sizeof(char));
    }

    char *identicon = (char *)calloc(256, sizeof(char));
    snprintf(identicon, 256, "%s%s%s%s%s%s",
             colorString,
             leftArm[identiconSeed[0] % (sizeof(leftArm) / sizeof(leftArm[0]))],
             body[identiconSeed[1] % (sizeof(body) / sizeof(body[0]))],
             rightArm[identiconSeed[2] % (sizeof(rightArm) / sizeof(rightArm[0]))],
             accessory[identiconSeed[3] % (sizeof(accessory) / sizeof(accessory[0]))],
             resetString);

    free(colorString);
    free(resetString);
    return identicon;
}
