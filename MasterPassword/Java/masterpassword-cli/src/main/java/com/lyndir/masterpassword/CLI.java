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


package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.ifNotNullElse;

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

    private static final String ENV_USERNAME    = "MP_USERNAME";
    private static final String ENV_PASSWORD    = "MP_PASSWORD";
    private static final String ENV_SITETYPE    = "MP_SITETYPE";
    private static final String ENV_SITECOUNTER = "MP_SITECOUNTER";

    public static void main(final String[] args)
            throws IOException {

        // Read information from the environment.
        String siteName = null;
        String userName = System.getenv().get( ENV_USERNAME );
        String masterPassword = System.getenv().get( ENV_PASSWORD );
        String siteTypeName = ifNotNullElse( System.getenv().get( ENV_SITETYPE ), "" );
        MPElementType siteType = siteTypeName.isEmpty()? MPElementType.GeneratedLong: MPElementType.forName( siteTypeName );
        String siteCounterName = ifNotNullElse( System.getenv().get( ENV_SITECOUNTER ), "" );
        int siteCounter = siteCounterName.isEmpty()? 1: Integer.parseInt( siteCounterName );

        // Parse information from option arguments.
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

                siteType = MPElementType.forName( arg );
                typeArg = false;
            } else if ("-c".equals( arg ) || "--counter".equals( arg ))
                counterArg = true;
            else if (counterArg) {
                siteCounter = ConversionUtils.toIntegerNN( arg );
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
                System.out.format( "\t\tDefault: %s.  The password type to use for this site.\n", siteType.getName() );
                System.out.println( "\t\tUse 'list' to see the available types." );

                System.out.println();
                System.out.println( "\t-c | --counter [site counter]" );
                System.out.format( "\t\tDefault: %d.  The counter to use for this site.\n", siteCounter );
                System.out.println( "\t\tIncrement the counter if you need a new password." );

                System.out.println();
                System.out.println( "\t-u | --username [user's name]" );
                System.out.println( "\t\tDefault: asked.  The name of the user." );

                System.out.println();
                System.out.println( "Available environment variables:" );

                System.out.format( "\t%s\n", ENV_USERNAME );
                System.out.println( "\t\tThe name of the user." );

                System.out.format( "\t%s\n", ENV_PASSWORD );
                System.out.println( "\t\tThe master password of the user." );

                System.out.println();
                return;
            } else
                siteName = arg;

        // Read missing information from the console.
        Console console = System.console();
        try (InputStreamReader inReader = new InputStreamReader( System.in )) {
            LineReader lineReader = new LineReader( inReader );

            if (siteName == null) {
                System.err.format( "Site name: " );
                siteName = lineReader.readLine();
            }

            if (userName == null) {
                System.err.format( "User's name: " );
                userName = lineReader.readLine();
            }

            if (masterPassword == null) {
                if (console != null)
                    masterPassword = new String( console.readPassword( "%s's master password: ", userName ) );

                else {
                    System.err.format( "%s's master password: ", userName );
                    masterPassword = lineReader.readLine();
                }
            }
        }

        // Encode and write out the site password.
        System.out.println( new MasterKey( userName, masterPassword ).encode( siteName, siteType, siteCounter ) );
    }
}
