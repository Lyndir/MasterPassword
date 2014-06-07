//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include <alg/sha256.h>

#include "types.h"

const MPElementType TypeWithName(const char *typeName) {
    char lowerTypeName[strlen(typeName)];
    strcpy(lowerTypeName, typeName);
    for (char *tN = lowerTypeName; *tN; ++tN)
        *tN = tolower(*tN);

    if (0 == strcmp(lowerTypeName, "x") || 0 == strcmp(lowerTypeName, "max") || 0 == strcmp(lowerTypeName, "maximum"))
        return MPElementTypeGeneratedMaximum;
    if (0 == strcmp(lowerTypeName, "l") || 0 == strcmp(lowerTypeName, "long"))
        return MPElementTypeGeneratedLong;
    if (0 == strcmp(lowerTypeName, "m") || 0 == strcmp(lowerTypeName, "med") || 0 == strcmp(lowerTypeName, "medium"))
        return MPElementTypeGeneratedMedium;
    if (0 == strcmp(lowerTypeName, "b") || 0 == strcmp(lowerTypeName, "basic"))
        return MPElementTypeGeneratedBasic;
    if (0 == strcmp(lowerTypeName, "s") || 0 == strcmp(lowerTypeName, "short"))
        return MPElementTypeGeneratedShort;
    if (0 == strcmp(lowerTypeName, "p") || 0 == strcmp(lowerTypeName, "pin"))
        return MPElementTypeGeneratedPIN;

    fprintf(stderr, "Not a generated type name: %s", lowerTypeName);
    abort();
}

const char *CipherForType(MPElementType type, uint8_t seedByte) {
    if (!(type & MPElementTypeClassGenerated)) {
        fprintf(stderr, "Not a generated type: %d", type);
        abort();
    }

    switch (type) {
        case MPElementTypeGeneratedMaximum: {
            char *ciphers[] = { "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" };
            return ciphers[seedByte % 2];
        }
        case MPElementTypeGeneratedLong: {
            char *ciphers[] = { "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno", "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno", "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno", "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno", "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno", "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno", "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" };
            return ciphers[seedByte % 21];
        }
        case MPElementTypeGeneratedMedium: {
            char *ciphers[] = { "CvcnoCvc", "CvcCvcno" };
            return ciphers[seedByte % 2];
        }
        case MPElementTypeGeneratedBasic: {
            char *ciphers[] = { "aaanaaan", "aannaaan", "aaannaaa" };
            return ciphers[seedByte % 3];
        }
        case MPElementTypeGeneratedShort: {
            return "Cvcn";
        }
        case MPElementTypeGeneratedPIN: {
            return "nnnn";
        }
        default: {
            fprintf(stderr, "Unknown generated type: %d", type);
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

    char *id = calloc(65, sizeof(char));
    for (int kH = 0; kH < 32; kH++)
        sprintf(&(id[kH * 2]), "%02X", hash[kH]);

    return id;
}

const char *Hex(const void *buf, size_t length) {
    char *id = calloc(length*2+1, sizeof(char));
    for (int kH = 0; kH < length; kH++)
        sprintf(&(id[kH * 2]), "%02X", ((const uint8_t*)buf)[kH]);
    return id;
}
