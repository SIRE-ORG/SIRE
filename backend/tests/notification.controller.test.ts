import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getNotifications, markAsRead, markAllAsRead } from '../src/controllers/notification.controller'; // Ajusta la ruta si es necesario

// 1. Elevamos el mock de las funciones que usa tu controlador de notificaciones
const prismaMock = vi.hoisted(() => ({
    notification: {
        findMany: vi.fn(),
        count: vi.fn(),
        updateMany: vi.fn(),
    }
}));

// 2. Mockeamos el archivo del repositorio exacto que importa tu controlador
vi.mock('../src/repositories/prisma.repository.js', () => ({
    default: prismaMock
}));

describe('Módulo: Notificaciones', () => {
    let mockRequest: any;
    let mockReply: any;

    beforeEach(() => {
        vi.clearAllMocks();
        // Preparamos request con headers, params y query vacíos por defecto
        mockRequest = { body: {}, headers: {}, params: {}, query: {} };
        mockReply = {
            status: vi.fn().mockReturnThis(),
            send: vi.fn()
        };
    });

    // ==========================================
    // PRUEBAS: getNotifications
    // ==========================================
    it('Obtener: Debería fallar con 401 si no se envía x-user-id', async () => {
        await getNotifications(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(401);
    });

    it('Obtener: Debería retornar las notificaciones del usuario con estado 200', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        mockRequest.query = { page: '1', limit: '10', unreadOnly: 'true' };

        prismaMock.notification.findMany.mockResolvedValue([{ id: '1', message: 'Test Notif' }]);

        // Como Promise.all hace dos .count(), devolvemos un valor para unreadCount y otro para totalItems
        prismaMock.notification.count
            .mockResolvedValueOnce(5)  // Total Unread
            .mockResolvedValueOnce(15); // Total Items

        await getNotifications(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(200);
        // Validamos que se envíe la estructura correcta de paginación
        expect(mockReply.send).toHaveBeenCalledWith(expect.objectContaining({
            data: [{ id: '1', message: 'Test Notif' }],
            unreadCount: 5,
            pagination: { page: 1, limit: 10, total: 15 }
        }));
    });

    it('Obtener: Debería retornar 500 si Prisma falla', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        prismaMock.notification.findMany.mockRejectedValue(new Error('DB Error'));

        await getNotifications(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(500);
    });

    // ==========================================
    // PRUEBAS: markAsRead
    // ==========================================
    it('Marcar Leída: Debería fallar con 401 si no se envía x-user-id', async () => {
        mockRequest.params = { id: 'notif-1' };
        await markAsRead(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(401);
    });

    it('Marcar Leída: Debería fallar con 404 si la notificación no existe o no es del usuario', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        mockRequest.params = { id: 'notif-fantasma' };

        // Simula que no se actualizó ninguna fila
        prismaMock.notification.updateMany.mockResolvedValue({ count: 0 });

        await markAsRead(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(404);
    });

    it('Marcar Leída: Debería actualizar y retornar 200', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        mockRequest.params = { id: 'notif-1' };

        prismaMock.notification.updateMany.mockResolvedValue({ count: 1 });

        await markAsRead(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    // ==========================================
    // PRUEBAS: markAllAsRead
    // ==========================================
    it('Marcar Todas: Debería fallar con 401 si no se envía x-user-id', async () => {
        await markAllAsRead(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(401);
    });

    it('Marcar Todas: Debería actualizar todas las del usuario y retornar 200', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';

        // Simula que actualizó 3 notificaciones
        prismaMock.notification.updateMany.mockResolvedValue({ count: 3 });

        await markAllAsRead(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Marcar Todas: Debería retornar 500 si Prisma falla en el update', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        prismaMock.notification.updateMany.mockRejectedValue(new Error('Prisma Network Error'));

        await markAllAsRead(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(500);
    });
});