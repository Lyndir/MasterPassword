package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.google.common.base.*;
import com.google.common.collect.*;
import com.google.common.io.CharSink;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.MPConstant;
import java.io.*;
import javax.annotation.Nullable;


/**
 * Manages user data stored in user-specific {@code .mpsites} files under {@code .mpw.d}.
 * @author lhunath, 14-12-07
 */
public class MPUserFileManager extends MPUserManager {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPUserFileManager.class );
    private static final MPUserFileManager instance;

    static {
        String rcDir = System.getenv( MPConstant.env_rcDir );
        if (rcDir != null)
            instance = create( new File( rcDir ) );
        else
            instance = create( new File( ifNotNullElseNullable( System.getProperty( "user.home" ), System.getenv( "HOME" ) ), ".mpw.d" ) );
    }

    private final File userFilesDirectory;

    public static MPUserFileManager get() {
        MPUserManager.instance = instance;
        return instance;
    }

    public static MPUserFileManager create(final File userFilesDirectory) {
        return new MPUserFileManager( userFilesDirectory );
    }

    protected MPUserFileManager(final File userFilesDirectory) {

        super( unmarshallUsers( userFilesDirectory ) );
        this.userFilesDirectory = userFilesDirectory;
    }

    private static Iterable<MPUser> unmarshallUsers(final File userFilesDirectory) {
        if (!userFilesDirectory.mkdirs() && !userFilesDirectory.isDirectory()) {
            logger.err( "Couldn't create directory for user files: %s", userFilesDirectory );
            return ImmutableList.of();
        }

        return FluentIterable.from( listUserFiles( userFilesDirectory ) ).transform( new Function<File, MPUser>() {
            @Nullable
            @Override
            public MPUser apply(@Nullable final File file) {
                try {
                    return MPSiteUnmarshaller.unmarshall( Preconditions.checkNotNull( file ) ).getUser();
                }
                catch (final IOException e) {
                    logger.err( e, "Couldn't read user from: %s", file );
                    return null;
                }
            }
        } ).filter( Predicates.notNull() );
    }

    private static ImmutableList<File> listUserFiles(final File userFilesDirectory) {
        return ImmutableList.copyOf( ifNotNullElse( userFilesDirectory.listFiles( new FilenameFilter() {
            @Override
            public boolean accept(final File dir, final String name) {
                return name.endsWith( ".mpsites" );
            }
        } ), new File[0] ) );
    }

    @Override
    public void addUser(final MPUser user) {
        super.addUser( user );
        save();
    }

    @Override
    public void deleteUser(final MPUser user) {
        super.deleteUser( user );
        save();
    }

    /**
     * Write the current user state to disk.
     */
    public void save() {
        // Save existing users.
        for (final MPUser user : getUsers())
            try {
                new CharSink() {
                    @Override
                    public Writer openStream()
                            throws IOException {
                        File mpsitesFile = new File( userFilesDirectory, user.getFullName() + ".mpsites" );
                        return new OutputStreamWriter( new FileOutputStream( mpsitesFile ), Charsets.UTF_8 );
                    }
                }.write( MPSiteMarshaller.marshallSafe( user ).getExport() );
            }
            catch (final IOException e) {
                logger.err( e, "Unable to save sites for user: %s", user );
            }

        // Remove deleted users.
        for (final File userFile : listUserFiles( userFilesDirectory ))
            if (getUserNamed( userFile.getName().replaceFirst( "\\.mpsites$", "" ) ) == null)
                if (!userFile.delete())
                    logger.err( "Couldn't delete file: %s", userFile );
    }

    /**
     * @return The location on the file system where the user models are stored.
     */
    public File getPath() {
        return userFilesDirectory;
    }
}
