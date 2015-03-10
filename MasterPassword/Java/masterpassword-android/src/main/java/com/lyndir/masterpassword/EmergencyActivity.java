package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import android.app.Activity;
import android.content.*;
import android.content.ClipboardManager;
import android.graphics.Paint;
import android.os.Bundle;
import android.text.*;
import android.text.method.PasswordTransformationMethod;
import android.view.View;
import android.view.WindowManager;
import android.widget.*;
import butterknife.ButterKnife;
import butterknife.InjectView;
import com.google.common.base.Throwables;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.ConversionUtils;
import java.util.Arrays;
import java.util.concurrent.*;
import javax.annotation.Nullable;


public class EmergencyActivity extends Activity {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( EmergencyActivity.class );

    private final ListeningExecutorService executor           = MoreExecutors.listeningDecorator( Executors.newSingleThreadExecutor() );
    private final ValueChangedListener     updateMasterKey    = new ValueChangedListener() {
        @Override
        void update() {
            updateMasterKey();
        }
    };
    private final ValueChangedListener     updateSitePassword = new ValueChangedListener() {
        @Override
        void update() {
            updateSitePassword();
        }
    };

    private ListenableFuture<MasterKey> masterKeyFuture;

    @InjectView(R.id.progressView)
    ProgressBar progressView;

    @InjectView(R.id.fullNameField)
    EditText fullNameField;

    @InjectView(R.id.masterPasswordField)
    EditText masterPasswordField;

    @InjectView(R.id.siteNameField)
    EditText siteNameField;

    @InjectView(R.id.siteTypeField)
    Spinner siteTypeField;

    @InjectView(R.id.counterField)
    EditText counterField;

    @InjectView(R.id.siteVersionField)
    Spinner siteVersionField;

    @InjectView(R.id.sitePasswordField)
    TextView sitePasswordField;

    @InjectView(R.id.sitePasswordTip)
    TextView sitePasswordTip;

    @InjectView(R.id.rememberFullNameField)
    CheckBox rememberFullNameField;

    @InjectView(R.id.rememberPasswordField)
    CheckBox forgetPasswordField;

    @InjectView(R.id.maskPasswordField)
    CheckBox maskPasswordField;

    private int    hc_userName;
    private int    hc_masterPassword;
    private String sitePassword;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate( savedInstanceState );
        Res.init( getResources() );

        getWindow().setFlags( WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE );
        setContentView( R.layout.activity_emergency );
        ButterKnife.inject( this );

        fullNameField.setOnFocusChangeListener( updateMasterKey );
        masterPasswordField.setOnFocusChangeListener( updateMasterKey );
        siteNameField.addTextChangedListener( updateSitePassword );
        siteTypeField.setOnItemSelectedListener( updateSitePassword );
        counterField.addTextChangedListener( updateSitePassword );
        siteVersionField.setOnItemSelectedListener( updateMasterKey );
        sitePasswordField.addTextChangedListener( new ValueChangedListener() {
            @Override
            void update() {
                boolean noPassword = TextUtils.isEmpty( sitePasswordField.getText() );
                sitePasswordTip.setVisibility( noPassword? View.INVISIBLE: View.VISIBLE );

                if (noPassword)
                    sitePassword = null;
            }
        } );

