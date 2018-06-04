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

package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.lyndir.masterpassword.MPAlgorithmException;
import com.lyndir.masterpassword.MPIdenticon;
import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.*;
import java.awt.*;
import java.awt.event.*;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import javax.annotation.Nullable;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-08
 */
@SuppressWarnings({ "MagicNumber", "serial" })
public class UnlockFrame extends JFrame {

    private final SignInCallback              signInCallback;
    private final Components.GradientPanel    root;
    private final JLabel                      identiconLabel;
    private final JButton                     signInButton;
    private final JPanel                      authenticationContainer;
    private       AuthenticationPanel<?>      authenticationPanel;
    private       Future<?>                   identiconFuture;
    private       boolean                     incognito;
    @Nullable
    private       MPUser<? extends MPSite<?>> user;

    public UnlockFrame(final SignInCallback signInCallback) {
        super( "Unlock Master Password" );
        this.signInCallback = signInCallback;

        setDefaultCloseOperation( DISPOSE_ON_CLOSE );
        addWindowFocusListener( new WindowAdapter() {
            @Override
            public void windowGainedFocus(final WindowEvent e) {
                root.setGradientColor( Res.colors().frameBg() );
            }

            @Override
            public void windowLostFocus(final WindowEvent e) {
                root.setGradientColor( Color.RED );
            }
        } );

        // Sign In
        JPanel signInBox = Components.boxLayout( BoxLayout.LINE_AXIS, Box.createGlue(), signInButton = Components.button( "Sign In" ),
                                                 Box.createGlue() );
        signInBox.setBackground( null );

        setContentPane( root = Components.gradientPanel( new FlowLayout(), Res.colors().frameBg() ) );
        root.setLayout( new BoxLayout( root, BoxLayout.PAGE_AXIS ) );
        root.setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
        root.add( Components.borderPanel( authenticationContainer = Components.boxLayout( BoxLayout.PAGE_AXIS ),
                                          BorderFactory.createRaisedBevelBorder(), Res.colors().frameBg() ) );
        root.add( Box.createVerticalStrut( 8 ) );
        root.add( identiconLabel = Components.label( " ", SwingConstants.CENTER ) );
        root.add( Box.createVerticalStrut( 8 ) );
        root.add( signInBox );

        authenticationContainer.setOpaque( true );
        authenticationContainer.setBackground( Res.colors().controlBg() );
        authenticationContainer.setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
        identiconLabel.setFont( Res.emoticonsFont().deriveFont( 14.f ) );
        identiconLabel.setToolTipText(
                strf( "A representation of your identity across all Master Password apps.%nIt should always be the same." ) );
        signInButton.addActionListener( new AbstractAction() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                trySignIn();
            }
        } );

        createAuthenticationPanel();

        setLocationByPlatform( true );
        setLocationRelativeTo( null );
    }

    protected void repack() {
        pack();
        setMinimumSize( new Dimension( Math.max( 300, getPreferredSize().width ), Math.max( 300, getPreferredSize().height ) ) );
        pack();
    }

    private void createAuthenticationPanel() {
        authenticationContainer.removeAll();

        if (incognito) {
            authenticationPanel = new IncognitoAuthenticationPanel( this );
        } else {
            authenticationPanel = new ModelAuthenticationPanel( this );
        }
        authenticationPanel.updateUser( false );
        authenticationContainer.add( authenticationPanel );
        authenticationContainer.add( Components.stud() );

        JCheckBox incognitoCheckBox = Components.checkBox( "Incognito" );
        incognitoCheckBox.setToolTipText( "Log in without saving any information." );
        incognitoCheckBox.setSelected( incognito );
        incognitoCheckBox.addItemListener( e -> {
            incognito = incognitoCheckBox.isSelected();
            SwingUtilities.invokeLater( this::createAuthenticationPanel );
        } );

        JComponent toolsPanel = Components.boxLayout( BoxLayout.LINE_AXIS, incognitoCheckBox, Box.createGlue() );
        authenticationContainer.add( toolsPanel );
        for (final JButton button : authenticationPanel.getButtons()) {
            toolsPanel.add( button );
            button.setBorder( BorderFactory.createEmptyBorder() );
            button.setMargin( new Insets( 0, 0, 0, 0 ) );
            button.setAlignmentX( RIGHT_ALIGNMENT );
            button.setContentAreaFilled( false );
        }

        checkSignIn();
        validate();
        repack();

        SwingUtilities.invokeLater( () -> ifNotNullElse( authenticationPanel.getFocusComponent(), signInButton ).requestFocusInWindow() );
    }

    void updateUser(@Nullable final MPUser<? extends MPSite<?>> user) {
        this.user = user;
        checkSignIn();
    }

    boolean checkSignIn() {
        if (identiconFuture != null)
            identiconFuture.cancel( false );
        identiconFuture = Res.schedule( this, () -> SwingUtilities.invokeLater( () -> {
            String fullName       = (user == null)? "": user.getFullName();
            char[] masterPassword = authenticationPanel.getMasterPassword();

            if (fullName.isEmpty() || (masterPassword.length == 0)) {
                identiconLabel.setText( " " );
                return;
            }

            MPIdenticon identicon = new MPIdenticon( fullName, masterPassword );
            identiconLabel.setText( identicon.getText() );
            identiconLabel.setForeground(
                    Res.colors().fromIdenticonColor( identicon.getColor(), Res.Colors.BackgroundMode.DARK ) );
        } ), 300, TimeUnit.MILLISECONDS );

        String  fullName       = (user == null)? "": user.getFullName();
        char[]  masterPassword = authenticationPanel.getMasterPassword();
        boolean enabled        = !fullName.isEmpty() && (masterPassword.length > 0);
        signInButton.setEnabled( enabled );

        return enabled;
    }

    void trySignIn(final JComponent... signInComponents) {
        if ((user == null) || !checkSignIn())
            return;

        for (final JComponent signInComponent : signInComponents)
            signInComponent.setEnabled( false );

        signInButton.setEnabled( false );
        signInButton.setText( "Signing In..." );

        Res.execute( this, () -> {
            try {
                user.authenticate( authenticationPanel.getMasterPassword() );

                SwingUtilities.invokeLater( () -> {
                    signInCallback.signedIn( authenticationPanel.newPasswordFrame() );
                    dispose();
                } );
            }
            catch (final MPIncorrectMasterPasswordException | MPAlgorithmException e) {
                SwingUtilities.invokeLater( () -> {
                    JOptionPane.showMessageDialog( null, e.getLocalizedMessage(), "Sign In Failed", JOptionPane.ERROR_MESSAGE );
                    authenticationPanel.reset();
                    signInButton.setText( "Sign In" );
                    for (final JComponent signInComponent : signInComponents)
                        signInComponent.setEnabled( true );
                    checkSignIn();
                } );
            }
        } );
    }

    @FunctionalInterface
    public interface SignInCallback {

        void signedIn(PasswordFrame<?, ?> passwordFrame);
    }
}
