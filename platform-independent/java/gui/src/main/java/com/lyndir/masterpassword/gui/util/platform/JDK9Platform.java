package com.lyndir.masterpassword.gui.util.platform;

import java.awt.*;
import java.awt.desktop.*;
import java.io.File;


/**
 * @author lhunath, 2018-07-29
 */
@SuppressWarnings("Since15")
public class JDK9Platform implements IPlatform {

    @Override
    public boolean installAppForegroundHandler(final Runnable handler) {
        Desktop.getDesktop().addAppEventListener( new AppForegroundListener() {
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
        Desktop.getDesktop().addAppEventListener( (AppReopenedListener) e -> handler.run() );
        return true;
    }

    @Override
    public boolean show(final File file) {
        if (!file.exists())
            return false;

        Desktop.getDesktop().browseFileDirectory( file );
        return true;
    }
}
