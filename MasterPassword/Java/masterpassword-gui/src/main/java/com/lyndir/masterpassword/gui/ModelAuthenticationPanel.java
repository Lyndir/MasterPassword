package com.lyndir.masterpassword.gui;

import com.google.common.base.Function;
import com.google.common.collect.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.MPUserFileManager;
import com.lyndir.masterpassword.util.Components;
import java.awt.*;
import java.awt.event.*;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;


/**
 * @author lhunath, 2014-06-11
 */
public class ModelAuthenticationPanel extends AuthenticationPanel implements ItemListener, ActionListener, DocumentListener {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( ModelAuthenticationPanel.class );

    private final JComboBox<ModelUser> userField;
    private final JLabel               masterPasswordLabel;
    private final JPasswordField       masterPasswordField;

    public ModelAuthenticationPanel(final UnlockFrame unlockFrame) {
        super( unlockFrame );
        add( Components.stud() );

        // Avatar
        avatarLabel.addMouseListener( new MouseAdapter() {
            @Override
            public void mouseClicked(final MouseEvent e) {
                ModelUser selectedUser = getSelectedUser();
                if (selectedUser != null) {
                    selectedUser.setAvatar( selectedUser.getAvatar() + 1 );
                    updateUser( false );
                }
            }
        } );

        // User
        JLabel userLabel = Components.label( "User:" );
        userLabel.setAlignmentX( LEFT_ALIGNMENT );
        userLabel.setHorizontalAlignment( SwingConstants.CENTER );
        userLabel.setVerticalAlignment( SwingConstants.BOTTOM );
        add( userLabel );

        userField = new JComboBox<ModelUser>( new DefaultComboBoxModel<>( readConfigUsers() ) ) {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
        userField.setFont( Res.valueFont().deriveFont( 12f ) );
        userField.setAlignmentX( LEFT_ALIGNMENT );
        userField.addItemListener( this );
        userField.addActionListener( this );
        add( userField );
        add( Components.stud() );

        // Master Password
        masterPasswordLabel = Components.label( "Master Password:" );
        masterPasswordLabel.setAlignmentX( LEFT_ALIGNMENT );
        masterPasswordLabel.setHorizontalAlignment( SwingConstants.CENTER );
        masterPasswordLabel.setVerticalAlignment( SwingConstants.BOTTOM );
        add( masterPasswordLabel );

        masterPasswordField = Components.passwordField();
        masterPasswordField.setAlignmentX( LEFT_ALIGNMENT );
        masterPasswordField.addActionListener( this );
        masterPasswordField.getDocument().addDocumentListener( this );
        add( masterPasswordField );
    }

    @Override
    public Component getFocusComponent() {
        return masterPasswordField.isVisible()? masterPasswordField: null;
    }

    @Override
    protected void updateUser(boolean repack) {
        ModelUser selectedUser = getSelectedUser();
        if (selectedUser != null) {
            avatarLabel.setIcon( Res.avatar( selectedUser.getAvatar() ) );
            boolean showPasswordField = !selectedUser.keySaved();
            if (masterPasswordField.isVisible() != showPasswordField) {
                masterPasswordLabel.setVisible( showPasswordField );
                masterPasswordField.setVisible( showPasswordField );
                repack = true;
            }
        }

        super.updateUser( repack );
    }

    @Override
    protected ModelUser getSelectedUser() {
        int selectedIndex = userField.getSelectedIndex();
        if (selectedIndex < 0)
            return null;

        ModelUser selectedUser = userField.getModel().getElementAt( selectedIndex );
        if (selectedUser != null)
            selectedUser.setMasterPassword( new String( masterPasswordField.getPassword() ) );

        return selectedUser;
    }

    @Override
    public Iterable<? extends JButton> getButtons() {
        return ImmutableList.of( new JButton( Res.iconAdd() ) {
            {
                addActionListener( new ActionListener() {
                    @Override
                    public void actionPerformed(final ActionEvent e) {
                        String fullName = JOptionPane.showInputDialog( ModelAuthenticationPanel.this, //
                                                                       "Enter your full name, ensuring it is correctly spelled and capitalized:",
                                                                       "New User", JOptionPane.QUESTION_MESSAGE );
                        MPUserFileManager.get().addUser( new MPUser( fullName ) );
                        userField.setModel( new DefaultComboBoxModel<>( readConfigUsers() ) );
                        updateUser( true );
                    }
                } );
            }
        }, new JButton( Res.iconQuestion() ) {
            {
                addActionListener( new ActionListener() {
                    @Override
                    public void actionPerformed(final ActionEvent e) {
                        JOptionPane.showMessageDialog( ModelAuthenticationPanel.this, //
                                                       "Reads users and sites from the directory at ~/.mpw.", //
                                                       "Help", JOptionPane.INFORMATION_MESSAGE );
                    }
                } );
            }
        } );
    }

    @Override
    public void reset() {
        masterPasswordField.setText( "" );
    }

    private ModelUser[] readConfigUsers() {
        return FluentIterable.from( MPUserFileManager.get().getUsers() ).transform( new Function<MPUser, ModelUser>() {
            @Nullable
            @Override
            public ModelUser apply(final MPUser model) {
                return new ModelUser( model );
            }
        } ).toArray( ModelUser.class );
    }

    @Override
    public void itemStateChanged(final ItemEvent e) {
        updateUser( false );
    }

    @Override
    public void actionPerformed(final ActionEvent e) {
        updateUser( false );
        unlockFrame.trySignIn( userField );
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
}
