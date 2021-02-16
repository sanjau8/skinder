const mysql=require("mysql")

// SQL Connection

const con=mysql.createConnection({
    host:"team2practo.cs4jmf8qoxwe.us-east-1.rds.amazonaws.com",
    user:"team2practo",
    password:"team2practo",
    port:"3306",
    database:'redClone',
    timezone: '+5:30'
    
});

con.connect(function(err){
    if(err)
    {

        console.log("SQL connection failed"+err.stack)        
    }
    else
    {
    console.log("--SQL connection successfull")    
    
    }
})



exports.con=con







