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

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.google.common.base.Charsets;
import com.google.common.collect.ImmutableList;
import com.google.common.io.CharSink;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.*;
import java.io.*;
import java.util.HashMap;
import java.util.Map;
import javax.annotation.Nonnull;


/**
 * Manages user data stored in user-specific {@code .mpsites} files under {@code .mpw.d}.
 *
 * @author lhunath, 14-12-07
 */
@SuppressWarnings("CallToSystemGetenv")
public class MPFileUserManager extends MPUserManager<MPFileUser> {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger            logger = Logger.get( MPFileUserManager.class );
    private static final MPFileUserManager instance;

    static {
        String rcDir = System.getenv( MPConstant.env_rcDir );
        if (rcDir != null)
            instance = create( new File( rcDir ) );
        else
            instance = create( new File( ifNotNullElseNullable( System.getProperty( "user.home" ), System.getenv( "HOME" ) ), ".mpw.d" ) );
    }

    private final File path;

    public static MPFileUserManager get() {
        return instance;
    }

    public static MPFileUserManager create(final File path) {
        return new MPFileUserManager( path );
    }

    protected MPFileUserManager(final File path) {

        super( unmarshallUsers( path ) );
        this.path = path;
    }

    private static Iterable<MPFileUser> unmarshallUsers(final File userFilesDirectory) {
        if (!userFilesDirectory.mkdirs() && !userFilesDirectory.isDirectory()) {
            logger.err( "Couldn't create directory for user files: %s", userFilesDirectory );
            return ImmutableList.of();
        }

        Map<String, MPFileUser> users = new HashMap<>();
        for (final File userFile : listUserFiles( userFilesDirectory ))
            for (final MPMarshalFormat format : MPMarshalFormat.values())
                if (userFile.getName().endsWith( format.fileSuffix() ))
                    try {
                        MPFileUser user         = format.unmarshaller().unmarshall( userFile, null );
                        MPFileUser previousUser = users.put( user.getFullName(), user );
                        if ((previousUser != null) && (previousUser.getFormat().ordinal() > user.getFormat().ordinal()))
                            users.put( previousUser.getFullName(), previousUser );
                    }
                    catch (final IOException | MPMarshalException e) {
                        logger.err( e, "Couldn't read user from: %s", userFile );
                    }
                    catch (final MPKeyUnavailableException | MPIncorrectMasterPasswordException | MPAlgorithmException e) {
                        logger.err( e, "Couldn't authenticate user for: %s", userFile );
                    }

        return users.values();
    }

    private static ImmutableList<File> listUserFiles(final File userFilesDirectory) {
        return ImmutableList.copyOf( ifNotNullElse( userFilesDirectory.listFiles( (dir, name) -> {
            for (final MPMarshalFormat format : MPMarshalFormat.values())
                if (name.endsWith( format.fileSuffix() ))
                    return true;

            return false;
        } ), new File[0] ) );
    }

    @Override
    public void deleteUser(final MPFileUser user) {
        super.deleteUser( user );

        // Remove deleted users.
        File userFile = getUserFile( user, user.getFormat() );
        if (userFile.exists() && !userFile.delete())
            logger.err( "Couldn't delete file: %s", userFile );
    }

    /**
     * Write the current user state to disk.
     */
    public void save(final MPFileUser user, final MPMasterKey masterKey)
            throws MPKeyUnavailableException, MPAlgorithmException {
        try {
            MPMarshalFormat format = user.getFormat();
            new CharSink() {
                @Override
                public Writer openStream()
                        throws IOException {
                    return new OutputStreamWriter( new FileOutputStream( getUserFile( user, format ) ), Charsets.UTF_8 );
                }
            }.write( format.marshaller().marshall( user ) );
        }
        catch (final MPMarshalException | IOException e) {
            logger.err( e, "Unable to save sites for user: %s", user );
        }
    }

    @Nonnull
    private File getUserFile(final MPUser<?> user, final MPMarshalFormat format) {
        return new File( path, user.getFullName() + format.fileSuffix() );
    }

    /**
     * @return The location on the file system where the user models are stored.
     */
    public File getPath() {
        return path;
    }
}
