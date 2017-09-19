package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.ifNotNullElse;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Predicate;
import com.google.common.collect.FluentIterable;
import com.google.common.collect.Iterables;
import com.google.common.primitives.UnsignedInteger;
import com.google.common.util.concurrent.*;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.model.*;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.gui.util.UnsignedIntegerModel;
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

    @SuppressWarnings("FieldCanBeLocal")
    private final Components.GradientPanel     root;
    private final JTextField                   siteNameField;
    private final JButton                      siteActionButton;
    private final JComboBox<MasterKey.Version> siteVersionField;
    private final JSpinner                     siteCounterField;
    private final UnsignedIntegerModel         siteCounterModel;
    private final JComboBox<MPResultType>      resultTypeField;
    private final JPasswordField               passwordField;
    private final JLabel                       tipLabel;
    private final JCheckBox                    maskPasswordField;
    private final char                         passwordEchoChar;
    private final Font                         passwordEchoFont;
    private final User                         user;

    @Nullable
    private Site    currentSite;
    private boolean updatingUI;

    public PasswordFrame(final User user) {
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
                if (currentSite instanceof ModelSite)
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
        siteCounterModel = new UnsignedIntegerModel( UnsignedInteger.ONE, UnsignedInteger.ONE );
        MPResultType[] types = Iterables.toArray( MPResultType.forClass( MPResultTypeClass.Template ), MPResultType.class );
        JComponent siteSettings = Components.boxLayout( BoxLayout.LINE_AXIS,                                                  //
                                                        resultTypeField = Components.comboBox( types ),                         //
                                                        Components.stud(),                                                    //
                                                        siteVersionField = Components.comboBox( MasterKey.Version.values() ), //
                                                        Components.stud(),                                                    //
                                                        siteCounterField = Components.spinner( siteCounterModel ) );
        sitePanel.add( siteSettings );
        resultTypeField.setFont( Res.valueFont().deriveFont( 12f ) );
        resultTypeField.setSelectedItem( MPResultType.DEFAULT );
        resultTypeField.addItemListener( new ItemListener() {
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
            public void itemStateChanged(final ItemEvent e) {
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
    private ListenableFuture<String> updatePassword(final boolean allowNameCompletion) {

        final String siteNameQuery = siteNameField.getText();
        if (updatingUI)
            return Futures.immediateCancelledFuture();
        if ((siteNameQuery == null) || siteNameQuery.isEmpty() || !user.isKeyAvailable()) {
            siteActionButton.setVisible( false );
            tipLabel.setText( null );
            passwordField.setText( null );
            return Futures.immediateCancelledFuture();
        }

        MPResultType      resultType    = resultTypeField.getModel().getElementAt( resultTypeField.getSelectedIndex() );
        MasterKey.Version siteVersion = siteVersionField.getItemAt( siteVersionField.getSelectedIndex() );
        UnsignedInteger   siteCounter = siteCounterModel.getNumber();

        Iterable<Site> siteResults = user.findSitesByName( siteNameQuery );
        if (!allowNameCompletion)
            siteResults = FluentIterable.from( siteResults ).filter( new Predicate<Site>() {
                @Override
                public boolean apply(@Nullable final Site siteResult) {
                    return (siteResult != null) && siteNameQuery.equals( siteResult.getSiteName() );
                }
            } );
        final Site site = ifNotNullElse( Iterables.getFirst( siteResults, null ),
                                         new IncognitoSite( siteNameQuery, siteCounter, resultType, siteVersion ) );
        if ((currentSite != null) && currentSite.getSiteName().equals( site.getSiteName() )) {
            site.setResultType( resultType );
            site.setAlgorithmVersion( siteVersion );
            site.setSiteCounter( siteCounter );
        }

        ListenableFuture<String> passwordFuture = Res.execute( this, new Callable<String>() {
            @Override
            public String call()
                    throws Exception {
                return user.getKey( site.getAlgorithmVersion() )
                           .siteResult( site.getSiteName(), site.getSiteCounter(), MPKeyPurpose.Authentication, null, site.getResultType(), null );
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
                        resultTypeField.setSelectedItem( currentSite.getResultType() );
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
