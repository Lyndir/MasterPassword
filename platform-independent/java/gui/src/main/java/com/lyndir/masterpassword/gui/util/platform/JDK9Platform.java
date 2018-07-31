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

    @Override
    public boolean installAppForegroundHandler(final Runnable handler) {
        desktop.addAppEventListener( new AppForegroundListener() {
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
    public boolean installAppReopenHandler(final Runnable handler) {
        desktop.addAppEventListener( (AppReopenedListener) e -> handler.run() );
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
