package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.IncorrectMasterPasswordException;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-08
 */
public class UnlockFrame extends JFrame {

    private final SignInCallback           signInCallback;
    private final Components.GradientPanel root;
    private final JButton                  signInButton;
    private final JPanel                   authenticationContainer;
    private       AuthenticationPanel      authenticationPanel;
    private       boolean                  incognito;
    public        User                     user;

    public UnlockFrame(final SignInCallback signInCallback)
            throws HeadlessException {
        super( "Unlock Master Password" );
        this.signInCallback = signInCallback;

        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setContentPane(root = Components.gradientPanel(new BorderLayout(20, 20), Res.colors().frameBg()));
        root.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        addWindowFocusListener(new WindowAdapter() {
            @Override
            public void windowGainedFocus(WindowEvent e) {
                root.setGradientColor(Res.colors().frameBg());
            }

            @Override
            public void windowLostFocus(WindowEvent e) {
                root.setGradientColor(Color.RED);
            }
        });

        authenticationContainer = Components.boxLayout( BoxLayout.PAGE_AXIS );
        authenticationContainer.setOpaque( true );
        authenticationContainer.setBackground( Res.colors().controlBg() );
        authenticationContainer.setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
        add( Components.borderPanel( authenticationContainer, BorderFactory.createRaisedBevelBorder(), Res.colors().frameBg() ) );

        // Sign In
        JPanel signInBox = Components.boxLayout( BoxLayout.LINE_AXIS, Box.createGlue(), signInButton = Components.button( "Sign In" ),
                                                 Box.createGlue() );
        signInBox.setBackground( null );
        root.add( signInBox, BorderLayout.SOUTH );
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
        authenticationContainer.add( toolsPanel );
        for (JButton button : authenticationPanel.getButtons()) {
            toolsPanel.add( button );
            button.setMargin( new Insets( 0, 0, 0, 0 ) );
            button.setAlignmentX(RIGHT_ALIGNMENT);
            button.setContentAreaFilled(false);
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

    void updateUser(User user) {
        this.user = user;
        checkSignIn();
    }

    boolean checkSignIn() {
        boolean enabled = user != null && !user.getFullName().isEmpty() && authenticationPanel.getMasterPassword().length > 0;
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
                try {
                    user.authenticate( authenticationPanel.getMasterPassword() );

                    SwingUtilities.invokeLater( new Runnable() {
                        @Override
                        public void run() {
                            signInCallback.signedIn( user );
                            dispose();
                        }
                    } );
                }
                catch (final IncorrectMasterPasswordException e) {
                    SwingUtilities.invokeLater( new Runnable() {
                        @Override
                        public void run() {
                            JOptionPane.showMessageDialog( null, e.getLocalizedMessage(), "Sign In Failed", JOptionPane.ERROR_MESSAGE );
                            authenticationPanel.reset();
                            signInButton.setText( "Sign In" );
                            for (JComponent signInComponent : signInComponents)
                                signInComponent.setEnabled( true );
                            checkSignIn();
                        }
                    } );
                }

            }
        } );
    }

    interface SignInCallback {

        void signedIn(User user);
    }
}
