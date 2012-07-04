/*
 *   Copyright 2008, Maarten Billemont
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */
package com.lyndir.lhunath.masterpassword;

import com.google.common.io.LineReader;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.ConversionUtils;
import java.io.*;
import java.util.Arrays;


/**
 * <p> <i>Jun 10, 2008</i> </p>
 *
 * @author mbillemo
 */
public class CLI {

    static final Logger logger = Logger.get( CLI.class );

    public static void main(final String[] args)
            throws IOException {

        InputStream in = System.in;

        /* Arguments. */
        String userName = null, siteName = null;
        int counter = 1;
        MPElementType type = MPElementType.GeneratedLong;
        boolean typeArg = false, counterArg = false, userNameArg = false;
        for (final String arg : Arrays.asList( args ))
            if ("-t".equals( arg ) || "--type".equals( arg ))
                typeArg = true;
            else if (typeArg) {
                if ("list".equalsIgnoreCase( arg )) {
                    System.out.format( "%30s | %s\n", "type", "description" );
                    for (final MPElementType aType : MPElementType.values())
                        System.out.format( "%30s | %s\n", aType.getName(), aType.getDescription() );
                    System.exit( 0 );
                }

                type = MPElementType.forName( arg );
                typeArg = false;
            } else if ("-c".equals( arg ) || "--counter".equals( arg ))
                counterArg = true;
            else if (counterArg) {
                counter = ConversionUtils.toIntegerNN( arg );
                counterArg = false;
            } else if ("-u".equals( arg ) || "--username".equals( arg ))
                userNameArg = true;
            else if (userNameArg) {
                userName = arg;
                userNameArg = false;
            } else if ("-h".equals( arg ) || "--help".equals( arg )) {
                System.out.println();
                System.out.println( "\tMaster Password CLI" );
                System.out.println( "\t\tLyndir" );

                System.out.println( "[options] [site name]" );
                System.out.println();
                System.out.println( "Available options:" );
                System.out.println( "\t-t | --type [site password type]" );
                System.out.format( "\t\tDefault: %s.  The password type to use for this site.\n", type.getName() );
                System.out.println( "\t\tUse 'list' to see the available types." );

                System.out.println();
                System.out.println( "\t-c | --counter [site counter]" );
                System.out.format( "\t\tDefault: %d.  The counter to use for this site.\n", counter );
                System.out.println( "\t\tIncrement the counter if you need a new password." );

                System.out.println();
                System.out.println( "\t-u | --username [user's name]" );
                System.out.println( "\t\tDefault: asked.  The name of the current user." );

                System.out.println();
                return;
            } else
                siteName = arg;
        LineReader lineReader = new LineReader( new InputStreamReader( System.in ) );
        if (siteName == null) {
            System.out.print( "Site name: " );
            siteName = lineReader.readLine();
        }
        if (userName == null) {
            System.out.print( "User's name: " );
            userName = lineReader.readLine();
        }
        System.out.print( "User's master password: " );
        String masterPassword = lineReader.readLine();

        String sitePassword = MasterPassword.generateContent( type, siteName, MasterPassword.keyForPassword( masterPassword, userName ),
                                                              counter );
        System.out.println( sitePassword );
    }
}
