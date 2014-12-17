package com.lyndir.masterpassword.model;

import com.google.common.base.*;
import com.google.common.collect.*;
import com.google.common.io.CharSink;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.io.*;
import javax.annotation.Nullable;


/**
 * @author lhunath, 14-12-07
 */
public class MPUserFileManager extends MPUserManager {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPUserFileManager.class );
    private static final MPUserFileManager instance = create( new File( System.getProperty( "user.home" ), ".mpw" ) );

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

        return FluentIterable.from( ImmutableList.copyOf( userFilesDirectory.listFiles( new FilenameFilter() {
            @Override
            public boolean accept(final File dir, final String name) {
                return name.endsWith( ".mpsites" );
            }
        } ) ) ).transform( new Function<File, MPUser>() {
            @Nullable
            @Override
            public MPUser apply(final File file) {
                try {
                    return MPSiteUnmarshaller.unmarshall( file ).getUser();
                }
                catch (IOException e) {
                    logger.err( e, "Couldn't read user from: %s", file );
                    return null;
                }
            }
        } ).filter( Predicates.notNull() );
    }

    public void save() {
        for (final MPUser user : getUsers())
            try {
                new CharSink() {
                    @Override
                    public Writer openStream()
                            throws IOException {
                        return new FileWriter( new File(userFilesDirectory, user.getFullName() + ".mpsites" ) );
                    }
                }.write( MPSiteMarshaller.marshallSafe( user ).getExport() );
            }
            catch (IOException e) {
                logger.err( e, "Unable to save sites for user: %s", user );
            }
    }
}
