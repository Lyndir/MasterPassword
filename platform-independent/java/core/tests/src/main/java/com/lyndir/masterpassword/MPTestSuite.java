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

import com.google.common.base.Preconditions;
import com.google.common.collect.Lists;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.ConversionUtils;
import java.io.IOException;
import java.net.URL;
import java.util.*;
import java.util.concurrent.Callable;
import javax.xml.parsers.*;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.ext.DefaultHandler2;


/**
 * @author lhunath, 2015-12-22
 */
@SuppressWarnings({ "HardCodedStringLiteral", "ProhibitedExceptionDeclared" })
public class MPTestSuite implements Callable<Boolean> {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger                = Logger.get( MPTestSuite.class );
    private static final String DEFAULT_RESOURCE_NAME = "mpw_tests.xml";

    private final MPTests  tests;
    private       Listener listener;

    public MPTestSuite()
            throws UnavailableException {
        this( DEFAULT_RESOURCE_NAME );
    }

    public MPTestSuite(final String resourceName)
            throws UnavailableException {
        try {
            tests = new MPTests();
            tests.cases = Lists.newLinkedList();
            SAXParser        parser    = SAXParserFactory.newInstance().newSAXParser();
            Enumeration<URL> resources = Thread.currentThread().getContextClassLoader().getResources( "." );
            parser.parse( Thread.currentThread().getContextClassLoader().getResourceAsStream( resourceName ), new DefaultHandler2() {
                private final Deque<String> currentTags = Lists.newLinkedList();
                private final Deque<StringBuilder> currentTexts = Lists.newLinkedList();
                private MPTests.Case currentCase;

                @Override
                public void startElement(final String uri, final String localName, final String qName, final Attributes attributes)
                        throws SAXException {
                    super.startElement( uri, localName, qName, attributes );
                    currentTags.push( qName );
                    currentTexts.push( new StringBuilder() );

                    if ("case".equals( qName )) {
                        currentCase = new MPTests.Case();
                        currentCase.identifier = attributes.getValue( "id" );
                        currentCase.parent = attributes.getValue( "parent" );
                    }
                }

                @Override
                public void endElement(final String uri, final String localName, final String qName)
                        throws SAXException {
                    super.endElement( uri, localName, qName );
                    Preconditions.checkState( qName.equals( currentTags.pop() ) );
                    String text = Preconditions.checkNotNull( currentTexts.pop() ).toString();

                    if ("case".equals( qName ))
                        tests.cases.add( currentCase );
                    if ("algorithm".equals( qName ))
                        currentCase.algorithm = ConversionUtils.toInteger( text ).orElse( null );
                    if ("fullName".equals( qName ))
                        currentCase.fullName = text;
                    if ("masterPassword".equals( qName ))
                        currentCase.masterPassword = text;
                    if ("keyID".equals( qName ))
                        currentCase.keyID = text;
                    if ("siteName".equals( qName ))
                        currentCase.siteName = text;
                    if ("siteCounter".equals( qName ))
                        currentCase.siteCounter = text.isEmpty()? null: UnsignedInteger.valueOf( text );
                    if ("resultType".equals( qName ))
                        currentCase.resultType = text;
                    if ("keyPurpose".equals( qName ))
                        currentCase.keyPurpose = text;
                    if ("keyContext".equals( qName ))
                        currentCase.keyContext = text;
                    if ("result".equals( qName ))
                        currentCase.result = text;
                }

                @Override
                public void characters(final char[] ch, final int start, final int length)
                        throws SAXException {
                    super.characters( ch, start, length );

                    Preconditions.checkNotNull( currentTexts.peek() ).append( ch, start, length );
                }
            } );
        }
        catch (final IllegalArgumentException | ParserConfigurationException | SAXException | IOException e) {
            throw new UnavailableException( e );
        }

        for (final MPTests.Case testCase : tests.getCases())
            testCase.initializeParentHierarchy( tests );
    }

    public void setListener(final Listener listener) {
        this.listener = listener;
    }

    public MPTests getTests() {
        return tests;
    }

    public boolean forEach(final String testName, final TestCase testFunction)
            throws Exception {
        List<MPTests.Case> cases = tests.getCases();
        for (int c = 0; c < cases.size(); c++) {
            MPTests.Case testCase = cases.get( c );
            if (testCase.getResult().isEmpty())
                continue;

            progress( Logger.Target.INFO, c, cases.size(), //
                      "[%s] on %s...", testName, testCase.getIdentifier() );

            if (!testFunction.run( testCase )) {
                progress( Logger.Target.ERROR, cases.size(), cases.size(), //
                          "[%s] on %s: FAILED!", testName, testCase.getIdentifier() );

                return false;
            }

            progress( Logger.Target.INFO, c + 1, cases.size(), //
                      "[%s] on %s: passed!", testName, testCase.getIdentifier() );
        }

        return true;
    }

    private void progress(final Logger.Target target, final int current, final int max, final String format, final Object... args) {
        logger.log( target, format, args );

        if (listener != null)
            listener.progress( current, max, format, args );
    }

    @Override
    public Boolean call()
            throws Exception {
        return forEach( "mpw", testCase -> {
            MPMasterKey masterKey = new MPMasterKey( testCase.getFullName(), testCase.getMasterPassword().toCharArray() );
            String sitePassword = masterKey.siteResult( testCase.getSiteName(), testCase.getAlgorithm(), testCase.getSiteCounter(),
                                                        testCase.getKeyPurpose(), testCase.getKeyContext(),
                                                        testCase.getResultType(), null );

            return testCase.getResult().equals( sitePassword );
        } );
    }

    public static class UnavailableException extends Exception {

        private static final long serialVersionUID = 1L;

        public UnavailableException(final Throwable cause) {
            super( cause );
        }
    }


    @FunctionalInterface
    public interface Listener {

        void progress(int current, int max, String messageFormat, Object... args);
    }


    @FunctionalInterface
    public interface TestCase {

        boolean run(MPTests.Case testCase)
                throws Exception;
    }
}
