package com.lyndir.lhunath.masterpassword;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.google.common.base.Splitter;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import com.google.common.io.CharStreams;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.Iterator;
import java.util.NoSuchElementException;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;


/**
 * @author lhunath, 2014-06-11
 */
public class ConfigAuthenticationPanel extends AuthenticationPanel implements ItemListener, ActionListener, DocumentListener {

    private final JComboBox      userField;
    private final JLabel         masterPasswordLabel;
    private final JPasswordField masterPasswordField;

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

        // Master Password
        masterPasswordLabel = new JLabel( "Master Password:" );
        masterPasswordLabel.setAlignmentX( Component.LEFT_ALIGNMENT );
        masterPasswordLabel.setHorizontalAlignment( SwingConstants.CENTER );
        masterPasswordLabel.setVerticalAlignment( SwingConstants.BOTTOM );
        add( masterPasswordLabel );

        masterPasswordField = new JPasswordField() {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
        masterPasswordField.setAlignmentX( Component.LEFT_ALIGNMENT );
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
        boolean masterPasswordMissing = userField.getSelectedItem() == null || !((User) userField.getSelectedItem()).hasKey();
        if (masterPasswordField.isVisible() != masterPasswordMissing) {
            masterPasswordLabel.setVisible( masterPasswordMissing );
            masterPasswordField.setVisible( masterPasswordMissing );
            repack = true;
        }

        super.updateUser( repack );
    }

    @Override
    protected User getUser() {
        User selectedUser = (User) userField.getSelectedItem();
        if (selectedUser.hasKey()) {
            return selectedUser;
        }

        return new User( selectedUser.getName(), new String( masterPasswordField.getPassword() ) );
    }

    public String getHelpText() {
        return "Reads users from ~/.mpw, the following syntax applies:\nUser Name:masterpassword"
               + "\n\nEnsure the file's permissions make it only readable by you!";
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
            JOptionPane.showMessageDialog( this, "First create the config file at:\n" + mpwConfig.getAbsolutePath() +
                                                 "\n\nIt should contain a line for each user of the following format:" +
                                                 "\nUser Name:masterpassword" +
                                                 "\n\nEnsure the file's permissions make it only readable by you!", //
                                           "Config File Not Found", JOptionPane.WARNING_MESSAGE );
            return new User[0];
        }
        catch (IOException | NoSuchElementException e) {
            e.printStackTrace();
            String error = ifNotNullElse( e.getLocalizedMessage(), ifNotNullElse( e.getMessage(), e.toString() ) );
            JOptionPane.showMessageDialog( this, //
                                           "Problem reading config file:\n" + mpwConfig.getAbsolutePath() //
                                           + "\n\n" + error, //
                                           "Config File Not Readable", JOptionPane.WARNING_MESSAGE );
            return new User[0];
        }
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
