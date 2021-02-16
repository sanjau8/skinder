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

  const blob = bucket.file(req.file.originalname);
  const blobStream = blob.createWriteStream({metadata: {
    contentType: req.file.mimetype
},
resumable: false});

  blobStream.on('error', err => {
    console.log(err)
    res.send(err)
  });

  blobStream.on('finish', () => {
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${blob.name}`
  
    res.status(200).send(publicUrl);
    console.log(publicUrl)
  });

  blobStream.end(req.file.buffer);
  


  
  

 }
    

exports.fileUpload=fileUpload