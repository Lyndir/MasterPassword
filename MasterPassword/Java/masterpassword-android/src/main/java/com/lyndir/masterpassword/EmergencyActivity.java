package com.lyndir.masterpassword;

import android.app.Activity;
import android.content.SharedPreferences;
import android.graphics.Paint;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.*;
import butterknife.ButterKnife;
import butterknife.InjectView;
import com.google.common.base.Throwables;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.concurrent.*;
import java.util.prefs.Preferences;


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

    private ListenableFuture<byte[]> masterKeyFuture;

    @InjectView(R.id.progressView)
    ProgressBar progressView;

    @InjectView(R.id.userNameField)
    EditText userNameField;

    @InjectView(R.id.masterPasswordField)
    EditText masterPasswordField;

    @InjectView(R.id.siteNameField)
    EditText siteNameField;

    @InjectView(R.id.typeField)
    Spinner typeField;

    @InjectView(R.id.counterField)
    NumberPicker counterField;

    @InjectView(R.id.sitePasswordField)
    TextView sitePasswordField;

    private int hc_userName;
    private int hc_masterPassword;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate( savedInstanceState );
        Res.init( getResources() );

        setContentView( R.layout.activity_emergency );
        ButterKnife.inject( this );

        userNameField.setOnFocusChangeListener( updateMasterKey );
        masterPasswordField.setOnFocusChangeListener( updateMasterKey );
        siteNameField.addTextChangedListener( updateSitePassword );
        typeField.setOnItemSelectedListener( updateSitePassword );
        counterField.setOnValueChangedListener( updateSitePassword );

        userNameField.setTypeface( Res.exo_Thin );
        userNameField.setPaintFlags( userNameField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        masterPasswordField.setTypeface( Res.sourceCodePro_ExtraLight );
        masterPasswordField.setPaintFlags( userNameField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        siteNameField.setTypeface( Res.exo_Regular );
        siteNameField.setPaintFlags( userNameField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );
        sitePasswordField.setTypeface( Res.sourceCodePro_Black );
        sitePasswordField.setPaintFlags( userNameField.getPaintFlags() | Paint.SUBPIXEL_TEXT_FLAG );

        typeField.setAdapter( new ArrayAdapter<>( this, R.layout.type_item, MPElementType.forClass( MPElementTypeClass.Generated ) ) );
        typeField.setSelection( MPElementType.GeneratedLong.ordinal() );

        counterField.setMinValue( 1 );
        counterField.setMaxValue( Integer.MAX_VALUE );
        counterField.setWrapSelectorWheel( false );
    }

    @Override
    protected void onResume() {
        super.onResume();

        userNameField.setText( getPreferences( MODE_PRIVATE ).getString( "userName", "" ) );
        masterPasswordField.requestFocus();
    }

    @Override
    protected void onPause() {
        synchronized (this) {
            hc_userName = hc_masterPassword = 0;
            if (masterKeyFuture != null) {
                masterKeyFuture.cancel( true );
                masterKeyFuture = null;
            }
        }

        sitePasswordField.setText( "" );
        progressView.setVisibility( View.INVISIBLE );

        super.onPause();
    }

    private synchronized void updateMasterKey() {
        final String userName = userNameField.getText().toString();
        final String masterPassword = masterPasswordField.getText().toString();
        if (userName.hashCode() == hc_userName && masterPassword.hashCode() == hc_masterPassword)
            return;
        hc_userName = userName.hashCode();
        hc_masterPassword = masterPassword.hashCode();

        SharedPreferences.Editor pref = getPreferences( MODE_PRIVATE ).edit();
        pref.putString( "userName", userName );
        pref.commit();

        if (masterKeyFuture != null)
            masterKeyFuture.cancel( true );

        if (userName.isEmpty() || masterPassword.isEmpty()) {
            sitePasswordField.setText( "" );
            progressView.setVisibility( View.INVISIBLE );
            return;
        }

        progressView.setVisibility( View.VISIBLE );
        (masterKeyFuture = executor.submit( new Callable<byte[]>() {
            @Override
            public byte[] call()
                    throws Exception {
                try {
                    return MasterPassword.keyForPassword( masterPassword, userName );
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
        final MPElementType type = (MPElementType) typeField.getSelectedItem();
        final int counter = counterField.getValue();

        if (masterKeyFuture == null || siteName.isEmpty() || type == null) {
            sitePasswordField.setText( "" );
            progressView.setVisibility( View.INVISIBLE );
            return;
        }

        progressView.setVisibility( View.VISIBLE );
        executor.submit( new Runnable() {
            @Override
            public void run() {
                try {
                    final String sitePassword = MasterPassword.generateContent( type, siteName, masterKeyFuture.get(), counter );

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

