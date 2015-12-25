package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import android.app.*;
import android.os.*;
import android.view.View;
import android.view.WindowManager;
import android.widget.*;
import butterknife.ButterKnife;
import butterknife.InjectView;
import com.google.common.base.*;
import com.google.common.collect.*;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.Set;
import java.util.concurrent.*;
import javax.annotation.Nullable;


public class TestActivity extends Activity implements MPTestSuite.Listener {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( TestActivity.class );

    private final ListeningExecutorService backgroundExecutor = MoreExecutors.listeningDecorator( Executors.newSingleThreadExecutor() );
    private final ListeningExecutorService mainExecutor       = MoreExecutors.listeningDecorator( new MainThreadExecutor() );

    @InjectView(R.id.progressView)
    ProgressBar progressView;

    @InjectView(R.id.statusView)
    TextView statusView;

    @InjectView(R.id.logView)
    TextView logView;

    @InjectView(R.id.actionButton)
    Button actionButton;

    private MPTestSuite               testSuite;
    private ListenableFuture<Boolean> testFuture;
    private Runnable                  action;
    private ImmutableSet<String>      testNames;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate( savedInstanceState );
        Res.init( getResources() );

        getWindow().setFlags( WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE );
        setContentView( R.layout.activity_test );
        ButterKnife.inject( this );

        try {
            setStatus( 0, 0, null );
            testSuite = new MPTestSuite();
            testSuite.setListener( this );
            testNames = FluentIterable.from( testSuite.getTests().getCases() ).transform(
                    new Function<MPTests.Case, String>() {
                        @Nullable
                        @Override
                        public String apply(@Nullable final MPTests.Case input) {
                            return input == null? null: input.identifier;
                        }
                    } ).filter( Predicates.notNull() ).toSet();
        }
        catch (MPTestSuite.UnavailableException e) {
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
    protected void onStart() {
        super.onStart();

        final Set<String> integrityTestsPassed = getPreferences( MODE_PRIVATE ).getStringSet( "integrityTestsPassed",
                                                                                              ImmutableSet.<String>of() );
        if (!FluentIterable.from( testNames ).anyMatch( new Predicate<String>() {
            @Override
            public boolean apply(@Nullable final String testName) {
                return !integrityTestsPassed.contains( testName );
            }
        } )) {
            // None of the tests we need to perform were missing from the tests that have already been passed on this device.
            finish();
            EmergencyActivity.start( TestActivity.this );
        }
    }

    @Override
    protected void onResume() {
        super.onResume();

        if (testFuture == null) {
            setStatus( R.string.tests_testing, R.string.tests_btn_testing, null );
            Futures.addCallback( testFuture = backgroundExecutor.submit( testSuite ), new FutureCallback<Boolean>() {
                @Override
                public void onSuccess(@Nullable final Boolean result) {
                    if (result != null && result)
                        setStatus( R.string.tests_passed, R.string.tests_btn_passed, new Runnable() {
                            @Override
                            public void run() {
                                getPreferences( MODE_PRIVATE ).edit().putStringSet( "integrityTestsPassed", testNames ).apply();
                                finish();
                                EmergencyActivity.start( TestActivity.this );
                            }
                        } );
                    else
                        setStatus( R.string.tests_failed, R.string.tests_btn_failed, new Runnable() {
                            @Override
                            public void run() {
                                finish();
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
    }

    public void onAction(View v) {
        if (action != null)
            action.run();
    }

    private void setStatus(int statusId, int buttonId, @Nullable Runnable action) {
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
                logView.append( strf( '\n' + messageFormat, args ) );

                progressView.setMax( max );
                progressView.setProgress( current );
            }
        } );
    }
}

