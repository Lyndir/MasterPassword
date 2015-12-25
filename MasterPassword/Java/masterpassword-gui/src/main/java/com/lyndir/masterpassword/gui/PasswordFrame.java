package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.FluentIterable;
import com.google.common.collect.Iterables;
import com.google.common.primitives.UnsignedInteger;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.util.PredicateNN;
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
    private final JButton                      siteActionButton;
    private final JComboBox<MPSiteType>        siteTypeField;
    private final JComboBox<MasterKey.Version> siteVersionField;
    private final JSpinner                     siteCounterField;
    private final JPasswordField               passwordField;
    private final JLabel                       tipLabel;
    private final JCheckBox                    maskPasswordField;
    private final char                         passwordEchoChar;
    private final Font                         passwordEchoFont;

    @Nullable
    private Site    currentSite;
    private boolean updatingUI;

    public PasswordFrame(User user)
            throws HeadlessException {
        super( "Master Password" );
        this.user = user;

        setDefaultCloseOperation( DISPOSE_ON_CLOSE );
        setContentPane( root = Components.gradientPanel( new FlowLayout(), Res.colors().frameBg() ) );
        root.setLayout( new BoxLayout( root, BoxLayout.PAGE_AXIS ) );
        root.setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );

        // Site
        JPanel sitePanel = Components.boxLayout( BoxLayout.PAGE_AXIS );
        sitePanel.setOpaque( true );
        sitePanel.setBackground( Res.colors().controlBg() );
        sitePanel.setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
        root.add( Components.borderPanel( sitePanel, BorderFactory.createRaisedBevelBorder(), Res.colors().frameBg() ) );

        // User
        sitePanel.add( Components.label( strf( "Generating passwords for: %s", user.getFullName() ), SwingConstants.CENTER ) );
        sitePanel.add( Components.stud() );

        // Site Name
        sitePanel.add( Components.label( "Site Name:" ) );
        JComponent siteControls = Components.boxLayout( BoxLayout.LINE_AXIS, //
                                                        siteNameField = Components.textField(), Components.stud(),
                                                        siteActionButton = Components.button( "Add Site" ) );
        siteNameField.getDocument().addDocumentListener( this );
        siteNameField.addActionListener( new ActionListener() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                Futures.addCallback( updatePassword( true ), new FutureCallback<String>() {
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
        siteActionButton.addActionListener( new ActionListener() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                if (currentSite == null)
                    return;
                else if (currentSite instanceof ModelSite)
                    PasswordFrame.this.user.deleteSite( currentSite );
                else
                    PasswordFrame.this.user.addSite( currentSite );
                siteNameField.requestFocus();

                updatePassword( true );
            }
        } );
        sitePanel.add( siteControls );
        sitePanel.add( Components.stud() );

        // Site Type & Counter
        MPSiteType[] types = Iterables.toArray( MPSiteType.forClass( MPSiteTypeClass.Generated ), MPSiteType.class );
        JComponent siteSettings = Components.boxLayout(                                                                       BoxLayout.LINE_AXIS,                                                  //
                                                        siteTypeField = Components.comboBox( types ),                         //
                                                        Components.stud(),                                                    //
                                                        siteVersionField = Components.comboBox( MasterKey.Version.values() ), //
                                                        Components.stud(),                                                    //
                                                        siteCounterField = Components.spinner(
                                                                new SpinnerNumberModel( 1L, 1L, UnsignedInteger.MAX_VALUE, 1L ) ) );
        sitePanel.add( siteSettings );
        siteTypeField.setFont( Res.valueFont().deriveFont( 12f ) );
        siteTypeField.setSelectedItem( MPSiteType.GeneratedLong );
        siteTypeField.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(final ItemEvent e) {
                updatePassword( true );
            }
        } );

        siteVersionField.setFont( Res.valueFont().deriveFont( 12f ) );
        siteVersionField.setAlignmentX( RIGHT_ALIGNMENT );
        siteVersionField.setSelectedItem( MasterKey.Version.CURRENT );
        siteVersionField.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(final ItemEvent e) {
                updatePassword( true );
            }
        } );

        siteCounterField.setFont( Res.valueFont().deriveFont( 12f ) );
        siteCounterField.setAlignmentX( RIGHT_ALIGNMENT );
        siteCounterField.addChangeListener( new ChangeListener() {
            @Override
            public void stateChanged(final ChangeEvent e) {
                updatePassword( true );
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
        passwordField.setAlignmentX( Component.CENTER_ALIGNMENT );
        passwordField.setHorizontalAlignment( JTextField.CENTER );
        passwordField.putClientProperty( "JPasswordField.cutCopyAllowed", true );
        passwordField.setEditable( false );
        passwordField.setBackground( null );
        passwordField.setBorder( null );
        passwordEchoChar = passwordField.getEchoChar();
        passwordEchoFont = passwordField.getFont().deriveFont( 40f );
        updateMask();

        // Tip
        tipLabel = Components.label( " ", SwingConstants.CENTER );
        tipLabel.setAlignmentX( Component.CENTER_ALIGNMENT );
        JPanel passwordContainer = Components.boxLayout( BoxLayout.PAGE_AXIS, maskPasswordField, Box.createGlue(), passwordField,
                                                         Box.createGlue(), tipLabel );
        passwordContainer.setOpaque( true );
        passwordContainer.setBackground( Color.white );
        passwordContainer.setBorder( BorderFactory.createEmptyBorder( 8, 8, 8, 8 ) );
        root.add( Box.createVerticalStrut( 8 ) );
        root.add( Components.borderPanel( passwordContainer, BorderFactory.createLoweredSoftBevelBorder(), Res.colors().frameBg() ),
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
    private ListenableFuture<String> updatePassword(boolean allowNameCompletion) {

        final String siteNameQuery = siteNameField.getText();
        if (updatingUI)
            return Futures.immediateCancelledFuture();
        if (siteNameQuery == null || siteNameQuery.isEmpty() || !user.isKeyAvailable()) {
            siteActionButton.setVisible( false );
            tipLabel.setText( null );
            passwordField.setText( null );
            return Futures.immediateCancelledFuture();
        }

        final MPSiteType siteType = siteTypeField.getModel().getElementAt( siteTypeField.getSelectedIndex() );
        final MasterKey.Version siteVersion = siteVersionField.getItemAt( siteVersionField.getSelectedIndex() );
        final UnsignedInteger siteCounter = UnsignedInteger.valueOf( ((Number) siteCounterField.getValue()).longValue() );

        Iterable<Site> siteResults = user.findSitesByName( siteNameQuery );
        if (!allowNameCompletion)
            siteResults = FluentIterable.from( siteResults ).filter( new PredicateNN<Site>() {
                @Override
                public boolean apply(Site input) {
                    return siteNameQuery.equals( input.getSiteName() );
                }
            } );
        final Site site = Iterables.getFirst( siteResults,
                                              new IncognitoSite( siteNameQuery, siteType, siteCounter, siteVersion ) );
        if (currentSite != null && currentSite.getSiteName().equals( site.getSiteName() )) {
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
                        siteActionButton.setVisible( user instanceof ModelUser );
                        if (currentSite instanceof ModelSite)
                            siteActionButton.setText( "Delete Site" );
                        else
                            siteActionButton.setText( "Add Site" );
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
        updatePassword( true );
    }

    @Override
    public void removeUpdate(final DocumentEvent e) {
        updatePassword( false );
    }

    @Override
    public void changedUpdate(final DocumentEvent e) {
        updatePassword( true );
    }
}
