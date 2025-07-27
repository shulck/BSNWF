//
//  index.ts
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 06.07.2025.
//

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Инициализируем Firebase Admin
admin.initializeApp();

// Функция для отправки push уведомлений при новом сообщении
export const sendMessageNotification = functions.database
  .ref("/messages/{chatId}/{messageId}")
  .onCreate(async (snapshot, context) => {
    const { chatId, messageId } = context.params;
    const messageData = snapshot.val();

    console.log(`New message in chat ${chatId}:`, messageData);

    try {
      // Получаем информацию о чате
      const chatSnapshot = await admin.database()
        .ref(`/chats/${chatId}`)
        .once("value");
      
      const chatData = chatSnapshot.val();
      if (!chatData) {
        console.log("Chat not found");
        return;
      }

      // Получаем участников чата
      const participants = chatData.participants || [];
      const senderId = messageData.senderID;
      const senderName = messageData.senderName || "Someone";
      const messageContent = messageData.content || "New message";
      const messageType = messageData.type || "text";

      console.log(`Sending notifications to ${participants.length} participants`);

      // Отправляем уведомления всем участникам кроме отправителя
      const notifications = participants
        .filter((participantId: string) => participantId !== senderId)
        .map(async (participantId: string) => {
          return sendNotificationToUser(
            participantId,
            senderName,
            messageContent,
            messageType,
            chatId,
            messageId
          );
        });

      await Promise.all(notifications);
      console.log("All notifications sent successfully");

    } catch (error) {
      console.error("Error sending notifications:", error);
    }
  });

// Функция для уведомлений о новых задачах
export const sendTaskNotification = functions.firestore
  .document('tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const taskData = snap.data();
    const taskId = context.params.taskId;

    console.log(`New task created: ${taskId}`, taskData);

    try {
      // Получаем назначенных пользователей
      const assignedTo = taskData.assignedTo || [];
      const createdBy = taskData.createdBy;
      const taskTitle = taskData.title || "New task";

      console.log(`Sending task notifications to ${assignedTo.length} users`);

      // Отправляем уведомления всем назначенным пользователям кроме создателя
      const notifications = assignedTo
        .filter((userId: string) => userId !== createdBy)
        .map(async (userId: string) => {
          return sendTaskNotificationToUser(userId, taskTitle, taskId);
        });

      await Promise.all(notifications);
      console.log("All task notifications sent successfully");

    } catch (error) {
      console.error("Error sending task notifications:", error);
    }
  });

// Функция для уведомлений о новых событиях
export const sendEventNotification = functions.firestore
  .document('events/{eventId}')
  .onCreate(async (snap, context) => {
    const eventData = snap.data();
    const eventId = context.params.eventId;

    console.log(`New event created: ${eventId}`, eventData);

    try {
      // Получаем ID группы
      const groupId = eventData.groupId;
      if (!groupId) {
        console.log("No group ID found for event");
        return;
      }

      // Пропускаем персональные события
      if (eventData.isPersonal) {
        console.log("Skipping personal event notification");
        return;
      }

      // Получаем всех участников группы
      const groupSnapshot = await admin.firestore()
        .collection("groups")
        .doc(groupId)
        .get();

      const groupData = groupSnapshot.data();
      if (!groupData) {
        console.log("Group not found");
        return;
      }

      const groupMembers = groupData.members || [];
      const createdBy = eventData.createdBy;
      const eventTitle = eventData.title || "New event";

      console.log(`Sending event notifications to ${groupMembers.length} group members`);

      // Отправляем уведомления всем участникам группы кроме создателя
      const notifications = groupMembers
        .filter((userId: string) => userId !== createdBy)
        .map(async (userId: string) => {
          return sendEventNotificationToUser(userId, eventTitle, eventId);
        });

      await Promise.all(notifications);
      console.log("All event notifications sent successfully");

    } catch (error) {
      console.error("Error sending event notifications:", error);
    }
  });

// Функция для отправки уведомления конкретному пользователю (чат)
async function sendNotificationToUser(
  userId: string,
  senderName: string,
  messageContent: string,
  messageType: string,
  chatId: string,
  messageId: string
) {
  try {
    // Получаем FCM токены пользователя
    const userSnapshot = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    const userData = userSnapshot.data();
    if (!userData) {
      console.log(`User ${userId} not found`);
      return;
    }

    const tokens = await getUserFCMTokens(userData);
    if (tokens.length === 0) {
      console.log(`No FCM tokens for user ${userId}`);
      return;
    }

    // Формируем текст сообщения
    let notificationBody = messageContent;
    if (messageType === "image") {
      notificationBody = "📷 Photo";
    }

    // Проверяем упоминания
    const isMention = messageContent.includes("@");
    const notificationTitle = isMention ? 
      `${senderName} mentioned you` : 
      senderName;

    // Создаем уведомление
    const message = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      data: {
        type: isMention ? "mention" : "chat",
        chatId: chatId,
        messageId: messageId,
        senderName: senderName,
        timestamp: Date.now().toString()
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert"
        },
        payload: {
          aps: {
            alert: {
              title: notificationTitle,
              body: notificationBody
            },
            sound: "default",
            badge: 1,
            category: isMention ? "MENTION_NOTIFICATION" : "CHAT_NOTIFICATION",
            "interruption-level": isMention ? "time-sensitive" : "active"
          }
        }
      },
      android: {
        priority: "high" as const,
        notification: {
          sound: "default",
          priority: "high" as const,
          channelId: "chat_notifications"
        }
      }
    };

    await sendToAllTokens(tokens, message, userId);

  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
  }
}