        fullNameField.setTypeface( Res.exo_Thin );
        fullNameField.setPaintFlags( fullNameField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        masterPasswordField.setTypeface( Res.sourceCodePro_ExtraLight );
        masterPasswordField.setPaintFlags( masterPasswordField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        siteNameField.setTypeface( Res.exo_Regular );
        siteNameField.setPaintFlags( siteNameField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        sitePasswordField.setTypeface( Res.sourceCodePro_Black );
        sitePasswordField.setPaintFlags( sitePasswordField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );

        siteTypeField.setAdapter( new ArrayAdapter<>( this, R.layout.spinner_item, MPSiteType.forClass( MPSiteTypeClass.Generated ) ) );
        siteTypeField.setSelection( MPSiteType.GeneratedLong.ordinal() );

        siteVersionField.setAdapter( new ArrayAdapter<>( this, R.layout.spinner_item, MasterKey.Version.values() ) );
        siteVersionField.setSelection( MasterKey.Version.CURRENT.ordinal() );

        rememberFullNameField.setOnCheckedChangeListener( new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(final CompoundButton buttonView, final boolean isChecked) {
                getPreferences( MODE_PRIVATE ).edit().putBoolean( "rememberFullName", isChecked ).apply();
                if (isChecked)
                    getPreferences( MODE_PRIVATE ).edit().putString( "fullName", fullNameField.getText().toString() ).apply();
                else
                    getPreferences( MODE_PRIVATE ).edit().putString( "fullName", "" ).apply();
            }
        } );
        forgetPasswordField.setOnCheckedChangeListener( new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(final CompoundButton buttonView, final boolean isChecked) {
                getPreferences( MODE_PRIVATE ).edit().putBoolean( "forgetPassword", isChecked ).apply();
            }
        } );
        maskPasswordField.setOnCheckedChangeListener( new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(final CompoundButton buttonView, final boolean isChecked) {
                getPreferences( MODE_PRIVATE ).edit().putBoolean( "maskPassword", isChecked ).apply();
                sitePasswordField.setTransformationMethod( isChecked? new PasswordTransformationMethod(): null );
            }
        } );
    }

    @Override
    protected void onResume() {
        super.onResume();

        fullNameField.setText( getPreferences( MODE_PRIVATE ).getString( "fullName", "" ) );
        rememberFullNameField.setChecked( isRememberFullNameEnabled() );
        forgetPasswordField.setChecked( isForgetPasswordEnabled() );
        maskPasswordField.setChecked( isMaskPasswordEnabled() );
        sitePasswordField.setTransformationMethod( isMaskPasswordEnabled()? new PasswordTransformationMethod(): null );

        if (TextUtils.isEmpty( masterPasswordField.getText() ))
            masterPasswordField.requestFocus();
        else
            siteNameField.requestFocus();
    }

    @Override
    protected void onPause() {
        if (isForgetPasswordEnabled()) {
            synchronized (this) {
                hc_userName = hc_masterPassword = 0;
                if (masterKeyFuture != null) {
                    masterKeyFuture.cancel( true );
                    masterKeyFuture = null;
                }

                masterPasswordField.setText( "" );
            }
        }

        siteNameField.setText( "" );
        sitePasswordField.setText( "" );
        progressView.setVisibility( View.INVISIBLE );

        super.onPause();
    }

    private boolean isRememberFullNameEnabled() {
        return getPreferences( MODE_PRIVATE ).getBoolean( "rememberFullName", false );
    }

    private boolean isForgetPasswordEnabled() {
        return getPreferences( MODE_PRIVATE ).getBoolean( "forgetPassword", false );
    }

    private boolean isMaskPasswordEnabled() {
        return getPreferences( MODE_PRIVATE ).getBoolean( "maskPassword", false );
    }

    private synchronized void updateMasterKey() {
        final String fullName = fullNameField.getText().toString();
        final char[] masterPassword = masterPasswordField.getText().toString().toCharArray();
        final MasterKey.Version version = (MasterKey.Version) siteVersionField.getSelectedItem();
        try {
            if (fullName.hashCode() == hc_userName && Arrays.hashCode( masterPassword ) == hc_masterPassword &&
                masterKeyFuture != null && masterKeyFuture.get().getAlgorithmVersion() == version)
                return;
        }
        catch (InterruptedException | ExecutionException e) {
            return;
        }
        hc_userName = fullName.hashCode();
        hc_masterPassword = Arrays.hashCode( masterPassword );

        if (isRememberFullNameEnabled())
            getPreferences( MODE_PRIVATE ).edit().putString( "fullName", fullName ).apply();

        if (masterKeyFuture != null)
            masterKeyFuture.cancel( true );

        if (fullName.isEmpty() || masterPassword.length == 0) {
            sitePasswordField.setText( "" );
            progressView.setVisibility( View.INVISIBLE );
            return;
        }

        sitePasswordField.setText( "" );
        progressView.setVisibility( View.VISIBLE );
        (masterKeyFuture = executor.submit( new Callable<MasterKey>() {
            @Override
            public MasterKey call()
                    throws Exception {
                try {
                    return MasterKey.create( version, fullName, masterPassword );
                }
                catch (RuntimeException e) {
                    sitePasswordField.setText( "" );
                    progressView.setVisibility( View.INVISIBLE );
                    logger.err( e, "While generating master key." );
                    throw e;
                }
            }
        } )).addListener( new Runnable() {
            @Override
            public void run() {
                runOnUiThread( new Runnable() {
                    @Override
                    public void run() {
                        updateSitePassword();
                    }
                } );
            }
        }, executor );
    }

    private void updateSitePassword() {
        final String siteName = siteNameField.getText().toString();
        final MPSiteType type = (MPSiteType) siteTypeField.getSelectedItem();
        final int counter = ConversionUtils.toIntegerNN( counterField.getText() );

        if (masterKeyFuture == null || siteName.isEmpty() || type == null) {
            sitePasswordField.setText( "" );
            progressView.setVisibility( View.INVISIBLE );

            if (masterKeyFuture == null)
                updateMasterKey();
            return;
        }

        sitePasswordField.setText( "" );
        progressView.setVisibility( View.VISIBLE );
        executor.submit( new Runnable() {
            @Override
            public void run() {
                try {
                    sitePassword = masterKeyFuture.get().encode( siteName, type, counter, MPSiteVariant.Password, null );

                    runOnUiThread( new Runnable() {
                        @Override
                        public void run() {
                            sitePasswordField.setText( sitePassword );
                            progressView.setVisibility( View.INVISIBLE );
                        }
                    } );
                }
                catch (InterruptedException ignored) {
                    sitePasswordField.setText( "" );
                    progressView.setVisibility( View.INVISIBLE );
                }
                catch (ExecutionException e) {
                    sitePasswordField.setText( "" );
                    progressView.setVisibility( View.INVISIBLE );
                    logger.err( e, "While generating site password." );
                    throw Throwables.propagate( e );
                }
                catch (RuntimeException e) {
                    sitePasswordField.setText( "" );
                    progressView.setVisibility( View.INVISIBLE );
                    logger.err( e, "While generating site password." );
                    throw e;
                }
            }
        } );
    }

    public void copySitePassword(View view) {
        if (TextUtils.isEmpty( sitePassword ))
            return;

        ClipDescription description = new ClipDescription( strf( "Password for %s", siteNameField.getText() ),
                                                           new String[]{ ClipDescription.MIMETYPE_TEXT_PLAIN } );
        ClipData clipData = new ClipData( description, new ClipData.Item( sitePassword ) );
        ((ClipboardManager) getSystemService( CLIPBOARD_SERVICE )).setPrimaryClip( clipData );

        Intent startMain = new Intent( Intent.ACTION_MAIN );
        startMain.addCategory( Intent.CATEGORY_HOME );
        startMain.setFlags( Intent.FLAG_ACTIVITY_NEW_TASK );
        startActivity( startMain );
    }

    private abstract class ValueChangedListener
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

