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

    private final SignInCallback      signInCallback;
    private final JPanel              root;
    private final JButton             signInButton;
    private final JPanel              authenticationContainer;
    private       AuthenticationPanel authenticationPanel;
    private       boolean             incognito;
    public        User                user;

    public UnlockFrame(final SignInCallback signInCallback)
            throws HeadlessException {
        super( "Unlock Master Password" );
        this.signInCallback = signInCallback;

        setDefaultCloseOperation( DISPOSE_ON_CLOSE );
        setContentPane( root = new JPanel( new BorderLayout( 20, 20 ) ) );
        root.setBackground( Res.colors().frameBg() );
        root.setBorder( new EmptyBorder( 20, 20, 20, 20 ) );

        authenticationContainer = Components.boxLayout( BoxLayout.PAGE_AXIS );
        authenticationContainer.setBackground( Res.colors().controlBg() );
        authenticationContainer.setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
        add( Components.bordered( authenticationContainer, BorderFactory.createRaisedBevelBorder(), Res.colors().frameBg() ) );

        // Sign In
        JPanel signInBox = Components.boxLayout( BoxLayout.LINE_AXIS, Box.createGlue(), signInButton = Components.button( "Sign In" ),
                                                 Box.createGlue() );
        signInBox.setBackground( null );
        root.add( signInBox, BorderLayout.SOUTH );
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

        final JCheckBox incognitoCheckBox = Components.checkBox( "Incognito" );
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
        if (!checkSignIn())
            return;

        for (JComponent signInComponent : signInComponents)
            signInComponent.setEnabled( false );

        signInButton.setEnabled( false );
        signInButton.setText( "Signing In..." );

        Res.execute( this, new Runnable() {
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

                        authenticationPanel.reset();
                        signInButton.setText( "Sign In" );
                        for (JComponent signInComponent : signInComponents)
                            signInComponent.setEnabled( true );
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
