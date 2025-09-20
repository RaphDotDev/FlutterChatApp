import express from 'express';
import {createServer} from 'http';
import {connectDB} from './config/db.js';
import userRoutes from './routes/userRoutes.js';

//connect to DB
connectDB();
//initialize express
const app = express();

app.use(express.json());

app.use('/api/users',userRoutes);

app.listen(process.env.PORT || 3000, ()=> 
    console.log("Server Started at",process.env.PORT) 
);