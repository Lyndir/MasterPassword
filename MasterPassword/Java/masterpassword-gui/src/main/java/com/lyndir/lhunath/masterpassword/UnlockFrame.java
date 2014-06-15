package com.lyndir.lhunath.masterpassword;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.lyndir.lhunath.masterpassword.util.Components;
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
    private       boolean        useConfig;
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
        signInButton.setAlignmentX( LEFT_ALIGNMENT );
        signInButton.addActionListener( new AbstractAction() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                trySignIn();
            }
        } );

        useConfig = ConfigAuthenticationPanel.hasConfigUsers();
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
        if (useConfig) {
            authenticationPanel = new ConfigAuthenticationPanel( this );
        } else {
            authenticationPanel = new TextAuthenticationPanel( this );
        }
        authenticationPanel.updateUser( false );
        authenticationContainer.add( authenticationPanel, BorderLayout.CENTER );

        final JCheckBox typeCheckBox = new JCheckBox( "Use Config File" );
        typeCheckBox.setAlignmentX( LEFT_ALIGNMENT );
        typeCheckBox.setSelected( useConfig );
        typeCheckBox.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(final ItemEvent e) {
                useConfig = typeCheckBox.isSelected();
                SwingUtilities.invokeLater( new Runnable() {
                    @Override
                    public void run() {
                        createAuthenticationPanel();
                    }
                } );
            }
        } );

        JButton typeHelp = new JButton( Res.iconQuestion() );
        typeHelp.setMargin( new Insets( 0, 0, 0, 0 ) );
        typeHelp.setBackground( Color.red );
        typeHelp.setAlignmentX( RIGHT_ALIGNMENT );
        typeHelp.setBorder( null );
        typeHelp.addActionListener( new ActionListener() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                JOptionPane.showMessageDialog( UnlockFrame.this, authenticationPanel.getHelpText(), "Help",
                                               JOptionPane.INFORMATION_MESSAGE );
            }
        } );
        if (authenticationPanel.getHelpText() == null) {
            typeHelp.setVisible( false );
        }
        JComponent typePanel = Components.boxLayout( BoxLayout.LINE_AXIS, typeCheckBox, Box.createGlue(), typeHelp );
        typePanel.setAlignmentX( Component.LEFT_ALIGNMENT );
        authenticationContainer.add( typePanel );

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
        boolean enabled = user != null && !user.getName().isEmpty() && user.hasKey();
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
