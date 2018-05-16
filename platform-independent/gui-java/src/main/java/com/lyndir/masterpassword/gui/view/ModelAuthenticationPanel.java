//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Preconditions;
import com.google.common.collect.ImmutableList;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.MPAlgorithm;
import com.lyndir.masterpassword.MPResultType;
import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.impl.*;
import java.awt.*;
import java.awt.event.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import javax.swing.plaf.metal.MetalComboBoxEditor;


/**
 * @author lhunath, 2014-06-11
 */
public class ModelAuthenticationPanel extends AuthenticationPanel<MPFileUser> implements ItemListener, ActionListener, DocumentListener {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger           = Logger.get( ModelAuthenticationPanel.class );
    private static final long   serialVersionUID = 1L;

    private final JComboBox<MPFileUser> userField;
    private final JLabel                masterPasswordLabel;
    private final JPasswordField        masterPasswordField;

    public ModelAuthenticationPanel(final UnlockFrame unlockFrame) {
        super( unlockFrame );
        add( Components.stud() );

        // Avatar
        avatarLabel.addMouseListener( new MouseAdapter() {
            @Override
            public void mouseClicked(final MouseEvent e) {
                MPFileUser selectedUser = getSelectedUser();
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
        userField.setFont( Res.valueFont().deriveFont( userField.getFont().getSize2D() ) );
        userField.addItemListener( this );
        userField.addActionListener( this );
        userField.setRenderer( new DefaultListCellRenderer() {
            private static final long serialVersionUID = 1L;

            @Override
            @SuppressWarnings("unchecked")
            public Component getListCellRendererComponent(final JList<?> list, final Object value, final int index,
                                                          final boolean isSelected, final boolean cellHasFocus) {
                String userValue = ((MPUser<MPFileSite>) value).getFullName();
                return super.getListCellRendererComponent( list, userValue, index, isSelected, cellHasFocus );
            }
        } );
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
        MPFileUser selectedUser = getSelectedUser();
        if (selectedUser != null) {
            avatarLabel.setIcon( Res.avatar( selectedUser.getAvatar() ) );
            boolean showPasswordField = !selectedUser.isMasterKeyAvailable(); // TODO: is this the same as keySaved()?
            if (masterPasswordField.isVisible() != showPasswordField) {
                masterPasswordLabel.setVisible( showPasswordField );
                masterPasswordField.setVisible( showPasswordField );
                repack = true;
            }
        }

        super.updateUser( repack );
    }

    @Nullable
    @Override
    protected MPFileUser getSelectedUser() {
        int selectedIndex = userField.getSelectedIndex();
        if (selectedIndex < 0)
            return null;

        return userField.getModel().getElementAt( selectedIndex );
    }

    @Nonnull
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
                        MPFileUserManager.get().addUser( new MPFileUser( fullName ) );
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
                        MPFileUser deleteUser = getSelectedUser();
                        if (deleteUser == null)
                            return;

                        if (JOptionPane.showConfirmDialog( ModelAuthenticationPanel.this, //
                                                           strf( "Are you sure you want to delete the user and sites remembered for:%n%s.",
                                                                 deleteUser.getFullName() ), //
                                                           "Delete User", JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE )
                            == JOptionPane.CANCEL_OPTION)
                            return;

                        MPFileUserManager.get().deleteUser( deleteUser );
                        userField.setModel( new DefaultComboBoxModel<>( readConfigUsers() ) );
                        updateUser( true );
                    }
                } );
                setToolTipText( "Delete the selected user." );
            }
        }, new JButton( Res.iconQuestion() ) {
            {
                addActionListener( e -> JOptionPane.showMessageDialog(
                        ModelAuthenticationPanel.this, //
                        strf( "Reads users and sites from the directory at:%n%s",
                              MPFileUserManager.get().getPath().getAbsolutePath() ), //
                        "Help", JOptionPane.INFORMATION_MESSAGE ) );
                setToolTipText( "More information." );
            }
        } );
    }

    @Override
    public void reset() {
        masterPasswordField.setText( "" );
    }

    @Override
    public PasswordFrame<MPFileUser, MPFileSite> newPasswordFrame() {
        return new PasswordFrame<MPFileUser, MPFileSite>( Preconditions.checkNotNull( getSelectedUser() ) ) {
            @Override
            protected MPFileSite createSite(final MPFileUser user, final String siteName, final UnsignedInteger siteCounter,
                                            final MPResultType resultType,
                                            final MPAlgorithm algorithm) {
                return new MPFileSite( user, siteName, algorithm, siteCounter, resultType );
            }
        };
    }

    private static MPFileUser[] readConfigUsers() {
        return MPFileUserManager.get().getUsers().toArray( new MPFileUser[0] );
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
