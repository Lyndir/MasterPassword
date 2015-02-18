#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>

#define ftl(...) do { fprintf( stderr, __VA_ARGS__ ); exit(2); } while (0)

#include "mpw-algorithm.h"
#include "mpw-util.h"

#include "mpw-tests-util.h"

int main(int argc, char *const argv[]) {

    int failedTests = 0;

    xmlNodePtr tests = xmlDocGetRootElement( xmlParseFile( "mpw_tests.xml" ) );
    for (xmlNodePtr testCase = tests->children; testCase; testCase = testCase->next) {
        if (testCase->type != XML_ELEMENT_NODE || xmlStrcmp( testCase->name, BAD_CAST "case" ) != 0)
            continue;

        // Read in the test case.
        xmlChar *id = mpw_xmlTestCaseString( testCase, "id" );
        uint32_t algorithm = mpw_xmlTestCaseInteger( testCase, "algorithm" );
        xmlChar *fullName = mpw_xmlTestCaseString( testCase, "fullName" );
        xmlChar *masterPassword = mpw_xmlTestCaseString( testCase, "masterPassword" );
        xmlChar *keyID = mpw_xmlTestCaseString( testCase, "keyID" );
        xmlChar *siteName = mpw_xmlTestCaseString( testCase, "siteName" );
        uint32_t siteCounter = mpw_xmlTestCaseInteger( testCase, "siteCounter" );
        xmlChar *siteTypeString = mpw_xmlTestCaseString( testCase, "siteType" );
        xmlChar *siteVariantString = mpw_xmlTestCaseString( testCase, "siteVariant" );
        xmlChar *siteContext = mpw_xmlTestCaseString( testCase, "siteContext" );
        xmlChar *result = mpw_xmlTestCaseString( testCase, "result" );

        MPSiteType siteType = mpw_typeWithName( (char *)siteTypeString );
        MPSiteVariant siteVariant = mpw_variantWithName( (char *)siteVariantString );

        // Run the test case.
        fprintf( stdout, "test case %s... ", id );
        if (!xmlStrlen( result )) {
            fprintf( stdout, "abstract.\n" );
            continue;
        }

        // 1. calculate the master key.
        const uint8_t *masterKey = mpw_masterKeyForUser(
                (char *)fullName, (char *)masterPassword, algorithm );
        if (!masterKey)
            ftl( "Couldn't derive master key." );

        // 2. calculate the site password.
        const char *sitePassword = mpw_passwordForSite(
                masterKey, (char *)siteName, siteType, siteCounter, siteVariant, (char *)siteContext, algorithm );
        mpw_free( masterKey, MP_dkLen );
        if (!sitePassword)
            ftl( "Couldn't derive site password." );

        // Check the result.
        if (xmlStrcmp( result, BAD_CAST sitePassword ) == 0)
            fprintf( stdout, "pass.\n" );

        else {
            ++failedTests;
            fprintf( stdout, "FAILED!  (got %s != expected %s)\n", sitePassword, result );
        }

        // Free test case.
        mpw_freeString( sitePassword );
        xmlFree( id );
        xmlFree( fullName );
        xmlFree( masterPassword );
        xmlFree( keyID );
        xmlFree( siteName );
        xmlFree( siteTypeString );
        xmlFree( siteVariantString );
        xmlFree( siteContext );
        xmlFree( result );
    }

    return failedTests;
}
