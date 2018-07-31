package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.*;
import com.google.common.collect.ImmutableList;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.ObjectUtils;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.gui.MPGuiConstants;
import com.lyndir.masterpassword.gui.MasterPassword;
import com.lyndir.masterpassword.gui.model.MPIncognitoUser;
import com.lyndir.masterpassword.gui.model.MPNewSite;
import com.lyndir.masterpassword.gui.util.*;
import com.lyndir.masterpassword.gui.util.Platform;
import com.lyndir.masterpassword.model.*;
import com.lyndir.masterpassword.model.impl.*;
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Transferable;
import java.awt.event.*;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.*;
import java.util.Optional;
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
public class UserContentPanel extends JPanel implements MasterPassword.Listener, MPUser.Listener {

    private static final Random  random     = new Random();
    private static final Logger  logger     = Logger.get( UserContentPanel.class );
    private static final JButton iconButton = Components.button( Res.icons().user(), null, null );

    private final JButton addButton    = Components.button( Res.icons().add(), event -> addUser(),
                                                            "Add a new user to Master Password." );
    private final JButton importButton = Components.button( Res.icons().import_(), event -> importUser(),
                                                            "Import a user from a backup file into Master Password." );
    private final JButton helpButton   = Components.button( Res.icons().help(), event -> showHelp(),
                                                            "Show information on how to use Master Password." );

    private final JPanel userToolbar = Components.panel( BoxLayout.PAGE_AXIS );
    private final JPanel siteToolbar = Components.panel( BoxLayout.PAGE_AXIS );

    @Nullable
    private MPUser<?>   showingUser;
    private ContentMode contentMode;

    public UserContentPanel() {
        userToolbar.setPreferredSize( iconButton.getPreferredSize() );
        siteToolbar.setPreferredSize( iconButton.getPreferredSize() );

        setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );
        setBorder( Components.marginBorder() );
        showUser( null );

