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

//
//  mpw-tests-util.c
//  MasterPassword
//
//  Created by Maarten Billemont on 2014-12-21.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mpw-util.h"

#include "mpw-tests-util.h"

static xmlChar const *mpw_xmlPath(xmlNodePtr context) {

    if (context->parent) {
        char *string = calloc( 256, 1 );
        snprintf( string, 256, "%s/%s", mpw_xmlPath( context->parent ), context->name );
        return BAD_CAST string;
    }

    return context->name? context->name: (xmlChar const *)"";
}

xmlNodePtr mpw_xmlTestCaseNode(xmlNodePtr testCaseNode, const char *nodeName) {

    // Try to find an attribute node.
    for (xmlAttrPtr child = testCaseNode->properties; child; child = child->next)
        if (xmlStrcmp( child->name, BAD_CAST nodeName ) == 0)
            return (xmlNodePtr)child;

    // Try to find an element node.
    for (xmlNodePtr child = testCaseNode->children; child; child = child->next)
        if (xmlStrcmp( child->name, BAD_CAST nodeName ) == 0)
            return child;

    // Missing content, try to find parent case.
    if (strcmp( nodeName, "parent" ) == 0)
        // Was just searching for testCaseNode's parent, none found.
        return NULL;
    xmlChar *parentId = mpw_xmlTestCaseString( testCaseNode, "parent" );
    if (!parentId)
        // testCaseNode has no parent, give up.
        return NULL;

    for (xmlNodePtr otherTestCaseNode = testCaseNode->parent->children; otherTestCaseNode; otherTestCaseNode = otherTestCaseNode->next) {
        xmlChar *id = mpw_xmlTestCaseString( otherTestCaseNode, "id" );
        int foundParent = id && xmlStrcmp( id, parentId ) == 0;
        xmlFree( id );

        if (foundParent) {
            xmlFree( parentId );
            return mpw_xmlTestCaseNode( otherTestCaseNode, nodeName );
        }
    }

    err( "Missing parent: %s, for case: %s", parentId, mpw_xmlTestCaseString( testCaseNode, "id" ) );
    return NULL;
}

xmlChar *mpw_xmlTestCaseString(xmlNodePtr context, const char *nodeName) {

    xmlNodePtr child = mpw_xmlTestCaseNode( context, nodeName );
    return child? xmlNodeGetContent( child ): NULL;
}

uint32_t mpw_xmlTestCaseInteger(xmlNodePtr context, const char *nodeName) {

    xmlChar *string = mpw_xmlTestCaseString( context, nodeName );
    uint32_t integer = string? (uint32_t)atol( (char *)string ): 0;
    xmlFree( string );

    return integer;
}
