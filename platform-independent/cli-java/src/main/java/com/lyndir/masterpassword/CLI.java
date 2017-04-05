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
import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.base.Charsets;
import com.google.common.base.Joiner;
import com.google.common.collect.Maps;
import com.google.common.io.LineReader;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.util.ConversionUtils;
import com.lyndir.lhunath.opal.system.util.StringUtils;
import java.io.*;
import java.util.Arrays;
import java.util.Map;


/**
 * <p> <i>Jun 10, 2008</i> </p>
 *
 * @author mbillemo
 */
@SuppressWarnings({ "UseOfSystemOutOrSystemErr", "HardCodedStringLiteral" })
public final class CLI {

    public static void main(final String... args)
            throws IOException {

        // Read information from the environment.
        char[] masterPassword;
        String siteName = null, context = null;
        String userName = System.getenv( MPConstant.env_userName );
        String siteTypeName = ifNotNullElse( System.getenv( MPConstant.env_siteType ), "" );
        MPSiteType siteType = siteTypeName.isEmpty()? MPSiteType.GeneratedLong: MPSiteType.forOption( siteTypeName );
        MPSiteVariant variant = MPSiteVariant.Password;
        String siteCounterName = ifNotNullElse( System.getenv( MPConstant.env_siteCounter ), "" );
        UnsignedInteger siteCounter = siteCounterName.isEmpty()? UnsignedInteger.valueOf( 1 ): UnsignedInteger.valueOf( siteCounterName );

        // Parse information from option arguments.
        boolean userNameArg = false, typeArg = false, counterArg = false, variantArg = false, contextArg = false;
        for (final String arg : Arrays.asList( args ))
            // Full Name
            if ("-u".equals( arg ) || "--username".equals( arg ))
                userNameArg = true;
            else if (userNameArg) {
                userName = arg;
                userNameArg = false;
            }

            // Type
            else if ("-t".equals( arg ) || "--type".equals( arg ))
                typeArg = true;
            else if (typeArg) {
                siteType = MPSiteType.forOption( arg );
                typeArg = false;
            }

            // Counter
            else if ("-c".equals( arg ) || "--counter".equals( arg ))
                counterArg = true;
            else if (counterArg) {
                siteCounter = UnsignedInteger.valueOf( arg );
                counterArg = false;
            }

            // Variant
            else if ("-v".equals( arg ) || "--variant".equals( arg ))
                variantArg = true;
            else if (variantArg) {
                variant = MPSiteVariant.forOption( arg );
                variantArg = false;
            }

            // Context
            else if ("-C".equals( arg ) || "--context".equals( arg ))
                contextArg = true;
            else if (contextArg) {
                context = arg;
                contextArg = false;
            }

            // Help
            else if ("-h".equals( arg ) || "--help".equals( arg )) {
                System.out.println();
                System.out.format( "Usage: mpw [-u name] [-t type] [-c counter] site%n%n" );
                System.out.format( "    -u name      Specify the full name of the user.%n" );
                System.out.format( "                 Defaults to %s in env.%n%n", MPConstant.env_userName );
                System.out.format( "    -t type      Specify the password's template.%n" );
                System.out.format( "                 Defaults to %s in env or 'long' for password, 'name' for login.%n", MPConstant.env_siteType );

                int optionsLength = 0;
                Map<String, MPSiteType> typeMap = Maps.newLinkedHashMap();
                for (final MPSiteType elementType : MPSiteType.values()) {
                    String options = Joiner.on( ", " ).join( elementType.getOptions() );
                    typeMap.put( options, elementType );
                    optionsLength = Math.max( optionsLength, options.length() );
                }
                for (final Map.Entry<String, MPSiteType> entry : typeMap.entrySet()) {
                    String infoString = strf( "                  -v %" + optionsLength + "s | ", entry.getKey() );
                    String infoNewline = strf( "%n%s | ", StringUtils.repeat( " ", infoString.length() - 3 ) );
                    infoString += entry.getValue().getDescription().replaceAll( strf( "%n" ), infoNewline );
                    System.out.println( infoString );
                }
                System.out.println();

                System.out.format( "    -c counter   The value of the counter.%n" );
                System.out.format( "                 Defaults to %s in env or '1'.%n%n", MPConstant.env_siteCounter );
                System.out.format( "    -v variant   The kind of content to generate.%n" );
                System.out.format( "                 Defaults to 'password'.%n" );

                optionsLength = 0;
                Map<String, MPSiteVariant> variantMap = Maps.newLinkedHashMap();
                for (final MPSiteVariant elementVariant : MPSiteVariant.values()) {
                    String options = Joiner.on( ", " ).join( elementVariant.getOptions() );
                    variantMap.put( options, elementVariant );
                    optionsLength = Math.max( optionsLength, options.length() );
                }
                for (final Map.Entry<String, MPSiteVariant> entry : variantMap.entrySet()) {
                    String infoString = strf( "                  -v %" + optionsLength + "s | ", entry.getKey() );
                    String infoNewline = strf( "%n%s | ", StringUtils.repeat( " ", infoString.length() - 3 ) );
                    infoString += entry.getValue().getDescription().replaceAll( strf( "%n" ), infoNewline );
                    System.out.println( infoString );
                }
                System.out.println();

                System.out.format( "    -C context   A variant-specific context.%n" );
                System.out.format( "                 Defaults to empty.%n" );
                for (final Map.Entry<String, MPSiteVariant> entry : variantMap.entrySet()) {
                    String infoString = strf( "                  -v %" + optionsLength + "s | ", entry.getKey() );
                    String infoNewline = strf( "%n%s | ", StringUtils.repeat( " ", infoString.length() - 3 ) );
                    infoString += entry.getValue().getContextDescription().replaceAll( strf( "%n" ), infoNewline );
                    System.out.println( infoString );
                }
                System.out.println();

                System.out.format( "    ENVIRONMENT%n%n" );
                System.out.format( "        MP_USERNAME    | The full name of the user.%n" );
                System.out.format( "        MP_SITETYPE    | The default password template.%n" );
                System.out.format( "        MP_SITECOUNTER | The default counter value.%n%n" );
                return;
            } else
                siteName = arg;

        // Read missing information from the console.
        Console console = System.console();
        try (InputStreamReader inReader = new InputStreamReader( System.in, Charsets.UTF_8 )) {
            LineReader lineReader = new LineReader( inReader );

            if (siteName == null) {
                System.err.format( "Site name: " );
                siteName = lineReader.readLine();
            }

            if (userName == null) {
                System.err.format( "User's name: " );
                userName = lineReader.readLine();
            }

            if (console != null)
                masterPassword = console.readPassword( "%s's master password: ", userName );

            else {
                System.err.format( "%s's master password: ", userName );
                masterPassword = lineReader.readLine().toCharArray();
            }
        }

        // Encode and write out the site password.
        System.out.println( MasterKey.create( userName, masterPassword ).encode( siteName, siteType, siteCounter, variant, context ) );
    }
}
