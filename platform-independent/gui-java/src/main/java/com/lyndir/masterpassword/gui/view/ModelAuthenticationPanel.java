package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.base.Function;
import com.google.common.base.Preconditions;
import com.google.common.collect.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.model.ModelUser;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.MPUserFileManager;
import com.lyndir.masterpassword.gui.util.Components;
import java.awt.*;
import java.awt.event.*;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import javax.swing.plaf.metal.MetalComboBoxEditor;
import org.jetbrains.annotations.NotNull;


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
        add( userLabel );

        userField = Components.comboBox( readConfigUsers() );
        userField.setFont( Res.valueFont().deriveFont( 12f ) );
        userField.addItemListener( this );
        userField.addActionListener( this );
        userField.setEditor( new MetalComboBoxEditor() {
            @Override
            protected JTextField createEditorComponent() {
                JTextField editorComponents = Components.textField();
                editorComponents.setForeground( Color.red );
                return editorComponents;
            }
        } );

        add( userField );
        add( Components.stud() );

        // Master Password
        masterPasswordLabel = Components.label( "Master Password:" );
        add( masterPasswordLabel );

        masterPasswordField = Components.passwordField();
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

        return userField.getModel().getElementAt( selectedIndex );
    }

    @NotNull
    @Override
    public char[] getMasterPassword() {
        return masterPasswordField.getPassword();
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
                setToolTipText( "Add a new user to the list." );
            }
        }, new JButton( Res.iconDelete() ) {
            {
                addActionListener( new ActionListener() {
                    @Override
                    public void actionPerformed(final ActionEvent e) {
                        ModelUser deleteUser = getSelectedUser();
                        if (deleteUser == null)
                            return;

                        if (JOptionPane.showConfirmDialog( ModelAuthenticationPanel.this, //
                                                       strf( "Are you sure you want to delete the user and sites remembered for:\n%s.",
                                                             deleteUser.getFullName() ), //
                                                       "Delete User", JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE ) == JOptionPane.CANCEL_OPTION)
                            return;

                        MPUserFileManager.get().deleteUser( deleteUser.getModel() );
                        userField.setModel( new DefaultComboBoxModel<>( readConfigUsers() ) );
                        updateUser( true );
                    }
                } );
                setToolTipText( "Delete the selected user." );
            }
        }, new JButton( Res.iconQuestion() ) {
            {
                addActionListener( new ActionListener() {
                    @Override
                    public void actionPerformed(final ActionEvent e) {
                        JOptionPane.showMessageDialog( ModelAuthenticationPanel.this, //
                                                       strf( "Reads users and sites from the directory at:\n%s",
                                                             MPUserFileManager.get().getPath().getAbsolutePath() ), //
                                                       "Help", JOptionPane.INFORMATION_MESSAGE );
                    }
                } );
                setToolTipText( "More information." );
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
            public ModelUser apply(@Nullable final MPUser model) {
                return new ModelUser( Preconditions.checkNotNull( model ) );
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
