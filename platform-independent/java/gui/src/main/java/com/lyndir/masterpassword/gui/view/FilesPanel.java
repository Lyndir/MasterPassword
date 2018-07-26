package com.lyndir.masterpassword.gui.view;

import static com.lyndir.masterpassword.util.Utilities.*;

import com.lyndir.masterpassword.gui.util.Res;
import com.lyndir.masterpassword.gui.util.CollectionListModel;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.impl.MPFileUserManager;
import java.awt.*;
import java.util.Collection;
import java.util.concurrent.CopyOnWriteArraySet;
import javax.annotation.Nullable;
import javax.swing.*;


/**
 * @author lhunath, 2018-07-14
 */
@SuppressWarnings("serial")
public class FilesPanel extends JPanel {

    private final Collection<Listener> listeners = new CopyOnWriteArraySet<>();

    private final JButton avatarButton = Components.button( Res.icons().avatar( 0 ), event -> setAvatar() );

    private final CollectionListModel<MPUser<?>> usersModel =
            CollectionListModel.<MPUser<?>>copy( MPFileUserManager.get().getFiles() ).selection( this::setUser );
    private final JComboBox<? extends MPUser<?>> userField  =
            Components.comboBox( usersModel, user -> ifNotNull( user, MPUser::getFullName ) );

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
        avatarButton.setToolTipText( "The avatar for your user.  Click to change it." );

        // -
        add( Components.strut( Components.margin() ) );

        // User Selection
        add( userField );
    }

    public void reload() {
        // TODO: Should we use a listener here instead?
        usersModel.set( MPFileUserManager.get().reload() );
    }

    public boolean addListener(final Listener listener) {
        return listeners.add( listener );
    }

    private void setAvatar() {
        MPUser<?> selectedUser = usersModel.getSelectedItem();
        if (selectedUser == null)
            return;

        selectedUser.setAvatar( (selectedUser.getAvatar() + 1) % Res.icons().avatars() );
        avatarButton.setIcon( Res.icons().avatar( selectedUser.getAvatar() ) );
    }

    public void setUser(@Nullable final MPUser<?> user) {
        avatarButton.setIcon( Res.icons().avatar( (user == null)? 0: user.getAvatar() ) );

        for (final Listener listener : listeners)
            listener.onUserSelected( user );
    }

    public interface Listener {

        void onUserSelected(@Nullable MPUser<?> user);
    }
}
