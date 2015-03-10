package com.lyndir.masterpassword;

import static org.testng.Assert.*;

import com.google.common.io.Resources;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.StringUtils;
import java.net.URL;
import javax.xml.bind.JAXBContext;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;


public class MasterKeyTest {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MasterKeyTest.class );

    private MPWTests      tests;
    private MPWTests.Case defaultCase;

    @BeforeMethod
    public void setUp()
            throws Exception {

        URL testCasesResource = Resources.getResource( "mpw_tests.xml" );
        tests = (MPWTests) JAXBContext.newInstance( MPWTests.class ).createUnmarshaller().unmarshal( testCasesResource );
        for (MPWTests.Case testCase : tests.getCases())
            testCase.initializeParentHierarchy( tests );
        defaultCase = tests.getCase( MPWTests.ID_DEFAULT );
    }

    @Test
    public void testEncode()
            throws Exception {

        for (MPWTests.Case testCase : tests.getCases()) {
            if (testCase.getResult().isEmpty())
                continue;

            logger.inf( "Running test case: %s [testEncode]", testCase.getIdentifier() );
            MasterKey masterKey = MasterKey.create( testCase.getAlgorithm(), testCase.getFullName(), testCase.getMasterPassword() );
            assertEquals(
                    masterKey.encode( testCase.getSiteName(), testCase.getSiteType(), testCase.getSiteCounter(), testCase.getSiteVariant(),
                                      testCase.getSiteContext() ), testCase.getResult(), "Failed test case: " + testCase );
            logger.inf( "passed!" );
        }
    }

    @Test
    public void testGetUserName()
            throws Exception {

        assertEquals( MasterKey.create( defaultCase.getFullName(), defaultCase.getMasterPassword() ).getFullName(),
                      defaultCase.getFullName() );
    }

    @Test
    public void testGetKeyID()
            throws Exception {

        for (MPWTests.Case testCase : tests.getCases()) {
            if (testCase.getResult().isEmpty())
                continue;

            logger.inf( "Running test case: %s [testGetKeyID]", testCase.getIdentifier() );
            MasterKey masterKey = MasterKey.create( testCase.getFullName(), testCase.getMasterPassword() );
            assertEquals( CodeUtils.encodeHex( masterKey.getKeyID() ), testCase.getKeyID(), "Failed test case: " + testCase );
            logger.inf( "passed!" );
        }
    }

    @Test
    public void testInvalidate()
            throws Exception {

        try {
            MasterKey masterKey = MasterKey.create( defaultCase.getFullName(), defaultCase.getMasterPassword() );
            masterKey.invalidate();
            masterKey.encode( defaultCase.getSiteName(), defaultCase.getSiteType(), defaultCase.getSiteCounter(),
                              defaultCase.getSiteVariant(), defaultCase.getSiteContext() );
            assertTrue( false, "Master key should have been invalidated, but was still usable." );
        }
        catch (IllegalStateException ignored) {
        }
    }
}
