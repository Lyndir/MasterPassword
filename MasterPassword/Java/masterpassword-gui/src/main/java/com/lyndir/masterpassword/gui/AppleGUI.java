package com.lyndir.masterpassword.gui;

import com.apple.eawt.*;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-10
 */
public class AppleGUI extends GUI {

    public AppleGUI() {

        Application application = Application.getApplication();
        application.addAppEventListener( new AppForegroundListener() {

            @Override
            public void appMovedToBackground(AppEvent.AppForegroundEvent arg0) {
            }

            @Override
            public void appRaisedToForeground(AppEvent.AppForegroundEvent arg0) {
                open();
            }
        } );
        application.addAppEventListener( new AppReOpenedListener() {
            @Override
            public void appReOpened(AppEvent.AppReOpenedEvent arg0) {
                open();
            }
        } );
    }

    @Override
    protected PasswordFrame newPasswordFrame(final User user) {
        PasswordFrame frame = super.newPasswordFrame( user );
        frame.setDefaultCloseOperation( WindowConstants.DISPOSE_ON_CLOSE );

        return frame;
    }
}
