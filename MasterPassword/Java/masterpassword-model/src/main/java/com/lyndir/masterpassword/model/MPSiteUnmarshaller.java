package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.google.common.base.Preconditions;
import com.google.common.collect.ImmutableList;
import com.google.common.io.CharStreams;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.ConversionUtils;
import com.lyndir.lhunath.opal.system.util.NNOperation;
import com.lyndir.masterpassword.MPSiteType;
import com.lyndir.masterpassword.MasterKey;
import java.io.*;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;


/**
 * @author lhunath, 14-12-07
 */
public class MPSiteUnmarshaller {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger            logger            = Logger.get( MPSite.class );
    private static final DateTimeFormatter rfc3339           = ISODateTimeFormat.dateTimeNoMillis();
    private static final Pattern[]         unmarshallFormats = new Pattern[]{
            Pattern.compile( "^([^ ]+) +(\\d+) +(\\d+)(:\\d+)? +([^\t]+)\t(.*)" ),
            Pattern.compile( "^([^ ]+) +(\\d+) +(\\d+)(:\\d+)?(:\\d+)? +([^\t]*)\t *([^\t]+)\t(.*)" ) };
    private static final Pattern           headerFormat      = Pattern.compile( "^#\\s*([^:]+): (.*)" );

    private final int     importFormat;
    private final int     mpVersion;
    private final boolean clearContent;
    private final MPUser  user;

    @Nonnull
    public static MPSiteUnmarshaller unmarshall(@Nonnull File file)
            throws IOException {
        try (Reader reader = new FileReader( file )) {
            return unmarshall( CharStreams.readLines( reader ) );
        }
    }

    @Nonnull
    public static MPSiteUnmarshaller unmarshall(@Nonnull List<String> lines) {
        byte[] keyID = null;
        String fullName = null;
        int mpVersion = 0, importFormat = 0, avatar = 0;
        boolean clearContent = false, headerStarted = false;
        MPSiteType defaultType = MPSiteType.GeneratedLong;
        MPSiteUnmarshaller marshaller = null;
        final ImmutableList.Builder<MPSite> sites = ImmutableList.builder();

        for (String line : lines)
            // Header delimitor.
            if (line.startsWith( "##" ))
                if (!headerStarted)
                    // Starts the header.
                    headerStarted = true;
                else
                    // Ends the header.
                    marshaller = new MPSiteUnmarshaller( importFormat, mpVersion, fullName, keyID, avatar, defaultType, clearContent );

                // Comment.
            else if (line.startsWith( "#" )) {
                if (headerStarted && marshaller == null) {
                    // In header.
                    Matcher headerMatcher = headerFormat.matcher( line );
                    if (headerMatcher.matches()) {
                        String name = headerMatcher.group( 1 ), value = headerMatcher.group( 2 );
                        if ("Full Name".equalsIgnoreCase( name ) || "User Name".equalsIgnoreCase( name ))
                            fullName = value;
                        else if ("Key ID".equalsIgnoreCase( name ))
                            keyID = CodeUtils.decodeHex( value );
                        else if ("Algorithm".equalsIgnoreCase( name ))
                            mpVersion = ConversionUtils.toIntegerNN( value );
                        else if ("Format".equalsIgnoreCase( name ))
                            importFormat = ConversionUtils.toIntegerNN( value );
                        else if ("Avatar".equalsIgnoreCase( name ))
                            avatar = ConversionUtils.toIntegerNN( value );
                        else if ("Passwords".equalsIgnoreCase( name ))
                            clearContent = value.equalsIgnoreCase( "visible" );
                        else if ("Default Type".equalsIgnoreCase( name ))
                            defaultType = MPSiteType.forType( ConversionUtils.toIntegerNN( value ) );
                    }
                }
            }

            // No comment.
            else if (marshaller != null)
                ifNotNull( marshaller.unmarshallSite( line ), new NNOperation<MPSite>() {
                    @Override
                    public void apply(@Nonnull final MPSite site) {
                        sites.add( site );
                    }
                } );

        return Preconditions.checkNotNull( marshaller, "No full header found in import file." );
    }

    protected MPSiteUnmarshaller(final int importFormat, final int mpVersion, final String fullName, final byte[] keyID, final int avatar,
                                 final MPSiteType defaultType, final boolean clearContent) {
        this.importFormat = importFormat;
        this.mpVersion = mpVersion;
        this.clearContent = clearContent;

        user = new MPUser( fullName, keyID, MasterKey.Version.fromInt( mpVersion ), avatar, defaultType, new DateTime( 0 ) );
    }

    @Nullable
    public MPSite unmarshallSite(@Nonnull String siteLine) {
        Matcher siteMatcher = unmarshallFormats[importFormat].matcher( siteLine );
        if (!siteMatcher.matches())
            return null;

        MPSite site;
        switch (importFormat) {
            case 0:
                site = new MPSite( user, //
                                   MasterKey.Version.fromInt( ConversionUtils.toIntegerNN( siteMatcher.group( 4 ).replace( ":", "" ) ) ), //
                                   rfc3339.parseDateTime( siteMatcher.group( 1 ) ).toInstant(), //
                                   siteMatcher.group( 5 ), //
                                   MPSiteType.forType( ConversionUtils.toIntegerNN( siteMatcher.group( 3 ) ) ), MPSite.DEFAULT_COUNTER, //
                                   ConversionUtils.toIntegerNN( siteMatcher.group( 2 ) ), //
                                   null, //
                                   siteMatcher.group( 6 ) );
                break;

            case 1:
                site = new MPSite( user, //
                                   MasterKey.Version.fromInt( ConversionUtils.toIntegerNN( siteMatcher.group( 4 ).replace( ":", "" ) ) ), //
                                   rfc3339.parseDateTime( siteMatcher.group( 1 ) ).toInstant(), //
                                   siteMatcher.group( 7 ), //
                                   MPSiteType.forType( ConversionUtils.toIntegerNN( siteMatcher.group( 3 ) ) ),
                                   UnsignedInteger.valueOf( siteMatcher.group( 5 ).replace( ":", "" ) ), //
                                   ConversionUtils.toIntegerNN( siteMatcher.group( 2 ) ), //
                                   siteMatcher.group( 6 ), //
                                   siteMatcher.group( 8 ) );
                break;

            default:
                throw logger.bug( "Unexpected format: %d", importFormat );
        }

        user.addSite( site );
        return site;
    }

    public MPUser getUser() {
        return user;
    }
}
