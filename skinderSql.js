const sqlconn=require("./mySql")
const con=sqlconn.con



function InsertToTable(tableName,data){

    const fields=Object.keys(data)
    const values=Object.values(data)

    let n=fields.length

    var sqlField=""
    var sqlValues=""
    let i=0
    while(i<n-1){

        sqlField=sqlField+`${fields[i]},`
        sqlValues=sqlValues+`'${values[i]}',`
        i+=1

    }

    sqlField=sqlField+`${fields[i]}`
    sqlValues=sqlValues+`'${values[i]}'`




    const query=`insert into ${tableName} (${sqlField}) values (${sqlValues})`

    return new Promise(function(resolve,reject){

        con.query(query,function(err,result){
            if(err){
    
                console.log(err.stack)
                reject("error occured")
            }
            else{
                resolve("inserted")
            }
            
        })
    })
    
    
}


function selectWhere(tableName,fields,conditions,orders){

    
    var query=`select ${fields} from ${tableName}`
    
    if(conditions!=undefined){
        query=query+` where ${conditions}`
    }

    if(orders!=undefined){
        query=query+` order by ${orders}`
    }

    return new Promise(function(resolve,reject){
    con.query(query,function(err,result){
        if(err){

            reject(err.stack)
            
        }
        else{
            
            resolve(result)
    
           
        }
       
    })
})


}






function nonORMQuery(query){

    return new Promise(function(resolve,reject){
        con.query(query,function(err,result){
            if(err){
    
                reject(err.stack)
                
            }
            else{
                
                resolve(result)
        
               
            }
           
        })
    })
    
}


function storedProcedures(procedureName,data){
 const query=`call ${procedureName}("${data["uid"]}",${data["pcid"]},'${data["uod"]}')`
 console.log(query)

 return new Promise(function(resolve,reject){
    con.query(query,function(err,result){
        if(err){

            reject(err.stack)
            
        }
        else{
            
            resolve(result)
    
           
        }
       
    })
})

}

exports.InsertToTable=InsertToTable
exports.selectWhere=selectWhere
exports.nonORMQuery=nonORMQuery
exports.storedProcedures=storedProcedures