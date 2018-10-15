package com.lyndir.masterpassword.gui.util.platform;

import com.apple.eawt.*;
import com.apple.eio.FileManager;
import com.google.common.base.Preconditions;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.io.*;
import java.net.URI;


/**
 * @author lhunath, 2018-07-29
 */
public class ApplePlatform implements IPlatform {

    private static final Logger      logger      = Logger.get( ApplePlatform.class );
    private static final Application application = Preconditions.checkNotNull(
            Application.getApplication(), "Not an Apple Java application." );

    private AppForegroundListener appForegroundHandler;
    private AppReOpenedListener appReopenHandler;

    @Override
    public boolean installAppForegroundHandler(final Runnable handler) {
        if (appForegroundHandler == null)
            application.addAppEventListener( appForegroundHandler = new AppForegroundListener() {
                @Override
                public void appMovedToBackground(final AppEvent.AppForegroundEvent e) {
                }

                @Override
                public void appRaisedToForeground(final AppEvent.AppForegroundEvent e) {
                    handler.run();
                }
            } );

        return true;
    }

    @Override
    public boolean removeAppForegroundHandler() {
        if (appForegroundHandler == null)
            return false;

        application.removeAppEventListener( appForegroundHandler );
        return true;
    }

    @Override
    public boolean installAppReopenHandler(final Runnable handler) {
        application.addAppEventListener( appReopenHandler = e -> handler.run() );
        return true;
    }

    @Override
    public boolean removeAppReopenHandler() {
        if (appReopenHandler == null)
            return false;

        application.removeAppEventListener( appReopenHandler );
        return true;
    }

    @Override
    public boolean requestForeground() {
        application.requestForeground( true );
        return true;
    }

    @Override
    public boolean show(final File file) {
        try {
            return FileManager.revealInFinder( file );
        }
        catch (final FileNotFoundException e) {
            logger.err( e, "While showing: %s", file );
            return false;
        }
    }

    @Override
    public boolean open(final URI url) {
        try {
            FileManager.openURL( url.toString() );
            return true;
        }
        catch (final IOException e) {
            logger.err( e, "While opening: %s", url );
            return false;
        }
    }
}
