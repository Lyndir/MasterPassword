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

package com.lyndir.masterpassword.model.impl;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.ImmutableCollection;
import com.google.common.collect.ImmutableSortedSet;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.MPIncorrectMasterPasswordException;
import com.lyndir.masterpassword.model.MPUser;
import java.util.*;
import java.util.concurrent.CopyOnWriteArraySet;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class MPBasicUser<S extends MPBasicSite<?, ?>> extends Changeable implements MPUser<S> {

    protected final Logger        logger    = Logger.get( getClass() );
    private final   Set<Listener> listeners = new CopyOnWriteArraySet<>();

    private       int         avatar;
    private final String      fullName;
    private       MPAlgorithm algorithm;
    @Nullable
    protected     MPMasterKey masterKey;

    private final Map<String, S> sites = new LinkedHashMap<>();

    protected MPBasicUser(final String fullName, final MPAlgorithm algorithm) {
        this( 0, fullName, algorithm );
    }

    protected MPBasicUser(final int avatar, final String fullName, final MPAlgorithm algorithm) {
        this.avatar = avatar;
        this.fullName = fullName;
        this.algorithm = algorithm;
    }

    @Override
    public int getAvatar() {
        return avatar;
    }

    @Override
    public void setAvatar(final int avatar) {
        this.avatar = avatar;

        setChanged();
    }

    @Nonnull
    @Override
    public String getFullName() {
        return fullName;
    }

    @Nonnull
    @Override
    public MPAlgorithm getAlgorithm() {
        return algorithm;
    }

    @Override
    public void setAlgorithm(final MPAlgorithm algorithm) {
        this.algorithm = algorithm;

        setChanged();
    }

    @Nullable
    @Override
    public byte[] getKeyID() {
        try {
            return getMasterKey().getKeyID( getAlgorithm() );
        }
        catch (final MPException e) {
            logger.wrn( e, "While deriving key ID for user: %s", this );
            return null;
        }
    }

    @Nullable
    @Override
    public String exportKeyID() {
        return CodeUtils.encodeHex( getKeyID() );
    }

    @Override
    public void authenticate(final char[] masterPassword)
            throws MPIncorrectMasterPasswordException, MPAlgorithmException {
        try {
            authenticate( new MPMasterKey( getFullName(), masterPassword ) );
        }
        catch (final MPKeyUnavailableException e) {
            throw new IllegalStateException( e );
        }
    }

    @Override
    public void authenticate(final MPMasterKey masterKey)
            throws MPIncorrectMasterPasswordException, MPKeyUnavailableException, MPAlgorithmException {
        if (!masterKey.getFullName().equals( getFullName() ))
            throw new IllegalArgumentException(
                    "Master key (for " + masterKey.getFullName() + ") is not for this user (" + getFullName() + ")." );

        byte[] keyID = getKeyID();
        if ((keyID != null) && !Arrays.equals( masterKey.getKeyID( getAlgorithm() ), keyID ))
            throw new MPIncorrectMasterPasswordException( this );

        this.masterKey = masterKey;

        for (final Listener listener : listeners)
            listener.onUserAuthenticated( this );
    }

    @Override
    public boolean isMasterKeyAvailable() {
        return masterKey != null;
    }

    @Nonnull
    @Override
    public MPMasterKey getMasterKey()
            throws MPKeyUnavailableException {
        if (masterKey == null)
            throw new MPKeyUnavailableException( "Master key was not yet set for: " + this );

        return masterKey;
    }

    @Override
    public S addSite(final S site) {
        sites.put( site.getSiteName(), site );

        setChanged();
        return site;
    }

    @Override
    public void deleteSite(final S site) {
        sites.values().remove( site );

        setChanged();
    }

    @Nonnull
    @Override
    public Collection<S> getSites() {
        return Collections.unmodifiableCollection( sites.values() );
    }

    @Nonnull
    @Override
    public ImmutableCollection<S> findSites(@Nullable final String query) {
        ImmutableSortedSet.Builder<S> results = ImmutableSortedSet.naturalOrder();
        if (query != null)
            for (final S site : getSites())
                if (site.getSiteName().startsWith( query ))
                    results.add( site );

        return results.build();
    }

    @Override
    public boolean addListener(final Listener listener) {
        return listeners.add( listener );
    }

    @Override
    public boolean removeListener(final Listener listener) {
        return listeners.remove( listener );
    }

    @Override
    protected void onChanged() {
        super.onChanged();

        for (final Listener listener : listeners)
            listener.onUserUpdated( this );
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getFullName() );
    }

    @Override
    public boolean equals(final Object obj) {
        return (this == obj) || ((obj instanceof MPUser) && Objects.equals( getFullName(), ((MPUser<?>) obj).getFullName() ));
    }

    @Override
    public int compareTo(@Nonnull final MPUser<?> o) {
        return getFullName().compareTo( o.getFullName() );
    }

    @Override
    public String toString() {
        return strf( "{%s: %s}", getClass().getSimpleName(), getFullName() );
    }
}
