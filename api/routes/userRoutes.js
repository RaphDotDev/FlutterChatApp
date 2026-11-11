import express from 'express';
import { registerUser, loginUser, getAllUsers } from '../controllers/userController.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/users', authMiddleware, getAllUsers);
router.get('/', authMiddleware, getAllUsers);

export default router;
