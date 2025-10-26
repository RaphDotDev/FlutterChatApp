import express from 'express';
import {createServer} from 'http';
import {connectDB} from './config/db.js';
import routerUser from './routes/userRoutes.js';
import chatRoutes from './routes/chatRoutes.js';
import {Server} from 'socket.io';
import { getRoomId } from './utils/chatHelper.js';
import { getUndeliveredMessages, getUserLastSeen, markMessageAsDelivered, updateMessageStatus, updateUserLastSeen } from './services/chatServices.js';
import User from './models/user.js';
import message from './models/message.js';
import user from './models/user.js';

//connect to DB
connectDB();
//initialize express
const app = express();

app.use(express.json());
app.use('/api/users',routerUser);
app.use('/api/chat',chatRoutes);

const httpServer = createServer(app);
const io = new Server(httpServer, {cors:{origin:'*'}});

const onlineUsers = new Map();

io.on('connection', (socket) => {
    console.log('New Client connected', socket.id);
    let currentUserId = null;

    //Register User
    socket.on('register_user', ({userId}) => {
        if (!userId) return;

        currentUserId = userId;
        onlineUsers.set(userId, socket.id);

        console.log(`User ${userId} registered with socket ${socket.id}`);

        checkPendingMessages();
    });

    //Join Room when user is online
    socket.on('join_room', async({userId, partnerId}) => {
        if(!userId || !partnerId) {
            console.log('Invalid join_room request: missing userId or partnerId');
            return;
        }

        currentUserId = userId;
        onlineUsers.set(userId, socket.id);

        const roomId = getRoomId(userId, partnerId);
        socket.join(roomId);
        console.log(`User ${userId} joined room: ${roomId}`);

        //check undelivered chats to the partnerId and will mark as delivered
        try{
            const undeliveredMessages = await getUndeliveredMessages(userId, partnerId);
            const undeliveredCount = await markMessageAsDelivered(userId, partnerId);

            if(undeliveredCount > 0) {
            console.log(`Marked ${undeliveredCount} messages as delivered for ${userId}`);

              undeliveredMessages.forEach(message => {
                io.to(roomId).emit('message_status', {
                    messageId: message.messageId,
                    status: 'delivered',
                    sender: message.sender,
                    receiver: message.receiver
                });
              });
            }
        
            //notify user parter if online
            io.to(roomId).emit('user_status', {
                userId: userId,
                status: 'online'
            });

            if(onlineUsers.has(partnerId)) {
                socket.emit('user_status', {
                    userId: userId,
                    status: 'online'
                });
            }else {
                //state as offline
                const lastSeen = await getUserLastSeen(partnerId);
                socket.emit('user_status', {
                    userId: userId,
                    status: 'offline',
                    lastSeen: lastSeen || new Date().toISOString()
                })
            }
        }catch(err){
            console.log('Error handling room join : ', err)
        }
    });

    //Sending Message
    socket.on('send_message', async(message) => {
        if(!message.sender  || !message.receiver || !message.message || !message.messageId){
            console.error('Invalid message format: ', message);
            return;
        }

        const roomId = getRoomId(message.sender, message.receiver);

        await createMessage({
            ...message,
            status: 'sent',
            roomId: roomId
        });
        console.log(`Message in room ${roomId} from ${message.sender} to ${message.receiver}: ${message.message}`);
        if(onlineUsers.has(message.receiver)) {
            message.status = 'delivered';
            await updateMessageStatus(message.messageId, 'delivered');
        }else{
            message.status= 'sent';
        }
        io.to(roomId).emit('new_message', message);

        //User is online but not in the room (notification)
        if(onlineUsers.has(message.receiver)) {
            const receiverSocketId = onlineUsers.get(message.receiver);
            const receiverSocket = io.sockets.sockets.get(receiverSocketId);

            if (receiverSocket && !receiverSocket.rooms.has(roomId)){
                const sender = await User.findbyId(message.sender).select('userName');

                receiverSocket.emit('new_message_notification', {
                    senderId: message.sender,
                    senderName: sender.userName,
                    messageId: message.messageId,
                    message: message.message
                });
            }
        }
    });
    
    const typingTimeouts = new Map();

    //User starts typing
    socket.on('typing_start', (userId, receiverId) => {
        if(!userId || !receiverId) return;

        const roomId = getRoomId(userId, receiverId);
        const key = `${userId}_${receiverId}`;

        if(typingTimeouts.has(key)) {
            clearTimeout(typingTimeouts.get(key));
        }

        socket.io(roomId).emit('typing_indicator', {
            userId,
            isTyping: true,
        });

        const timeOut = setTimeout(() => {
            socket.to(roomId).emit('typing_indicator', {
                userId, 
                isTyping: false
            });
            typingTimeouts.delete(key);
        },5000);

        typingTimeouts.set(key, timeOut);
    });

    //User end typing
    socket.on('typing_end', (userId, receiverId) => {
        if(!userId || !receiverId) return;

        const roomId = getRoomId(userId, receiverId);
        const key = `${userId}_${receiverId}`;

        if(typingTimeouts.has(key)) {
            clearTimeout(typingTimeouts.get(key));
            typingTimeouts.delete(key);
        }

        socket.io(roomId).emit('typing_indicator', {
            userId,
            isTyping: false,
        });
    });

    //Message delivered
    socket.on('message_delivered', async({messageId, senderId, receiverId}) => {
        try{
            await updateMessageStatus(messageId, 'delivered');
            
            const roomId = getRoomId(senderId, receiverId);
            const statusUpdate = {
                messageId: messageId,
                status: 'delivered',
                sender: senderId,
                receiver: receiverId
            }

           io.to(roomId).emit('message_status', statusUpdate); 

        }catch(err){

        }
    });

    //Message read
     socket.on('message_read', async({messageIds, senderId, receiverId}) => {
        try{

            for(const messageId of messageIds){
                await updateMessageStatus(messageId, 'read');
            }
            const roomId = getRoomId(senderId, receiverId);

            messageIds.forEach((messageId) => {
            const statusUpdate = {
                messageId: messageId,
                status: 'read',
                sender: senderId,
                receiver: receiverId
            };
             io.to(roomId).emit('message_status', statusUpdate); 
            });
        }catch(err){

        }
    });

    //Mark Message read
    socket.on('mark_message_read', async({userId, partnerId}) => {
        try{

            var count = await markMessageAsRead(userId,partnerId);

            if(count > 0) {
                 const roomId = getRoomId(senderId, receiverId);
                 io.to(roomId).emit('messages_all_read', {
                    reader: userId,
                    sender: partnerId
                 }); 
            }
            
            if(onlineUsers.has(partnerId)) {
                const senderSocketId = onlineUsers.get(partnerId);
                const senderSocket = io.sockets.sockets.get(senderSocketId);

                if(senderSocket && !senderSocket.rooms.has(roomId)){
                    senderSocket.emit('message_all_read', {
                        reader: userId,
                        sender:partnerId
                    })
                }
            }

        }catch(err){

        }
    });

    //Online status of the users
    socket.on('user_status_change', async({userId, status, lastSeen}) => {
        if(status === 'offline'){
            await updateUserLastSeen(userId, lastSeen);

            if(onlineUsers.get(userId) === socket.id){
                onlineUsers.delete(userId);
            }

            io.emit('user_status', {
                userId:userId,
                status: 'offline',
                lastSeen: lastSeen
            });
        }else{
            onlineUsers.set(userId, socket.id);
            io.emit('user_status', {
                userId: userId,
                status: 'online',
            })
        }
    });

    // Disconnection
    socket.on('disconnect', async() =>{
        if(currentUserId) {
            if(onlineUsers.get(currentUserId) == socket.id){
                onlineUsers.delete(currentUserId);
            }

            const lastSeen = new Date().toISOString();
            await updateUserLastSeen(currentUserId, lastSeen);

            io.emit('user_status', {
                userId: currentUserId,
                status: 'offline',
                lastSeen: lastSeen
            });
        }
    })

});

