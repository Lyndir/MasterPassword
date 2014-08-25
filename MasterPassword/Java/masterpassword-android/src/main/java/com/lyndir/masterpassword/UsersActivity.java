package com.lyndir.masterpassword;

import android.app.Activity;
import android.os.Bundle;
import android.widget.LinearLayout;
import butterknife.ButterKnife;
import butterknife.InjectView;
import com.lyndir.masterpassword.model.Avatar;
import com.lyndir.masterpassword.model.User;
import com.lyndir.masterpassword.view.AvatarView;


public class UsersActivity extends Activity {

    @InjectView(R.id.users)
    LinearLayout users;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate( savedInstanceState );
        setContentView( R.layout.activity_users );
        ButterKnife.inject( this );
    }

    @Override
    protected void onResume() {
        super.onResume();

        AvatarView avatarView = new AvatarView( this );
        avatarView.setUser( new User( "Maarten Billemont", Avatar.EIGHT ) );
        users.addView( avatarView );
    }
}

