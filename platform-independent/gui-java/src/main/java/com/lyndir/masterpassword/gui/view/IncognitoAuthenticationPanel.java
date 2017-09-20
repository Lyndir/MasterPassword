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

import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.model.IncognitoUser;
import com.lyndir.masterpassword.gui.model.User;
import com.lyndir.masterpassword.gui.util.Components;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.annotation.Nonnull;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;


/**
 * @author lhunath, 2014-06-11
 */
public class IncognitoAuthenticationPanel extends AuthenticationPanel implements DocumentListener, ActionListener {

    private final JTextField     fullNameField;
    private final JPasswordField masterPasswordField;

    public IncognitoAuthenticationPanel(final UnlockFrame unlockFrame) {

        // Full Name
        super( unlockFrame );
        add( Components.stud() );

        JLabel fullNameLabel = Components.label( "Full Name:" );
        add( fullNameLabel );

        fullNameField = Components.textField();
        fullNameField.setFont( Res.valueFont().deriveFont( 12f ) );
        fullNameField.getDocument().addDocumentListener( this );
        fullNameField.addActionListener( this );
        add( fullNameField );
        add( Components.stud() );

        // Master Password
        JLabel masterPasswordLabel = Components.label( "Master Password:" );
        add( masterPasswordLabel );

        masterPasswordField = Components.passwordField();
        masterPasswordField.addActionListener( this );
        masterPasswordField.getDocument().addDocumentListener( this );
        add( masterPasswordField );
    }

    @Override
    public Component getFocusComponent() {
        return fullNameField;
    }

    @Override
    public void reset() {
        masterPasswordField.setText( "" );
    }

    @Override
    protected User getSelectedUser() {
        return new IncognitoUser( fullNameField.getText() );
    }

    @Nonnull
    @Override
    public char[] getMasterPassword() {
        return masterPasswordField.getPassword();
    }

    @Override
    public void insertUpdate(final DocumentEvent e) {
        updateUser( false );
    }

    @Override
    public void removeUpdate(final DocumentEvent e) {
        updateUser( false );
    }

    @Override
    public void changedUpdate(final DocumentEvent e) {
        updateUser( false );
    }

    @Override
    public void actionPerformed(final ActionEvent e) {
        updateUser( false );
        unlockFrame.trySignIn( fullNameField, masterPasswordField );
    }
}
