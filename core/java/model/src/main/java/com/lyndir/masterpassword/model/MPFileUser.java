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

package com.lyndir.masterpassword.model;

import com.google.common.collect.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import java.util.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.joda.time.*;


/**
 * @author lhunath, 14-12-07
 */
public class MPFileUser extends MPUser<MPFileSite> implements Comparable<MPFileUser> {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPFileUser.class );

    private final String                 fullName;
    private final Collection<MPFileSite> sites = Sets.newHashSet();

    @Nullable
    private byte[]              keyID;
    private MPMasterKey.Version algorithmVersion;
    private MPMarshalFormat     format;

    private int             avatar;
    private MPResultType    defaultType;
    private ReadableInstant lastUsed;

    public MPFileUser(final String fullName) {
        this( fullName, null, MPMasterKey.Version.CURRENT );
    }

    public MPFileUser(final String fullName, @Nullable final byte[] keyID, final MPMasterKey.Version algorithmVersion) {
        this( fullName, keyID, algorithmVersion, 0, MPAlgorithm.mpw_default_type, new Instant(), MPMarshalFormat.DEFAULT );
    }

    public MPFileUser(final String fullName, @Nullable final byte[] keyID, final MPMasterKey.Version algorithmVersion, final int avatar,
                      final MPResultType defaultType, final ReadableInstant lastUsed, final MPMarshalFormat format) {
        this.fullName = fullName;
        this.keyID = (keyID == null)? null: keyID.clone();
        this.algorithmVersion = algorithmVersion;
        this.avatar = avatar;
        this.defaultType = defaultType;
        this.lastUsed = lastUsed;
        this.format = format;
    }

    @Override
    public String getFullName() {
        return fullName;
    }

    @Override
    public MPMasterKey.Version getAlgorithmVersion() {
        return algorithmVersion;
    }

    public void setAlgorithmVersion(final MPMasterKey.Version algorithmVersion) {
        this.algorithmVersion = algorithmVersion;
    }

    public MPMarshalFormat getFormat() {
        return format;
    }

    public void setFormat(final MPMarshalFormat format) {
        this.format = format;
    }

    @Override
    public int getAvatar() {
        return avatar;
    }

    public void setAvatar(final int avatar) {
        this.avatar = avatar;
    }

    public MPResultType getDefaultType() {
        return defaultType;
    }

    public void setDefaultType(final MPResultType defaultType) {
        this.defaultType = defaultType;
    }

    public ReadableInstant getLastUsed() {
        return lastUsed;
    }

    public void use() {
        lastUsed = new Instant();
    }

    public Iterable<MPFileSite> getSites() {
        return sites;
    }

    @Override
    public void addSite(final MPFileSite site) {
        sites.add( site );
    }

    @Override
    public void deleteSite(final MPFileSite site) {
        sites.remove( site );
    }

    @Override
    public Collection<MPFileSite> findSites(final String query) {
        ImmutableList.Builder<MPFileSite> results = ImmutableList.builder();
        for (final MPFileSite site : getSites())
            if (site.getSiteName().startsWith( query ))
                results.add( site );

        return results.build();
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
     * @throws MPIncorrectMasterPasswordException If authentication fails due to the given master password not matching the user's keyID.
     */
    @Nonnull
    @Override
    public MPMasterKey authenticate(final char[] masterPassword)
            throws MPIncorrectMasterPasswordException {
        try {
            key = new MPMasterKey( getFullName(), masterPassword );
            if ((keyID == null) || (keyID.length == 0))
                keyID = key.getKeyID( algorithmVersion );
            else if (!Arrays.equals( key.getKeyID( algorithmVersion ), keyID ))
                throw new MPIncorrectMasterPasswordException( this );

            return key;
        }
        catch (final MPInvalidatedException e) {
            throw logger.bug( e );
        }
    }

    void save()
            throws MPInvalidatedException {
        MPFileUserManager.get().save( this, getMasterKey() );
    }

    @Override
    public int compareTo(final MPFileUser o) {
        int comparison = getLastUsed().compareTo( o.getLastUsed() );
        if (comparison == 0)
            comparison = getFullName().compareTo( o.getFullName() );

        return comparison;
    }
}
