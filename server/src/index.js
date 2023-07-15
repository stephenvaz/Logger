import express from "express"
import multer from "multer";
import moment from "moment";

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
// this is for the static files

app.listen(3000, () => {
    console.clear();
    console.log("Server@http://localhost:3000");
});

app.get("/", (req, res) => {
    res.send("v1.0.0");
});


const csvFilter = (req, file, cb) => {
    if (file.mimetype === 'text/csv') {
        cb(null, true);
    } else {
        cb(new Error('Only CSV files are allowed.'));
    }
};

const storage = multer.diskStorage({
    destination: 'uploads/',
    filename: (req, file, cb) => {
        const originalname = file.originalname;
        const name = originalname.split('.')[0];
        const extension = originalname.split('.').pop();
        const timestamp = moment().format('DD-MM-YYYY_HH:mm:ss');
        const filename = `${name}_${timestamp}.${extension}`;
        cb(null, filename);
    }
});

const upload = multer({ storage: storage, fileFilter: csvFilter }).single('csvFile');


const multerErrWrapper = (req, res, next) => {
    upload(req, res, function (err) {
        if (err) {
            console.log(err);
            return res.status(500).json({ message: err.message });
        }
        next();
        // Everything went fine.
    });
};

app.post('/upload', multerErrWrapper, (req, res) => {
    // Handle the uploaded file
    try {
        if (!req.file) {
            res.status(400).json({ error: 'No CSV file provided.' });
            return;
        }

        // Process the CSV file
        console.log(req.file);

        return res.status(200).json({ message: 'CSV file uploaded successfully.' });
    } catch (error) {
        console.log(error);
        return res.status(500).json({ error: 'Something went wrong.' });
    }

});
