package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.Iterables;
import com.lyndir.masterpassword.util.Components;
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;


/**
 * @author lhunath, 2014-06-08
 */
public class PasswordFrame extends JFrame implements DocumentListener {

    private final User                     user;
    private final JTextField               siteNameField;
    private final JComboBox<MPElementType> siteTypeField;
    private final JSpinner                 siteCounterField;
    private final JTextField               passwordField;
    private final JLabel                   tipLabel;

    public PasswordFrame(User user)
            throws HeadlessException {
        super( "Master Password" );
        this.user = user;

        JLabel label;

        setContentPane( new JPanel( new BorderLayout( 20, 20 ) ) {
            {
                setBorder( new EmptyBorder( 20, 20, 20, 20 ) );
            }
        } );

        // User
        add( label = new JLabel( strf( "Generating passwords for: %s", user.getUserName() ) ), BorderLayout.NORTH );
        label.setFont( Res.exoRegular().deriveFont( 12f ) );
        label.setAlignmentX( LEFT_ALIGNMENT );

        // Site
        JPanel sitePanel = new JPanel();
        sitePanel.setLayout( new BoxLayout( sitePanel, BoxLayout.PAGE_AXIS ) );
        sitePanel.setBorder( new CompoundBorder( new EtchedBorder( EtchedBorder.RAISED ), new EmptyBorder( 8, 8, 8, 8 ) ) );
        add( sitePanel, BorderLayout.CENTER );

        // Site Name
        sitePanel.add( label = new JLabel( "Site Name:", JLabel.LEADING ) );
        label.setFont( Res.exoRegular().deriveFont( 12f ) );
        label.setAlignmentX( LEFT_ALIGNMENT );

        sitePanel.add( siteNameField = new JTextField() {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        } );
        siteNameField.setFont( Res.exoRegular().deriveFont( 12f ) );
        siteNameField.setAlignmentX( LEFT_ALIGNMENT );
        siteNameField.getDocument().addDocumentListener( this );
        siteNameField.addActionListener( new ActionListener() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                updatePassword( new PasswordCallback() {
                    @Override
                    public void passwordGenerated(final String siteName, final String sitePassword) {
                        StringSelection clipboardContents = new StringSelection( sitePassword );
                        Toolkit.getDefaultToolkit().getSystemClipboard().setContents( clipboardContents, null );

                        SwingUtilities.invokeLater( new Runnable() {
                            @Override
                            public void run() {
                                passwordField.setText( null );
                                siteNameField.setText( null );

                                if (getDefaultCloseOperation() == WindowConstants.EXIT_ON_CLOSE)
                                    System.exit( 0 );
                                else
                                    dispose();
                            }
                        } );
                    }
                } );
            }
        } );

        // Site Type & Counter
        MPElementType[] types = Iterables.toArray( MPElementType.forClass( MPElementTypeClass.Generated ), MPElementType.class );
        JComponent siteSettings = Components.boxLayout( BoxLayout.LINE_AXIS, //
                                                        siteTypeField = new JComboBox<>( types ), //
                                                        siteCounterField = new JSpinner(
                                                                new SpinnerNumberModel( 1, 1, Integer.MAX_VALUE, 1 ) ) {
                                                            @Override
                                                            public Dimension getMaximumSize() {
                                                                return new Dimension( 20, getPreferredSize().height );
                                                            }
                                                        } );
        siteSettings.setAlignmentX( LEFT_ALIGNMENT );
        sitePanel.add( siteSettings );
        siteTypeField.setFont( Res.exoRegular().deriveFont( 12f ) );
        siteTypeField.setAlignmentX( LEFT_ALIGNMENT );
        siteTypeField.setAlignmentY( CENTER_ALIGNMENT );
        siteTypeField.setSelectedItem( MPElementType.GeneratedLong );
        siteTypeField.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(final ItemEvent e) {
                updatePassword( null );
            }
        } );

        siteCounterField.setFont( Res.exoRegular().deriveFont( 12f ) );
        siteCounterField.setAlignmentX( RIGHT_ALIGNMENT );
        siteCounterField.setAlignmentY( CENTER_ALIGNMENT );
        siteCounterField.addChangeListener( new ChangeListener() {
            @Override
            public void stateChanged(final ChangeEvent e) {
                updatePassword( null );
            }
        } );

        // Password
        passwordField = new JTextField( " " );
        passwordField.setFont( Res.sourceCodeProBlack().deriveFont( 40f ) );
        passwordField.setHorizontalAlignment( JTextField.CENTER );
        passwordField.setAlignmentX( Component.CENTER_ALIGNMENT );
        passwordField.setEditable( false );

        // Tip
        tipLabel = new JLabel( " ", JLabel.CENTER );
        tipLabel.setFont( Res.exoThin().deriveFont( 9f ) );
        tipLabel.setAlignmentX( Component.CENTER_ALIGNMENT );

        add( Components.boxLayout( BoxLayout.PAGE_AXIS, passwordField, tipLabel ), BorderLayout.SOUTH );

        pack();
        setMinimumSize( getSize() );
        setPreferredSize( new Dimension( 600, getSize().height ) );
        pack();

        setLocationByPlatform( true );
        setLocationRelativeTo( null );
    }

    private void updatePassword(final PasswordCallback callback) {
        final MPElementType siteType = (MPElementType) siteTypeField.getSelectedItem();
        final String siteName = siteNameField.getText();
        final int siteCounter = (Integer) siteCounterField.getValue();

        if (siteType.getTypeClass() != MPElementTypeClass.Generated || siteName == null || siteName.isEmpty() || !user.hasKey()) {
            passwordField.setText( null );
            tipLabel.setText( null );
            return;
        }

        Res.execute( new Runnable() {
            @Override
            public void run() {
                final String sitePassword = user.getKey().encode( siteName, siteType, siteCounter, MPElementVariant.Password, null );
                if (callback != null)
                    callback.passwordGenerated( siteName, sitePassword );

                SwingUtilities.invokeLater( new Runnable() {
                    @Override
                    public void run() {
                        if (!siteName.equals( siteNameField.getText() ))
                            return;

                        passwordField.setText( sitePassword );
                        tipLabel.setText( "Press [Enter] to copy the password." );
                    }
                } );
            }
        } );
    }

    @Override
    public void insertUpdate(final DocumentEvent e) {
        updatePassword( null );
    }

    @Override
    public void removeUpdate(final DocumentEvent e) {
        updatePassword( null );
    }

    @Override
    public void changedUpdate(final DocumentEvent e) {
        updatePassword( null );
    }

    interface PasswordCallback {

        void passwordGenerated(String siteName, String sitePassword);
    }
}
