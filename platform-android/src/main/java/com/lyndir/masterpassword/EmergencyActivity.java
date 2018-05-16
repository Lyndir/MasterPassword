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

package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import android.app.*;
import android.content.*;
import android.content.ClipboardManager;
import android.graphics.Paint;
import android.os.Build;
import android.os.Bundle;
import android.text.*;
import android.text.method.PasswordTransformationMethod;
import android.view.View;
import android.view.WindowManager;
import android.widget.*;
import butterknife.BindView;
import butterknife.ButterKnife;
import com.google.common.collect.ImmutableList;
import com.google.common.primitives.UnsignedInteger;
import com.google.common.util.concurrent.ListeningExecutorService;
import com.google.common.util.concurrent.MoreExecutors;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.model.MPConstant;
import java.text.MessageFormat;
import java.util.*;
import java.util.concurrent.Executors;
import javax.annotation.Nullable;


public class EmergencyActivity extends Activity {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger   logger                = Logger.get( EmergencyActivity.class );
    private static final ClipData EMPTY_CLIP            = new ClipData( new ClipDescription( "", new String[0] ), new ClipData.Item( "" ) );
    private static final int      PASSWORD_NOTIFICATION = 0;
    private static final int      CLIPBOARD_CLEAR_DELAY = 20 /* s */ * MPConstant.MS_PER_S;

    private final Preferences                        preferences    = Preferences.get( this );
    private final ListeningExecutorService           executor       = MoreExecutors.listeningDecorator(
            Executors.newSingleThreadExecutor() );
    private final ImmutableList<MPResultType>        allResultTypes = ImmutableList.copyOf(
            MPResultType.forClass( MPResultTypeClass.Template ) );
    private final ImmutableList<MPAlgorithm.Version> allVersions    = ImmutableList.copyOf( MPAlgorithm.Version.values() );

    @Nullable
    private MPMasterKey masterKey;

    @BindView(R.id.progressView)
    ProgressBar progressView;

    @BindView(R.id.fullNameField)
    EditText fullNameField;

    @BindView(R.id.masterPasswordField)
    EditText masterPasswordField;

    @BindView(R.id.siteNameField)
    EditText siteNameField;

    @BindView(R.id.resultTypeButton)
    Button resultTypeButton;

    @BindView(R.id.counterField)
    Button siteCounterButton;

    @BindView(R.id.siteVersionButton)
    Button siteVersionButton;

    @BindView(R.id.sitePasswordField)
    Button sitePasswordField;

    @BindView(R.id.sitePasswordTip)
    TextView sitePasswordTip;

    @BindView(R.id.rememberFullNameField)
    CheckBox rememberFullNameField;

    @BindView(R.id.rememberPasswordField)
    CheckBox forgetPasswordField;

    @BindView(R.id.maskPasswordField)
    CheckBox maskPasswordField;

    private int    id_userName;
    private int    id_masterPassword;
    @Nullable
    private String sitePassword;

    public static void start(final Context context) {
        context.startActivity( new Intent( context, EmergencyActivity.class ) );
    }

