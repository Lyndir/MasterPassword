package com.lyndir.masterpassword.gui;

import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
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
        JLabel fullNameLabel = new JLabel( "Full Name:" );
        fullNameLabel.setFont( Res.exoRegular().deriveFont( 12f ) );
        fullNameLabel.setAlignmentX( LEFT_ALIGNMENT );
        fullNameLabel.setHorizontalAlignment( SwingConstants.CENTER );
        fullNameLabel.setVerticalAlignment( SwingConstants.BOTTOM );
        add( fullNameLabel );

        fullNameField = new JTextField() {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
        fullNameField.setFont( Res.sourceCodeProRegular().deriveFont( 12f ) );
        fullNameField.setAlignmentX( LEFT_ALIGNMENT );
        fullNameField.getDocument().addDocumentListener( this );
        fullNameField.addActionListener( this );
        add( fullNameField );

        // Master Password
        JLabel masterPasswordLabel = new JLabel( "Master Password:" );
        masterPasswordLabel.setFont( Res.exoRegular().deriveFont( 12f ) );
        masterPasswordLabel.setAlignmentX( LEFT_ALIGNMENT );
        masterPasswordLabel.setHorizontalAlignment( SwingConstants.CENTER );
        masterPasswordLabel.setVerticalAlignment( SwingConstants.BOTTOM );
        add( masterPasswordLabel );

        masterPasswordField = new JPasswordField() {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
        masterPasswordField.setAlignmentX( LEFT_ALIGNMENT );
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
        return new IncognitoUser( fullNameField.getText(), new String( masterPasswordField.getPassword() ) );
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
