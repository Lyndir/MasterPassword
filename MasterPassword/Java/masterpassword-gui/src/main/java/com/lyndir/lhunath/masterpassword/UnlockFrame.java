package com.lyndir.lhunath.masterpassword;

import com.google.common.io.Resources;
import com.lyndir.lhunath.masterpassword.util.Components;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;


/**
 * @author lhunath, 2014-06-08
 */
public class UnlockFrame extends JFrame implements DocumentListener {

    private static final ExecutorService executor = Executors.newSingleThreadExecutor();

    private final SignInCallback signInCallback;
    private final JPanel     root;
    private final JLabel     avatarView;
    private final JTextField userNameField;
    private final JTextField masterPasswordField;
    private final JButton    signInButton;

    public UnlockFrame(final SignInCallback signInCallback)
            throws HeadlessException {
        super( "Unlock Master Password" );
        this.signInCallback = signInCallback;

        JLabel label;

        setDefaultCloseOperation( DISPOSE_ON_CLOSE );
        setContentPane( root = new JPanel( new BorderLayout( 20, 20 ) ) );
        root.setBorder( new EmptyBorder( 20, 20, 20, 20 ) );

        JPanel userAndPassword = new JPanel();
        userAndPassword.setLayout( new BoxLayout( userAndPassword, BoxLayout.PAGE_AXIS ) );
        userAndPassword.setBorder( new CompoundBorder( new EtchedBorder( EtchedBorder.RAISED ), new EmptyBorder( 8, 8, 8, 8 ) ) );
        add( userAndPassword, BorderLayout.CENTER );

        // Avatar
        userAndPassword.add( Box.createVerticalGlue() );
        userAndPassword.add( avatarView = new JLabel( new ImageIcon( Resources.getResource( "media/Avatars/avatar-0.png" ) ) ) {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, Integer.MAX_VALUE );
            }
        } );
        userAndPassword.add( Box.createVerticalGlue() );

        // User Name
        userAndPassword.add( label = new JLabel( "User Name:" ) );
        label.setHorizontalAlignment( SwingConstants.CENTER );
        label.setVerticalAlignment( SwingConstants.BOTTOM );
        userAndPassword.add( userNameField = new JTextField() {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        } );
        userNameField.getDocument().addDocumentListener( this );
        userNameField.addActionListener( new AbstractAction() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                trySignIn();
            }
        } );

        // Master Password
        userAndPassword.add( label = new JLabel( "Master Password:" ) );
        label.setHorizontalAlignment( SwingConstants.CENTER );
        label.setVerticalAlignment( SwingConstants.BOTTOM );
        userAndPassword.add( masterPasswordField = new JPasswordField() {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        } );
        masterPasswordField.getDocument().addDocumentListener( this );
        masterPasswordField.addActionListener( new AbstractAction() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                trySignIn();
            }
        } );

        // Sign In
        add( Components.boxLayout( BoxLayout.LINE_AXIS, Box.createGlue(), signInButton = new JButton( "Sign In" ), Box.createGlue() ),
             BorderLayout.SOUTH );
        signInButton.addActionListener( new AbstractAction() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                trySignIn();
            }
        } );

        checkSignIn();

        pack();
        setMinimumSize( getSize() );
        setPreferredSize( new Dimension( 300, 300 ) );
        pack();

        setLocationByPlatform( true );
        setLocationRelativeTo( null );
    }

    private boolean checkSignIn() {
        String userName = userNameField.getText();
        String masterPassword = masterPasswordField.getText();

        boolean enabled = !userName.isEmpty() && !masterPassword.isEmpty();
        signInButton.setEnabled( enabled );

        return enabled;
    }

    private void trySignIn() {
        if (!checkSignIn())
            return;

        final String userName = userNameField.getText();
        final String masterPassword = masterPasswordField.getText();

        userNameField.setEnabled( false );
        masterPasswordField.setEnabled( false );
        signInButton.setEnabled( false );
        signInButton.setText( "Signing In..." );

        executor.submit( new Runnable() {
            @Override
            public void run() {
                final boolean success = signInCallback.signedIn( userName, masterPassword );
                SwingUtilities.invokeLater( new Runnable() {
                    @Override
                    public void run() {
                        if (success) {
                            dispose();
                            return;
                        }

                        userNameField.setEnabled( true );
                        masterPasswordField.setEnabled( true );
                        signInButton.setText( "Sign In" );
                        checkSignIn();
                    }
                } );
            }
        } );
    }

    @Override
    public void insertUpdate(final DocumentEvent e) {
        checkSignIn();
    }

    @Override
    public void removeUpdate(final DocumentEvent e) {
        checkSignIn();
    }

    @Override
    public void changedUpdate(final DocumentEvent e) {
        checkSignIn();
    }

    interface SignInCallback {

        boolean signedIn(String userName, String masterPassword);
    }
}
