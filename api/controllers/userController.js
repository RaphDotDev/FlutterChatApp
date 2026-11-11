import { register, login, getUsersService } from '../services/authService.js';

export const registerUser = async (req, res) => {
  const { userName, password } = req.body;

  if (!userName || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  try {
    const user = await register(userName, password);

    if (user?.error) {
      return res.status(400).json(user);
    }

    return res.status(200).json(user);
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ message: 'Failed to register' });
  }
};

export const loginUser = async (req, res) => {
  const { userName, password } = req.body;

  if (!userName || !password) {
    return res.status(400).json({ message: 'Username and password are required' });
  }

  try {
    const response = await login(userName, password);

    if (!response) {
      return res.status(401).json({ message: 'Login Failed! Invalid credentials.' });
    }

    return res.status(200).json(response);
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ message: 'Failed to Login' });
  }
};

export const getAllUsers = async (req, res) => {
  try {
    const users = await getUsersService(req.userId);
    return res.status(200).json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    return res.status(500).json({ message: 'Failed to fetch users' });
  }
};
