import Message from '../models/message.js';
import User from '../models/user.js';
import { getRoomId } from '../utils/chatHelper.js';
import message from '../models/message.js';
import user from '../models/user.js';
import mongoose from 'mongoose';
const ObjectId = mongoose.Types.ObjectId;

export const createMessage = async (messageData) => {
    try{
      const message = await Message.create({
        chatRoomId: messageData.roomId,
        messageId: messageData.messageId,
        sender: messageData.sender,
        receiver: messageData.receiver,
        status: messageData.status || 'sent'     
      });  

      //await message.save();
      return message;

    }catch(error) {
    throw new error;
    }

};

export const fetchChatMessages = async ({currentUserId, senderId, 
  receiverId, page = 1, limit= 20}) => {

    const roomId = getRoomId(senderId, receiverId);
    const query = {chatRoomId: roomId};

    try{

      if(currentUserId == receiverId) {
        const undeliveryQuery = {
          chatRoomId: roomId,
          receiver: mongoose.Types.ObjectId(currentUserId),
          sender: mongoose.Types.ObjectId(senderId),
          status: 'sent'
        };
        const undeliverredUpdate = await Message.updateMany(
          undeliveryQuery,
          {
            $set: {status: 'delivered'},
          }
        );
        if(undeliverredUpdate.modifiedCount > 0) {
          console.log(`Updated ${undeliverredUpdate.modifiedCount} messages delivered status`);
        }
       }

       const messages = await Message.aggregate([
        {
          $match: query
        },
        {
          $sort: {createdAt: -1}
        },
        {
          $skip: (page - 1) * limit
        },
        {
          $limit: limit
        },
        {
          $addFields: {
            isMine: {
              req: ["sender", {$toObjectId: currentUserId}]
            }
          }
        }
      ]);

      return messages.reverse();

    }catch(error) {
      throw new Error('failed to retrieve message');
    }

};

export const updateMessageStatus = async(messageId, status) => {

  try{ 

    const message = await Message.findOneAndUpdate(
      {messageId: messageId},
      {status: status},
      {new: true}
    )
    return message;

  }catch(error) {
    throw new Error('Failed to update message');
  }

};


export const getUndeliveredMessages = async(userId, partnerId) => {

  try{ 

    const message = await Message.find(
      {receiver: userId, sender: partnerId, status: 'sent'},
    ).sort({createdAt: -1});
    return message;

  }catch(error) {
    throw new Error('Failed to update message');
  }

};

export const updateUserLastSeen = async(userId, lastSeen) => {

  try{ 

    const user = await User.findByIdAndUpdate(
      userId,
      {lastSeen: lastSeen},
      {new: true}
    )
    return user;

  }catch(error) {
    throw error;
  }

};


export const markMessageAsDelivered = async(userId, partnerId) => {

  try{ 

    const result = await Message.updateMany(
      {receiver: new ObjectId(userId), sender: new ObjectId(partnerId),
        status: 'sent'
      },
      {$set: {
        status: 'delivered'
      }}
    )
    return result.modifiedCount;

  }catch(error) {
    throw error;
  }

};

export const markMessageAsRead = async(userId, partnerId) => {

  try{ 

    const result = await Message.updateMany(
      {receiver: ObjectId(userId), sender: ObjectId(partnerId),
        status: ['sent', 'delivered']
      },
      {$set: {
        status: 'read'
      }}
    )
    return result.modifiedCount;

  }catch(error) {
    throw error;
  }

};

export const getUserLastSeen = async(userId) => {

  try{ 
    const user = await User.findById(userId).select('lastSeen');

    if(!user){
      return null;
    }


    return user.lastSeen ? user.lastSeen.toISOString() : null;

  }catch(error) {
    throw error;
  }

};


export const getUserOnlineStatus = async(userId) => {

  try{ 
    const user = await User.findById(userId).select('isOnline, lastSeen');

    if(!user){
      return {isOnline: false, lastSeen: null};
    }


    return {
      isOnline: user.isOnline || false,
      lastSeen: user.lastSeen ? user.lastSeen.toISOString() : null
    };

  }catch(error) {
    throw error;
  }

};

