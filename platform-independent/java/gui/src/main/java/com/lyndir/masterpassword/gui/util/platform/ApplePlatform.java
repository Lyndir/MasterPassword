package com.lyndir.masterpassword.gui.util.platform;

import com.apple.eawt.*;
import com.apple.eio.FileManager;
import com.google.common.base.Preconditions;
import com.google.common.base.Throwables;
import java.io.File;
import java.io.FileNotFoundException;


/**
 * @author lhunath, 2018-07-29
 */
public class ApplePlatform implements IPlatform {

    static Application application = Preconditions.checkNotNull(
            Application.getApplication(), "Not an Apple Java application." );

    @Override
    public boolean installAppForegroundHandler(final Runnable handler) {
        application.addAppEventListener( new AppForegroundListener() {
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
    public boolean installAppReopenHandler(final Runnable handler) {
        application.addAppEventListener( (AppReOpenedListener) e -> handler.run() );
        return true;
    }

    @Override
    public boolean show(final File file) {
        try {
            return FileManager.revealInFinder( file );
        }
        catch (final FileNotFoundException ignored) {
            return false;
        }
    }
}
