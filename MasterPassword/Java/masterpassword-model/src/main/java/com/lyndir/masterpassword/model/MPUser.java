package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Sets;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.masterpassword.MPSiteType;
import com.lyndir.masterpassword.MasterKey;
import java.util.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.joda.time.*;


/**
 * @author lhunath, 14-12-07
 */
public class MPUser implements Comparable<MPUser> {

    private final String fullName;
    private final Collection<MPSite> sites = Sets.newHashSet();

    @Nullable
    private       byte[]            keyID;
    private final MasterKey.Version algorithmVersion;
    private       int               avatar;
    private       MPSiteType        defaultType;
    private       ReadableInstant   lastUsed;

    public MPUser(final String fullName) {
        this( fullName, null );
    }

    public MPUser(final String fullName, @Nullable final byte[] keyID) {
        this( fullName, keyID, MasterKey.Version.CURRENT, 0, MPSiteType.GeneratedLong, new DateTime() );
    }

    public MPUser(final String fullName, @Nullable final byte[] keyID, final MasterKey.Version algorithmVersion, final int avatar,
                  final MPSiteType defaultType, final ReadableInstant lastUsed) {
        this.fullName = fullName;
        this.keyID = keyID;
        this.algorithmVersion = algorithmVersion;
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

    public void deleteSite(final MPSite site) {
        sites.remove( site );
    }

    public String getFullName() {
        return fullName;
    }

    public boolean hasKeyID() {
        return keyID != null;
    }

    public String exportKeyID() {
        return CodeUtils.encodeHex( keyID );
    }

    /**
     * Performs an authentication attempt against the keyID for this user.
     *
     * Note: If this user doesn't have a keyID set yet, authentication will always succeed and the key ID will be set as a result.
     *
     * @param masterPassword The password to authenticate with.
     *
     * @return The master key for the user if authentication was successful.
     *
     * @throws IncorrectMasterPasswordException If authentication fails due to the given master password not matching the user's keyID.
     */
    @Nonnull
    public MasterKey authenticate(final char[] masterPassword)
            throws IncorrectMasterPasswordException {
        MasterKey masterKey = MasterKey.create( algorithmVersion, getFullName(), masterPassword );
        if (keyID == null || keyID.length == 0)
            keyID = masterKey.getKeyID();
        else if (!Arrays.equals( masterKey.getKeyID(), keyID ))
            throw new IncorrectMasterPasswordException( this );

        return masterKey;
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
