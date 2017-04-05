package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import android.app.*;
import android.content.Context;
import android.content.Intent;
import android.os.*;
import android.view.View;
import android.widget.*;
import butterknife.BindView;
import butterknife.ButterKnife;
import com.google.common.base.*;
import com.google.common.collect.*;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.concurrent.*;
import javax.annotation.Nullable;


public class TestActivity extends Activity implements MPTestSuite.Listener {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( TestActivity.class );

    private final Preferences              preferences        = Preferences.get( this );
    private final ListeningExecutorService backgroundExecutor = MoreExecutors.listeningDecorator( Executors.newSingleThreadExecutor() );
    private final ListeningExecutorService mainExecutor       = MoreExecutors.listeningDecorator( new MainThreadExecutor() );

    @BindView(R.id.progressView)
    ProgressBar progressView;

    @BindView(R.id.statusView)
    TextView statusView;

    @BindView(R.id.logView)
    TextView logView;

    @BindView(R.id.actionButton)
    Button actionButton;

    @BindView(R.id.nativeKDFField)
    CheckBox nativeKDFField;

    private MPTestSuite               testSuite;
    private ListenableFuture<Boolean> testFuture;
    private Runnable                  action;
    private ImmutableSet<String>      testNames;

    public static void startNoSkip(final Context context) {
        context.startActivity( new Intent( context, TestActivity.class ) );
    }

    @Override
    public void onCreate(@Nullable final Bundle savedInstanceState) {
        super.onCreate( savedInstanceState );

        setContentView( R.layout.activity_test );
        ButterKnife.bind( this );

        nativeKDFField.setOnCheckedChangeListener( new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(final CompoundButton buttonView, final boolean isChecked) {
                preferences.setNativeKDFEnabled( isChecked );
                MasterKey.setAllowNativeByDefault( isChecked );
            }
        } );

        try {
            setStatus( 0, 0, null );
            testSuite = new MPTestSuite();
            testSuite.setListener( this );
            testNames = FluentIterable.from( testSuite.getTests().getCases() ).transform(
                    new Function<MPTests.Case, String>() {
                        @Nullable
                        @Override
                        public String apply(@Nullable final MPTests.Case input) {
                            return (input == null)? null: input.identifier;
                        }
                    } ).filter( Predicates.notNull() ).toSet();
        }
        catch (final MPTestSuite.UnavailableException e) {
            logger.err( e, "While loading test suite" );
            setStatus( R.string.tests_unavailable, R.string.tests_btn_unavailable, new Runnable() {
                @Override
                public void run() {
                    finish();
                }
            } );
        }
    }

    @Override
    protected void onResume() {
        super.onResume();

        nativeKDFField.setChecked( preferences.isAllowNativeKDF() );

        if (testFuture == null)
            startTestSuite();
    }

    private void startTestSuite() {
        if (testFuture != null)
            testFuture.cancel( true );

        MasterKey.setAllowNativeByDefault( preferences.isAllowNativeKDF() );

        setStatus( R.string.tests_testing, R.string.tests_btn_testing, null );
        Futures.addCallback( testFuture = backgroundExecutor.submit( testSuite ), new FutureCallback<Boolean>() {
            @Override
            public void onSuccess(@Nullable final Boolean result) {
                if ((result != null) && result)
                    setStatus( R.string.tests_passed, R.string.tests_btn_passed, new Runnable() {
                        @Override
                        public void run() {
                            preferences.setTestsPassed( testNames );
                            finish();
                        }
                    } );
                else
                    setStatus( R.string.tests_failed, R.string.tests_btn_failed, new Runnable() {
                        @Override
                        public void run() {
                            startTestSuite();
                        }
                    } );
            }

            @Override
            public void onFailure(final Throwable t) {
                logger.err( t, "While running test suite" );
                setStatus( R.string.tests_failed, R.string.tests_btn_failed, new Runnable() {
                    @Override
                    public void run() {
                        finish();
                    }
                } );
            }
        }, mainExecutor );
    }

    public void onAction(final View v) {
        if (action != null)
            action.run();
    }

    private void setStatus(final int statusId, final int buttonId, @Nullable final Runnable action) {
        this.action = action;

        if (statusId == 0)
            statusView.setText( null );
        else
            statusView.setText( statusId );

        if (buttonId == 0)
            actionButton.setText( null );
        else
            actionButton.setText( buttonId );
        actionButton.setEnabled( action != null );
    }

    @Override
    public void progress(final int current, final int max, final String messageFormat, final Object... args) {
        runOnUiThread( new Runnable() {
            @Override
            public void run() {
                logView.append( strf( "%n" + messageFormat, args ) );

                progressView.setMax( max );
                progressView.setProgress( current );
            }
        } );
    }
}

