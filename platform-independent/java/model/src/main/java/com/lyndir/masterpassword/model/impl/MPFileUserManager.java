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

import com.google.common.collect.ImmutableSortedSet;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.model.MPConfig;
import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.CopyOnWriteArraySet;


/**
 * Manages user data stored in user-specific {@code .mpsites} files under {@code .mpw.d}.
 *
 * @author lhunath, 14-12-07
 */
@SuppressWarnings("CallToSystemGetenv")
public class MPFileUserManager {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger            logger   = Logger.get( MPFileUserManager.class );
    private static final MPFileUserManager instance = create( MPConfig.get().rcDir() );

    private final Collection<Listener>    listeners  = new CopyOnWriteArraySet<>();
    private final Map<String, MPFileUser> userByName = new HashMap<>();
    private final File                    path;

    public static MPFileUserManager get() {
        return instance;
    }

    public static MPFileUserManager create(final File path) {
        return new MPFileUserManager( path );
    }

    protected MPFileUserManager(final File path) {
        this.path = path;
        reload();
    }

    public void reload() {
        userByName.clear();

        File[] pathFiles;
        if ((!path.exists() && !path.mkdirs()) || ((pathFiles = path.listFiles()) == null)) {
            logger.err( "Couldn't create directory for user files: %s", path );
            return;
        }

        for (final MPMarshalFormat format : MPMarshalFormat.values())
            for (final File file : pathFiles)
                if (format.matches( file ))
                    try {
                        MPFileUser user = MPFileUser.load( file );
                        if (user != null)
                            add( user );
                    }
                    catch (final IOException | MPMarshalException e) {
                        logger.err( e, "Couldn't read user from: %s", file );
                    }

        fireUpdated();
    }

    public MPFileUser add(final String fullName) {
        return add( new MPFileUser( fullName, getPath() ) );
    }

    public MPFileUser add(final MPFileUser user) {
        // We migrate in two steps to allow the first to complete even if the user is not in the right state to complete the latter.
        user.migrateTo( getPath() );
        user.migrateTo( MPMarshalFormat.DEFAULT );

        MPFileUser oldUser = userByName.put( user.getFullName(), user );
        if (oldUser != null) {
            oldUser.invalidate();

            // Delete old user, it is replaced by the new one.
            if (!oldUser.getFile().equals( user.getFile() ) && oldUser.getFile().exists())
                if (!oldUser.getFile().delete())
                    logger.err( "Couldn't delete file: %s, after replacing with: %s", oldUser.getFile(), user.getFile() );
        }
        fireUpdated();

        return user;
    }

    public void delete(final MPFileUser user) {
        user.invalidate();

        // Remove deleted users.
        File userFile = user.getFile();
        if (userFile.exists() && !userFile.delete())
            logger.err( "Couldn't delete file: %s", userFile );
        else if (userByName.values().remove( user ))
            fireUpdated();
    }

    public File getPath() {
        return path;
    }

    public ImmutableSortedSet<MPFileUser> getFiles() {
        return ImmutableSortedSet.copyOf( userByName.values() );
    }

    public void addListener(final Listener listener) {
        if (listeners.add( listener ))
            listener.onFilesUpdated( getFiles() );
    }

    public void removeListener(final Listener listener) {
        listeners.remove( listener );
    }

    private void fireUpdated() {
        if (listeners.isEmpty())
            return;

        ImmutableSortedSet<MPFileUser> files = getFiles();
        for (final Listener listener : listeners)
            listener.onFilesUpdated( files );
    }

    public interface Listener {

        void onFilesUpdated(ImmutableSortedSet<MPFileUser> files);
    }
}
