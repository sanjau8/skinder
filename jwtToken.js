const jwt = require('jsonwebtoken')
const jwtSql=require("./jwtSql")

const ACCESS_TOKEN_SECRET="swsh23hjddnns"
const ACCESS_TOKEN_LIFE=3600
const REFRESH_TOKEN_SECRET="dhw782wujnd99ahmmakhanjkajikhiwn2n"
const REFRESH_TOKEN_LIFE=86400



//============== GET ACCESS TOKENS =============================


function getAccessToken(payload){
    let accessToken = jwt.sign(payload, ACCESS_TOKEN_SECRET, {
        algorithm: "HS256",
        expiresIn: ACCESS_TOKEN_LIFE
    });

    let refreshToken = jwt.sign(payload, REFRESH_TOKEN_SECRET, {
        algorithm: "HS256",
        expiresIn: REFRESH_TOKEN_LIFE
    });

    console.log(refreshToken.length)
    jwtSql.deleteRefreshToken(payload["uid"])
    jwtSql.addRefreshToken(payload["uid"],refreshToken)

    return {"accessToken":accessToken}
}



//================== TO BE USED AS MIDDLEWARE ====================================
function verifyAccess(req, res, next){

    let accessToken = req.headers["authorization"]
    if (!accessToken){
        return res.status(403).send("the token has expired or has a invalid signature")
    }

    let payload
    try{
        
        payload = jwt.verify(accessToken, ACCESS_TOKEN_SECRET)
        console.log(jwt.decode(accessToken,{key:ACCESS_TOKEN_SECRET})["uid"])

        res.locals.uid=payload["uid"];
        
        next();
    }
    catch(e){
        return res.status(401).send("request unauthorized error")
    }

}




//===================== REFRESH TOKEN ===============================================

function tokenRefresh(req,res){
    
    let accessToken = req.headers["authorization"]   
    
    if (!accessToken){
        return res.status(403).send()
    }

    let payload=jwt.decode(accessToken,{key:ACCESS_TOKEN_SECRET})
    
    jwtSql.getRefreshToken(payload["uid"]).then(function(uid){
        res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE'); // If needed
  res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type'); // If needed
  res.setHeader('Access-Control-Allow-Credentials', true);

        
  let load=jwt.verify(uid,REFRESH_TOKEN_SECRET)
    
   
    let accessToken = jwt.sign({"uid":load["uid"],"email":load["email"]}, ACCESS_TOKEN_SECRET, {
        algorithm: "HS256",
        expiresIn: ACCESS_TOKEN_LIFE
    });

    res.send({"accessToken":accessToken})

    }).catch(function(err){
        console.log(err)
        res.status(440).send("Session Expired Login Again")
        jwtSql.deleteRefreshToken(payload["uid"])
    })

}


//================== DELETE REFRESH TOKEN ====================================
function logout(req,res){

    let accessToken = req.headers["authorization"]   

    let payload=jwt.decode(accessToken,{key:ACCESS_TOKEN_SECRET})

    jwtSql.deleteRefreshToken(payload["uid"])
    res.send({"message":"Logged Out Successfully"})

}

exports.getAccessToken=getAccessToken;
exports.verifyAccess=verifyAccess
exports.tokenRefresh=tokenRefresh
exports.logout=logout