//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================


package com.lyndir.masterpassword.gui;

import com.google.common.base.Charsets;
import com.google.common.io.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.TypeUtils;

import com.lyndir.masterpassword.gui.model.User;
import com.lyndir.masterpassword.gui.view.PasswordFrame;
import com.lyndir.masterpassword.gui.view.UnlockFrame;
import java.io.*;
import java.net.URI;
import java.net.URL;
import java.util.Enumeration;
import java.util.jar.*;
import javax.swing.*;


/**
 * <p> <i>Jun 10, 2008</i> </p>
 *
 * @author mbillemo
 */
public class GUI implements UnlockFrame.SignInCallback {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( GUI.class );

    protected final UnlockFrame unlockFrame = new UnlockFrame( this );
    private PasswordFrame passwordFrame;

    public static void main(final String... args) {

        if (Config.get().checkForUpdates())
            checkUpdate();

        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        }
        catch (UnsupportedLookAndFeelException | ClassNotFoundException | InstantiationException | IllegalAccessException ignored) {
        }

        TypeUtils.<GUI>newInstance( "com.lyndir.masterpassword.gui.platform.mac.AppleGUI" ).or( new GUI() ).open();
    }

    private static void checkUpdate() {
        try {
            Enumeration<URL> manifestURLs = Thread.currentThread().getContextClassLoader().getResources( JarFile.MANIFEST_NAME );
            while (manifestURLs.hasMoreElements()) {
                InputStream manifestStream = manifestURLs.nextElement().openStream();
                Attributes attributes = new Manifest( manifestStream ).getMainAttributes();
                if (!GUI.class.getCanonicalName().equals( attributes.getValue( Attributes.Name.MAIN_CLASS ) ))
                    continue;

                String manifestRevision = attributes.getValue( Attributes.Name.IMPLEMENTATION_VERSION );
                String upstreamRevisionURL = "http://masterpasswordapp.com/masterpassword-gui.jar.rev";
                CharSource upstream = Resources.asCharSource( URI.create( upstreamRevisionURL ).toURL(), Charsets.UTF_8 );
                String upstreamRevision = upstream.readFirstLine();
                logger.inf( "Local Revision:    <%s>", manifestRevision );
                logger.inf( "Upstream Revision: <%s>", upstreamRevision );
                if ((manifestRevision != null) && !manifestRevision.equalsIgnoreCase( upstreamRevision )) {
                    logger.wrn( "You are not running the current official version.  Please update from:\n"
                                + "http://masterpasswordapp.com/masterpassword-gui.jar" );
                    JOptionPane.showMessageDialog( null, "A new version of Master Password is available.\n"
                                                         + "Please download the latest version from http://masterpasswordapp.com",
                                                   "Update Available", JOptionPane.WARNING_MESSAGE );
                }
            }
        }
        catch (final IOException e) {
            logger.wrn( e, "Couldn't check for version update." );
        }
    }

    protected void open() {
        SwingUtilities.invokeLater( new Runnable() {
            @Override
            public void run() {
                if (passwordFrame == null)
                    unlockFrame.setVisible( true );
                else
                    passwordFrame.setVisible( true );
            }
        } );
    }

    @Override
    public void signedIn(final User user) {
        passwordFrame = newPasswordFrame( user );
        open();
    }

    protected PasswordFrame newPasswordFrame(final User user) {
        return new PasswordFrame( user );
    }
}
