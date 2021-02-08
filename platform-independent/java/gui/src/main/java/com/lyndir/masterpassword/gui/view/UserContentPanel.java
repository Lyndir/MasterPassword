package com.lyndir.masterpassword.gui.view;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.*;
import com.google.common.collect.ImmutableList;
import com.google.common.primitives.UnsignedInteger;
import com.google.common.util.concurrent.ListenableFuture;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.ObjectUtils;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.gui.*;
import com.lyndir.masterpassword.gui.model.*;
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
import java.security.SecureRandom;
import java.util.*;
import java.util.Optional;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import javax.swing.text.PlainDocument;


/**
 * @author lhunath, 2018-07-14
 */
@SuppressWarnings("SerializableStoresNonSerializable")
public class UserContentPanel extends JPanel implements State.Listener, MPUser.Listener {

    private static final Random    random             = new SecureRandom();
    private static final int       SIZE_RESULT        = 48;
    private static final Logger    logger             = Logger.get( UserContentPanel.class );
    private static final JButton   iconButton         = Components.button( Res.icons().user(), null, null );
    private static final KeyStroke copyLoginKeyStroke = KeyStroke.getKeyStroke( KeyEvent.VK_ENTER, InputEvent.SHIFT_DOWN_MASK );
    private static final Pattern   EACH_CHARACTER     = Pattern.compile( "." );

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

        State.get().addListener( this );
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
            State.get().activateUser( new MPIncognitoUser( fullName ) );
        else
            State.get().activateUser( MPFileUserManager.get().add( fullName ) );
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

                    State.get().activateUser( MPFileUserManager.get().add( importUser ) );
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
                State.get().version(),
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

        private final JPasswordField masterPasswordField;
        private final JLabel         errorLabel;
        private final JLabel         identiconLabel;

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

            add( identiconLabel = Components.label( SwingConstants.CENTER ) );
            identiconLabel.setFont( Res.fonts().identiconFont( Components.TEXT_SIZE_CONTROL ) );
            add( Box.createGlue() );

