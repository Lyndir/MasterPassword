package com.lyndir.masterpassword.gui.util.platform;

import com.lyndir.lhunath.opal.system.logging.Logger;
import java.awt.*;
import java.awt.desktop.*;
import java.io.File;
import java.io.IOException;
import java.net.URI;


/**
 * @author lhunath, 2018-07-29
 */
@SuppressWarnings("Since15")
public class JDK9Platform implements IPlatform {

    private static final Logger  logger  = Logger.get( JDK9Platform.class );
    private static final Desktop desktop = Desktop.getDesktop();

    private AppForegroundListener appForegroundHandler;
    private AppReopenedListener   appReopenHandler;

    @Override
    public boolean installAppForegroundHandler(final Runnable handler) {
        if (appForegroundHandler == null)
            desktop.addAppEventListener( appForegroundHandler = new AppForegroundListener() {
                @Override
                public void appRaisedToForeground(final AppForegroundEvent e) {
                    handler.run();
                }

                @Override
                public void appMovedToBackground(final AppForegroundEvent e) {
                }
            } );

        return true;
    }

    @Override
    public boolean removeAppForegroundHandler() {
        if (appForegroundHandler == null)
            return false;

        desktop.removeAppEventListener( appForegroundHandler );
        return true;
    }

    @Override
    public boolean installAppReopenHandler(final Runnable handler) {
        if (appReopenHandler == null)
            desktop.addAppEventListener( appReopenHandler = e -> handler.run() );

        return true;
    }

    @Override
    public boolean removeAppReopenHandler() {
        if (appReopenHandler == null)
            return false;

        desktop.removeAppEventListener( appReopenHandler );
        return true;
    }

    @Override
    public boolean requestForeground() {
        desktop.requestForeground( true );
        return true;
    }

    @Override
    public boolean show(final File file) {
        if (!file.exists())
            return false;

        desktop.browseFileDirectory( file );
        return true;
    }

    @Override
    public boolean open(final URI url) {
        try {
            desktop.browse( url );
            return true;
        }
        catch (final IOException e) {
            logger.err( e, "While opening: %s", url );
            return false;
        }
    }
}
