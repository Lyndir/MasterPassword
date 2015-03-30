package com.lyndir.masterpassword.gui;

import com.lyndir.masterpassword.gui.util.Components;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import org.jetbrains.annotations.NotNull;


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

    @NotNull
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
