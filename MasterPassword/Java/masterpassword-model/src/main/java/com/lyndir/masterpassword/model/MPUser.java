package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Sets;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.masterpassword.MPSiteType;
import java.util.*;
import org.joda.time.*;


/**
 * @author lhunath, 14-12-07
 */
public class MPUser implements Comparable<MPUser> {

    private final String fullName;
    private final Collection<MPSite> sites = Sets.newHashSet();

    private byte[]          keyID;
    private int             avatar;
    private MPSiteType      defaultType;
    private ReadableInstant lastUsed;

    public MPUser(final String fullName) {
        this( fullName, null );
    }

    public MPUser(final String fullName, final byte[] keyID) {
        this( fullName, keyID, 0, MPSiteType.GeneratedLong, new DateTime() );
    }

    public MPUser(final String fullName, final byte[] keyID, final int avatar, final MPSiteType defaultType,
                  final ReadableInstant lastUsed) {
        this.fullName = fullName;
        this.keyID = keyID;
        this.avatar = avatar;
        this.defaultType = defaultType;
        this.lastUsed = lastUsed;
    }

    public Collection<MPSiteResult> findSitesByName(String query) {
        ImmutableList.Builder<MPSiteResult> results = ImmutableList.builder();
        for (MPSite site : getSites())
            if (site.getSiteName().startsWith( query ))
                results.add( new MPSiteResult( site ) );

        return results.build();
    }

    public void addSite(final MPSite site) {
        sites.add( site );
    }

    public String getFullName() {
        return fullName;
    }

    public boolean hasKeyID() {
        return keyID != null;
    }

    public boolean hasKeyID(final byte[] keyID) {
        return Arrays.equals( this.keyID, keyID );
    }

    public String exportKeyID() {
        return CodeUtils.encodeHex( keyID );
    }

    public void setKeyID(final byte[] keyID) {
        this.keyID = keyID;
    }

    public int getAvatar() {
        return avatar;
    }

    public void setAvatar(final int avatar) {
        this.avatar = avatar;
    }

    public MPSiteType getDefaultType() {
        return defaultType;
    }

    public void setDefaultType(final MPSiteType defaultType) {
        this.defaultType = defaultType;
    }

    public ReadableInstant getLastUsed() {
        return lastUsed;
    }

    public void updateLastUsed() {
        this.lastUsed = new Instant();
    }

    public Iterable<MPSite> getSites() {
        return sites;
    }

    @Override
    public boolean equals(final Object obj) {
        return this == obj || obj instanceof MPUser && Objects.equals( fullName, ((MPUser) obj).fullName );
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( fullName );
    }

    @Override
    public String toString() {
        return strf( "{MPUser: %s}", fullName );
    }

    @Override
    public int compareTo(final MPUser o) {
        int comparison = lastUsed.compareTo( o.lastUsed );
        if (comparison == 0)
            comparison = fullName.compareTo( o.fullName );

        return comparison;
    }
}
