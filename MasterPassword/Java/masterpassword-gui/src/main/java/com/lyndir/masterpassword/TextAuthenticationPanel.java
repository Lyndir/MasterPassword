package com.lyndir.masterpassword;

import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;


/**
 * @author lhunath, 2014-06-11
 */
public class TextAuthenticationPanel extends AuthenticationPanel implements DocumentListener, ActionListener {

    private final JTextField     userNameField;
    private final JPasswordField masterPasswordField;

    public TextAuthenticationPanel(final UnlockFrame unlockFrame) {

        // User Name
        super( unlockFrame );
        JLabel userNameLabel = new JLabel( "User Name:" );
        userNameLabel.setAlignmentX( Component.LEFT_ALIGNMENT );
        userNameLabel.setHorizontalAlignment( SwingConstants.CENTER );
        userNameLabel.setVerticalAlignment( SwingConstants.BOTTOM );
        add( userNameLabel );

        userNameField = new JTextField() {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
        userNameField.setAlignmentX( Component.LEFT_ALIGNMENT );
        userNameField.getDocument().addDocumentListener( this );
        userNameField.addActionListener( this );
        add( userNameField );

        // Master Password
        JLabel masterPasswordLabel = new JLabel( "Master Password:" );
        masterPasswordLabel.setAlignmentX( Component.LEFT_ALIGNMENT );
        masterPasswordLabel.setHorizontalAlignment( SwingConstants.CENTER );
        masterPasswordLabel.setVerticalAlignment( SwingConstants.BOTTOM );
        add( masterPasswordLabel );

        masterPasswordField = new JPasswordField() {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
        masterPasswordField.setAlignmentX( Component.LEFT_ALIGNMENT );
        masterPasswordField.addActionListener( this );
        masterPasswordField.getDocument().addDocumentListener( this );
        add( masterPasswordField );
    }

    @Override
    public Component getFocusComponent() {
        return userNameField;
    }

    @Override
    protected User getUser() {
        return new User( userNameField.getText(), new String( masterPasswordField.getPassword() ) );
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
        unlockFrame.trySignIn( userNameField, masterPasswordField );
    }
}
