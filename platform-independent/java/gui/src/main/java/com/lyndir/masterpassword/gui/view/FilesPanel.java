package com.lyndir.masterpassword.gui.view;

import com.google.common.collect.ImmutableList;
import com.lyndir.masterpassword.MPAlgorithm;
import com.lyndir.masterpassword.MPResultType;
import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.util.CollectionListModel;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.impl.MPFileUser;
import com.lyndir.masterpassword.model.impl.MPFileUserManager;
import java.awt.*;
import java.awt.event.*;
import java.util.Collection;
import java.util.concurrent.CopyOnWriteArraySet;
import javax.annotation.Nullable;
import javax.swing.*;


/**
 * @author lhunath, 2018-07-14
 */
@SuppressWarnings("serial")
public class FilesPanel extends JPanel implements ItemListener {

    private final Collection<Listener> listeners = new CopyOnWriteArraySet<>();

    private final JLabel                         avatarLabel       = new JLabel();
    private final CollectionListModel<MPUser<?>> usersModel        = new CollectionListModel<>();
    private final JComboBox<MPUser<?>>           userField         =
            Components.comboBox( usersModel, user -> (user != null)? user.getFullName(): null );
    private final JButton                        preferencesButton = Components.button( "..." );

    protected FilesPanel() {
        setOpaque( false );
        setBackground( Res.colors().transparent() );
        setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

        // -
        add( Box.createVerticalGlue() );

        // Avatar
        add( avatarLabel );
        avatarLabel.setHorizontalAlignment( SwingConstants.CENTER );
        avatarLabel.setMaximumSize( new Dimension( Integer.MAX_VALUE, 0 ) );
        avatarLabel.setToolTipText( "The avatar for your user.  Click to change it." );

        // -
        add( Components.strut( Components.margin() ) );

        // User Selection
        add( Components.panel( BoxLayout.LINE_AXIS, userField, preferencesButton ) );
        preferencesButton.setAction( new AbstractAction() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                MPUser<?> user = usersModel.getSelectedItem();
                if (user == null)
                    return;
                MPFileUser fileUser = (user instanceof MPFileUser)? (MPFileUser) user: null;

                ImmutableList.Builder<Component> components = ImmutableList.builder();
                if (fileUser != null)
                    components.add( Components.label( "Default Password Type:" ),
                                    Components.comboBox( MPResultType.values(), MPResultType::getLongName,
                                                         fileUser.getDefaultType(), fileUser::setDefaultType ),
                                    Components.strut() );

                components.add( Components.label( "Default Algorithm:" ),
                                Components.comboBox( MPAlgorithm.Version.values(), MPAlgorithm.Version::name,
                                                     user.getAlgorithm().version(),
                                                     version -> user.setAlgorithm( version.getAlgorithm() ) ) );

                Components.showDialog( preferencesButton, user.getFullName(), new JOptionPane( Components.panel(
                        BoxLayout.PAGE_AXIS, components.build().toArray( new Component[0] ) ) ) );
            }
        } );
        userField.addItemListener( this );
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
