package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.lyndir.masterpassword.util.Components;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;


/**
 * @author lhunath, 2014-06-08
 */
public class UnlockFrame extends JFrame {

    private final SignInCallback signInCallback;
    private final JPanel         root;
    private final JButton        signInButton;
    private final JPanel         authenticationContainer;
    private       boolean        incognito;
    public        User           user;

    public UnlockFrame(final SignInCallback signInCallback)
            throws HeadlessException {
        super( "Unlock Master Password" );
        this.signInCallback = signInCallback;

        setDefaultCloseOperation( DISPOSE_ON_CLOSE );
        setContentPane( root = new JPanel( new BorderLayout( 20, 20 ) ) );
        root.setBorder( new EmptyBorder( 20, 20, 20, 20 ) );

        authenticationContainer = new JPanel();
        authenticationContainer.setLayout( new BoxLayout( authenticationContainer, BoxLayout.PAGE_AXIS ) );
        authenticationContainer.setBorder( new CompoundBorder( new EtchedBorder( EtchedBorder.RAISED ), new EmptyBorder( 8, 8, 8, 8 ) ) );
        add( authenticationContainer );

        // Sign In
        root.add( Components.boxLayout( BoxLayout.LINE_AXIS, Box.createGlue(), signInButton = new JButton( "Sign In" ), Box.createGlue() ),
                  BorderLayout.SOUTH );
        signInButton.setFont( Res.exoRegular().deriveFont( 12f ) );
        signInButton.setAlignmentX( LEFT_ALIGNMENT );
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
        setPreferredSize( null );
        pack();
        setMinimumSize( getSize() );
        setPreferredSize( new Dimension( 300, 300 ) );
        pack();
    }

    private void createAuthenticationPanel() {
        authenticationContainer.removeAll();

        final AuthenticationPanel authenticationPanel;
        if (incognito) {
            authenticationPanel = new IncognitoAuthenticationPanel( this );
        } else {
            authenticationPanel = new ModelAuthenticationPanel( this );
        }
        authenticationPanel.updateUser( false );
        authenticationContainer.add( authenticationPanel, BorderLayout.CENTER );

        final JCheckBox incognitoCheckBox = new JCheckBox( "Incognito" );
        incognitoCheckBox.setFont( Res.exoRegular().deriveFont( 12f ) );
        incognitoCheckBox.setAlignmentX( LEFT_ALIGNMENT );
        incognitoCheckBox.setSelected( incognito );
        incognitoCheckBox.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(final ItemEvent e) {
                incognito = incognitoCheckBox.isSelected();
                SwingUtilities.invokeLater( new Runnable() {
                    @Override
                    public void run() {
                        createAuthenticationPanel();
                    }
                } );
            }
        } );

        JComponent toolsPanel = Components.boxLayout( BoxLayout.LINE_AXIS, incognitoCheckBox, Box.createGlue() );
        toolsPanel.setAlignmentX( Component.LEFT_ALIGNMENT );
        authenticationContainer.add( toolsPanel );
        for (JButton button : authenticationPanel.getButtons()) {
            button.setMargin( new Insets( 0, 0, 0, 0 ) );
            button.setAlignmentX( RIGHT_ALIGNMENT );
            button.setBorder( null );
            toolsPanel.add( button );
        }

        checkSignIn();
        validate();
        repack();

        SwingUtilities.invokeLater( new Runnable() {
            @Override
            public void run() {
                ifNotNullElse( authenticationPanel.getFocusComponent(), signInButton ).requestFocusInWindow();
            }
        } );
    }

    void setUser(User user) {
        this.user = user;
        checkSignIn();
    }

    boolean checkSignIn() {
        boolean enabled = user != null && !user.getFullName().isEmpty() && user.hasKey();
        signInButton.setEnabled( enabled );

        return enabled;
    }

    void trySignIn(final JComponent... signInComponents) {
        if (!checkSignIn()) {
            return;
        }

        for (JComponent signInComponent : signInComponents) {
            signInComponent.setEnabled( false );
        }

        signInButton.setEnabled( false );
        signInButton.setText( "Signing In..." );

        Res.execute( new Runnable() {
            @Override
            public void run() {
                final boolean success = signInCallback.signedIn( user );

                SwingUtilities.invokeLater( new Runnable() {
                    @Override
                    public void run() {
                        if (success) {
                            dispose();
                            return;
                        }

                        signInButton.setText( "Sign In" );
                        for (JComponent signInComponent : signInComponents) {
                            signInComponent.setEnabled( true );
                        }
                        checkSignIn();
                    }
                } );
            }
        } );
    }

    interface SignInCallback {

        boolean signedIn(User user);
    }
}
