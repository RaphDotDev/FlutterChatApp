import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const UserSchema = new mongoose.Schema({
    userName: {type: String, required: true, unique:true},
    password: {type: String , required: true},
    lastSeen: {
        type: Date,
        default: Date.now
    }});

    //runs before the user saves in the database
    //if password is modified it will be decrypt
    UserSchema.pre('save', async function (next) {
    if(this.isModified('password')) {
        this.password = await bcrypt.hash(this.password, 12);
    }
    next(); // this is used to tell mongoose to continue the operations once
            // the function is done
    });
    // to check if the given Password is match to the hashed password
    UserSchema.methods.correctPassword = async function (candidatePassword, 
        userPassword) {
        return await bcrypt.compare(candidatePassword,userPassword);
    }

    export default mongoose.model('User', UserSchema);