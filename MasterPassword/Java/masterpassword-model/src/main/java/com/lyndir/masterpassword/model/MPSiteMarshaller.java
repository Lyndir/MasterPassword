package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.ifNotNullElse;
import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.base.Preconditions;
import com.lyndir.masterpassword.MasterKey;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.joda.time.Instant;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;


/**
 * @author lhunath, 14-12-07
 */
public class MPSiteMarshaller {

    private static final DateTimeFormatter rfc3339 = ISODateTimeFormat.dateTimeNoMillis();

    private final StringBuilder export      = new StringBuilder();
    private       ContentMode   contentMode = ContentMode.PROTECTED;
    private MasterKey masterKey;

    public static MPSiteMarshaller marshallSafe(final MPUser user) {
        MPSiteMarshaller marshaller = new MPSiteMarshaller();
        marshaller.marshallHeaderForSafeContent( user );
        for (MPSite site : user.getSites())
            marshaller.marshallSite( site );

        return marshaller;
    }

    public static MPSiteMarshaller marshallVisible(final MPUser user, final MasterKey masterKey) {
        MPSiteMarshaller marshaller = new MPSiteMarshaller();
        marshaller.marshallHeaderForVisibleContentWithKey( user, masterKey );
        for (MPSite site : user.getSites())
            marshaller.marshallSite( site );

        return marshaller;
    }

    private String marshallHeaderForSafeContent(final MPUser user) {
        return marshallHeader( ContentMode.PROTECTED, user, null );
    }

    private String marshallHeaderForVisibleContentWithKey(final MPUser user, final MasterKey masterKey) {
        return marshallHeader( ContentMode.VISIBLE, user, masterKey );
    }

    private String marshallHeader(final ContentMode contentMode, final MPUser user, @Nullable final MasterKey masterKey) {
        this.masterKey = masterKey;

        StringBuilder header = new StringBuilder();
        header.append( "# Master Password site export\n" );
        header.append( "#     " ).append( contentMode.description() ).append( '\n' );
        header.append( "# \n" );
        header.append( "##\n" );
        header.append( "# Format: 1\n" );
        header.append( "# Date: " ).append( rfc3339.print( new Instant() ) ).append( '\n' );
        header.append( "# User Name: " ).append( user.getFullName() ).append( '\n' );
        header.append( "# Full Name: " ).append( user.getFullName() ).append( '\n' );
        header.append( "# Avatar: " ).append( user.getAvatar() ).append( '\n' );
        header.append( "# Key ID: " ).append( user.exportKeyID() ).append( '\n' );
        header.append( "# Version: " ).append( user.getAlgorithmVersion().toBundleVersion() ).append( '\n' );
        header.append( "# Algorithm: " ).append( user.getAlgorithmVersion().toInt() ).append( '\n' );
        header.append( "# Default Type: " ).append( user.getDefaultType().getType() ).append( '\n' );
        header.append( "# Passwords: " ).append( contentMode.name() ).append( '\n' );
        header.append( "##\n" );
        header.append( "#\n" );
        header.append( "#               Last     Times  Password                      Login\t                     Site\tSite\n" );
        header.append( "#               used      used      type                       name\t                     name\tpassword\n" );

        export.append( header );
        return header.toString();
    }

    public String marshallSite(MPSite site) {
        String exportLine = strf( "%s  %8d  %8s  %25s\t%25s\t%s", //
                                  rfc3339.print( site.getLastUsed() ), // lastUsed
                                  site.getUses(), // uses
                                  strf( "%d:%d:%d", //
                                        site.getSiteType().getType(), // type
                                        site.getAlgorithmVersion(), // algorithm
                                        site.getSiteCounter() ), // counter
                                  ifNotNullElse( site.getLoginName(), "" ), // loginName
                                  site.getSiteName(), // siteName
                                  ifNotNullElse( contentMode.contentForSite( site, masterKey ), "" ) // password
        );
        export.append( exportLine ).append( '\n' );

        return exportLine;
    }

    public String getExport() {
        return export.toString();
    }

    public ContentMode getContentMode() {
        return contentMode;
    }

    public enum ContentMode {
        PROTECTED( "Export of site names and stored passwords (unless device-private) encrypted with the master key." ) {
            @Override
            public String contentForSite(final MPSite site, @Nullable final MasterKey masterKey) {
                return site.exportContent();
            }
        },
        VISIBLE( "Export of site names and passwords in clear-text." ) {
            @Override
            public String contentForSite(final MPSite site, @Nonnull final MasterKey masterKey) {
                return site.resultFor( Preconditions.checkNotNull( masterKey, "Master key is required when content mode is VISIBLE." ) );
            }
        };

        private final String description;

        ContentMode(final String description) {
            this.description = description;
        }

        public String description() {
            return description;
        }

        public abstract String contentForSite(final MPSite site, final MasterKey masterKey);
    }
}
