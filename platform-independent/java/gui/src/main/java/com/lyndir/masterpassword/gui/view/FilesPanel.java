package com.lyndir.masterpassword.gui.view;

import static com.lyndir.masterpassword.util.Utilities.*;

import com.google.common.collect.ImmutableSortedSet;
import com.lyndir.masterpassword.gui.MasterPassword;
import com.lyndir.masterpassword.gui.util.*;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.impl.MPFileUser;
import com.lyndir.masterpassword.model.impl.MPFileUserManager;
import java.awt.*;
import javax.annotation.Nullable;
import javax.swing.*;


/**
 * @author lhunath, 2018-07-14
 */
@SuppressWarnings("serial")
public class FilesPanel extends JPanel implements MPFileUserManager.Listener, State.Listener {

    private final JButton avatarButton = Components.button( Res.icons().avatar( 0 ), event -> setAvatar(),
                                                            "Click to change the user's avatar." );

    private final CollectionListModel<MPUser<?>> usersModel =
            new CollectionListModel<MPUser<?>>( MPFileUserManager.get().getFiles() ).selection( State.get()::activateUser );

    protected FilesPanel() {
        setOpaque( false );
        setBackground( Res.colors().transparent() );
        setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

        // -
        add( Box.createVerticalGlue() );

        // Avatar
        add( avatarButton );
        avatarButton.setHorizontalAlignment( SwingConstants.CENTER );
        avatarButton.setMaximumSize( new Dimension( Integer.MAX_VALUE, 0 ) );

        // -
        add( Components.strut( Components.margin() ) );

        // User Selection
        add( Components.comboBox( usersModel, user -> ifNotNull( user, MPUser::getFullName ) ) );

        MPFileUserManager.get().addListener( this );
        State.get().addListener( this );
    }

    private void setAvatar() {
        MPUser<?> selectedUser = usersModel.getSelectedItem();
        if (selectedUser == null)
            return;

        selectedUser.setAvatar( (selectedUser.getAvatar() + 1) % Res.icons().avatars() );
        avatarButton.setIcon( Res.icons().avatar( selectedUser.getAvatar() ) );
    }

    @Override
    public void onFilesUpdated(final ImmutableSortedSet<MPFileUser> files) {
        usersModel.set( files );
    }

    @Override
    public void onUserSelected(@Nullable final MPUser<?> user) {
        usersModel.selectItem( user );
        avatarButton.setIcon( Res.icons().avatar( (user == null)? 0: user.getAvatar() ) );
    }
}
