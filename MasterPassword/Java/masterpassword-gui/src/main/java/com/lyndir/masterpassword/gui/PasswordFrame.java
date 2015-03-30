package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.Iterables;
import com.google.common.util.concurrent.*;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.gui.util.Components;
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.event.*;
import java.util.concurrent.Callable;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.*;


/**
 * @author lhunath, 2014-06-08
 */
public class PasswordFrame extends JFrame implements DocumentListener {

    private final User                         user;
    private final Components.GradientPanel     root;
    private final JTextField                   siteNameField;
    private final JButton                      siteAddButton;
    private final JComboBox<MPSiteType>        siteTypeField;
    private final JComboBox<MasterKey.Version> siteVersionField;
    private final JSpinner                     siteCounterField;
    private final JPasswordField               passwordField;
    private final JLabel                       tipLabel;
    private final JCheckBox                    maskPasswordField;
    private final char                         passwordEchoChar;
    private final Font                         passwordEchoFont;
    private       boolean                      updatingUI;
    private       Site                         currentSite;

    public PasswordFrame(User user)
            throws HeadlessException {
        super( "Master Password" );
        this.user = user;

        setDefaultCloseOperation( DISPOSE_ON_CLOSE );
        setContentPane( root = Components.gradientPanel( new BorderLayout( 20, 20 ), Res.colors().frameBg() ) );
        root.setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );

        // Site
        JPanel sitePanel = Components.boxLayout( BoxLayout.PAGE_AXIS );
        sitePanel.setOpaque( true );
        sitePanel.setBackground( Res.colors().controlBg() );
        sitePanel.setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
        add( Components.borderPanel( sitePanel, BorderFactory.createRaisedBevelBorder(), Res.colors().frameBg() ), BorderLayout.CENTER );

        // User
        sitePanel.add( Components.label( strf( "Generating passwords for: %s", user.getFullName() ), SwingConstants.CENTER ) );
        sitePanel.add( Components.stud() );

