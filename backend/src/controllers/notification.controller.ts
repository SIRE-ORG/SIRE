import type { FastifyRequest, FastifyReply } from 'fastify';
import prisma from '../repositories/prisma.repository.js';

// GET /api/v1/notifications?unreadOnly=&page=&limit=
export const getNotifications = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;
        if (!userId) {
            return reply.status(401).send({ error: { code: 'UNAUTHORIZED', message: 'Se requiere el header x-user-id' } });
        }

        // Lee los parámetros de la URL con valores por defecto
        const query = request.query as any;
        const page = Number.parseInt(query.page) || 1;
        const limit = Number.parseInt(query.limit) || 10;
        const unreadOnly = query.unreadOnly === 'true';

        const skip = (page - 1) * limit;

        // Condición de búsqueda
        const whereClause: any = { userId };
        if (unreadOnly) {
            whereClause.read = false;
        }

        const [notifications, totalUnread, totalItems] = await Promise.all([
            prisma.notification.findMany({
                where: whereClause,
                orderBy: { createdAt: 'desc' }, // Las más nuevas primero
                skip,
                take: limit
            }),
            prisma.notification.count({
                where: { userId, read: false }
            }),
            prisma.notification.count({
                where: whereClause
            })
        ]);

        return reply.status(200).send({
            data: notifications,
            unreadCount: totalUnread,
            pagination: { page, limit, total: totalItems }
        });

    } catch (error) {
        console.error("ERROR OBTENIENDO NOTIFICACIONES:", error);
        return reply.status(500).send({ error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al listar notificaciones' } });
    }
};

// PATCH /api/v1/notifications/:id/read
export const markAsRead = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;
        const { id } = request.params as { id: string };

        if (!userId) {
            return reply.status(401).send({ error: { code: 'UNAUTHORIZED', message: 'Se requiere el header x-user-id' } });
        }

        // Usamos updateMany como medida de seguridad
        // para asegurar que solo actualice si la notificación le pertenece a ese userId
        const result = await prisma.notification.updateMany({
            where: { id, userId },
            data: { read: true }
        });

        if (result.count === 0) {
            return reply.status(404).send({ error: { code: 'NOT_FOUND', message: 'Notificación no encontrada o no te pertenece' } });
        }

        return reply.status(200).send({ message: 'Notificación marcada como leída' });
    } catch (error) {
        console.error("ERROR MARCANDO NOTIFICACIÓN:", error);
        return reply.status(500).send({ error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al actualizar notificación' } });
    }
};

// PATCH /api/v1/notifications/read-all
export const markAllAsRead = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;
        if (!userId) {
            return reply.status(401).send({ error: { code: 'UNAUTHORIZED', message: 'Se requiere el header x-user-id' } });
        }

        await prisma.notification.updateMany({
            where: { userId, read: false },
            data: { read: true }
        });

        return reply.status(200).send({ message: 'Todas las notificaciones marcadas como leídas' });
    } catch (error) {
        console.error("ERROR MARCANDO TODAS LAS NOTIFICACIONES:", error);
        return reply.status(500).send({ error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al actualizar notificaciones' } });
    }
};