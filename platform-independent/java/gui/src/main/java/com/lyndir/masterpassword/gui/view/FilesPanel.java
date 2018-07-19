package com.lyndir.masterpassword.gui.view;

import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.util.CollectionListModel;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.impl.MPFileUserManager;
import java.awt.*;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.util.Collection;
import java.util.concurrent.CopyOnWriteArraySet;
import javax.annotation.Nullable;
import javax.swing.*;


/**
 * @author lhunath, 2018-07-14
 */
public class FilesPanel extends JPanel implements ItemListener {

    private final Collection<Listener> listeners = new CopyOnWriteArraySet<>();

    private final JLabel                         avatarLabel = new JLabel();
    private final CollectionListModel<MPUser<?>> usersModel  = new CollectionListModel<>();
    private final JComboBox<MPUser<?>>           userField   =
            Components.comboBox( usersModel, user -> (user != null)? user.getFullName(): null );

    protected FilesPanel() {
        setOpaque( false );
        setBackground( new Color( 0, 0, 0, 0 ) );
        setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

        // -
        add( Box.createVerticalGlue() );

        // Avatar
        add( avatarLabel );
        avatarLabel.setHorizontalAlignment( SwingConstants.CENTER );
        avatarLabel.setMaximumSize( new Dimension( Integer.MAX_VALUE, 0 ) );
        avatarLabel.setToolTipText( "The avatar for your user.  Click to change it." );

        // -
        add( Components.strut( 20 ) );

        // User Selection
        add( userField );
        userField.addItemListener( this );

        // -
        add( Box.createVerticalGlue() );
    }

    public void reload() {
        MPFileUserManager.get().reload();
        usersModel.set( MPFileUserManager.get().getFiles() );
    }

    public boolean addListener(final Listener listener) {
        return listeners.add( listener );
    }

    @Override
    public void itemStateChanged(final ItemEvent e) {
        if (e.getStateChange() != ItemEvent.SELECTED)
            return;

        MPUser<?> selectedUser = usersModel.getSelectedItem();
        avatarLabel.setIcon( Res.avatar( (selectedUser == null)? 0: selectedUser.getAvatar() ) );

        for (final Listener listener : listeners)
            listener.onUserSelected( selectedUser );
    }

    public interface Listener {

        void onUserSelected(@Nullable MPUser<?> selectedUser);
    }
}
