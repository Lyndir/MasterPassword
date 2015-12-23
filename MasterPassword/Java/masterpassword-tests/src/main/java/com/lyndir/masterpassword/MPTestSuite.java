package com.lyndir.masterpassword;

import com.google.common.io.Resources;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.NNFunctionNN;
import java.net.URL;
import javax.annotation.Nonnull;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;


/**
 * @author lhunath, 2015-12-22
 */
public class MPTestSuite {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger                = Logger.get( MPTestSuite.class );
    private static final String DEFAULT_RESOURCE_NAME = "mpw_tests.xml";

    private MPTests tests;

    public MPTestSuite()
            throws UnavailableException {
        this( DEFAULT_RESOURCE_NAME );
    }

    public MPTestSuite(String resourceName)
            throws UnavailableException {
        try {
            URL testCasesResource = Resources.getResource( resourceName );
            tests = (MPTests) JAXBContext.newInstance( MPTests.class ).createUnmarshaller().unmarshal( testCasesResource );

            for (MPTests.Case testCase : tests.getCases())
                testCase.initializeParentHierarchy( tests );
        }
        catch (IllegalArgumentException | JAXBException e) {
            throw new UnavailableException( e );
        }
    }

    public MPTests getTests() {
        return tests;
    }

    public boolean forEach(String testName, NNFunctionNN<MPTests.Case, Boolean> testFunction) {
        for (MPTests.Case testCase : tests.getCases()) {
            if (testCase.getResult().isEmpty())
                continue;

            logger.inf( "[%s] on %s...", testName, testCase.getIdentifier() );
            if (!testFunction.apply( testCase )) {
                logger.err( "[%s] on %s: FAILED!", testName, testCase.getIdentifier() );
                return false;
            }
            logger.inf( "[%s] on %s: passed!", testName, testCase.getIdentifier() );
        }

        return true;
    }

    public boolean run() {
        return forEach( "mpw", new NNFunctionNN<MPTests.Case, Boolean>() {
            @Nonnull
            @Override
            public Boolean apply(@Nonnull final MPTests.Case testCase) {
                MasterKey masterKey = MasterKey.create( testCase.getAlgorithm(), testCase.getFullName(), testCase.getMasterPassword() );
                String sitePassword = masterKey.encode( testCase.getSiteName(), testCase.getSiteType(), testCase.getSiteCounter(),
                                                        testCase.getSiteVariant(), testCase.getSiteContext() );

                return testCase.getResult().equals( sitePassword );
            }
        } );
    }

    public static class UnavailableException extends Exception {

        public UnavailableException(final Throwable cause) {
            super( cause );
        }
    }
}
