package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.Iterables;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.util.Components;
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.event.*;
import java.util.concurrent.Callable;
import javax.annotation.Nonnull;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;


/**
 * @author lhunath, 2014-06-08
 */
public class PasswordFrame extends JFrame implements DocumentListener {

    private final User                  user;
    private final JTextField            siteNameField;
    private final JButton               siteAddButton;
    private final JComboBox<MPSiteType> siteTypeField;
    private final JSpinner              siteCounterField;
    private final JTextField            passwordField;
    private final JLabel                tipLabel;
    private       boolean               updatingUI;
    private       Site                  currentSite;

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
        add( label = new JLabel( strf( "Generating passwords for: %s", user.getFullName() ) ), BorderLayout.NORTH );
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

        JComponent siteControls = Components.boxLayout( BoxLayout.LINE_AXIS, //
                                                        siteNameField = new JTextField() {
                                                            @Override
                                                            public Dimension getMaximumSize() {
                                                                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
                                                            }
                                                        }, siteAddButton = new JButton( "Add Site" ) {
                    @Override
                    public Dimension getMaximumSize() {
                        return new Dimension( 20, getPreferredSize().height );
                    }
                } );
        siteAddButton.setVisible( false );
        siteAddButton.setFont( Res.exoRegular().deriveFont( 12f ) );
        siteAddButton.setAlignmentX( RIGHT_ALIGNMENT );
        siteAddButton.setAlignmentY( CENTER_ALIGNMENT );
        siteAddButton.addActionListener( new ActionListener() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                PasswordFrame.this.user.addSite( currentSite );
                siteAddButton.setVisible( false );
            }
        } );
        siteControls.setAlignmentX( LEFT_ALIGNMENT );
        sitePanel.add( siteControls );
        siteNameField.setFont( Res.sourceCodeProRegular().deriveFont( 12f ) );
        siteNameField.setAlignmentX( LEFT_ALIGNMENT );
        siteNameField.getDocument().addDocumentListener( this );
        siteNameField.addActionListener( new ActionListener() {
            @Override
            public void actionPerformed(final ActionEvent e) {
                Futures.addCallback( updatePassword(), new FutureCallback<String>() {
                    @Override
                    public void onSuccess(final String sitePassword) {
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

                    @Override
                    public void onFailure(final Throwable t) {
                    }
                } );
            }
        } );

        // Site Type & Counter
        MPSiteType[] types = Iterables.toArray( MPSiteType.forClass( MPSiteTypeClass.Generated ), MPSiteType.class );
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
        siteTypeField.setFont( Res.sourceCodeProRegular().deriveFont( 12f ) );
        siteTypeField.setAlignmentX( LEFT_ALIGNMENT );
        siteTypeField.setAlignmentY( CENTER_ALIGNMENT );
        siteTypeField.setSelectedItem( MPSiteType.GeneratedLong );
        siteTypeField.addItemListener( new ItemListener() {
            @Override
            public void itemStateChanged(final ItemEvent e) {
                updatePassword();
            }
        } );

        siteCounterField.setFont( Res.sourceCodeProRegular().deriveFont( 12f ) );
        siteCounterField.setAlignmentX( RIGHT_ALIGNMENT );
        siteCounterField.setAlignmentY( CENTER_ALIGNMENT );
        siteCounterField.addChangeListener( new ChangeListener() {
            @Override
            public void stateChanged(final ChangeEvent e) {
                updatePassword();
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
        tipLabel.setFont( Res.exoRegular().deriveFont( 9f ) );
        tipLabel.setAlignmentX( Component.CENTER_ALIGNMENT );

        add( Components.boxLayout( BoxLayout.PAGE_AXIS, passwordField, tipLabel ), BorderLayout.SOUTH );

        pack();
        setMinimumSize( getSize() );
        setPreferredSize( new Dimension( 600, getSize().height ) );
        pack();

        setLocationByPlatform( true );
        setLocationRelativeTo( null );
    }

    @Nonnull
    private ListenableFuture<String> updatePassword() {

        final String siteNameQuery = siteNameField.getText();
        if (updatingUI)
            return Futures.immediateCancelledFuture();
        if (siteNameQuery == null || siteNameQuery.isEmpty() || !user.hasKey()) {
            passwordField.setText( null );
            tipLabel.setText( null );
            return Futures.immediateCancelledFuture();
        }

        MPSiteType siteType = siteTypeField.getModel().getElementAt( siteTypeField.getSelectedIndex() );
        final int siteCounter = (Integer) siteCounterField.getValue();
        final Site site = currentSite != null && currentSite.getSiteName().equals( siteNameQuery )? currentSite
                : Iterables.getFirst( user.findSitesByName( siteNameQuery ), new IncognitoSite( siteNameQuery, siteType, siteCounter ) );
        assert site != null;
        if (site == currentSite) {
            site.setSiteType( siteType );
            site.setSiteCounter( siteCounter );
        }

        ListenableFuture<String> passwordFuture = Res.execute( new Callable<String>() {
            @Override
            public String call()
                    throws Exception {
                return user.getKey().encode( site.getSiteName(), site.getSiteType(), site.getSiteCounter(), MPSiteVariant.Password, null );
            }
        } );
        Futures.addCallback( passwordFuture, new FutureCallback<String>() {
            @Override
            public void onSuccess(final String sitePassword) {
                SwingUtilities.invokeLater( new Runnable() {
                    @Override
                    public void run() {
                        updatingUI = true;
                        currentSite = site;
                        siteAddButton.setVisible( user instanceof ModelUser && !(currentSite instanceof ModelSite) );
                        siteTypeField.setSelectedItem( currentSite.getSiteType() );
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
