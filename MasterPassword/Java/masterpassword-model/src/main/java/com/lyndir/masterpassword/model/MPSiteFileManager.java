package com.lyndir.masterpassword.model;

import com.google.common.io.CharSink;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.io.*;


/**
 * @author lhunath, 14-12-07
 */
public class MPSiteFileManager extends MPSiteManager {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPSiteFileManager.class );

    private final File file;

    public static MPSiteFileManager create(final File file) {
        try {
            return new MPSiteFileManager( file );
        }
        catch (IOException e) {
            throw logger.bug( e, "Unable to open sites from file: %s", file );
        }
    }

    protected MPSiteFileManager(final File file)
            throws IOException {

        super( MPSiteUnmarshaller.unmarshall( file ).getUser() );
        this.file = file;
    }

    public void save() {
        try {
            new CharSink() {
                @Override
                public Writer openStream()
                        throws IOException {
                    return new FileWriter( file );
                }
            }.write( MPSiteMarshaller.marshallSafe( getUser() ).getExport() );
        }
        catch (IOException e) {
            logger.err( e, "Unable to save sites to file: %s", file );
        }
    }

    public File getFile() {
        return file;
    }
}
