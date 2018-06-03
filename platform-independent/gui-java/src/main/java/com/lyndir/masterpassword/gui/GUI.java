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

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Charsets;
import com.google.common.io.CharSource;
import com.google.common.io.Resources;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.TypeUtils;
import com.lyndir.masterpassword.gui.view.PasswordFrame;
import com.lyndir.masterpassword.gui.view.UnlockFrame;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.net.URI;
import java.net.URL;
import java.util.Enumeration;
import java.util.Optional;
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

    private final UnlockFrame         unlockFrame = new UnlockFrame( this );
    private       PasswordFrame<?, ?> passwordFrame;

    public static void main(final String... args) {
        if (Config.get().checkForUpdates())
            checkUpdate();

        // Try and set the system look & feel, if available.
        try {
            UIManager.setLookAndFeel( UIManager.getSystemLookAndFeelClassName() );
        }
        catch (final UnsupportedLookAndFeelException | ClassNotFoundException | InstantiationException | IllegalAccessException ignored) {
        }

        try {
            // AppleGUI adds support for macOS features.
            Optional<Class<GUI>> appleGUI = TypeUtils.loadClass( "com.lyndir.masterpassword.gui.platform.mac.AppleGUI" );
            if (appleGUI.isPresent())
                appleGUI.get().getConstructor().newInstance().open();

            else // No special platform handling.
                new GUI().open();
        }
        catch (final IllegalAccessException | InstantiationException | NoSuchMethodException | InvocationTargetException e) {
            throw logger.bug( e );
        }
    }

    private static void checkUpdate() {
        try {
            Enumeration<URL> manifestURLs = Thread.currentThread().getContextClassLoader().getResources( JarFile.MANIFEST_NAME );
            while (manifestURLs.hasMoreElements())
                try (InputStream manifestStream = manifestURLs.nextElement().openStream()) {
                    Attributes attributes = new Manifest( manifestStream ).getMainAttributes();
                    if (!GUI.class.getCanonicalName().equals( attributes.getValue( Attributes.Name.MAIN_CLASS ) ))
                        continue;

                    String     manifestRevision    = attributes.getValue( Attributes.Name.IMPLEMENTATION_VERSION );
                    String     upstreamRevisionURL = "https://masterpassword.app/masterpassword-gui.jar.rev";
                    CharSource upstream            = Resources.asCharSource( URI.create( upstreamRevisionURL ).toURL(), Charsets.UTF_8 );
                    String     upstreamRevision    = upstream.readFirstLine();
                    if ((manifestRevision != null) && (upstreamRevision != null) && !manifestRevision.equalsIgnoreCase(
                            upstreamRevision )) {
                        logger.inf( "Local Revision:    <%s>", manifestRevision );
                        logger.inf( "Upstream Revision: <%s>", upstreamRevision );
                        logger.wrn( "You are not running the current official version.  Please update from:%n%s",
                                    "https://masterpassword.app/masterpassword-gui.jar" );
                        JOptionPane.showMessageDialog( null,
                                                       strf( "A new version of Master Password is available.%n "
                                                             + "Please download the latest version from %s",
                                                             "https://masterpassword.app" ),
                                                       "Update Available", JOptionPane.WARNING_MESSAGE );
                    }
                }
                catch (final IOException e) {
                    logger.wrn( e, "Couldn't check for version update." );
                }
        }
        catch (final IOException e) {
            logger.wrn( e, "Couldn't inspect JAR." );
        }
    }

    protected void open() {
        SwingUtilities.invokeLater( () -> {
            if (passwordFrame == null)
                unlockFrame.setVisible( true );
            else
                passwordFrame.setVisible( true );
        } );
    }

    @Override
    public void signedIn(final PasswordFrame<?, ?> passwordFrame) {
        this.passwordFrame = passwordFrame;
        open();
    }
}
