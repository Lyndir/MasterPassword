package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Joiner;
import com.google.common.base.Strings;
import com.google.common.collect.ImmutableList;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.gui.model.MPNewSite;
import com.lyndir.masterpassword.gui.util.*;
import com.lyndir.masterpassword.model.*;
import com.lyndir.masterpassword.model.impl.*;
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Transferable;
import java.awt.event.*;
import java.util.*;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;


/**
 * @author lhunath, 2018-07-14
 */
@SuppressWarnings("SerializableStoresNonSerializable")
public class UserContentPanel extends JPanel implements FilesPanel.Listener, MPUser.Listener {

    private static final Random  random     = new Random();
    private static final Logger  logger     = Logger.get( UserContentPanel.class );
    private static final JButton iconButton = Components.button( Res.icons().user(), null, null );

    private final JButton addButton    = Components.button( Res.icons().add(), event -> addUser(),
                                                            "Add a new user to Master Password." );

    private final JPanel userToolbar = Components.panel( BoxLayout.PAGE_AXIS );
    private final JPanel siteToolbar = Components.panel( BoxLayout.PAGE_AXIS );

    @Nullable
    private MPUser<?> listeningUser;

    public UserContentPanel() {
        userToolbar.setPreferredSize( iconButton.getPreferredSize() );
        siteToolbar.setPreferredSize( iconButton.getPreferredSize() );

        setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );
        setBorder( Components.marginBorder() );
        setUser( null );
    }

    protected JComponent getUserToolbar() {
        return userToolbar;
    }

    protected JComponent getSiteToolbar() {
        return siteToolbar;
    }

    @Override
    public void onUserSelected(@Nullable final MPUser<?> user) {
        setUser( user );
    }

    @Override
    public void onUserUpdated(final MPUser<?> user) {
        setUser( user );
    }

    @Override
    public void onUserAuthenticated(final MPUser<?> user) {
        setUser( user );
    }

    @Override
    public void onUserInvalidated(final MPUser<?> user) {
        setUser( user );
    }

    private void setUser(@Nullable final MPUser<?> user) {
        Res.ui( () -> {
            if (listeningUser != null)
                listeningUser.removeListener( this );
            listeningUser = user;

            userToolbar.removeAll();
            siteToolbar.removeAll();
            removeAll();

            if (user == null)
                add( new NoUserPanel() );

            else {
                user.addListener( this );

                if (!user.isMasterKeyAvailable())
                    add( new AuthenticateUserPanel( user ) );

                else
                    add( new AuthenticatedUserPanel( user ) );
            }

            revalidate();
            transferFocus();
        } );
    }

    private void addUser() {
        Object fullName = JOptionPane.showInputDialog(
                this, strf( "<html>Enter your full legal name:</html>" ), "Add User",
                JOptionPane.QUESTION_MESSAGE, null, null, "Robert Lee Mitchell" );
        if (fullName == null)
            return;

        setUser( MPFileUserManager.get().add( fullName.toString() ) );
    }

    private final class NoUserPanel extends JPanel {

        private NoUserPanel() {
            setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            userToolbar.add( addButton );

            add( Box.createGlue() );
            add( Components.heading( "Select a user to proceed." ) );
            add( Box.createGlue() );
        }
    }


    private final class AuthenticateUserPanel extends JPanel implements ActionListener, DocumentListener {

        @Nonnull
        private final MPUser<?> user;

        private final JButton deleteButton = Components.button( Res.icons().delete(), event -> deleteUser(),
                                                                "Delete this user from Master Password." );

        private final JPasswordField masterPasswordField = Components.passwordField();
        private final JLabel         errorLabel          = Components.label();
        private final JLabel         identiconLabel      = Components.label( SwingConstants.CENTER );

        private Future<?> identiconJob;

        private AuthenticateUserPanel(@Nonnull final MPUser<?> user) {
            setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            this.user = user;

            userToolbar.add( addButton );
            userToolbar.add( deleteButton );

            add( Components.heading( user.getFullName(), SwingConstants.CENTER ) );
            add( Components.strut() );

            add( identiconLabel );
            identiconLabel.setFont( Res.fonts().emoticonsFont( Components.TEXT_SIZE_CONTROL ) );
            add( Box.createGlue() );

            add( Components.label( "Master Password:" ) );
            add( Components.strut() );
            add( masterPasswordField );
            masterPasswordField.addActionListener( this );
            masterPasswordField.getDocument().addDocumentListener( this );
            add( errorLabel );
            errorLabel.setForeground( Res.colors().errorFg() );
            add( Box.createGlue() );
        }

        private void deleteUser() {
            MPFileUser fileUser = (user instanceof MPFileUser)? (MPFileUser) user: null;
            if (fileUser == null)
                return;

            if (JOptionPane.YES_OPTION == JOptionPane.showConfirmDialog(
                    this, strf( "<html>Delete the user <strong>%s</strong>?<br><br><em>%s</em></html>",
                                fileUser.getFullName(), fileUser.getFile().getName() ),
                    "Delete User", JOptionPane.YES_NO_OPTION ))
                MPFileUserManager.get().delete( fileUser );
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
            errorLabel.setText( " " );

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


    private final class AuthenticatedUserPanel extends JPanel implements KeyListener {

        public static final int SIZE_RESULT = 48;

        private final JButton userButton      = Components.button( Res.icons().user(), event -> showUserPreferences(),
                                                                   "Show user preferences." );
        private final JButton logoutButton    = Components.button( Res.icons().lock(), event -> logoutUser(),
                                                                   "Sign out and lock user." );
        private final JButton settingsButton  = Components.button( Res.icons().settings(), event -> showSiteSettings(),
                                                                   "Show site settings." );
        private final JButton questionsButton = Components.button( Res.icons().question(), null,
                                                                   "Show site recovery questions." );
        private final JButton deleteButton    = Components.button( Res.icons().delete(), event -> deleteSite(),
                                                                   "Delete the site from the user." );

        @Nonnull
        private final MPUser<?>                      user;
        private final JLabel                         passwordLabel = Components.label( SwingConstants.CENTER );
        private final JLabel                         passwordField = Components.heading( SwingConstants.CENTER );
        private final JLabel                         queryLabel    = Components.label();
        private final JTextField                     queryField    = Components.textField( null, this::updateSites );
        private final CollectionListModel<MPSite<?>> sitesModel    =
                new CollectionListModel<MPSite<?>>().selection( this::showSiteResult );
        private final JList<MPSite<?>>               sitesList     =
                Components.list( sitesModel, this::getSiteDescription );

        private Future<?> updateSitesJob;

        private AuthenticatedUserPanel(@Nonnull final MPUser<?> user) {
            setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            this.user = user;

            userToolbar.add( addButton );
            userToolbar.add( userButton );
            userToolbar.add( logoutButton );

            siteToolbar.add( settingsButton );
            siteToolbar.add( questionsButton );
            siteToolbar.add( deleteButton );
            settingsButton.setEnabled( false );
            deleteButton.setEnabled( false );

            add( Components.heading( user.getFullName(), SwingConstants.CENTER ) );

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
            queryField.addActionListener( event -> useSite() );
            queryField.addKeyListener( this );
            queryField.requestFocusInWindow();
            add( Components.strut() );
            add( Components.scrollPane( sitesList ) );
            sitesModel.registerList( sitesList );
            add( Box.createGlue() );
        }

        public void showUserPreferences() {
            ImmutableList.Builder<Component> components = ImmutableList.builder();

            MPFileUser fileUser = (user instanceof MPFileUser)? (MPFileUser) user: null;
            if (fileUser != null)
                components.add( Components.label( "Default Password Type:" ),
                                Components.comboBox( MPResultType.values(), MPResultType::getLongName,
                                                     fileUser.getDefaultType(), fileUser::setDefaultType ),
                                Components.strut() );

            components.add( Components.label( "Default Algorithm:" ),
                            Components.comboBox( MPAlgorithm.Version.values(), MPAlgorithm.Version::name,
                                                 user.getAlgorithm().version(),
                                                 version -> user.setAlgorithm( version.getAlgorithm() ) ) );

            Components.showDialog( this, user.getFullName(), new JOptionPane( Components.panel(
                    BoxLayout.PAGE_AXIS, components.build().toArray( new Component[0] ) ) ) );
        }

        public void logoutUser() {
            user.invalidate();
        }

        public void showSiteSettings() {
            MPSite<?> site = sitesModel.getSelectedItem();
            if (site == null)
                return;

            ImmutableList.Builder<Component> components = ImmutableList.builder();
            components.add( Components.label( "Algorithm:" ),
                            Components.comboBox( MPAlgorithm.Version.values(), MPAlgorithm.Version::name,
                                                 site.getAlgorithm().version(),
                                                 version -> site.setAlgorithm( version.getAlgorithm() ) ) );

            components.add( Components.label( "Counter:" ),
                            Components.spinner( new UnsignedIntegerModel( site.getCounter(), UnsignedInteger.ONE )
                                                        .selection( site::setCounter ) ),
                            Components.strut() );

            components.add( Components.label( "Password Type:" ),
                            Components.comboBox( MPResultType.values(), MPResultType::getLongName,
                                                 site.getResultType(), site::setResultType ),
                            Components.strut() );

            components.add( Components.label( "Login Type:" ),
                            Components.comboBox( MPResultType.values(), MPResultType::getLongName,
                                                 site.getLoginType(), site::setLoginType ),
                            Components.strut() );

            MPFileSite fileSite = (site instanceof MPFileSite)? (MPFileSite) site: null;
            if (fileSite != null)
                components.add( Components.label( "URL:" ),
                                Components.textField( fileSite.getUrl(), fileSite::setUrl ),
                                Components.strut() );

            Components.showDialog( this, site.getSiteName(), new JOptionPane( Components.panel(
                    BoxLayout.PAGE_AXIS, components.build().toArray( new Component[0] ) ) ) );
        }

        public void deleteSite() {
            MPSite<?> site = sitesModel.getSelectedItem();
            if (site == null)
                return;

            if (JOptionPane.YES_OPTION == JOptionPane.showConfirmDialog(
                    this, strf( "<html>Forget the site <strong>%s</strong>?</html>", site.getSiteName() ),
                    "Delete Site", JOptionPane.YES_NO_OPTION ))
                user.deleteSite( site );
        }

        private String getSiteDescription(@Nonnull final MPSite<?> site) {
            if (site instanceof MPNewSite)
                return strf( "<html><strong>%s</strong> &lt;Add new site&gt;</html>", queryField.getText() );

            ImmutableList.Builder<Object> parameters = ImmutableList.builder();
            try {
                MPFileSite fileSite = (site instanceof MPFileSite)? (MPFileSite) site: null;
                if (fileSite != null)
                    parameters.add( Res.format( fileSite.getLastUsed() ) );
                parameters.add( site.getAlgorithm().version() );
                parameters.add( strf( "#%d", site.getCounter().longValue() ) );
                parameters.add( strf( "<em>%s</em>", site.getLogin() ) );
                if ((fileSite != null) && (fileSite.getUrl() != null))
                    parameters.add( fileSite.getUrl() );
            }
            catch (final MPAlgorithmException | MPKeyUnavailableException e) {
                logger.err( e, "While generating site description." );
                parameters.add( e.getLocalizedMessage() );
            }

            return strf( "<html><strong>%s</strong> (%s)</html>", site.getSiteName(),
                         Joiner.on( " - " ).skipNulls().join( parameters.build() ) );
        }

        private void useSite() {
            MPSite<?> site = sitesModel.getSelectedItem();
            if (site instanceof MPNewSite) {
                if (JOptionPane.YES_OPTION == JOptionPane.showConfirmDialog(
                        this, strf( "<html>Remember the site <strong>%s</strong>?</html>", site.getSiteName() ),
                        "New Site", JOptionPane.YES_NO_OPTION )) {
                    sitesModel.setSelectedItem( user.addSite( site.getSiteName() ) );
                    useSite();
                }
                return;
            }

            showSiteResult( site, result -> {
                if (result == null)
                    return;

                if (site instanceof MPFileSite)
                    ((MPFileSite) site).use();

                Transferable clipboardContents = new StringSelection( result );
                Toolkit.getDefaultToolkit().getSystemClipboard().setContents( clipboardContents, null );

                Res.ui( () -> {
                    Window window = SwingUtilities.windowForComponent( UserContentPanel.this );
                    if (window != null)
                        window.dispatchEvent( new WindowEvent( window, WindowEvent.WINDOW_CLOSING ) );
                } );
            } );
        }

        private void showSiteResult(@Nullable final MPSite<?> site) {
            showSiteResult( site, null );
        }

        private void showSiteResult(@Nullable final MPSite<?> site, @Nullable final Consumer<String> resultCallback) {
            if (site == null) {
                if (resultCallback != null)
                    resultCallback.accept( null );
                Res.ui( () -> {
                    passwordLabel.setText( " " );
                    passwordField.setText( " " );
                    settingsButton.setEnabled( false );
                    deleteButton.setEnabled( false );
                } );
                return;
            }

            Res.job( () -> {
                try {
                    String result = site.getResult();
                    if (resultCallback != null)
                        resultCallback.accept( result );

                    Res.ui( () -> {
                        passwordLabel.setText( strf( "Your password for %s:", site.getSiteName() ) );
                        passwordField.setText( result );
                        settingsButton.setEnabled( true );
                        deleteButton.setEnabled( true );
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

        private synchronized void updateSites(@Nullable final String query) {
            if (updateSitesJob != null)
                updateSitesJob.cancel( true );

            updateSitesJob = Res.job( () -> {
                Collection<MPSite<?>> sites = new LinkedList<>();
                if (!Strings.isNullOrEmpty( query )) {
                    sites.addAll( new LinkedList<>( user.findSites( query ) ) );

                    if (sites.stream().noneMatch( site -> site.getSiteName().equalsIgnoreCase( query ) ))
                        sites.add( new MPNewSite( user, query ) );
                }

                Res.ui( () -> sitesModel.set( sites ) );
            } );
        }
    }
}
