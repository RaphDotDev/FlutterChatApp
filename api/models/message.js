import mongoose from "mongoose";

const messageSchema = new mongoose.Schema({

    chatRoomId: {
        type: String,
        required: true,
        index: true
    }, 
    messageId : {
        type: String,
        required: true,
        unique: true,
        index:true
    },
    sender: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required:true,
        index:true
    },
    receiver: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required:true,
        index:true
    },
    message: {
        type: String,
        required:true,
    },
    status: {
        type: String,
        enum: ['sent', 'delivered', 'read'],
        default: 'sent',
        index: true
    },
    createdAt: {
        type: Date,
        default: Date.now,
        index:true
    }
});

messageSchema.index({chatRoomId: 1, createdAt: -1 });
messageSchema.index({receiver: 1 , status:1});

export default mongoose.model('Message', messageSchema);


/*
 * index:true 
 * Adding index: true to a schema field tells MongoDB to build an index on that field.

Purpose: Makes searches, updates, and sorting by that field much faster. (No need to scan all the documents until it finds the document)
Note: Indexes speed up reads but add a little overhead when writing new documents (since the index must also update). 
 
 // Query using the indexed field
const msg = await Message.findOne({ messageId: "msg_001" });
*/

/*

type: mongoose.Schema.Types.ObjectId creates a field that stores a MongoDB ObjectId.

It acts as a reference (foreign key) to another document in a different collection.

Storing: 
{
  "chatRoomId": "room1",
  "sender": ObjectId("66f8c1d5e9a8f0..."), // id of the User
  "receiver": ObjectId("66f9a2e9a123f4..."), // id of the User
  "message": "Hello!"
}

Populating: 
const msg = await Message.findOne().populate("sender receiver");

{
  "chatRoomId": "room1",
  "sender": { "_id": "66f8c1d5e9a8f0...", "userName": "Alice" },
  "receiver": { "_id": "66f9a2e9a123f4...", "userName": "Bob" },
  "message": "Hello!"
}

*/