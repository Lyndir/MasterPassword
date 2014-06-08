/*
 *   Copyright 2008, Maarten Billemont
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */
package com.lyndir.lhunath.masterpassword;

import com.apple.eawt.*;
import java.io.IOException;
import javax.swing.*;


/**
 * <p> <i>Jun 10, 2008</i> </p>
 *
 * @author mbillemo
 */
public class GUI implements UnlockFrame.SignInCallback {

    private UnlockFrame unlockFrame = new UnlockFrame( this );
    private PasswordFrame passwordFrame;

    public static void main(final String[] args)
            throws IOException {

        new GUI().open();
    }

    public GUI() {

        try {
            getClass().getClassLoader().loadClass( "com.apple.eawt.Application" );
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
        catch (ClassNotFoundException | NoClassDefFoundError ignored) {
        }
    }

    private void open() {
        SwingUtilities.invokeLater( new Runnable() {
            @Override
            public void run() {
                if (passwordFrame == null) {
                    unlockFrame.setVisible( true );
                } else {
                    passwordFrame.setVisible( true );
                }
            }
        } );
    }

    @Override
    public boolean signedIn(final String userName, final String masterPassword) {
        final byte[] key = MasterPassword.keyForPassword( masterPassword, userName );
        passwordFrame = new PasswordFrame( new User( userName, key ) );

        open();
        return true;
    }
}
