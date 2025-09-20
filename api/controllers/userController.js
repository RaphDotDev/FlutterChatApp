import {register, login} from '../services/authService.js';

export const registerUser = async (req, res) => {
    const {userName, password} = req.body;

    try{

    const user = await register(userName,password);
    return res.status(201).json(user);

    }catch(error) {
    return res.status(500).json({message: 'Failed to register'});
    }

}

export const loginUser = async (req, res) => {
    const {userName, password} = req.body;

    try{

    const response = await login(userName,password);
    
    if (!response){
         return res.status(401).json({message: 'Login Failed!'});
    }

     return res.status(200).json(response);

    }catch(error) {
    return res.status(500).json({message: 'Failed to Login'});
    }

}