        // Site Name
        sitePanel.add( Components.label( "Site Name:" ) );
        JComponent siteControls = Components.boxLayout( BoxLayout.LINE_AXIS, //
                                                        siteNameField = Components.textField(), Components.stud(),
                                                        siteAddButton = Components.button( "Add Site" ) );
        siteNameField.getDocument().addDocumentListener( this );
        siteNameField.addActionListener( new ActionListener() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                Futures.addCallback( updatePassword(), new FutureCallback<String>() {
                    @Override
                    public void onSuccess(@Nullable final String sitePassword) {
                        StringSelection clipboardContents = new StringSelection( sitePassword );
                        Toolkit.getDefaultToolkit().getSystemClipboard().setContents( clipboardContents, null );

                        SwingUtilities.invokeLater( new Runnable() {
                            @Override
                            public void run() {
                                passwordField.setText( null );
                                siteNameField.setText( null );

                                dispatchEvent( new WindowEvent( PasswordFrame.this, WindowEvent.WINDOW_CLOSING ) );
                            }
                        } );
                    }

                    @Override
                    public void onFailure(final Throwable t) {
                    }
                } );
            }
        } );
        siteAddButton.setVisible( false );
        siteAddButton.addActionListener( new ActionListener() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                PasswordFrame.this.user.addSite( currentSite );
                siteAddButton.setVisible( false );
            }
        } );
        sitePanel.add( siteControls );
        sitePanel.add( Components.stud() );

        // Site Type & Counter
        MPSiteType[] types = Iterables.toArray( MPSiteType.forClass( MPSiteTypeClass.Generated ), MPSiteType.class );
        JComponent siteSettings = Components.boxLayout( BoxLayout.LINE_AXIS, //
                                                        siteTypeField = Components.comboBox( types ), //
                                                        Components.stud(), //
                                                        siteVersionField = Components.comboBox( MasterKey.Version.values() ), //
                                                        Components.stud(), //
                                                        siteCounterField = Components.spinner(
                                                                new SpinnerNumberModel( 1, 1, Integer.MAX_VALUE, 1 ) ) );
        sitePanel.add( siteSettings );
        siteTypeField.setFont( Res.valueFont().deriveFont( 12f ) );
        siteTypeField.setSelectedItem( MPSiteType.GeneratedLong );
        siteTypeField.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(final ItemEvent e) {
                updatePassword();
            }
        } );

        siteVersionField.setFont( Res.valueFont().deriveFont( 12f ) );
        siteVersionField.setAlignmentX( RIGHT_ALIGNMENT );
        siteVersionField.setSelectedItem( MasterKey.Version.CURRENT );
        siteVersionField.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(final ItemEvent e) {
                updatePassword();
            }
        } );

        siteCounterField.setFont( Res.valueFont().deriveFont( 12f ) );
        siteCounterField.setAlignmentX( RIGHT_ALIGNMENT );
        siteCounterField.addChangeListener( new ChangeListener() {
            @Override
            public void stateChanged(final ChangeEvent e) {
                updatePassword();
            }
        } );

        // Mask
        maskPasswordField = Components.checkBox( "Hide Password" );
        maskPasswordField.setAlignmentX( Component.CENTER_ALIGNMENT );
        maskPasswordField.setSelected( true );
        maskPasswordField.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(ItemEvent e) {
                updateMask();
            }
        } );

        // Password
        passwordField = Components.passwordField();
        passwordField.setAlignmentX(Component.CENTER_ALIGNMENT);
        passwordField.setHorizontalAlignment(JTextField.CENTER);
        passwordField.putClientProperty("JPasswordField.cutCopyAllowed", true);
        passwordField.setEditable(false);
        passwordField.setBackground(null);
        passwordField.setBorder( null );
        passwordEchoChar = passwordField.getEchoChar();
        passwordEchoFont = passwordField.getFont().deriveFont( 40f );
        updateMask();

        // Tip
        tipLabel = Components.label( " ", SwingConstants.CENTER );
        tipLabel.setAlignmentX( Component.CENTER_ALIGNMENT );
        JPanel passwordContainer = Components.boxLayout( BoxLayout.PAGE_AXIS, maskPasswordField, passwordField, tipLabel );
        passwordContainer.setOpaque( true );
        passwordContainer.setBackground( Color.white );
        passwordContainer.setBorder( BorderFactory.createEmptyBorder( 8, 8, 8, 8 ) );
        add( Components.borderPanel( passwordContainer, BorderFactory.createLoweredSoftBevelBorder(), Res.colors().frameBg() ),
             BorderLayout.SOUTH );

        pack();
        setMinimumSize( new Dimension( Math.max( 600, getPreferredSize().width ), Math.max( 300, getPreferredSize().height ) ) );
        pack();

        setLocationByPlatform( true );
        setLocationRelativeTo( null );
    }

    private void updateMask() {
        passwordField.setEchoChar( maskPasswordField.isSelected()? passwordEchoChar: (char) 0 );
        passwordField.setFont( maskPasswordField.isSelected()? passwordEchoFont: Res.bigValueFont().deriveFont( 40f ) );
    }

    @Nonnull
    private ListenableFuture<String> updatePassword() {

        final String siteNameQuery = siteNameField.getText();
        if (updatingUI)
            return Futures.immediateCancelledFuture();
        if (siteNameQuery == null || siteNameQuery.isEmpty() || !user.isKeyAvailable()) {
            tipLabel.setText( null );
            passwordField.setText( null );
            return Futures.immediateCancelledFuture();
        }

        final MPSiteType siteType = siteTypeField.getModel().getElementAt( siteTypeField.getSelectedIndex() );
        final MasterKey.Version siteVersion = siteVersionField.getItemAt( siteVersionField.getSelectedIndex() );
        final int siteCounter = (Integer) siteCounterField.getValue();
        final Site site = currentSite != null && currentSite.getSiteName().equals( siteNameQuery )? currentSite
                : Iterables.getFirst( user.findSitesByName( siteNameQuery ),
                                      new IncognitoSite( siteNameQuery, siteType, siteCounter, siteVersion ) );
        assert site != null;
        if (site == currentSite) {
            site.setSiteType( siteType );
            site.setAlgorithmVersion( siteVersion );
            site.setSiteCounter( siteCounter );
        }

        ListenableFuture<String> passwordFuture = Res.execute( this, new Callable<String>() {
            @Override
            public String call()
                    throws Exception {
                return user.getKey( site.getAlgorithmVersion() )
                           .encode( site.getSiteName(), site.getSiteType(), site.getSiteCounter(), MPSiteVariant.Password, null );
            }
        } );
        Futures.addCallback( passwordFuture, new FutureCallback<String>() {
            @Override
            public void onSuccess(@Nullable final String sitePassword) {
                SwingUtilities.invokeLater( new Runnable() {
                    @Override
                    public void run() {
                        updatingUI = true;
                        currentSite = site;
                        siteAddButton.setVisible( user instanceof ModelUser && !(currentSite instanceof ModelSite) );
                        siteTypeField.setSelectedItem( currentSite.getSiteType() );
                        siteVersionField.setSelectedItem( currentSite.getAlgorithmVersion() );
                        siteCounterField.setValue( currentSite.getSiteCounter() );
                        siteNameField.setText( currentSite.getSiteName() );
                        if (siteNameField.getText().startsWith( siteNameQuery ))
                            siteNameField.select( siteNameQuery.length(), siteNameField.getText().length() );

                        passwordField.setText( sitePassword );
                        tipLabel.setText( "Press [Enter] to copy the password.  Then paste it into the password field." );
                        updatingUI = false;
                    }
                } );
            }

            @Override
            public void onFailure(final Throwable t) {
            }
        } );

        return passwordFuture;
    }

    @Override
    public void insertUpdate(final DocumentEvent e) {
        updatePassword();
    }

    @Override
    public void removeUpdate(final DocumentEvent e) {
    }

    @Override
    public void changedUpdate(final DocumentEvent e) {
        updatePassword();
    }
}
