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

package com.lyndir.masterpassword;

import static org.testng.Assert.*;

import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.NNFunctionNN;
import javax.annotation.Nonnull;
import org.jetbrains.annotations.NonNls;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;


public class MasterKeyTest {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MasterKeyTest.class );

    @NonNls
    private MPTestSuite testSuite;

    @BeforeMethod
    public void setUp()
            throws Exception {

        testSuite = new MPTestSuite();
    }

    @Test
    public void testEncode()
            throws Exception {

        testSuite.forEach( "testEncode", new NNFunctionNN<MPTests.Case, Boolean>() {
            @Nonnull
            @Override
            public Boolean apply(@Nonnull final MPTests.Case testCase) {
                MasterKey masterKey = MasterKey.create( testCase.getAlgorithm(), testCase.getFullName(), testCase.getMasterPassword() );

                assertEquals(
                        masterKey.siteResult( testCase.getSiteName(), testCase.getSiteCounter(), testCase.getKeyPurpose(),
                                              testCase.getKeyContext(), testCase.getResultType(),
                                              null ),
                        testCase.getResult(), "[testEncode] Failed test case: " + testCase );

                return true;
            }
        } );
    }

    @Test
    public void testGetUserName()
            throws Exception {

        MPTests.Case defaultCase = testSuite.getTests().getDefaultCase();

        assertEquals( MasterKey.create( defaultCase.getFullName(), defaultCase.getMasterPassword() ).getFullName(),
                      defaultCase.getFullName(), "[testGetUserName] Failed test case: " + defaultCase );
    }

    @Test
    public void testGetKeyID()
            throws Exception {

        testSuite.forEach( "testGetKeyID", new NNFunctionNN<MPTests.Case, Boolean>() {
            @Nonnull
            @Override
            public Boolean apply(@Nonnull final MPTests.Case testCase) {
                MasterKey masterKey = MasterKey.create( testCase.getFullName(), testCase.getMasterPassword() );

                assertEquals( CodeUtils.encodeHex( masterKey.getKeyID() ),
                              testCase.getKeyID(), "[testGetKeyID] Failed test case: " + testCase );

                return true;
            }
        } );
    }

    @Test
    public void testInvalidate()
            throws Exception {

        try {
            MPTests.Case defaultCase = testSuite.getTests().getDefaultCase();

            MasterKey masterKey = MasterKey.create( defaultCase.getFullName(), defaultCase.getMasterPassword() );
            masterKey.invalidate();
            masterKey.siteResult( defaultCase.getSiteName(), defaultCase.getSiteCounter(), defaultCase.getKeyPurpose(),
                                  defaultCase.getKeyContext(), defaultCase.getResultType(),
                                  null );

            fail( "[testInvalidate] Master key should have been invalidated, but was still usable." );
        }
        catch (final IllegalStateException ignored) {
        }
    }
}