    @Override
    public void onCreate(@Nullable final Bundle savedInstanceState) {
        super.onCreate( savedInstanceState );

        getWindow().setFlags( WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE );
        setContentView( R.layout.activity_emergency );
        ButterKnife.bind( this );

        fullNameField.setOnFocusChangeListener( new ValueChangedListener() {
            @Override
            void update() {
                updateMasterKey();
            }
        } );
        masterPasswordField.setOnFocusChangeListener( new ValueChangedListener() {
            @Override
            void update() {
                updateMasterKey();
            }
        } );
        siteNameField.addTextChangedListener( new ValueChangedListener() {
            @Override
            void update() {
                siteCounterButton.setText( MessageFormat.format( "{0}", 1 ) );
                updateSitePassword();
            }
        } );
        resultTypeButton.setOnClickListener( new View.OnClickListener() {
            @Override
            public void onClick(final View v) {
                @SuppressWarnings("SuspiciousMethodCalls")
                MPResultType resultType =
                        allResultTypes.get( (allResultTypes.indexOf( resultTypeButton.getTag() ) + 1) % allResultTypes.size() );
                preferences.setDefaultResultType( resultType );
                resultTypeButton.setTag( resultType );
                resultTypeButton.setText( resultType.getShortName() );
                updateSitePassword();
            }
        } );
        siteCounterButton.setOnClickListener( new View.OnClickListener() {
            @Override
            public void onClick(final View v) {
                UnsignedInteger counter =
                        UnsignedInteger.valueOf( siteCounterButton.getText().toString() ).plus( UnsignedInteger.ONE );
                siteCounterButton.setText( MessageFormat.format( "{0}", counter ) );
                updateSitePassword();
            }
        } );
        siteVersionButton.setOnClickListener( new View.OnClickListener() {
            @Override
            public void onClick(final View v) {
                @SuppressWarnings("SuspiciousMethodCalls")
                MPAlgorithm.Version siteVersion =
                        allVersions.get( (allVersions.indexOf( siteVersionButton.getTag() ) + 1) % allVersions.size() );
                preferences.setDefaultVersion( siteVersion );
                siteVersionButton.setTag( siteVersion );
                siteVersionButton.setText( siteVersion.name() );
                updateMasterKey();
            }
        } );
        sitePasswordField.addTextChangedListener( new ValueChangedListener() {
            @Override
            void update() {
                boolean noPassword = TextUtils.isEmpty( sitePasswordField.getText() );
                sitePasswordTip.setVisibility( noPassword? View.INVISIBLE: View.VISIBLE );

                if (noPassword)
                    sitePassword = null;
            }
        } );

        fullNameField.setTypeface( Res.get( this ).exo_Thin() );
        fullNameField.setPaintFlags( fullNameField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        masterPasswordField.setTypeface( Res.get( this ).sourceCodePro_ExtraLight() );
        masterPasswordField.setPaintFlags( masterPasswordField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        siteNameField.setTypeface( Res.get( this ).exo_Regular() );
        siteNameField.setPaintFlags( siteNameField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        sitePasswordField.setTypeface( Res.get( this ).sourceCodePro_Black() );
        sitePasswordField.setPaintFlags( sitePasswordField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );

        rememberFullNameField.setOnCheckedChangeListener( new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(final CompoundButton buttonView, final boolean isChecked) {
                preferences.setRememberFullName( isChecked );
                if (isChecked)
                    preferences.setFullName( fullNameField.getText().toString() );
                else
                    preferences.setFullName( null );
            }
        } );
        forgetPasswordField.setOnCheckedChangeListener( new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(final CompoundButton buttonView, final boolean isChecked) {
                preferences.setForgetPassword( isChecked );
            }
        } );
        maskPasswordField.setOnCheckedChangeListener( new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(final CompoundButton buttonView, final boolean isChecked) {
                preferences.setMaskPassword( isChecked );
                sitePasswordField.setTransformationMethod( isChecked? new PasswordTransformationMethod(): null );
            }
        } );
    }

    @Override
    protected void onResume() {
        super.onResume();

        // FIXME:       MasterKey.setAllowNativeByDefault( preferences.isAllowNativeKDF() );

        fullNameField.setText( preferences.getFullName() );
        rememberFullNameField.setChecked( preferences.isRememberFullName() );
        forgetPasswordField.setChecked( preferences.isForgetPassword() );
        maskPasswordField.setChecked( preferences.isMaskPassword() );
        sitePasswordField.setTransformationMethod( preferences.isMaskPassword()? new PasswordTransformationMethod(): null );
        MPResultType defaultResultType = preferences.getDefaultResultType();
        resultTypeButton.setTag( defaultResultType );
        resultTypeButton.setText( defaultResultType.getShortName() );
        MPAlgorithm.Version defaultVersion = preferences.getDefaultVersion();
        siteVersionButton.setTag( defaultVersion );
        siteVersionButton.setText( defaultVersion.name() );
        siteCounterButton.setText( MessageFormat.format( "{0}", 1 ) );

        if (TextUtils.isEmpty( fullNameField.getText() ))
            fullNameField.requestFocus();
        else if (TextUtils.isEmpty( masterPasswordField.getText() ))
            masterPasswordField.requestFocus();
        else
            siteNameField.requestFocus();
    }

    @Override
    protected void onPause() {
        if (preferences.isForgetPassword()) {
            synchronized (this) {
                id_userName = id_masterPassword = 0;
                if (masterKey != null)
                    masterKey = null;

                masterPasswordField.setText( "" );
            }
        }

        siteNameField.setText( "" );
        sitePasswordField.setText( "" );
        progressView.setVisibility( View.INVISIBLE );

        super.onPause();
    }

    private synchronized void updateMasterKey() {
        String fullName       = fullNameField.getText().toString();
        char[] masterPassword = masterPasswordField.getText().toString().toCharArray();
        if ((id_userName == fullName.hashCode())
            && (id_masterPassword == Arrays.hashCode( masterPassword )))
            if (masterKey != null)
                return;

        id_userName = fullName.hashCode();
        id_masterPassword = Arrays.hashCode( masterPassword );

        if (preferences.isRememberFullName())
            preferences.setFullName( fullName );

        if (fullName.isEmpty() || (masterPassword.length == 0)) {
            sitePasswordField.setText( "" );
            progressView.setVisibility( View.INVISIBLE );
            return;
        }

        sitePasswordField.setText( "" );
        progressView.setVisibility( View.VISIBLE );
        masterKey = new MPMasterKey( fullName, masterPassword );
        updateSitePassword();
    }

