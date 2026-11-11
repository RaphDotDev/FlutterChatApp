import Message from '../models/message.js';
import User from '../models/user.js';
import { getRoomId } from '../utils/chatHelper.js';
import mongoose from 'mongoose';
const ObjectId = mongoose.Types.ObjectId;

export const createMessage = async (messageData) => {
  try {
    const message = await Message.create({
      chatRoomId: messageData.roomId,
      messageId: messageData.messageId,
      sender: messageData.sender,
      receiver: messageData.receiver,
      message: messageData.message,
      status: messageData.status || 'sent',
    });

    return message;
  } catch (error) {
    console.error('Error creating message:', error);
    throw error;
  }
};

export const fetchChatMessages = async ({
  currentUserId,
  senderId,
  receiverId,
  page = 1,
  limit = 20,
}) => {
  const safePage = Math.max(1, parseInt(page, 10) || 1);
  const safeLimit = Math.max(1, parseInt(limit, 10) || 20);

  const effectiveSenderId = senderId || currentUserId;
  const roomId = getRoomId(effectiveSenderId, receiverId);
  const query = { chatRoomId: roomId };

  try {
    if (currentUserId && currentUserId === receiverId) {
      const undeliveryQuery = {
        chatRoomId: roomId,
        receiver: new ObjectId(currentUserId),
        sender: new ObjectId(effectiveSenderId),
        status: 'sent',
      };
      const undeliveredUpdate = await Message.updateMany(undeliveryQuery, {
        $set: { status: 'delivered' },
      });
      if (undeliveredUpdate.modifiedCount > 0) {
        console.log(
          `Updated ${undeliveredUpdate.modifiedCount} messages delivered status`
        );
      }
    }

    const currentUserObjectId = currentUserId ? new ObjectId(currentUserId) : null;

    const messages = await Message.aggregate([
      {
        $match: query,
      },
      {
        $sort: { createdAt: -1 },
      },
      {
        $skip: (safePage - 1) * safeLimit,
      },
      {
        $limit: safeLimit,
      },
      {
        $addFields: {
          isMine: currentUserObjectId
            ? {
                $eq: ['$sender', currentUserObjectId],
              }
            : false,
        },
      },
    ]);

    return messages.reverse();
  } catch (error) {
    console.error('Error fetching chat messages:', error);
    throw new Error('failed to retrieve message');
  }
};

export const updateMessageStatus = async (messageId, status) => {
  try {
    const message = await Message.findOneAndUpdate(
      { messageId: messageId },
      { status: status },
      { new: true }
    );
    return message;
  } catch (error) {
    console.error('Error updating message status:', error);
    throw new Error('Failed to update message');
  }
};

export const getUndeliveredMessages = async (userId, partnerId) => {
  try {
    const messages = await Message.find({
      receiver: new ObjectId(userId),
      sender: new ObjectId(partnerId),
      status: 'sent',
    }).sort({ createdAt: -1 });
    return messages;
  } catch (error) {
    console.error('Error getting undelivered messages:', error);
    throw new Error('Failed to get undelivered messages');
  }
};

export const updateUserLastSeen = async (userId, lastSeen) => {
  try {
    const user = await User.findByIdAndUpdate(
      userId,
      { lastSeen: lastSeen, isOnline: false },
      { new: true }
    );
    return user;
  } catch (error) {
    console.error('Error updating user last seen:', error);
    throw error;
  }
};

export const markMessageAsDelivered = async (userId, partnerId) => {
  try {
    const result = await Message.updateMany(
      {
        receiver: new ObjectId(userId),
        sender: new ObjectId(partnerId),
        status: 'sent',
      },
      {
        $set: {
          status: 'delivered',
        },
      }
    );
    return result.modifiedCount;
  } catch (error) {
    console.error('Error marking message as delivered:', error);
    throw error;
  }
};

export const markMessageAsRead = async (userId, partnerId) => {
  try {
    const result = await Message.updateMany(
      {
        receiver: new ObjectId(userId),
        sender: new ObjectId(partnerId),
        status: { $in: ['sent', 'delivered'] },
      },
      {
        $set: {
          status: 'read',
        },
      }
    );
    return result.modifiedCount;
  } catch (error) {
    console.error('Error marking message as read:', error);
    throw error;
  }
};

export const getUserLastSeen = async (userId) => {
  try {
    const user = await User.findById(userId).select('lastSeen');
    if (!user) {
      return null;
    }
    return user.lastSeen ? user.lastSeen.toISOString() : null;
  } catch (error) {
    console.error('Error getting user last seen:', error);
    throw error;
  }
};

export const getUserOnlineStatus = async (userId) => {
  try {
    const user = await User.findById(userId).select('isOnline lastSeen');
    if (!user) {
      return { isOnline: false, lastSeen: null };
    }
    return {
      isOnline: user.isOnline || false,
      lastSeen: user.lastSeen ? user.lastSeen.toISOString() : null,
    };
  } catch (error) {
    console.error('Error getting user online status:', error);
    throw error;
  }
};

export const chatRoom = async (userId) => {
  try {
    const userObjectId = new ObjectId(userId);

    const privateChatQuery = {
      $or: [{ sender: userObjectId }, { receiver: userObjectId }],
    };

    const privateChats = await Message.aggregate([
      { $match: privateChatQuery },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: {
            $cond: [
              { $ne: ['$sender', userObjectId] },
              '$sender',
              '$receiver',
            ],
          },
          latestMessageTime: { $first: '$createdAt' },
          latestMessage: { $first: '$message' },
          latestMessageId: { $first: '$messageId' },
          sender: { $first: '$sender' },
          messages: {
            $push: {
              sender: '$sender',
              receiver: '$receiver',
              status: '$status',
            },
          },
        },
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'userDetails',
        },
      },
      {
        $unwind: '$userDetails',
      },
      {
        $project: {
          _id: 0,
          chatType: 'private',
          messageId: '$latestMessageId',
          username: '$userDetails.userName',
          userName: '$userDetails.userName',
          userId: { $toString: '$userDetails._id' },
          latestMessageTime: 1,
          latestMessage: 1,
          sender: '$sender',
          unreadCount: {
            $size: {
              $filter: {
                input: '$messages',
                as: 'msg',
                cond: {
                  $and: [
                    { $eq: ['$$msg.receiver', userObjectId] },
                    { $in: ['$$msg.status', ['sent', 'delivered']] },
                  ],
                },
              },
            },
          },
          latestMessageStatus: {
            $cond: [
              { $eq: ['$sender', userObjectId] },
              {
                $arrayElemAt: [
                  {
                    $map: {
                      input: {
                        $filter: {
                          input: '$messages',
                          as: 'msg',
                          cond: { $eq: ['$$msg.sender', userObjectId] },
                        },
                      },
                      as: 'm',
                      in: '$$m.status',
                    },
                  },
                  0,
                ],
              },
              null,
            ],
          },
        },
      },
    ]);

    return privateChats.sort((a, b) => {
      return new Date(b.latestMessageTime) - new Date(a.latestMessageTime);
    });
  } catch (error) {
    console.error('Error fetching chat rooms:', error);
    return [];
  }
};
