//
//  mpw-tests-util.h
//  MasterPassword
//
//  Created by Maarten Billemont on 2014-12-21.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#include <libxml/parser.h>

xmlNodePtr mpw_xmlTestCaseNode(
        xmlNodePtr testCaseNode, const char *nodeName);
xmlChar *mpw_xmlTestCaseString(
        xmlNodePtr context, const char *nodeName);
uint32_t mpw_xmlTestCaseInteger(
        xmlNodePtr context, const char *nodeName);
