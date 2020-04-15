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

import com.lyndir.masterpassword.*;
import java.util.Collection;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-05-14
 */
public interface MPUser<S extends MPSite<?>> extends Comparable<MPUser<?>> {

    // - Meta

    int getAvatar();

    void setAvatar(int avatar);

    @Nonnull
    String getFullName();

    @Nonnull
    MPUserPreferences getPreferences();

    // - Algorithm

    @Nonnull
    MPAlgorithm getAlgorithm();

    void setAlgorithm(MPAlgorithm algorithm);

    @Nullable
    String getKeyID();

    /**
     * Performs an authentication attempt against the keyID for this user.
     *
     * @param masterPassword The password to authenticate with.
     *
     * @throws MPIncorrectMasterPasswordException If authentication fails due to the given master password not matching the user's keyID.
     * @apiNote If a keyID is not set, authentication will always succeed and the keyID will be set to match the given master password.
     * <b>This method destroys the contents of the {@code masterPassword} array.</b>
     */
    void authenticate(char[] masterPassword)
            throws MPIncorrectMasterPasswordException, MPAlgorithmException;

    /**
     * Performs an authentication attempt against the keyID for this user.
     *
     * @param masterKey The master key to authenticate with.
     *
     * @throws MPIncorrectMasterPasswordException If authentication fails due to the given master password not matching the user's keyID.
     * @apiNote If a keyID is not set, authentication will always succeed and the keyID will be set to match the given key.
     */
    void authenticate(MPMasterKey masterKey)
            throws MPIncorrectMasterPasswordException, MPKeyUnavailableException, MPAlgorithmException;

    /**
     * Clear all authentication tokens and secrets from memory, effectively logging the user out.
     */
    void invalidate();

    /**
     * Wipe the key ID, allowing the user to {@link #authenticate(char[])} with any master password.
     *
     * Note: Authenticating with a different master password will cause all of the user's results to change.
     */
    void reset();

    boolean isMasterKeyAvailable();

    @Nonnull
    MPMasterKey getMasterKey()
            throws MPKeyUnavailableException;

    // - Relations

    @Nonnull
    S addSite(String siteName);

    @Nonnull
    S addSite(S site);

    boolean deleteSite(MPSite<?> site);

    @Nonnull
    Collection<S> getSites();

    void addListener(Listener listener);

    void removeListener(Listener listener);

    interface Listener {

        void onUserUpdated(MPUser<?> user);

        void onUserAuthenticated(MPUser<?> user);

        void onUserInvalidated(MPUser<?> user);
    }
}
