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
package com.lyndir.masterpassword;

import com.lyndir.lhunath.opal.system.util.TypeUtils;
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

        GUI gui;
        try {
            gui = TypeUtils.newInstance( AppleGUI.class );
        } catch (RuntimeException e) {
            gui = new GUI();
        }
        gui.open();
    }

    void open() {
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
    public boolean signedIn(final User user) {
        if (!user.hasKey()) {
            return false;
        }
        user.getKey();

        passwordFrame = new PasswordFrame( user );

        open();
        return true;
    }
}
