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

#include <stdio.h>
#include <stdlib.h>

#define ftl(...) do { fprintf( stderr, __VA_ARGS__ ); exit(2); } while (0)

#include "mpw-algorithm.h"
#include "mpw-util.h"

#include "mpw-tests-util.h"

int main(int argc, char *const argv[]) {

    int failedTests = 0;

    xmlNodePtr tests = xmlDocGetRootElement( xmlParseFile( "mpw_tests.xml" ) );
    if (!tests) {
        ftl( "Couldn't find test case: mpw_tests.xml\n" );
        abort();
    }

    for (xmlNodePtr testCase = tests->children; testCase; testCase = testCase->next) {
        if (testCase->type != XML_ELEMENT_NODE || xmlStrcmp( testCase->name, BAD_CAST "case" ) != 0)
            continue;

        // Read in the test case.
        xmlChar *id = mpw_xmlTestCaseString( testCase, "id" );
        MPAlgorithmVersion algorithm = (MPAlgorithmVersion)mpw_xmlTestCaseInteger( testCase, "algorithm" );
        xmlChar *fullName = mpw_xmlTestCaseString( testCase, "fullName" );
        xmlChar *masterPassword = mpw_xmlTestCaseString( testCase, "masterPassword" );
        xmlChar *keyID = mpw_xmlTestCaseString( testCase, "keyID" );
        xmlChar *siteName = mpw_xmlTestCaseString( testCase, "siteName" );
        MPCounterValue siteCounter = (MPCounterValue)mpw_xmlTestCaseInteger( testCase, "siteCounter" );
        xmlChar *resultTypeString = mpw_xmlTestCaseString( testCase, "resultType" );
        xmlChar *keyPurposeString = mpw_xmlTestCaseString( testCase, "keyPurpose" );
        xmlChar *keyContext = mpw_xmlTestCaseString( testCase, "keyContext" );
        xmlChar *result = mpw_xmlTestCaseString( testCase, "result" );

        MPResultType resultType = mpw_typeWithName( (char *)resultTypeString );
        MPKeyPurpose keyPurpose = mpw_purposeWithName( (char *)keyPurposeString );

        // Run the test case.
        do {
            fprintf( stdout, "test case %s... ", id );
            if (!xmlStrlen( result )) {
                fprintf( stdout, "abstract.\n" );
                continue;
            }

            // 1. calculate the master key.
            MPMasterKey masterKey = mpw_masterKey(
                    (char *)fullName, (char *)masterPassword, algorithm );
            if (!masterKey) {
                ftl( "Couldn't derive master key.\n" );
                abort();
            }

            // Check the master key.
            MPKeyID testKeyID = mpw_id_buf( masterKey, MPMasterKeySize );
            if (xmlStrcmp( keyID, BAD_CAST testKeyID ) != 0) {
                ++failedTests;
                fprintf( stdout, "FAILED!  (keyID: got %s != expected %s)\n", testKeyID, keyID );
                continue;
            }

            // 2. calculate the site password.
            const char *testResult = mpw_siteResult(
                    masterKey, (char *)siteName, siteCounter, keyPurpose, (char *)keyContext, resultType, NULL, algorithm );
            mpw_free( &masterKey, MPMasterKeySize );
            if (!testResult) {
                ftl( "Couldn't derive site password.\n" );
                continue;
            }

            // Check the site result.
            if (xmlStrcmp( result, BAD_CAST testResult ) != 0) {
                ++failedTests;
                fprintf( stdout, "FAILED!  (result: got %s != expected %s)\n", testResult, result );
                mpw_free_string( &testResult );
                continue;
            }
            mpw_free_string( &testResult );

            fprintf( stdout, "pass.\n" );
        } while(false);

        // Free test case.
        xmlFree( id );
        xmlFree( fullName );
        xmlFree( masterPassword );
        xmlFree( keyID );
        xmlFree( siteName );
        xmlFree( resultTypeString );
        xmlFree( keyPurposeString );
        xmlFree( keyContext );
        xmlFree( result );
    }

    return failedTests;
}
