/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Authenticate JWT token.  Uses Passport library.
 *  
 ***************************************************************************/

var JwtStrategy = require('passport-jwt').Strategy,
    ExtractJwt = require('passport-jwt').ExtractJwt;

// load up the user model
const User = require('../models/user');

//if we are not in production, load the .env file
//if we are in production, variables should be set and accessible
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
}

var secret = process.env.secret;

module.exports = function (passport) {
    var opts = {};
    opts.jwtFromRequest = ExtractJwt.fromAuthHeaderWithScheme('JWT');
    opts.secretOrKey = secret;
    passport.use(new JwtStrategy(opts, function (jwt_payload, done) {
        User.findOne({ _id: jwt_payload._id }, function (err, user) {
            if (err) {
                return done(err, false);
            }
            if (user) {
                if (user.tokenExpired || user.lockedOut || user.passwordExpired)
                    done(null, false);
                else if (user.loginAttempts > user.securityLoginAttempts)
                    done(null, false);
                else if (jwt_payload.device != null && jwt_payload.device != undefined) {


                    let found = false;
                    //test to see if the specific token is active
                    for (let i = 0; i < user.devices.length; i++) {

                        if (user.devices[i].uuid == jwt_payload.device) {

                            if (user.devices[i].activated==false)
                                done(null, false);

                            else
                                done(null, user);

                            found = true;
                            break;
                        }

                    }
                    if (found == false) 
                        done(null, user);

                }
                else
                    done(null, user);
            } else {
                done(null, false);
            }
        });
    }));
};