const checkPendingMessages = async(userId) => {
    try{
        const pendingMessages = await message.find({
            receiver: userId,
            status: 'sent',
        }).populate('sender', 'userName');

        if(pendingMessages.length > 0) {
            const messageBySender = {};

            pendingMessages.forEach((msg) => {
                if(!messageBySender[msg.sender._id]){
                    messageBySender[msg.sender._id] = [];
                }
                messageBySender[msg.sender._id].push(msg);
            });

            const userSocket = io.sockets.sockets.get(onlineUsers.get(userId));

            if(userSocket) {
                Object.keys(messageBySender).forEach((senderId) => {
                    const count = messageBySender[senderId].length;
                    const senderName= messageBySender[senderId][0].sender.userName;

                    userSocket.emit('pending_messages', {
                        senderId,
                        senderName,
                        count,
                        latestMessage: messageBySender['senderId'][0].message
                    })

                });
            }
        }

    }catch(error){

    }
};

httpServer.listen(process.env.PORT || 3000, ()=> 
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

/*Map 

Example:
const userMap = new Map([
  [1, 'Alice'],
  [2, 'Bob']
]);

// A new Map instance
const myMap = new Map();

// 1. Setting a string key (standard)
myMap.set("username", "developer_x");

// 2. Setting a number key (unique to Map)
myMap.set(101, "Admin User");

// 3. Setting an object as a key (unique to Map)
const userKey = { role: "guest" };
myMap.set(userKey, "Temporary Access");

// Accessing Data (using the .get() method)
console.log(myMap.get("username"));  // Output: developer_x
console.log(myMap.get(101));         // Output: Admin User
console.log(myMap.get(userKey));     // Output: Temporary Access (key is the object itself)

// Iterating over the map (maintains insertion order)
for (const [key, value] of myMap.entries()) {
  console.log(`Key: ${key} -> Value: ${value}`);
}

*/