            add( Components.label( "Master Password:" ) );
            add( Components.strut() );
            add( masterPasswordField = Components.passwordField() );
            masterPasswordField.addActionListener( this );
            masterPasswordField.getDocument().addDocumentListener( this );
            add( errorLabel = Components.label() );
            errorLabel.setForeground( Res.colors().errorFg() );
            add( Box.createGlue() );
        }

        @Override
        public void removeNotify() {
            char[] password = masterPasswordField.getPassword();
            Arrays.fill( password, (char) 0 );
            masterPasswordField.setText( new String( password ) );

            super.removeNotify();
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

                    if (user instanceof MPFileUser)
                        ((MPFileUser) user).migrateTo( MPMarshalFormat.DEFAULT );
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
                    user.getAlgorithm().identicon( user.getFullName(), masterPassword ): null;
            if (masterPassword != null)
                Arrays.fill( masterPassword, (char) 0 );

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


    private final class AuthenticatedUserPanel extends JPanel implements KeyListener, MPUser.Listener, KeyEventDispatcher {

        private final JButton userButton      = Components.button( Res.icons().user(), event -> showUserPreferences(),
                                                                   "Show user preferences." );
        private final JButton logoutButton    = Components.button( Res.icons().lock(), event -> logoutUser(),
                                                                   "Sign out and lock user." );
        private final JButton settingsButton  = Components.button( Res.icons().settings(), event -> showSiteSettings(),
                                                                   "Show site settings." );
        private final JButton questionsButton = Components.button( Res.icons().question(), event -> showSiteQuestions(),
                                                                   "Show site recovery questions." );
        private final JButton editButton      = Components.button( Res.icons().edit(), event -> showSiteValues(),
                                                                   "Set/save personal password/login." );
        private final JButton keyButton       = Components.button( Res.icons().key(), event -> showSiteKeys(),
                                                                   "Cryptographic site keys." );
        private final JButton deleteButton    = Components.button( Res.icons().delete(), event -> deleteSite(),
                                                                   "Delete the site from the user." );

        @Nonnull
        private final MPUser<?>                                                 user;
        private final JLabel                                                    resultLabel;
        private final JLabel                                                    resultField;
        private final JLabel                                                    answerLabel;
        private final JLabel                                                    answerField;
        private final JLabel                                                    queryLabel;
        private final JTextField                                                queryField;
        private final CollectionListModel<MPQuery.Result<? extends MPSite<?>>>  sitesModel;
        private final CollectionListModel<MPQuery.Result<? extends MPQuestion>> questionsModel;
        private final JList<MPQuery.Result<? extends MPSite<?>>>                sitesList;

        private boolean   showLogin;
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
            siteToolbar.add( editButton );
            siteToolbar.add( keyButton );
            siteToolbar.add( deleteButton );
            settingsButton.setEnabled( false );
            questionsButton.setEnabled( false );
            editButton.setEnabled( false );
            keyButton.setEnabled( false );
            deleteButton.setEnabled( false );

            answerLabel = Components.label( "Answer:" );
            answerField = Components.heading( SwingConstants.CENTER );
            answerField.setForeground( Res.colors().highlightFg() );
            answerField.setFont( Res.fonts().bigValueFont( SIZE_RESULT ) );
            questionsModel = new CollectionListModel<MPQuery.Result<? extends MPQuestion>>().selection( this::showQuestionItem );

            add( Components.heading( user.getFullName(), SwingConstants.CENTER ) );

            add( resultLabel = Components.label( SwingConstants.CENTER ) );
            add( resultField = Components.heading( SwingConstants.CENTER ) );
            resultField.setForeground( Res.colors().highlightFg() );
            resultField.setFont( Res.fonts().bigValueFont( SIZE_RESULT ) );
            add( Box.createGlue() );
            add( Components.strut() );

            add( queryLabel = Components.label() );
            queryLabel.setText( strf( "%s's password for:", user.getFullName() ) );
            add( queryField = Components.textField( null, this::updateSites ) );
            queryField.putClientProperty( "JTextField.variant", "search" );
            queryField.addActionListener( this::useSite );
            queryField.getInputMap().put( copyLoginKeyStroke, JTextField.notifyAction );
            queryField.addKeyListener( this );
            queryField.requestFocusInWindow();
            add( Components.strut() );

            add( Components.scrollPane( sitesList = Components.list(
                    sitesModel = new CollectionListModel<MPQuery.Result<? extends MPSite<?>>>().selection( this::showSiteItem ),
                    this::getSiteDescription ) ) );
            sitesList.registerKeyboardAction( this::useSite, KeyStroke.getKeyStroke( KeyEvent.VK_ENTER, 0 ),
                                              JComponent.WHEN_FOCUSED );
            sitesList.registerKeyboardAction( this::useSite, KeyStroke.getKeyStroke( KeyEvent.VK_ENTER, InputEvent.SHIFT_DOWN_MASK ),
                                              JComponent.WHEN_FOCUSED );
            add( Components.strut() );

            add( Components.label( strf(
                    "Press %s to copy password, %s+%s to copy login name.",
                    KeyEvent.getKeyText( KeyEvent.VK_ENTER ),
                    InputEvent.getModifiersExText( copyLoginKeyStroke.getModifiers() ),
                    KeyEvent.getKeyText( copyLoginKeyStroke.getKeyCode() ) ) ) );

            addHierarchyListener( e -> {
                if (HierarchyEvent.DISPLAYABILITY_CHANGED == (e.getChangeFlags() & HierarchyEvent.DISPLAYABILITY_CHANGED)) {
                    if (null != SwingUtilities.windowForComponent( this )) {
                        KeyboardFocusManager.getCurrentKeyboardFocusManager().addKeyEventDispatcher( this );
                        user.addListener( this );
                    } else {
                        KeyboardFocusManager.getCurrentKeyboardFocusManager().removeKeyEventDispatcher( this );
                        user.removeListener( this );
                    }
                }
            } );
        }

        public void showUserPreferences() {
            ImmutableList.Builder<Component> components = ImmutableList.builder();

            components.add( Components.label( "Default Algorithm:" ),
                            Components.comboBox( MPAlgorithm.Version.values(), MPAlgorithm.Version::name,
                                                 user.getAlgorithm().version(), user::setAlgorithm ) );

            components.add( Components.label( "Default Password Type:" ),
                            Components.comboBox( MPResultType.values(), MPResultType::getLongName,
                                                 user.getPreferences().getDefaultType(), user.getPreferences()::setDefaultType ),
                            Components.strut() );

            components.add( Components.checkBox( "Hide Passwords",
                                                 user.getPreferences().isHidePasswords(), user.getPreferences()::setHidePasswords ) );

            components.add( new JSeparator() );

            components.add( Components.checkBox( "Check For Updates",
                                                 MPGuiConfig.get().checkForUpdates(), MPGuiConfig.get()::setCheckForUpdates ) );

            components.add( Components.checkBox( strf( "<html>Stay Resident (reactivate with <strong><code>%s+%s</code></strong>)",
                                                       InputEvent.getModifiersExText( MPGuiConstants.ui_hotkey.getModifiers() ),
                                                       KeyEvent.getKeyText( MPGuiConstants.ui_hotkey.getKeyCode() ) ),
                                                 MPGuiConfig.get().stayResident(), MPGuiConfig.get()::setStayResident ) );

            Components.showDialog( this, user.getFullName(), new JOptionPane( Components.panel(
                    BoxLayout.PAGE_AXIS, components.build().toArray( new Component[0] ) ) ) );
        }

        public void logoutUser() {
            user.invalidate();
        }

        public void showSiteSettings() {
            MPSite<?> site = getSite();
            if (site == null)
                return;

            ImmutableList.Builder<Component> components = ImmutableList.builder();
            components.add( Components.label( "Algorithm:" ),
                            Components.comboBox( MPAlgorithm.Version.values(), MPAlgorithm.Version::name,
                                                 site.getAlgorithm().version(),
                                                 site::setAlgorithm ) );

            components.add( Components.label( "Counter:" ),
                            Components.spinner( new UnsignedIntegerModel( site.getCounter(), UnsignedInteger.ONE )
                                                        .selection( site::setCounter ) ),
                            Components.strut() );

            components.add( Components.label( "Password Type:" ),
                            Components.comboBox( MPResultType.values(), type ->
                                                         getTypeDescription( type, user.getPreferences().getDefaultType() ),
                                                 site.getResultType(), site::setResultType ),
                            Components.strut() );

            components.add( Components.label( "Login Type:" ),
                            Components.comboBox( MPResultType.values(), type ->
                                                         getTypeDescription( type, user.getAlgorithm().mpw_default_login_type() ),
                                                 site.getLoginType(), site::setLoginType ),
                            Components.strut() );

            MPFileSite fileSite = (site instanceof MPFileSite)? (MPFileSite) site: null;
            if (fileSite != null)
                components.add( Components.label( "URL:" ),
                                Components.textField( fileSite.getUrl(), fileSite::setUrl ),
                                Components.strut() );

            Components.showDialog( this, strf( "Settings for %s", site.getSiteName() ), new JOptionPane( Components.panel(
                    BoxLayout.PAGE_AXIS, components.build().toArray( new Component[0] ) ) ) );
        }

        private String getTypeDescription(final MPResultType type, final MPResultType... defaults) {
            boolean isDefault = false;
            for (final MPResultType d : defaults)
                if (isDefault = type == d)
                    break;

            return strf( "<html>%s%s%s, %s", isDefault? "<b>": "", type.getLongName(), isDefault? "</b>": "", type.getDescription() );
        }

        public void showSiteQuestions() {
            MPSite<?> site = getSite();
            if (site == null)
                return;

            JList<MPQuery.Result<? extends MPQuestion>> questionsList =
                    Components.list( questionsModel, this::getQuestionDescription );
            JTextField queryField = Components.textField( null, queryText -> Res.job( () -> {
                MPQuery query = new MPQuery( queryText );
                Collection<MPQuery.Result<? extends MPQuestion>> questionItems = new LinkedList<MPQuery.Result<? extends MPQuestion>>(
                        query.find( site.getQuestions(), MPQuestion::getKeyword ) );

                if (questionItems.stream().noneMatch( MPQuery.Result::isExact ))
                    questionItems.add( MPQuery.Result.allOf( new MPNewQuestion( site, query.getQuery() ), query.getQuery() ) );

                Res.ui( () -> questionsModel.set( questionItems ) );
            } ) );
            queryField.putClientProperty( "JTextField.variant", "search" );
            queryField.addActionListener( this::useQuestion );
            queryField.addKeyListener( new KeyAdapter() {
                @Override
                public void keyPressed(final KeyEvent event) {
                    if ((event.getKeyCode() == KeyEvent.VK_UP) || (event.getKeyCode() == KeyEvent.VK_DOWN))
                        questionsList.dispatchEvent( event );
                }

                @Override
                public void keyReleased(final KeyEvent event) {
                    if ((event.getKeyCode() == KeyEvent.VK_UP) || (event.getKeyCode() == KeyEvent.VK_DOWN))
                        questionsList.dispatchEvent( event );
                }
            } );

            Components.showDialog( this, strf( "Recovery answers for %s", site.getSiteName() ), new JOptionPane( Components.panel(
                    BoxLayout.PAGE_AXIS,
                    Components.label( "Security Question Keyword:" ), queryField,
                    Components.strut(),
                    answerLabel, answerField,
                    Components.strut(),
                    Components.scrollPane( questionsList ) ) ) {
                @Override
                public void selectInitialValue() {
                    queryField.requestFocusInWindow();
                }
            } );
        }

        public void showSiteValues() {
            MPSite<?> site = getSite();
            if (site == null)
                return;

            try {
                JTextField passwordField = Components.textField( site.getResult(), null );
                JTextField loginField    = Components.textField( site.getLogin(), null );
                passwordField.setEditable( site.getResultType().getTypeClass() == MPResultTypeClass.Stateful );
                loginField.setEditable( site.getLoginType().getTypeClass() == MPResultTypeClass.Stateful );

                if (JOptionPane.OK_OPTION == Components.showDialog( this, site.getSiteName(), new JOptionPane(
                        Components.panel(
                                BoxLayout.PAGE_AXIS,
                                Components.label( strf( "<html>Site Login (currently set to: <b>%s</b>):",
                                                        getTypeDescription( site.getLoginType() ) ) ),
                                loginField,
                                Components.strut(),
                                Components.label( strf( "<html>Site Password (currently set to: <b>%s</b>):",
                                                        getTypeDescription( site.getResultType() ) ) ),
                                passwordField,
                                Components.strut(),
                                Components.label( "<html>To save a personal value in these fields,\n" +
                                                  "change the type to <b>Saved</b> in the site's settings." ) ),
                        JOptionPane.PLAIN_MESSAGE, JOptionPane.OK_CANCEL_OPTION ) {
                    @Override
                    public void selectInitialValue() {
                        passwordField.requestFocusInWindow();
                    }
                } )) {
                    if (site instanceof MPFileSite) {
                        MPFileSite fileSite = (MPFileSite) site;

                        if (site.getResultType().getTypeClass() == MPResultTypeClass.Stateful)
                            fileSite.setSitePassword( site.getResultType(), passwordField.getText() );
                        if (site.getLoginType().getTypeClass() == MPResultTypeClass.Stateful)
                            fileSite.setLoginName( site.getLoginType(), loginField.getText() );
                    }
                }
            }
            catch (final MPKeyUnavailableException | MPAlgorithmException e) {
                logger.err( e, "While computing site edit results." );
            }
        }

        public void showSiteKeys() {
            MPSite<?> site = getSite();
            if (site == null)
                return;

            JTextArea resultField = Components.textArea();
            resultField.setEnabled( false );

            CollectionListModel<MPKeyPurpose> purposeModel = new CollectionListModel<>( MPKeyPurpose.values() );
            DocumentModel                     contextModel = new DocumentModel( new PlainDocument() );
            UnsignedIntegerModel              counterModel = new UnsignedIntegerModel( UnsignedInteger.ONE );
            CollectionListModel<MPResultType> typeModel    = new CollectionListModel<>( MPResultType.values() );
            DocumentModel                     stateModel   = new DocumentModel( new PlainDocument() );

            Runnable trigger = () -> Res.job( () -> {
                try {
                    MPKeyPurpose purpose = purposeModel.getSelectedItem();
                    MPResultType type    = typeModel.getSelectedItem();

                    String result = ((purpose == null) || (type == null))? null:
                            site.getResult( purpose, contextModel.getText(), counterModel.getNumber(), type, stateModel.getText() );

                    Res.ui( () -> resultField.setText( result ) );
                }
                catch (final MPKeyUnavailableException | MPAlgorithmException e) {
                    logger.err( e, "While computing site edit results." );
                }
            } );

            purposeModel.selection( MPKeyPurpose.Authentication, p -> trigger.run() );
            contextModel.selection( c -> trigger.run() );
            counterModel.selection( c -> trigger.run() );
            typeModel.selection( MPResultType.DeriveKey, t -> {
                switch (t) {
                    case DeriveKey:
                        stateModel.setText( "128" );
                        break;

                    default:
                        stateModel.setText( null );
                }

                trigger.run();
            } );
            stateModel.selection( c -> trigger.run() );

            if (JOptionPane.OK_OPTION == Components.showDialog( this, site.getSiteName(), new JOptionPane( Components.panel(
                    BoxLayout.PAGE_AXIS,
                    Components.heading( "Key Calculator" ),
                    Components.label( "Purpose:" ),
                    Components.comboBox( purposeModel, MPKeyPurpose::getShortName ),
                    Components.strut(),
                    Components.label( "Context:" ),
                    Components.textField( contextModel.getDocument() ),
                    Components.label( "Counter:" ),
                    Components.spinner( counterModel ),
                    Components.label( "Type:" ),
                    Components.comboBox( typeModel, this::getTypeDescription ),
                    Components.label( "State:" ),
                    Components.scrollPane( Components.textField( stateModel.getDocument() ) ),
                    Components.strut(),
                    resultField ) ) {
                {
                    setOptions( new Object[]{ "Copy", "Cancel" } );
                    setInitialValue( getOptions()[0] );
                }
            } ))
                copyResult( resultField.getText() );
        }

        public void deleteSite() {
            MPSite<?> site = getSite();
            if (site == null)
                return;

            if (JOptionPane.YES_OPTION == JOptionPane.showConfirmDialog(
                    this, strf( "<html>Forget the site <strong>%s</strong>?</html>", site.getSiteName() ),
                    "Delete Site", JOptionPane.YES_NO_OPTION ))
                user.deleteSite( site );
        }

        private String getSiteDescription(@Nullable final MPQuery.Result<? extends MPSite<?>> item) {
            MPSite<?> site = (item != null)? item.getValue(): null;
            if (site == null)
                return " ";
            if (site instanceof MPNewSite)
                return strf( "<html><strong>%s</strong> &lt;Add new site&gt;</html>", item.getKeyAsHTML() );

            ImmutableList.Builder<Object> parameters = ImmutableList.builder();
            MPFileSite                    fileSite   = (site instanceof MPFileSite)? (MPFileSite) site: null;
            if (fileSite != null)
                parameters.add( Res.format( fileSite.getLastUsed() ) );
            parameters.add( site.getAlgorithm().version() );
            parameters.add( strf( "#%d", site.getCounter().longValue() ) );
            if ((fileSite != null) && (fileSite.getUrl() != null))
                parameters.add( fileSite.getUrl() );

            return strf( "<html><strong>%s</strong> (%s)</html>", item.getKeyAsHTML(),
                         Joiner.on( " - " ).skipNulls().join( parameters.build() ) );
        }

        private String getQuestionDescription(@Nullable final MPQuery.Result<? extends MPQuestion> item) {
            MPQuestion question = (item != null)? item.getValue(): null;
            if (question == null)
                return "<site>";
            if (question instanceof MPNewQuestion)
                return strf( "<html>%s &lt;Add new question&gt;</html>", item.getKeyAsHTML() );

            return strf( "<html>%s</html>", item.getKeyAsHTML() );
        }

        private void useSite(final ActionEvent event) {
            MPSite<?> site = getSite();
            if (site instanceof MPNewSite) {
                if (JOptionPane.YES_OPTION != JOptionPane.showConfirmDialog(
                        this, strf( "<html>Remember the site <strong>%s</strong>?</html>", site.getSiteName() ),
                        "New Site", JOptionPane.YES_NO_OPTION ))
                    return;

                site = ((MPNewSite) site).addTo( user );
            }

            boolean   loginResult = (copyLoginKeyStroke.getModifiers() & event.getModifiers()) != 0;
            MPSite<?> fsite       = site;
            Res.ui( getSiteResult( site, loginResult ), result -> {
                if (result == null)
                    return;

                if (fsite instanceof MPFileSite)
                    ((MPFileSite) fsite).use();

                copyResult( result );
            } );
        }

        private void setShowLogin(final boolean showLogin) {
            if (showLogin == this.showLogin)
                return;

            this.showLogin = showLogin;
            showSiteItem( sitesModel.getSelectedItem() );
        }

        private void showSiteItem(@Nullable final MPQuery.Result<? extends MPSite<?>> item) {
            MPSite<?> site = (item != null)? item.getValue(): null;
            Res.ui( getSiteResult( site, showLogin ), result -> {
                settingsButton.setEnabled( site != null );
                questionsButton.setEnabled( site != null );
                editButton.setEnabled( site != null );
                keyButton.setEnabled( site != null );
                deleteButton.setEnabled( site != null );

                if (!showLogin && (site != null))
                    resultLabel.setText( (result != null)? strf( "Your password for %s:", site.getSiteName() ): " " );
                else if (showLogin && (site != null))
                    resultLabel.setText( (result != null)? strf( "Your login for %s:", site.getSiteName() ): " " );

                if ((result == null) || result.isEmpty())
                    resultField.setText( " " );
                else if (!showLogin && user.getPreferences().isHidePasswords())
                    resultField.setText( EACH_CHARACTER.matcher( result ).replaceAll( "•" ) );
                else
                    resultField.setText( result );
            } );
        }

        private ListenableFuture<String> getSiteResult(@Nullable final MPSite<?> site, final boolean loginResult) {
            return Res.job( () -> {
                try {
                    if (site != null)
                        return loginResult? site.getLogin(): site.getResult();
                }
                catch (final MPKeyUnavailableException | MPAlgorithmException e) {
                    logger.err( e, "While resolving password for: %s", site );
                }

                return null;
            } );
        }

        private void useQuestion(final ActionEvent event) {
            MPQuestion question = getQuestion();
            if (question instanceof MPNewQuestion) {
                if (JOptionPane.YES_OPTION != JOptionPane.showConfirmDialog(
                        this,
                        strf( "<html>Remember the security question with keyword <strong>%s</strong>?</html>",
                              Strings.isNullOrEmpty( question.getKeyword() )? "<empty>": question.getKeyword() ),
                        "New Question", JOptionPane.YES_NO_OPTION ))
                    return;

                question = question.getSite().addQuestion( question.getKeyword() );
            }

            MPQuestion fquestion = question;
            Res.ui( getQuestionResult( question ), result -> {
                if (result == null)
                    return;

                if (fquestion instanceof MPFileQuestion)
                    ((MPFileQuestion) fquestion).use();

                copyResult( result );
            } );
        }

        private void showQuestionItem(@Nullable final MPQuery.Result<? extends MPQuestion> item) {
            MPQuestion question = (item != null)? item.getValue(): null;
            Res.ui( getQuestionResult( question ), answer -> {
                if ((answer == null) || (question == null))
                    answerLabel.setText( " " );
                else
                    answerLabel.setText(
                            Strings.isNullOrEmpty( question.getKeyword() )?
                                    strf( "<html>Answer for site <b>%s</b>:", question.getSite().getSiteName() ):
                                    strf( "<html>Answer for site <b>%s</b>, of question with keyword <b>%s</b>:",
                                          question.getSite().getSiteName(), question.getKeyword() ) );
                answerField.setText( (answer != null)? answer: " " );
            } );
        }

        private ListenableFuture<String> getQuestionResult(@Nullable final MPQuestion question) {
            return Res.job( () -> {
                try {
                    if (question != null)
                        return question.getAnswer();
                }
                catch (final MPKeyUnavailableException | MPAlgorithmException e) {
                    logger.err( e, "While resolving answer for: %s", question );
                }

                return null;
            } );
        }

        private void copyResult(final String result) {
            Transferable clipboardContents = new StringSelection( result );
            Toolkit.getDefaultToolkit().getSystemClipboard().setContents( clipboardContents, null );

            Res.ui( () -> {
                Window answerDialog = SwingUtilities.windowForComponent( answerField );
                if (answerDialog instanceof Dialog)
                    answerDialog.setVisible( false );

                Window window = SwingUtilities.windowForComponent( UserContentPanel.this );
                if (window instanceof Frame)
                    ((Frame) window).setExtendedState( Frame.ICONIFIED );

                setShowLogin( false );
            } );
        }

        @Nullable
        private MPSite<?> getSite() {
            MPQuery.Result<? extends MPSite<?>> selectedSite = sitesModel.getSelectedItem();
            if (selectedSite == null)
                return null;

            return selectedSite.getValue();
        }

        @Nullable
        private MPQuestion getQuestion() {
            MPQuery.Result<? extends MPQuestion> selectedQuestion = questionsModel.getSelectedItem();
            if (selectedQuestion == null)
                return null;

            return selectedQuestion.getValue();
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

        private synchronized void updateSites(@Nullable final String queryText) {
            if (updateSitesJob != null)
                updateSitesJob.cancel( true );

            updateSitesJob = Res.job( () -> {
                MPQuery query = new MPQuery( queryText );
                Collection<MPQuery.Result<? extends MPSite<?>>> siteItems = new LinkedList<MPQuery.Result<? extends MPSite<?>>>(
                        query.find( user.getSites(), MPSite::getSiteName ) );

                if (!Strings.isNullOrEmpty( queryText ))
                    if (siteItems.stream().noneMatch( MPQuery.Result::isExact )) {
                        MPQuery.Result<? extends MPSite<?>> selectedItem = sitesModel.getSelectedItem();
                        if ((selectedItem != null) && user.equals( selectedItem.getValue().getUser() ) &&
                            queryText.equals( selectedItem.getValue().getSiteName() ))
                            siteItems.add( selectedItem );
                        else
                            siteItems.add( MPQuery.Result.allOf( new MPNewSite( user, query.getQuery() ), query.getQuery() ) );
                    }

                Res.ui( () -> sitesModel.set( siteItems ) );
            } );
        }

        @Override
        public void onUserUpdated(final MPUser<?> user) {
            updateSites( queryField.getText() );
            showSiteItem( sitesModel.getSelectedItem() );
        }

        @Override
        public void onUserAuthenticated(final MPUser<?> user) {
        }

        @Override
        public void onUserInvalidated(final MPUser<?> user) {
        }

        @Override
        public boolean dispatchKeyEvent(final KeyEvent e) {
            if (e.getKeyCode() == KeyEvent.VK_SHIFT)
                setShowLogin( e.isShiftDown() );

            return false;
        }
    }
}