// Функция для отправки уведомления о задаче конкретному пользователю
async function sendTaskNotificationToUser(
  userId: string,
  taskTitle: string,
  taskId: string
) {
  try {
    // Получаем FCM токены пользователя
    const userSnapshot = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    const userData = userSnapshot.data();
    if (!userData) {
      console.log(`User ${userId} not found for task notification`);
      return;
    }

    const tokens = await getUserFCMTokens(userData);
    if (tokens.length === 0) {
      console.log(`No FCM tokens for user ${userId} (task notification)`);
      return;
    }

    // Создаем уведомление о задаче
    const message = {
      notification: {
        title: "New Task Assigned",
        body: taskTitle,
      },
      data: {
        type: "task",
        taskId: taskId,
        timestamp: Date.now().toString()
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert"
        },
        payload: {
          aps: {
            alert: {
              title: "New Task Assigned",
              body: taskTitle
            },
            sound: "default",
            badge: 1,
            category: "TASK_NOTIFICATION",
            "interruption-level": "active"
          }
        }
      },
      android: {
        priority: "high" as const,
        notification: {
          sound: "default",
          priority: "high" as const,
          channelId: "task_notifications"
        }
      }
    };

    await sendToAllTokens(tokens, message, userId);

  } catch (error) {
    console.error(`Error sending task notification to user ${userId}:`, error);
  }
}

// Функция для отправки уведомления о событии конкретному пользователю
async function sendEventNotificationToUser(
  userId: string,
  eventTitle: string,
  eventId: string
) {
  try {
    // Получаем FCM токены пользователя
    const userSnapshot = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    const userData = userSnapshot.data();
    if (!userData) {
      console.log(`User ${userId} not found for event notification`);
      return;
    }

    const tokens = await getUserFCMTokens(userData);
    if (tokens.length === 0) {
      console.log(`No FCM tokens for user ${userId} (event notification)`);
      return;
    }

    // Создаем уведомление о событии
    const message = {
      notification: {
        title: "New Event Added",
        body: eventTitle,
      },
      data: {
        type: "event",
        eventId: eventId,
        timestamp: Date.now().toString()
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert"
        },
        payload: {
          aps: {
            alert: {
              title: "New Event Added",
              body: eventTitle
            },
            sound: "default",
            badge: 1,
            category: "EVENT_NOTIFICATION",
            "interruption-level": "active"
          }
        }
      },
      android: {
        priority: "high" as const,
        notification: {
          sound: "default",
          priority: "high" as const,
          channelId: "event_notifications"
        }
      }
    };

    await sendToAllTokens(tokens, message, userId);

  } catch (error) {
    console.error(`Error sending event notification to user ${userId}:`, error);
  }
}

// Вспомогательная функция для получения FCM токенов пользователя
async function getUserFCMTokens(userData: any): Promise<string[]> {
  const fcmTokens = userData.fcmTokens || [];
  const fcmToken = userData.fcmToken;

  let tokens: string[] = [];

  // Собираем все токены
  if (fcmTokens && Array.isArray(fcmTokens)) {
    tokens = fcmTokens.map((tokenData: any) => tokenData.token).filter(Boolean);
  }
  if (fcmToken && !tokens.includes(fcmToken)) {
    tokens.push(fcmToken);
  }

  return tokens;
}

// Вспомогательная функция для отправки на все токены
async function sendToAllTokens(tokens: string[], message: any, userId: string) {
  const sendPromises = tokens.map(async (token) => {
    try {
      const response = await admin.messaging().send({
        ...message,
        token: token
      });
      console.log(`✅ Notification sent to ${userId}: ${response}`);
      return response;
    } catch (error: any) {
      console.error(`❌ Failed to send to token ${token}:`, error);
      
      // Если токен недействителен, удаляем его
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log(`Removing invalid token: ${token}`);
        await removeInvalidToken(userId, token);
      }
      throw error;
    }
  });

  await Promise.allSettled(sendPromises);
}

// Функция для удаления недействительных токенов
async function removeInvalidToken(userId: string, invalidToken: string) {
  try {
    const userRef = admin.firestore().collection("users").doc(userId);
    const userDoc = await userRef.get();
    const userData = userDoc.data();

    if (userData?.fcmTokens) {
      const updatedTokens = userData.fcmTokens.filter(
        (tokenData: any) => tokenData.token !== invalidToken
      );
      
      await userRef.update({
        fcmTokens: updatedTokens
      });
      
      console.log(`Removed invalid token for user ${userId}`);
    }
  } catch (error) {
    console.error("Error removing invalid token:", error);
  }
}