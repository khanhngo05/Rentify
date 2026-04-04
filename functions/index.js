const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

const STATUS_NAME = {
    pending: 'Chờ xác nhận',
    confirmed: 'Đã xác nhận',
    renting: 'Đang thuê',
    returned: 'Đã trả',
    completed: 'Hoàn thành',
    cancelled: 'Đã hủy',
};

exports.notifyOrderStatusChanged = onDocumentUpdated(
    {
        document: 'orders/{orderId}',
        region: 'asia-southeast1',
    },
    async (event) => {
        const before = event.data.before.data();
        const after = event.data.after.data();

        if (!before || !after) return;

        const oldStatus = String(before.status || '');
        const newStatus = String(after.status || '');

        if (!newStatus || oldStatus === newStatus) return;

        const userId = String(after.userId || '');
        if (!userId) return;

        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        const userData = userDoc.data() || {};
        const tokens = Array.isArray(userData.fcmTokens)
            ? userData.fcmTokens.filter((value) => typeof value === 'string' && value.trim().length > 0)
            : [];

        if (tokens.length === 0) return;

        const orderId = event.params.orderId || '';
        const shortOrderId = orderId.slice(0, 8).toUpperCase();
        const statusName = STATUS_NAME[newStatus] || newStatus;
        const body = `Đơn #${shortOrderId} đã chuyển sang "${statusName}".`;

        const response = await admin.messaging().sendEachForMulticast({
            tokens,
            notification: {
                title: 'Cập nhật đơn hàng',
                body,
            },
            data: {
                type: 'order_status_changed',
                orderId,
                status: newStatus,
            },
            android: {
                priority: 'high',
            },
            apns: {
                headers: {
                    'apns-priority': '10',
                },
            },
        });

        const invalidTokens = [];
        response.responses.forEach((result, index) => {
            if (result.success) return;
            const code = result.error && result.error.code ? result.error.code : '';
            if (
                code === 'messaging/registration-token-not-registered' ||
                code === 'messaging/invalid-registration-token'
            ) {
                invalidTokens.push(tokens[index]);
            }
        });

        if (invalidTokens.length > 0) {
            await admin.firestore().collection('users').doc(userId).set(
                {
                    fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
                },
                { merge: true }
            );
        }
    }
);
