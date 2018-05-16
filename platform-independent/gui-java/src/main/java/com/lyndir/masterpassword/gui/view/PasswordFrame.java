//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.Iterables;
import com.google.common.primitives.UnsignedInteger;
import com.google.common.util.concurrent.*;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.gui.util.UnsignedIntegerModel;
import com.lyndir.masterpassword.model.MPSite;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.impl.MPFileSite;
import com.lyndir.masterpassword.model.impl.MPFileUser;
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Transferable;
import java.awt.event.*;
import java.util.Collection;
import java.util.stream.Collectors;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class PasswordFrame<U extends MPUser<S>, S extends MPSite<?>> extends JFrame implements DocumentListener {

    @SuppressWarnings("FieldCanBeLocal")
    private final Components.GradientPanel       root;
    private final JTextField                     siteNameField;
    private final JButton                        siteActionButton;
    private final JComboBox<MPAlgorithm.Version> siteVersionField;
    private final JSpinner                       siteCounterField;
    private final UnsignedIntegerModel           siteCounterModel;
    private final JComboBox<MPResultType>        resultTypeField;
    private final JPasswordField                 passwordField;
    private final JLabel                         tipLabel;
    private final JCheckBox                      maskPasswordField;
    private final char                           passwordEchoChar;
    private final Font                           passwordEchoFont;
    private final U                              user;

    @Nullable
    private S       currentSite;
    private boolean updatingUI;

    @SuppressWarnings("MagicNumber")
    protected PasswordFrame(final U user) {
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
                        Transferable clipboardContents = new StringSelection( sitePassword );
                        Toolkit.getDefaultToolkit().getSystemClipboard().setContents( clipboardContents, null );

                        SwingUtilities.invokeLater( () -> {
                            passwordField.setText( null );
                            siteNameField.setText( null );

                            dispatchEvent( new WindowEvent( PasswordFrame.this, WindowEvent.WINDOW_CLOSING ) );
                        } );
                    }

                    @Override
                    public void onFailure(@Nonnull final Throwable t) {
                    }
                } );
            }
        } );
        siteActionButton.addActionListener( e -> {
            if (currentSite == null)
                return;
            if (currentSite instanceof MPFileSite)
                this.user.deleteSite( currentSite );
            else
                this.user.addSite( currentSite );
            siteNameField.requestFocus();

            updatePassword( true );
        } );
        sitePanel.add( siteControls );
        sitePanel.add( Components.stud() );

        // Site Type & Counter
        siteCounterModel = new UnsignedIntegerModel( UnsignedInteger.ONE, UnsignedInteger.ONE );
        MPResultType[] types = Iterables.toArray( MPResultType.forClass( MPResultTypeClass.Template ), MPResultType.class );
        JComponent siteSettings = Components.boxLayout( BoxLayout.LINE_AXIS,                                                  //
                                                        resultTypeField = Components.comboBox( types ),                         //
                                                        Components.stud(),                                                    //
                                                        siteVersionField = Components.comboBox( MPAlgorithm.Version.values() ), //
                                                        Components.stud(),                                                    //
                                                        siteCounterField = Components.spinner( siteCounterModel ) );
        sitePanel.add( siteSettings );
        resultTypeField.setFont( Res.valueFont().deriveFont( resultTypeField.getFont().getSize2D() ) );
        resultTypeField.setSelectedItem( user.getAlgorithm().mpw_default_result_type() );
        resultTypeField.addItemListener( e -> updatePassword( true ) );

        siteVersionField.setFont( Res.valueFont().deriveFont( siteVersionField.getFont().getSize2D() ) );
        siteVersionField.setAlignmentX( RIGHT_ALIGNMENT );
        siteVersionField.setSelectedItem( user.getAlgorithm() );
        siteVersionField.addItemListener( e -> updatePassword( true ) );

        siteCounterField.setFont( Res.valueFont().deriveFont( siteCounterField.getFont().getSize2D() ) );
        siteCounterField.setAlignmentX( RIGHT_ALIGNMENT );
        siteCounterField.addChangeListener( e -> updatePassword( true ) );

        // Mask
        maskPasswordField = Components.checkBox( "Hide Password" );
        maskPasswordField.setAlignmentX( Component.CENTER_ALIGNMENT );
        maskPasswordField.setSelected( true );
        maskPasswordField.addItemListener( e -> updateMask() );

        // Password
        passwordField = Components.passwordField();
        passwordField.setAlignmentX( Component.CENTER_ALIGNMENT );
        passwordField.setHorizontalAlignment( SwingConstants.CENTER );
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

    @SuppressWarnings("MagicNumber")
    private void updateMask() {
        passwordField.setEchoChar( maskPasswordField.isSelected()? passwordEchoChar: (char) 0 );
        passwordField.setFont( maskPasswordField.isSelected()? passwordEchoFont: Res.bigValueFont().deriveFont( 40f ) );
    }

    @Nonnull
    private ListenableFuture<String> updatePassword(final boolean allowNameCompletion) {

        String siteNameQuery = siteNameField.getText();
        if (updatingUI)
            return Futures.immediateCancelledFuture();
        if ((siteNameQuery == null) || siteNameQuery.isEmpty() || !user.isMasterKeyAvailable()) {
            siteActionButton.setVisible( false );
            tipLabel.setText( null );
            passwordField.setText( null );
            return Futures.immediateCancelledFuture();
        }

        MPResultType    resultType    = resultTypeField.getModel().getElementAt( resultTypeField.getSelectedIndex() );
        MPAlgorithm     siteAlgorithm = siteVersionField.getItemAt( siteVersionField.getSelectedIndex() ).getAlgorithm();
        UnsignedInteger siteCounter   = siteCounterModel.getNumber();

        Collection<S> siteResults = user.findSites( siteNameQuery );
        if (!allowNameCompletion)
            siteResults = siteResults.stream().filter(
                    siteResult -> (siteResult != null) && siteNameQuery.equals( siteResult.getName() ) ).collect( Collectors.toList() );
        S site = ifNotNullElse( Iterables.getFirst( siteResults, null ),
                                createSite( user, siteNameQuery, siteCounter, resultType, siteAlgorithm ) );
        if ((currentSite != null) && currentSite.getName().equals( site.getName() )) {
            site.setResultType( resultType );
            site.setAlgorithm( siteAlgorithm );
            site.setCounter( siteCounter );
        }

        ListenableFuture<String> passwordFuture = Res.execute( this, () -> site.getResult( MPKeyPurpose.Authentication, null, null ) );
        Futures.addCallback( passwordFuture, new FutureCallback<String>() {
            @Override
            public void onSuccess(@Nullable final String sitePassword) {
                SwingUtilities.invokeLater( () -> {
                    updatingUI = true;
                    currentSite = site;
                    siteActionButton.setVisible( user instanceof MPFileUser );
                    if (currentSite instanceof MPFileSite)
                        siteActionButton.setText( "Delete Site" );
                    else
                        siteActionButton.setText( "Add Site" );
                    resultTypeField.setSelectedItem( currentSite.getResultType() );
                    siteVersionField.setSelectedItem( currentSite.getAlgorithm() );
                    siteCounterField.setValue( currentSite.getCounter() );
                    siteNameField.setText( currentSite.getName() );
                    if (siteNameField.getText().startsWith( siteNameQuery ))
                        siteNameField.select( siteNameQuery.length(), siteNameField.getText().length() );

                    passwordField.setText( sitePassword );
                    tipLabel.setText( "Press [Enter] to copy the password.  Then paste it into the password field." );
                    updatingUI = false;
                } );
            }

            @Override
            public void onFailure(@Nonnull final Throwable t) {
            }
        } );

        return passwordFuture;
    }

    protected abstract S createSite(U user, String siteName, UnsignedInteger siteCounter, MPResultType resultType, MPAlgorithm algorithm);

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
