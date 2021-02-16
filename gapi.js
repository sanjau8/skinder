const {OAuth2Client} = require('google-auth-library');

const client = new OAuth2Client("752169556635-q0u04asvqip10b7kcckntcfcltm6ek39.apps.googleusercontent.com");

async function verify(token) {
  const ticket = await client.verifyIdToken({
      idToken: token,
      audience: ["752169556635-q0u04asvqip10b7kcckntcfcltm6ek39.apps.googleusercontent.com", "538224454275-00gviuea25t7t987jha3hpqiuf0indan.apps.googleusercontent.com"] 
  });
  const payload = ticket.getPayload();
  
  const params={"user_id":payload["sub"],"email":payload["email"],"name":payload["name"],"image_link":payload["picture"],"stat":"success"}

  return params
 
}
verify().catch(function(err){
    const params={"stat":"error"}
    return params
});

exports.verify=verify;

