package com.lyndir.masterpassword.gui.view;

import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.impl.MPFileUser;
import com.lyndir.masterpassword.model.impl.MPFileUserManager;
import java.awt.*;
import java.awt.event.*;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.plaf.metal.MetalComboBoxEditor;


/**
 * @author lhunath, 2018-07-14
 */
public class FilesPanel extends JPanel implements ActionListener {

    private final Set<Listener> listeners = new CopyOnWriteArraySet<>();

    private final JLabel                avatarLabel = new JLabel();
    private final JComboBox<MPFileUser> userField   = Components.comboBox();

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
        userField.addActionListener( this );
        userField.setFont( Res.fonts().valueFont().deriveFont( userField.getFont().getSize2D() ) );
        userField.setRenderer( new DefaultListCellRenderer() {
            @Override
            @SuppressWarnings("unchecked")
            public Component getListCellRendererComponent(final JList<?> list, final Object value, final int index,
                                                          final boolean isSelected, final boolean cellHasFocus) {
                String userValue = (value == null)? null: ((MPFileUser) value).getFullName();
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

        // -
        add( Box.createVerticalGlue() );
    }

    public void reload() {
        MPFileUserManager.get().reload();
        userField.setModel( new DefaultComboBoxModel<>( MPFileUserManager.get().getFiles().toArray( new MPFileUser[0] ) ) );
        updateFile();
    }

    @Override
    public void actionPerformed(final ActionEvent e) {
        updateFile();
    }

    @Nullable
    private MPFileUser getSelectedUser() {
        int selectedIndex = userField.getSelectedIndex();
        if (selectedIndex < 0)
            return null;

        return userField.getModel().getElementAt( selectedIndex );
    }

    private void updateFile() {
        MPFileUser selectedFile = getSelectedUser();
        avatarLabel.setIcon( Res.avatar( (selectedFile == null)? 0: selectedFile.getAvatar() ) );

        for (final Listener listener : listeners)
            listener.onUserSelected( selectedFile );
    }

    public boolean addListener(final Listener listener) {
        return listeners.add( listener );
    }

    public interface Listener {

        void onUserSelected(@Nullable MPUser<?> selectedUser);
    }
}
