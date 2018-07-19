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
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Transferable;
import java.awt.event.*;
import java.util.Objects;
import java.util.concurrent.Future;
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
        super( new BorderLayout( 20, 20 ), null );
        setBorder( BorderFactory.createEmptyBorder( 20, 20, 20, 20 ) );
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

        @Nonnull
        private final MPUser<?> user;

        private final JPasswordField masterPasswordField = Components.passwordField();
        private final JLabel         errorLabel          = Components.label( null );

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

            add( Box.createGlue() );

            Res.ui( false, masterPasswordField::requestFocusInWindow );
        }

        @Override
        public void actionPerformed(final ActionEvent event) {
            try {
                user.authenticate( masterPasswordField.getPassword() );
            }
            catch (final MPIncorrectMasterPasswordException e) {
                logger.wrn( e, "During user authentication for: %s", user );
                errorLabel.setText( e.getLocalizedMessage() );
            }
            catch (final MPAlgorithmException e) {
                logger.err( e, "During user authentication for: %s", user );
                errorLabel.setText( e.getLocalizedMessage() );
            }
        }

        @Override
        public void insertUpdate(final DocumentEvent event) {
            errorLabel.setText( null );
        }

        @Override
        public void removeUpdate(final DocumentEvent event) {
            errorLabel.setText( null );
        }

        @Override
        public void changedUpdate(final DocumentEvent event) {
            errorLabel.setText( null );
        }
    }


    private static final class AuthenticatedUserPanel extends JPanel implements ActionListener, DocumentListener, ListSelectionListener,
            KeyListener {

        @Nonnull
        private final MPUser<?>                      user;
        private final JLabel                         passwordLabel = Components.label( " ", SwingConstants.CENTER );
        private final JLabel                         passwordField = Components.heading( " ", SwingConstants.CENTER );
        private final JLabel                         queryLabel    = Components.label( " " );
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
            passwordField.setFont( Res.fonts().bigValueFont().deriveFont( Font.BOLD, 48 ) );
            add( Box.createGlue() );
            add( Components.strut() );

            add( queryLabel );
            queryLabel.setText( strf( "%s's password for:", user.getFullName() ) );
            add( queryField );
            queryField.addActionListener( this );
            queryField.addKeyListener( this );
            queryField.getDocument().addDocumentListener( this );
            add( Components.strut() );
            add( Components.scrollPane( sitesList ) );
            sitesList.addListSelectionListener( this );
            add( Box.createGlue() );

            Res.ui( false, queryField::requestFocusInWindow );
        }

        @Override
        public void actionPerformed(final ActionEvent event) {
            showSiteResult( sitesList.getSelectedValue(), result -> {
                if (result == null)
                    return;

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
