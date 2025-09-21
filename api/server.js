import express from 'express';
import {createServer} from 'http';
import {connectDB} from './config/db.js';
import routerUser from './routes/userRoutes.js';
import chatRoutes from './routes/chatRoutes.js';

//connect to DB
connectDB();
//initialize express
const app = express();

app.use(express.json());

app.use('/api/users',routerUser);
app.use('/api/chat',chatRoutes);


app.listen(process.env.PORT || 3000, ()=> 
    console.log("Server Started at",process.env.PORT) 
);

/**
 * Use of {} and without {}
 * 
 * {} - used for named export
 * 
 * export const connectDB = () => { ... };
 * //to call to other file
 * import { connectDB } from './config/db.js';
 * 
 * without {} - used for default export
 * 
 * const connectDB = () => { ... };
    export default connectDB;
* import connectDB from './config/db.js';
 */