        MasterPassword.get().addListener( this );
    }

    protected JComponent getUserToolbar() {
        return userToolbar;
    }

    protected JComponent getSiteToolbar() {
        return siteToolbar;
    }

    @Override
    public void onUserSelected(@Nullable final MPUser<?> user) {
        showUser( user );
    }

    @Override
    public void onUserUpdated(final MPUser<?> user) {
        showUser( user );
    }

    @Override
    public void onUserAuthenticated(final MPUser<?> user) {
        showUser( user );
    }

    @Override
    public void onUserInvalidated(final MPUser<?> user) {
        showUser( user );
    }

    private void showUser(@Nullable final MPUser<?> user) {
        Res.ui( () -> {
            if (showingUser != null)
                showingUser.removeListener( this );

            ContentMode newContentMode = ContentMode.getContentMode( user );
            if ((newContentMode != contentMode) || !ObjectUtils.equals( showingUser, user )) {
                userToolbar.removeAll();
                siteToolbar.removeAll();
                removeAll();
                showingUser = user;
                switch (contentMode = newContentMode) {
                    case NO_USER:
                        add( new NoUserPanel() );
                        break;
                    case AUTHENTICATE:
                        add( new AuthenticateUserPanel( Preconditions.checkNotNull( showingUser ) ) );
                        break;
                    case AUTHENTICATED:
                        add( new AuthenticatedUserPanel( Preconditions.checkNotNull( showingUser ) ) );
                        break;
                }
                revalidate();
                transferFocus();
            }

            if (showingUser != null)
                showingUser.addListener( this );
        } );
    }

    private void addUser() {
        JTextField nameField      = Components.textField( "Robert Lee Mitchell", null );
        JCheckBox  incognitoField = Components.checkBox( "<html>Incognito <em>(Do not save this user to disk)</em></html>" );
        if (JOptionPane.OK_OPTION != Components.showDialog( this, "Add User", new JOptionPane( Components.panel(
                BoxLayout.PAGE_AXIS,
                Components.label( "<html>Enter your full legal name:</html>" ),
                Components.strut(),
                nameField,
                Components.strut(),
                incognitoField ), JOptionPane.QUESTION_MESSAGE, JOptionPane.OK_CANCEL_OPTION ) {
            @Override
            public void selectInitialValue() {
                nameField.requestFocusInWindow();
            }
        } ))
            return;
        String fullName = nameField.getText();
        if (Strings.isNullOrEmpty( fullName ))
            return;

        if (incognitoField.isSelected())
            MasterPassword.get().activateUser( new MPIncognitoUser( fullName ) );
        else
            MasterPassword.get().activateUser( MPFileUserManager.get().add( fullName ) );
    }

    private void importUser() {
        File importFile = Components.showLoadDialog( this, "Import User File" );
        if (importFile == null)
            return;

        try {
            MPFileUser importUser = MPFileUser.load( importFile );
            if (importUser == null) {
                JOptionPane.showMessageDialog(
                        this, "Not a Master Password file.",
                        "Import Failed", JOptionPane.ERROR_MESSAGE );
                return;
            }

            JPasswordField passwordField = Components.passwordField();
            if (JOptionPane.OK_OPTION == Components.showDialog( this, "Import User", new JOptionPane( Components.panel(
                    BoxLayout.PAGE_AXIS,
                    Components.label( strf( "<html>Enter the master password to import <strong>%s</strong>:</html>",
                                            importUser.getFullName() ) ),
                    Components.strut(),
                    passwordField ), JOptionPane.QUESTION_MESSAGE, JOptionPane.OK_CANCEL_OPTION ) {
                @Override
                public void selectInitialValue() {
                    passwordField.requestFocusInWindow();
                }
            } )) {
                try {
                    importUser.authenticate( passwordField.getPassword() );
                    Optional<MPFileUser> existingUser = MPFileUserManager.get().getFiles().stream().filter(
                            user -> user.getFullName().equalsIgnoreCase( importUser.getFullName() ) ).findFirst();
                    if (existingUser.isPresent() && (JOptionPane.YES_OPTION != JOptionPane.showConfirmDialog(
                            this,
                            strf( "<html>Importing user <strong>%s</strong> from this file will replace the existing user with the imported one.<br>"
                                  + "Are you sure?<br><br>"
                                  + "<em>Existing user last modified: %s<br>Imported user last modified: %s</em></html>",
                                  importUser.getFullName(),
                                  Res.format( existingUser.get().getLastUsed() ),
                                  Res.format( importUser.getLastUsed() ) ) )))
                        return;

                    MasterPassword.get().activateUser( MPFileUserManager.get().add( importUser ) );
                }
                catch (final MPIncorrectMasterPasswordException | MPAlgorithmException e) {
                    JOptionPane.showMessageDialog(
                            this, e.getLocalizedMessage(),
                            "Import Failed", JOptionPane.ERROR_MESSAGE );
                }
            }
        }
        catch (final IOException e) {
            logger.err( e, "While reading user import file." );
            JOptionPane.showMessageDialog(
                    this, strf( "<html>Couldn't read import file:<br><pre>%s</pre></html>.", e.getLocalizedMessage() ),
                    "Import Failed", JOptionPane.ERROR_MESSAGE );
        }
        catch (final MPMarshalException e) {
            logger.err( e, "While parsing user import file." );
            JOptionPane.showMessageDialog(
                    this, strf( "<html>Couldn't parse import file:<br><pre>%s</pre></html>.", e.getLocalizedMessage() ),
                    "Import Failed", JOptionPane.ERROR_MESSAGE );
        }
    }

    private void showHelp() {
        JOptionPane.showMessageDialog( this, Components.linkLabel( strf(
                "<h1>Master Password - v%s</h1>"
                + "<p>The primary goal of this application is to provide a reliable security solution that also "
                + "makes you independent from your computer.  If you lose access to this computer or your data, "
                + "the application can regenerate all your secrets from scratch on any new device.</p>"
                + "<h2>Opening Master Password</h2>"
                + "<p>To use Master Password, simply open the application on your computer. "
                + "Once running, you can bring up the user interface at any time by pressing the keys "
                + "<strong><code>%s+%s</code></strong>."
                + "<h2>Persistence</h2>"
                + "<p>Though at the core, Master Password does not require the use of any form of data "
                + "storage, the application does remember the names of the sites you've used in the past to "
                + "make it easier for you to use them again in the future.  All user information is saved in "
                + "files on your computer at the following location:<br><pre>%s</pre></p>"
                + "<p>You can read, modify, backup or place new files in this location as you see fit. "
                + "Some people even configure this location to be synced between their different computers "
                + "using services such as those provided by SpiderOak or Dropbox.</p>"
                + "<hr><p><a href='https://masterpassword.app'>https://masterpassword.app</a> — by Maarten Billemont</p>",
                MasterPassword.get().version(),
                InputEvent.getModifiersExText( MPGuiConstants.ui_hotkey.getModifiers() ),
                KeyEvent.getKeyText( MPGuiConstants.ui_hotkey.getKeyCode() ),
                MPFileUserManager.get().getPath().getAbsolutePath() ) ),
                                       "About Master Password", JOptionPane.INFORMATION_MESSAGE );
    }

    private enum ContentMode {
        NO_USER,
        AUTHENTICATE,
        AUTHENTICATED;

        static ContentMode getContentMode(@Nullable final MPUser<?> user) {
            if (user == null)
                return NO_USER;
            else if (!user.isMasterKeyAvailable())
                return AUTHENTICATE;
            else
                return AUTHENTICATED;
        }
    }


    private final class NoUserPanel extends JPanel {

        private NoUserPanel() {
            setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            userToolbar.add( addButton );
            userToolbar.add( importButton );
            userToolbar.add( Box.createGlue() );
            userToolbar.add( helpButton );

            add( Box.createGlue() );
            add( Components.heading( "Select a user to proceed." ) );
            add( Box.createGlue() );
        }
    }


    private final class AuthenticateUserPanel extends JPanel implements ActionListener, DocumentListener {

        @Nonnull
        private final MPUser<?> user;

        private final JButton exportButton = Components.button( Res.icons().export(), event -> exportUser(),
                                                                "Export this user to a backup file." );
        private final JButton deleteButton = Components.button( Res.icons().delete(), event -> deleteUser(),
                                                                "Delete this user from Master Password." );
        private final JButton resetButton  = Components.button( Res.icons().reset(), event -> resetUser(),
                                                                "Change the master password for this user." );

        private final JPasswordField masterPasswordField = Components.passwordField();
        private final JLabel         errorLabel          = Components.label();
        private final JLabel         identiconLabel      = Components.label( SwingConstants.CENTER );

        private Future<?> identiconJob;

        private AuthenticateUserPanel(@Nonnull final MPUser<?> user) {
            setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            this.user = user;

            userToolbar.add( addButton );
            userToolbar.add( importButton );
            userToolbar.add( exportButton );
            userToolbar.add( deleteButton );
            userToolbar.add( resetButton );
            userToolbar.add( Box.createGlue() );
            userToolbar.add( helpButton );

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

        private void exportUser() {
            MPFileUser fileUser = (user instanceof MPFileUser)? (MPFileUser) user: null;
            if (fileUser == null)
                return;

            File exportFile = Components.showSaveDialog( this, "Export User File", fileUser.getFile().getName() );
            if (exportFile == null)
                return;

            try {
                Platform.get().show(
                        Files.copy( fileUser.getFile().toPath(), exportFile.toPath(),
                                    StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.COPY_ATTRIBUTES ).toFile() );
            }
            catch (final IOException e) {
                JOptionPane.showMessageDialog(
                        this, e.getLocalizedMessage(),
                        "Export Failed", JOptionPane.ERROR_MESSAGE );
            }
        }

        private void deleteUser() {
            MPFileUser fileUser = (user instanceof MPFileUser)? (MPFileUser) user: null;
            if (fileUser == null)
                return;

            if (JOptionPane.YES_OPTION == JOptionPane.showConfirmDialog(
                    SwingUtilities.windowForComponent( this ), strf( "<html>Delete the user <strong>%s</strong>?<br><br><em>%s</em></html>",
                                                                     fileUser.getFullName(), fileUser.getFile().getName() ),
                    "Delete User", JOptionPane.YES_NO_OPTION ))
                MPFileUserManager.get().delete( fileUser );
        }

        private void resetUser() {
            JPasswordField passwordField = Components.passwordField();
            if (JOptionPane.OK_OPTION == Components.showDialog( this, "Reset User", new JOptionPane( Components.panel(
                    BoxLayout.PAGE_AXIS,
                    Components.label( strf( "<html>Enter the new master password for <strong>%s</strong>:</html>",
                                            user.getFullName() ) ),
                    Components.strut(),
                    passwordField,
                    Components.strut(),
                    Components.label( strf( "<html><em><strong>Note:</strong><br>Changing the master password "
                                            + "will change all of the user's passwords.<br>"
                                            + "Changing back to the original master password will also restore<br>"
                                            + "the user's original passwords.</em></html>",
                                            user.getFullName() ) ) ), JOptionPane.QUESTION_MESSAGE, JOptionPane.OK_CANCEL_OPTION ) {
                @Override
                public void selectInitialValue() {
                    passwordField.requestFocusInWindow();
                }
            } )) {
                char[] masterPassword = passwordField.getPassword();
                if ((masterPassword != null) && (masterPassword.length > 0))
                    try {
                        user.reset();
                        user.authenticate( masterPassword );
                    }
                    catch (final MPIncorrectMasterPasswordException e) {
                        errorLabel.setText( e.getLocalizedMessage() );
                        throw logger.bug( e );
                    }
                    catch (final MPAlgorithmException e) {
                        logger.err( e, "While resetting master password." );
                        errorLabel.setText( e.getLocalizedMessage() );
                    }
            }
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


    private final class AuthenticatedUserPanel extends JPanel implements KeyListener, MPUser.Listener {

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
            userToolbar.add( Box.createGlue() );
            userToolbar.add( helpButton );

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

            addHierarchyListener( e -> {
                if (null != SwingUtilities.windowForComponent( this ))
                    user.addListener( this );
                else
                    user.removeListener( this );
            } );
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
                    if (window instanceof Frame)
                        ((Frame) window).setExtendedState( Frame.ICONIFIED );
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

        @Override
        public void onUserUpdated(final MPUser<?> user) {
            updateSites( queryField.getText() );
            showSiteResult( sitesModel.getSelectedItem() );
        }

        @Override
        public void onUserAuthenticated(final MPUser<?> user) {
        }

        @Override
        public void onUserInvalidated(final MPUser<?> user) {
        }
    }
}