    private void updateSitePassword() {
        final String              siteName = siteNameField.getText().toString();
        final MPResultType        type     = (MPResultType) resultTypeButton.getTag();
        final UnsignedInteger     counter  = UnsignedInteger.valueOf( siteCounterButton.getText().toString() );
        final MPAlgorithm.Version version  = (MPAlgorithm.Version) siteVersionButton.getTag();

        if ((masterKey == null) || siteName.isEmpty() || (type == null)) {
            sitePasswordField.setText( "" );
            progressView.setVisibility( View.INVISIBLE );

            if (masterKey == null)
                updateMasterKey();
            return;
        }

        sitePasswordField.setText( "" );
        progressView.setVisibility( View.VISIBLE );
        executor.submit( new Runnable() {
            @Override
            public void run() {
                try {
                    sitePassword = masterKey.siteResult( siteName, version.getAlgorithm(), counter,
                                                         MPKeyPurpose.Authentication, null, type, null );

                    runOnUiThread( new Runnable() {
                        @Override
                        public void run() {
                            sitePasswordField.setText( sitePassword );
                            progressView.setVisibility( View.INVISIBLE );
                        }
                    } );
                }
                catch (final MPKeyUnavailableException ignored) {
                    sitePasswordField.setText( "" );
                    progressView.setVisibility( View.INVISIBLE );
                }
                catch (final RuntimeException e) {
                    sitePasswordField.setText( "" );
                    progressView.setVisibility( View.INVISIBLE );
                    logger.err( e, "While generating site password." );
                    throw e;
                }
            }
        } );
    }

    public void integrityTests(final View view) {
        if (masterKey != null)
            masterKey = null;

        TestActivity.startNoSkip( this );
    }

    public void copySitePassword(final View view) {
        final String currentSitePassword = sitePassword;
        if (TextUtils.isEmpty( currentSitePassword ))
            return;

        final ClipboardManager    clipboardManager    = (ClipboardManager) getSystemService( CLIPBOARD_SERVICE );
        final NotificationManager notificationManager = (NotificationManager) getSystemService( Context.NOTIFICATION_SERVICE );
        if (clipboardManager == null)
            return;

        String          title       = strf( "Password for %s", siteNameField.getText() );
        ClipDescription description = new ClipDescription( title, new String[]{ ClipDescription.MIMETYPE_TEXT_PLAIN } );
        clipboardManager.setPrimaryClip( new ClipData( description, new ClipData.Item( currentSitePassword ) ) );

        if (notificationManager != null) {
            Notification.Builder notificationBuilder = new Notification.Builder( this ).setContentTitle( title )
                                                                                       .setContentText(
                                                                                               "Paste the password into your app." )
                                                                                       .setSmallIcon( R.drawable.icon )
                                                                                       .setAutoCancel( true );
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
                notificationBuilder.setVisibility( Notification.VISIBILITY_SECRET )
                                   .setCategory( Notification.CATEGORY_RECOMMENDATION )
                                   .setLocalOnly( true );
            notificationManager.notify( PASSWORD_NOTIFICATION, notificationBuilder.build() );
        }

        final Timer timer = new Timer();
        timer.schedule( new TimerTask() {
            @Override
            public void run() {
                ClipData clip = clipboardManager.getPrimaryClip();
                for (int i = 0; i < clip.getItemCount(); ++i)
                    if (currentSitePassword.contentEquals( clip.getItemAt( i ).coerceToText( EmergencyActivity.this ) )) {
                        clipboardManager.setPrimaryClip( EMPTY_CLIP );
                        break;
                    }

                if (notificationManager != null)
                    notificationManager.cancel( PASSWORD_NOTIFICATION );
                timer.cancel();
            }
        }, CLIPBOARD_CLEAR_DELAY );

        Intent startMain = new Intent( Intent.ACTION_MAIN );
        startMain.addCategory( Intent.CATEGORY_HOME );
        startMain.setFlags( Intent.FLAG_ACTIVITY_NEW_TASK );
        startActivity( startMain );
    }

    private abstract static class ValueChangedListener
            implements TextWatcher, NumberPicker.OnValueChangeListener, AdapterView.OnItemSelectedListener, View.OnFocusChangeListener {

        abstract void update();

        @Override
        public void beforeTextChanged(final CharSequence s, final int start, final int count, final int after) {
        }

        @Override
        public void onTextChanged(final CharSequence s, final int start, final int before, final int count) {
        }

        @Override
        public void afterTextChanged(final Editable s) {
            update();
        }

        @Override
        public void onValueChange(final NumberPicker picker, final int oldVal, final int newVal) {
            update();
        }

        @Override
        public void onItemSelected(final AdapterView<?> parent, final View view, final int position, final long id) {
            update();
        }

        @Override
        public void onNothingSelected(final AdapterView<?> parent) {
            update();
        }

        @Override
        public void onFocusChange(final View v, final boolean hasFocus) {
            if (!hasFocus)
                update();
        }
    }
}

