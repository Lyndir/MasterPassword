package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.ImmutableCollection;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.util.CollectionListModel;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.*;
import com.lyndir.masterpassword.model.impl.MPFileSite;
import com.lyndir.masterpassword.model.impl.MPFileUser;
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Transferable;
import java.awt.event.*;
import java.util.Objects;
import java.util.Random;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.*;


/**
 * @author lhunath, 2018-07-14
 */
public class UserPanel extends Components.GradientPanel implements MPUser.Listener {

    private static final Logger logger = Logger.get( UserPanel.class );

    @Nullable
    private MPUser<?> user;

    public UserPanel() {
        super( new BorderLayout( Components.margin(), Components.margin() ), null );
        setBorder( Components.marginBorder() );
        setUser( null );
    }

    public void setUser(@Nullable final MPUser<?> user) {
        if ((this.user != null) && !Objects.equals( this.user, user ))
            this.user.removeListener( this );

        this.user = user;

        if (this.user != null)
            this.user.addListener( this );

        Res.ui( () -> {
            removeAll();
            if (this.user == null)
                add( new NoUserPanel(), BorderLayout.CENTER );

            else {
                if (!this.user.isMasterKeyAvailable())
                    add( new AuthenticateUserPanel( this.user ), BorderLayout.CENTER );

                else
                    add( new AuthenticatedUserPanel( this.user ), BorderLayout.CENTER );
            }

            revalidate();
            transferFocus();
        } );
    }

    @Override
    public void onUserUpdated(final MPUser<?> user) {
        setUser( user );
    }

    @Override
    public void onUserAuthenticated(final MPUser<?> user) {
        setUser( user );
    }

    private static final class NoUserPanel extends JPanel {

        private NoUserPanel() {
            setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            add( Box.createGlue() );
            add( Components.heading( "Select a user to proceed." ) );
            add( Box.createGlue() );
        }
    }


    private static final class AuthenticateUserPanel extends JPanel implements ActionListener, DocumentListener {

        private static final Random random = new Random();

        @Nonnull
        private final MPUser<?> user;

        private final JPasswordField masterPasswordField = Components.passwordField();
        private final JLabel         errorLabel          = Components.label();
        private final JLabel         identiconLabel      = Components.label( SwingConstants.CENTER );

        private Future<?> identiconJob;

        private AuthenticateUserPanel(@Nonnull final MPUser<?> user) {
            setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            this.user = user;

            add( Components.heading( user.getFullName(), SwingConstants.CENTER ) );
            add( Box.createGlue() );

            add( Components.label( "Master Password:" ) );
            add( Components.strut() );
            add( masterPasswordField );
            masterPasswordField.addActionListener( this );
            masterPasswordField.getDocument().addDocumentListener( this );
            add( errorLabel );
            errorLabel.setForeground( Res.colors().errorFg() );

            add( Components.strut() );
            add( identiconLabel );
            identiconLabel.setFont( Res.fonts().emoticonsFont( Components.TEXT_SIZE_CONTROL ) );

            add( Box.createGlue() );
        }

        @Override
        public void actionPerformed(final ActionEvent event) {
            updateIdenticon();

            char[] masterPassword = masterPasswordField.getPassword();
            Res.job( () -> {
                try {
                    user.authenticate( masterPassword );
                }
                catch (final MPIncorrectMasterPasswordException e) {
                    logger.wrn( e, "During user authentication for: %s", user );
                    errorLabel.setText( e.getLocalizedMessage() );
                }
                catch (final MPAlgorithmException e) {
                    logger.err( e, "During user authentication for: %s", user );
                    errorLabel.setText( e.getLocalizedMessage() );
                }
            } );
        }

        @Override
        public void insertUpdate(final DocumentEvent event) {
            update();
        }

        @Override
        public void removeUpdate(final DocumentEvent event) {
            update();
        }

        @Override
        public void changedUpdate(final DocumentEvent event) {
            update();
        }

        private synchronized void update() {
            errorLabel.setText( null );

            if (identiconJob != null)
                identiconJob.cancel( true );

            identiconJob = Res.job( this::updateIdenticon, 100 + random.nextInt( 100 ), TimeUnit.MILLISECONDS );
        }

        private void updateIdenticon() {
            char[] masterPassword = masterPasswordField.getPassword();
            MPIdenticon identicon = ((masterPassword != null) && (masterPassword.length > 0))?
                    new MPIdenticon( user.getFullName(), masterPassword ): null;

            Res.ui( () -> {
                if (identicon != null) {
                    identiconLabel.setForeground(
                            Res.colors().fromIdenticonColor( identicon.getColor(), Res.Colors.BackgroundMode.LIGHT ) );
                    identiconLabel.setText( identicon.getText() );
                } else {
                    identiconLabel.setForeground( null );
                    identiconLabel.setText( " " );
                }
            } );
        }
    }