export const chatRoom = async(userId) => {
  try{

    const userObjectId = new ObjectId(userId);

    const privateChatQuery = {
      $or: [{sender: userObjectId}, {receiver: userObjectId}]
    };

    const privateChats = await Message.aggregate([
      
      {$match: privateChatQuery},
      {$sort: {createdAt: -1}},
      {
        $group: {
          _id: {
            $cond: [
               {$ne:["$sender", userObjectId] },
                "$sender",
                "$receiver" 
            ]
          },
          latestMessageTime: {"$first": "$createdAt"},
          latestMessage: {"$first": "$message"},
          latestMessageId: {"$first": "$_id"},
          sender: {"$first": "$sender"},
          messages: {
            $push: {
              sender: "$sender",
              receiver: "$receiver",
              status: "$status"
            }
          }
        }
      },
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "_id",
          as: "userDetails"
        }
      },
      {
        $unwind: "$userDetails"
      },
      {
        $project: {
      _id: 0,
      chatType: "private",
      messageId: "$latestMessageId",
      userName: "$userDetails.userName",
      userId: "$userDetails._id",
      latestMessageTime: 1,
      latestMessage: 1,
      sender: "$sender",
      unreadCount: {
        $size: {
          $filter: {
            input: "$messages",
            as: "msg",
            cond: {
              $and: [
                { $eq: ["$$msg.receiver", userObjectId] },
                { $in: ["$$msg.status", ["sent", "delivered"]] }
              ]
            }
          }
        }
      },
      latestMessageStatus: {
        $cond: [
          { $eq: ["$sender", userObjectId] },
          {
            $arrayElemAt: [
              {
                $map: {
                  input: {
                    $filter: {
                      input: "$messages",
                      as: "msg",
                      cond: { $eq: ["$$msg.sender", userObjectId] }
                    }
                  },
                  as: "m",
                  in: "$$m.status"
                }
              },
              0
            ]
          },
          null
        ]
      }
    }
      }
    ]);

    return privateChats.sort((a, b) => {
      return new Date(b.latestMessageTime) - new Date(a.latestMessageTime)
    });

  }catch(error){

  }
}


/**
 * 
 * Model.find(conditions, [projection], [options], [callback]) - condtion only accepts one argument
 * 
 * 
 */

/**
 * 
 * Parameters and arguments
 * 
 * parameters is the placeholder in a function definition
 * 
 function greet(name, age) {   // ← "name" and "age" are parameters
  console.log(`Hello, my name is ${name}, I am ${age} years old`);
}

  Arguments is the actual value passed into the functions when its called
  greet("Alice", 25); 

 */
/**
 * 
 * First condition in fetch message (if currentId is equals to receiver Id)
 Bob sends message to Alice: 'sent was set'
  {
    "chatRoomId": "u1_u2",   // from getRoomId()
    "sender": "u2",
    "receiver": "u1",
    "status": "sent"
  }
 Alice Open the chat 
  {
    "chatRoomId": "u1_u2",
    "sender": "u2",
    "receiver": "u1",
    "status": "delivered"
  }
    - runs updateMany messages from sent to delivered messages from bob to alice
  
 */

/**
 * find() vs aggregate
 * 
 * -  Use find() if you just need to fetch records. (simply filtering, sort, limit)
   - Use aggregate() if you need to process or transform the data before returning.
 
   Example: 
   find();
   const messages = await Message.find({ chatRoomId: "u1_u2" })
  .sort({ createdAt: -1 })
  .limit(10);

  Aggregate:
  const messages = await Message.aggregate([
  { $match: { chatRoomId: "u1_u2" } },
  { $sort: { createdAt: -1 } },
  { $limit: 10 },
  { $addFields: { isMine: { $eq: ["$sender", ObjectId(currentUserId)] } } }
]);

{
  "_id": "msg123",
  "chatRoomId": "room1",
  "sender": ObjectId("aaa"),
  "receiver": ObjectId("bbb"),
  "text": "hello"
}

with added field:

{
  "_id": "msg123",
  "chatRoomId": "room1",
  "sender": ObjectId("aaa"),
  "receiver": ObjectId("bbb"),
  "text": "hello",
  "isMine": ???   // new field added here
}

 */

