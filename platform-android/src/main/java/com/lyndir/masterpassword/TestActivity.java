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

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import butterknife.BindView;
import butterknife.ButterKnife;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;
import javax.annotation.Nullable;


@SuppressWarnings("PublicMethodNotExposedInInterface" /* IDEA-191044 */)
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
    @Nullable
    private Runnable                  action;
    private Set<String>               testNames;

    public static void startNoSkip(final Context context) {
        context.startActivity( new Intent( context, TestActivity.class ) );
    }

    @Override
    public void onCreate(@Nullable final Bundle savedInstanceState) {
        super.onCreate( savedInstanceState );

        setContentView( R.layout.activity_test );
        ButterKnife.bind( this );

        nativeKDFField.setOnCheckedChangeListener( (buttonView, isChecked) -> {
            preferences.setNativeKDFEnabled( isChecked );
            // TODO: MasterKey.setAllowNativeByDefault( isChecked );
        } );

        try {
            setStatus( 0, 0, null );
            testSuite = new MPTestSuite();
            testSuite.setListener( this );
            testNames = testSuite.getTests().getCases().stream()
                                 .map( input -> (input == null)? null: input.identifier )
                                 .filter( Objects::nonNull ).collect( Collectors.toSet() );
        }
        catch (final MPTestSuite.UnavailableException e) {
            logger.err( e, "While loading test suite" );
            setStatus( R.string.tests_unavailable, R.string.tests_btn_unavailable, this::finish );
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

        // TODO: MasterKey.setAllowNativeByDefault( preferences.isAllowNativeKDF() );

        setStatus( R.string.tests_testing, R.string.tests_btn_testing, null );
        Futures.addCallback( testFuture = backgroundExecutor.submit( testSuite ), new FutureCallback<Boolean>() {
            @Override
            public void onSuccess(@Nullable final Boolean result) {
                if ((result != null) && result)
                    setStatus( R.string.tests_passed, R.string.tests_btn_passed, () -> {
                        preferences.setTestsPassed( testNames );
                        finish();
                    } );
                else
                    setStatus( R.string.tests_failed, R.string.tests_btn_failed, () -> startTestSuite() );
            }

            @Override
            public void onFailure(final Throwable t) {
                logger.err( t, "While running test suite" );
                setStatus( R.string.tests_failed, R.string.tests_btn_failed, () -> finish() );
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
        runOnUiThread( () -> {
            logView.append( strf( "%n" + messageFormat, args ) );

            progressView.setMax( max );
            progressView.setProgress( current );
        } );
    }
}