    private static final class AuthenticatedUserPanel extends JPanel implements ActionListener, DocumentListener, ListSelectionListener,
            KeyListener {

        public static final int SIZE_RESULT = 48;

        @Nonnull
        private final MPUser<?>                      user;
        private final JLabel                         passwordLabel = Components.label( SwingConstants.CENTER );
        private final JLabel                         passwordField = Components.heading( SwingConstants.CENTER );
        private final JLabel                         queryLabel    = Components.label();
        private final JTextField                     queryField    = Components.textField();
        private final CollectionListModel<MPSite<?>> sitesModel    = new CollectionListModel<>();
        private final JList<MPSite<?>>               sitesList     = Components.list( sitesModel,
                                                                                      value -> (value != null)? value.getName(): null );
        private       Future<?>                      updateSitesJob;

        private AuthenticatedUserPanel(@Nonnull final MPUser<?> user) {
            setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            this.user = user;

            add( Components.heading( user.getFullName(), SwingConstants.CENTER ) );
            add( Components.strut() );

            add( passwordLabel );
            add( passwordField );
            passwordField.setForeground( Res.colors().highlightFg() );
            passwordField.setFont( Res.fonts().bigValueFont( SIZE_RESULT ) );
            add( Box.createGlue() );
            add( Components.strut() );

            add( queryLabel );
            queryLabel.setText( strf( "%s's password for:", user.getFullName() ) );
            add( queryField );
            queryField.putClientProperty( "JTextField.variant", "search" );
            queryField.addActionListener( this );
            queryField.addKeyListener( this );
            queryField.getDocument().addDocumentListener( this );
            queryField.requestFocusInWindow();
            add( Components.strut() );
            add( Components.scrollPane( sitesList ) );
            sitesModel.registerList( sitesList );
            sitesList.addListSelectionListener( this );
            add( Box.createGlue() );
        }

        @Override
        public void actionPerformed(final ActionEvent event) {
            MPSite<?> site = sitesList.getSelectedValue();
            showSiteResult( site, result -> {
                if (result == null)
                    return;

                if (site instanceof MPFileSite)
                    ((MPFileSite) site).use();

                Transferable clipboardContents = new StringSelection( result );
                Toolkit.getDefaultToolkit().getSystemClipboard().setContents( clipboardContents, null );

                Res.ui( () -> {
                    Window window = SwingUtilities.windowForComponent( this );
                    window.dispatchEvent( new WindowEvent( window, WindowEvent.WINDOW_CLOSING ) );
                } );
            } );
        }

        @Override
        public void insertUpdate(final DocumentEvent event) {
            updateSites();
        }

        @Override
        public void removeUpdate(final DocumentEvent event) {
            updateSites();
        }

        @Override
        public void changedUpdate(final DocumentEvent event) {
            updateSites();
        }

        @Override
        public void valueChanged(final ListSelectionEvent event) {
            showSiteResult( event.getValueIsAdjusting()? null: sitesList.getSelectedValue(), null );
        }

        private void showSiteResult(@Nullable final MPSite<?> site, @Nullable final Consumer<String> resultCallback) {
            if (site == null) {
                if (resultCallback != null)
                    resultCallback.accept( null );
                Res.ui( () -> {
                    passwordLabel.setText( " " );
                    passwordField.setText( " " );
                } );
                return;
            }

            String siteName = site.getName();
            Res.job( () -> {
                try {
                    String result = user.getMasterKey().siteResult(
                            siteName, user.getAlgorithm(), UnsignedInteger.ONE,
                            MPKeyPurpose.Authentication, null, MPResultType.GeneratedLong, null );
                    if (resultCallback != null)
                        resultCallback.accept( result );

                    Res.ui( () -> {
                        passwordLabel.setText( strf( "Your password for %s:", siteName ) );
                        passwordField.setText( result );
                    } );
                }
                catch (final MPKeyUnavailableException | MPAlgorithmException e) {
                    logger.err( e, "While resolving password for: %s", site );
                }
            } );
        }

        @Override
        public void keyTyped(final KeyEvent event) {
        }

        @Override
        public void keyPressed(final KeyEvent event) {
            if ((event.getKeyCode() == KeyEvent.VK_UP) || (event.getKeyCode() == KeyEvent.VK_DOWN))
                sitesList.dispatchEvent( event );
        }

        @Override
        public void keyReleased(final KeyEvent event) {
            if ((event.getKeyCode() == KeyEvent.VK_UP) || (event.getKeyCode() == KeyEvent.VK_DOWN))
                sitesList.dispatchEvent( event );
        }

        private synchronized void updateSites() {
            if (updateSitesJob != null)
                updateSitesJob.cancel( true );

            updateSitesJob = Res.job( () -> {
                ImmutableCollection<? extends MPSite<?>> sites = user.findSites( queryField.getText() );
                Res.ui( () -> sitesModel.set( sites ) );
            } );
        }
    }
}
