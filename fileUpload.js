const {Storage} = require('@google-cloud/storage');

const storage = new Storage({
  
    projectId: ' intern-hack',
    keyFilename: './serviceAccountKey.json'
  
})




const bucket = storage.bucket("gs://intern-hack.appspot.com");


function fileUpload(req,res){
    // console.log(req.file);

    res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE'); // If needed
  res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type'); // If needed
  res.setHeader('Access-Control-Allow-Credentials', true);


  
  

  if (!req.file) {
    res.status(400).send('No file uploaded.');
    return;
  }

  uploadImageToStorage(req.file).then(function(url){
    console.log(url)
    res.send(url)
  }).catch(function(){
    console.log("error")
    res.send("Error")
  })

}

const uploadImageToStorage = (file) => {
  return new Promise((resolve, reject) => {
    if (!file) {
      reject('No image file');
    }
    let newFileName = `${file.originalname}_${Date.now()}`;

    let fileUpload = bucket.file(newFileName);

    const blobStream = fileUpload.createWriteStream({
      metadata: {
        contentType: file.mimetype
      }
    });

    blobStream.on('error', (error) => {
      reject('Something is wrong! Unable to upload at the moment.');
    });

    blobStream.on('finish', () => {
      // The public URL can be used to directly access the file via HTTP.
      const url = `https://storage.googleapis.com/${bucket.name}/${fileUpload.name}`;
      resolve(url);
    });

    blobStream.end(file.buffer);
  });
}    

exports.fileUpload=fileUpload