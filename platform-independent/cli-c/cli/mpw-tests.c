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
        uint32_t siteCounter = mpw_xmlTestCaseInteger( testCase, "siteCounter" );
        xmlChar *passwordTypeString = mpw_xmlTestCaseString( testCase, "passwordType" );
        xmlChar *keyPurposeString = mpw_xmlTestCaseString( testCase, "keyPurpose" );
        xmlChar *keyContext = mpw_xmlTestCaseString( testCase, "keyContext" );
        xmlChar *result = mpw_xmlTestCaseString( testCase, "result" );

        MPPasswordType siteType = mpw_typeWithName( (char *)passwordTypeString );
        MPKeyPurpose siteVariant = mpw_purposeWithName( (char *)keyPurposeString );

        // Run the test case.
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
            continue;
        }

        // 2. calculate the site password.
        MPSiteKey siteKey = mpw_siteKey(
                masterKey, (char *)siteName, siteCounter, siteVariant, (char *)keyContext, algorithm );
        const char *sitePassword = mpw_sitePassword(
                siteKey, siteType, algorithm );
        mpw_free( masterKey, MPMasterKeySize );
        mpw_free( siteKey, MPSiteKeySize );
        if (!sitePassword) {
            ftl( "Couldn't derive site password.\n" );
            continue;
        }

        // Check the result.
        if (xmlStrcmp( result, BAD_CAST sitePassword ) == 0)
            fprintf( stdout, "pass.\n" );

        else {
            ++failedTests;
            fprintf( stdout, "FAILED!  (got %s != expected %s)\n", sitePassword, result );
        }

        // Free test case.
        mpw_free_string( sitePassword );
        xmlFree( id );
        xmlFree( fullName );
        xmlFree( masterPassword );
        xmlFree( keyID );
        xmlFree( siteName );
        xmlFree( passwordTypeString );
        xmlFree( keyPurposeString );
        xmlFree( keyContext );
        xmlFree( result );
    }

    return failedTests;
}
