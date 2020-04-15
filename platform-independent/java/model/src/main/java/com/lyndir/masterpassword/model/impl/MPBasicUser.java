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

import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.*;
import java.util.*;
import java.util.concurrent.CopyOnWriteArraySet;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class MPBasicUser<S extends MPBasicSite<?, ?>> extends Changeable implements MPUser<S> {

    private static final Logger logger = Logger.get( MPBasicUser.class );

    private final Set<Listener> listeners = new CopyOnWriteArraySet<>();

    private       int         avatar;
    private final String      fullName;
    private       MPAlgorithm algorithm;
    @Nullable
    protected     MPMasterKey masterKey;

    private final Set<S> sites = new TreeSet<>();

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
        if (Objects.equals( this.avatar, avatar ))
            return;

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
    public MPUserPreferences getPreferences() {
        return new MPBasicUserPreferences<MPBasicUser<?>>( this );
    }

    @Nonnull
    @Override
    public MPAlgorithm getAlgorithm() {
        return algorithm;
    }

    @Override
    public void setAlgorithm(final MPAlgorithm algorithm) {
        if (Objects.equals( this.algorithm, algorithm ))
            return;

        this.algorithm = algorithm;
        setChanged();
    }

    @Nullable
    @Override
    public String getKeyID() {
        try {
            if (isMasterKeyAvailable())
                return getMasterKey().getKeyID( getAlgorithm() );
        }
        catch (final MPException e) {
            logger.wrn( e, "While deriving key ID for user: %s", this );
        }

        return null;
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

        String keyID = getKeyID();
        if (keyID != null && !keyID.equalsIgnoreCase( masterKey.getKeyID( getAlgorithm() ) ))
            throw new MPIncorrectMasterPasswordException( this );

        this.masterKey = masterKey;

        for (final Listener listener : listeners)
            listener.onUserAuthenticated( this );
    }

    @Override
    public void invalidate() {
        if (masterKey == null)
            return;

        masterKey.invalidate();
        masterKey = null;

        for (final Listener listener : listeners)
            listener.onUserInvalidated( this );
    }

    @Override
    public void reset() {
        invalidate();
    }

    @Override
    public boolean isMasterKeyAvailable() {
        return (masterKey != null) && masterKey.isValid();
    }

    @Nonnull
    @Override
    public MPMasterKey getMasterKey()
            throws MPKeyUnavailableException {
        if ((masterKey == null) || !masterKey.isValid())
            throw new MPKeyUnavailableException( "Master key was not yet set for: " + this );

        return masterKey;
    }

    @Nonnull
    @Override
    public S addSite(final S site) {
        sites.add( site );

        setChanged();
        return site;
    }

    @Override
    public boolean deleteSite(final MPSite<?> site) {
        if (!sites.remove( site ))
            return false;

        setChanged();
        return true;
    }

    @Nonnull
    @Override
    public Collection<S> getSites() {
        return Collections.unmodifiableCollection( sites );
    }

    @Override
    public void addListener(final Listener listener) {
        listeners.add( listener );
    }

    @Override
    public void removeListener(final Listener listener) {
        listeners.remove( listener );
    }

    @Override
    protected void onChanged() {
        for (final Listener listener : listeners)
            listener.onUserUpdated( this );
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getFullName() );
    }

    @Override
    public boolean equals(final Object obj) {
        return this == obj;
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
