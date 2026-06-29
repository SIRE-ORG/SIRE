import type { FastifyInstance } from 'fastify';
import { getNotifications, markAsRead, markAllAsRead } from '../controllers/notification.controller.js';

export async function notificationRoutes(app: FastifyInstance) {
    // GET /api/v1/notifications
    app.get('/', getNotifications);
    // PATCH /api/v1/notifications/read-all
    app.patch('/read-all', markAllAsRead);
    // PATCH /api/v1/notifications/:id/read
    app.patch('/:id/read', markAsRead);
}