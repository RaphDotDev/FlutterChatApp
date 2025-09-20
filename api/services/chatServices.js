import message from '../models/message.js';
import Message from '../models/message.js';

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

    }

};