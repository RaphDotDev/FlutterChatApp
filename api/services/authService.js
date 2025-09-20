import User from '../models/user.js';
import mongoose from 'mongoose';
import jwt from 'jsonwebtoken';
export const register = async (userName, password) => {
    if(password.length < 8) {
        return {error: 'Password must be 8 characters'};
    }

    try {

    const user = await User.create({userName, password});
    return {userId: user._id};

    }catch (err) {
     if (error.code === 11000) {
        return {error: 'Username already taken..'}
     }
     return {error: 'Failed to register'};
    }


}

export const login = async (userName, password) => {
    try {

    const user = await User.findOne({userName});
   
    if(!user) {
        throw new Error ('User not found');
    }
    
    const isMatch = await user.correctPassword(password,user.password);

    if(!isMatch) {
        throw new Error ('Invalid Password');
    }

    return {token: jwt.sign({userid: user._id}, process.env.JWT_SECRET, 
        {expiresIn: '10d'}), userId: user._id};

    }catch (err) {
    console.log(err.message);
     return null;
    }


}