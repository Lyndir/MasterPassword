package com.lyndir.lhunath.masterpassword;

import com.google.common.base.Splitter;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import com.google.common.io.CharStreams;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.Iterator;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-11
 */
public class ConfigAuthenticationPanel extends AuthenticationPanel implements ItemListener, ActionListener {

    private final JComboBox userField;

    public ConfigAuthenticationPanel(final UnlockFrame unlockFrame) {

        // User
        super( unlockFrame );
        JLabel userLabel = new JLabel( "User:" );
        userLabel.setAlignmentX( LEFT_ALIGNMENT );
        userLabel.setHorizontalAlignment( SwingConstants.CENTER );
        userLabel.setVerticalAlignment( SwingConstants.BOTTOM );
        add( userLabel );

        userField = new JComboBox<User>( new DefaultComboBoxModel<>( readConfigUsers() ) ) {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
        userField.setAlignmentX( LEFT_ALIGNMENT );
        userField.addItemListener( this );
        userField.addActionListener( this );
        add( userField );
    }

    @Override
    protected User getUser() {
        return (User) userField.getSelectedItem();
    }

    public static boolean hasConfigUsers() {
        return new File( System.getProperty( "user.home" ), ".mpw" ).canRead();
    }

    private User[] readConfigUsers() {
        ImmutableList.Builder<User> users = ImmutableList.builder();
        File mpwConfig = new File( System.getProperty( "user.home" ), ".mpw" );
        try (FileReader mpwReader = new FileReader( mpwConfig )) {
            for (String line : CharStreams.readLines( mpwReader )) {
                if (line.startsWith( "#" ) || line.startsWith( "//" ) || line.isEmpty()) {
                    continue;
                }

                Iterator<String> fields = Splitter.on( ':' ).limit( 2 ).split( line ).iterator();
                String userName = fields.next(), masterPassword = fields.next();
                users.add( new User( userName, masterPassword ) );
            }

            return Iterables.toArray( users.build(), User.class );
        }
        catch (FileNotFoundException e) {
            return null;
        }
        catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    @Override
    public void itemStateChanged(final ItemEvent e) {
        updateUser();
    }

    @Override
    public void actionPerformed(final ActionEvent e) {
        updateUser();
        unlockFrame.trySignIn( userField );
    }
}
