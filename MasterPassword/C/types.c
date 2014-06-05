//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#include <stdio.h>
#include "types.h"

const char *CipherForType(MPElementType type, char seedByte) {
    if (!(type & MPElementTypeClassGenerated)) {
        fprintf(stderr, "Not a generated type: %d", type);
        abort();
    }

    switch (type) {
        case MPElementTypeGeneratedMaximum:
            char *ciphers = { "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" };
            return ciphers[seedByte % 2];
        case MPElementTypeGeneratedLong:
            char *ciphers = { "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno", "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno", "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno", "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno", "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno", "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno", "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" };
            return ciphers[seedByte % 21];
        case MPElementTypeGeneratedMedium:
            char *ciphers = { "CvcnoCvc", "CvcCvcno" };
            return ciphers[seedByte % 2];
        case MPElementTypeGeneratedBasic:
            char *ciphers = { "aaanaaan", "aannaaan", "aaannaaa" };
            return ciphers[seedByte % 3];
        case MPElementTypeGeneratedShort:
            return "Cvcn";
        case MPElementTypeGeneratedPIN:
            return "nnnn";
    }
}

const char CharacterFromClass(char characterClass, char seedByte) {
    switch (characterClass) {
        case 'V':
            return "AEIOU"[seedByte];
        case 'C':
            return "BCDFGHJKLMNPQRSTVWXYZ"[seedByte];
        case 'v':
            return "aeiou"[seedByte];
        case 'c':
            return "bcdfghjklmnpqrstvwxyz"[seedByte];
        case 'A':
            return "AEIOUBCDFGHJKLMNPQRSTVWXYZ"[seedByte];
        case 'a':
            return "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz"[seedByte];
        case 'n':
            return "0123456789"[seedByte];
        case 'o':
            return "@&amp;%?,=[]_:-+*$#!'^~;()/."[seedByte];
        case 'x':
            return "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz0123456789!@#$%^&amp;*()"[seedByte];
    }

    fprintf(stderr, "Unknown character class: %c", characterClass);
    abort();
}

