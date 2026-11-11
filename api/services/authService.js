import User from '../models/user.js';
import jwt from 'jsonwebtoken';

export const register = async (userName, password) => {
  if (!userName || !password) {
    return { error: 'Username and password are required' };
  }

  if (password.length < 8) {
    return { error: 'Password must be at least 8 characters' };
  }

  try {
    const user = await User.create({ userName, password });
    const token = jwt.sign(
      { userId: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '10d' }
    );

    return {
      userId: user._id.toString(),
      token,
      userName: user.userName,
    };
  } catch (err) {
    if (err && err.code === 11000) {
      return { error: 'Username already taken..' };
    }
    return { error: 'Failed to register' };
  }
};

export const login = async (userName, password) => {
  if (!userName || !password) {
    return null;
  }

  try {
    console.log('Login attempt for user:', userName);
    const user = await User.findOne({ userName });

    if (!user) {
      console.log('User not found:', userName);
      return null;
    }

    const isMatch = await user.correctPassword(password, user.password);

    if (!isMatch) {
      console.log('Password does not match for user:', userName);
      return null;
    }

    return {
      token: jwt.sign(
        { userId: user._id.toString() },
        process.env.JWT_SECRET,
        { expiresIn: '10d' }
      ),
      userId: user._id.toString(),
      userName: user.userName,
    };
  } catch (err) {
    console.error('Login error:', err.message);
    return null;
  }
};

export const getUsersService = async (currentUserId) => {
  try {
    const query = currentUserId ? { _id: { $ne: currentUserId } } : {};
    const users = await User.find(query)
      .select('userName lastSeen isOnline')
      .sort({ userName: 1 });

    return users.map((u) => ({
      userId: u._id.toString(),
      userName: u.userName,
      username: u.userName,
      lastSeen: u.lastSeen ? u.lastSeen.toISOString() : null,
      isOnline: u.isOnline || false,
    }));
  } catch (err) {
    console.error('Error in getUsersService:', err);
    throw err;
  }
};
