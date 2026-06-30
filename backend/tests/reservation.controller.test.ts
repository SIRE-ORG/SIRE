import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
    createReservation,
    getMyReservations,
    getReceivedReservations,
    getReservationById,
    updateReservationStatus,
    cancelReservation
} from '../src/controllers/reservation.controller';

const prismaMock = vi.hoisted(() => ({
    reservation: {
        create: vi.fn(),
        findMany: vi.fn(),
        findUnique: vi.fn(),
        update: vi.fn(),
    },
    publication: {
        findUnique: vi.fn(),
    },
    notification: {
        create: vi.fn(),
    }
}));

vi.mock('@prisma/client', () => ({
    PrismaClient: class { constructor() { return prismaMock; } },
    ReservationStatus: {
        pending: 'pending',
        cancelled: 'cancelled',
        rejected: 'rejected',
        completed: 'completed',
        failed: 'failed',
        accepted: 'accepted'
    }
}));

describe('Módulo 3: Reservas', () => {
    let mockRequest: any;
    let mockReply: any;

    beforeEach(() => {
        vi.clearAllMocks();
        mockRequest = { body: {}, params: {}, headers: { 'x-user-id': 'jugador-1' } };
        mockReply = {
            status: vi.fn().mockReturnThis(),
            send: vi.fn()
        };
    });

    //POST /reservations
    it('Creación: Debería crear la reserva con estado inicial PENDING y retornar 201', async () => {
        mockRequest.body = { publicationId: 'cancha-1', date: '2026-06-20', startTime: '18:00', endTime: '19:00' };

        prismaMock.publication.findUnique.mockResolvedValue({
            id: 'cancha-1',
            ownerId: 'dueño-1',
            title: 'Cancha Central'
        });

        prismaMock.reservation.create.mockResolvedValue({ id: 'res-123', status: 'pending' });

        await createReservation(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(201);
    });

    it('Creación: Debería fallar con 400 si faltan campos obligatorios', async () => {
        mockRequest.body = { date: '2026-06-20' }; // Faltan publicationId, startTime, etc.

        await createReservation(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    it('Creación: Debería fallar con 400 si la fecha tiene formato inválido (H10 fix)', async () => {
        mockRequest.body = { publicationId: 'cancha-1', date: 'not-a-date', startTime: '18:00', endTime: '19:00' };

        await createReservation(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    //GET /reservations/mine
    it('Mis Reservas: Debería retornar las reservas del usuario (200)', async () => {
        prismaMock.reservation.findMany.mockResolvedValue([{ id: 'res-123', publicationId: 'cancha-1' }]);

        await getMyReservations(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Mis Reservas: Debería fallar con 401 si no se envía el header x-user-id', async () => {
        mockRequest.headers = {};

        await getMyReservations(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(401);
    });

    //GET /reservations/received
    it('Recibidas: Debería retornar las reservas sobre publicaciones del publisher (200)', async () => {
        mockRequest.headers['x-user-id'] = 'dueño-1';
        prismaMock.reservation.findMany.mockResolvedValue([
            { id: 'res-1', publication: { title: 'Cancha', city: 'Santiago', imageUrl: 'url' }, solicitante: { name: 'Juan' } }
        ]);

        await getReceivedReservations(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Recibidas: Debería fallar con 401 si falta x-user-id', async () => {
        mockRequest.headers = {};

        await getReceivedReservations(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(401);
    });

    it('Recibidas: Debería retornar 500 si Prisma falla', async () => {
        mockRequest.headers['x-user-id'] = 'dueño-1';
        prismaMock.reservation.findMany.mockRejectedValue(new Error('Caída de BD'));

        await getReceivedReservations(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(500);
    });

    //GET /reservations/:id
    it('Detalle: Debería retornar la reserva por id con su publication (200) — solicitante dueño', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.headers['x-user-id'] = 'jugador-1';

        prismaMock.reservation.findUnique.mockResolvedValue({
            id: 'res-123',
            solicitanteId: 'jugador-1',
            publication: { title: 'Cancha', city: 'Santiago', imageUrl: 'url', ownerId: 'dueño-1' }
        });

        await getReservationById(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Detalle: Debería retornar la reserva por id (200) — publisher dueño de la publicación', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.headers['x-user-id'] = 'dueño-1';

        prismaMock.reservation.findUnique.mockResolvedValue({
            id: 'res-123',
            solicitanteId: 'jugador-1',
            publication: { title: 'Cancha', city: 'Santiago', imageUrl: 'url', ownerId: 'dueño-1' }
        });

        await getReservationById(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Detalle: Debería bloquear con 403 si el usuario no es solicitante ni publisher', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.headers['x-user-id'] = 'intruso';

        prismaMock.reservation.findUnique.mockResolvedValue({
            id: 'res-123',
            solicitanteId: 'jugador-1',
            publication: { title: 'Cancha', city: 'Santiago', imageUrl: 'url', ownerId: 'dueño-1' }
        });

        await getReservationById(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(403);
    });

    it('Detalle: Debería fallar con 404 si la reserva no existe', async () => {
        mockRequest.params = { id: 'res-falsa' };
        mockRequest.headers['x-user-id'] = 'jugador-1';

        prismaMock.reservation.findUnique.mockResolvedValue(null);

        await getReservationById(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(404);
    });

    it('Detalle: Debería fallar con 401 si falta x-user-id', async () => {
        mockRequest.headers = {};
        mockRequest.params = { id: 'res-123' };

        await getReservationById(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(401);
    });

    it('Detalle: Debería retornar 500 si Prisma falla', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.headers['x-user-id'] = 'jugador-1';
        prismaMock.reservation.findUnique.mockRejectedValue(new Error('Caída de BD'));

        await getReservationById(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(500);
    });

    //PATCH /reservations/:id/status
    it('Gestión Dueño: Debería permitir al dueño cambiar el estado (200)', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.body = { status: 'accepted' };
        mockRequest.headers['x-user-id'] = 'dueño-1';

        prismaMock.reservation.findUnique.mockResolvedValue({
            id: 'res-123',
            publication: { ownerId: 'dueño-1' }
        });
        prismaMock.reservation.update.mockResolvedValue({ id: 'res-123', status: 'accepted' });

        await updateReservationStatus(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Gestión Dueño: Debería bloquear con 403 si un jugador o intruso intenta cambiar el estado', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.body = { status: 'accepted' };
        mockRequest.headers['x-user-id'] = 'jugador-1';

        prismaMock.reservation.findUnique.mockResolvedValue({
            id: 'res-123',
            publication: { ownerId: 'dueño-1' }
        });

        await updateReservationStatus(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(403);
    });

    it('Gestión Dueño: Debería fallar con 400 si se envía un estado inválido', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.body = { status: 'estado_inventado' };
        mockRequest.headers['x-user-id'] = 'dueño-1';

        prismaMock.reservation.findUnique.mockResolvedValue({
            id: 'res-123',
            publication: { ownerId: 'dueño-1' }
        });

        await updateReservationStatus(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    it('Gestión Dueño: Debería fallar con 404 si la reserva no existe', async () => {
        mockRequest.params = { id: 'res-falsa' };
        mockRequest.body = { status: 'accepted' };

        prismaMock.reservation.findUnique.mockResolvedValue(null);

        await updateReservationStatus(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(404);
    });

    //PATCH /reservations/:id/cancel
    it('Cancelación Jugador: Debería permitir al solicitante cancelar si está PENDING (200)', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.headers['x-user-id'] = 'jugador-1';

        prismaMock.reservation.findUnique.mockResolvedValue({
            id: 'res-123',
            status: 'pending',
            solicitanteId: 'jugador-1',
            publication: { ownerId: 'dueño-1', title: 'Cancha Central' }
        });

        prismaMock.reservation.update.mockResolvedValue({ id: 'res-123', status: 'cancelled' });

        await cancelReservation(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Cancelación Jugador: Debería bloquear con 403 si un jugador intenta cancelar la reserva de otro', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.headers['x-user-id'] = 'intruso';

        prismaMock.reservation.findUnique.mockResolvedValue({ id: 'res-123', status: 'pending', solicitanteId: 'jugador-1' });

        await cancelReservation(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(403);
    });

    it('Cancelación Jugador: Debería denegar la cancelación (400) si ya no está PENDING', async () => {
        mockRequest.params = { id: 'res-123' };
        mockRequest.headers['x-user-id'] = 'jugador-1';

        prismaMock.reservation.findUnique.mockResolvedValue({ id: 'res-123', status: 'accepted', solicitanteId: 'jugador-1' });

        await cancelReservation(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    //Nuevos tests

    // Protege la lógica contra intentos de cancelar IDs de reservas que ya fueron borrados o no existen
    it('Cancelación Jugador: Debería fallar con 404 si la reserva no existe', async () => {
        mockRequest.params = { id: 'res-falsa' };
        mockRequest.headers['x-user-id'] = 'jugador-1';

        prismaMock.reservation.findUnique.mockResolvedValue(null);

        await cancelReservation(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(404);
    });

    //MÓDULO 4: EXCEPCIONES GLOBALES
    it('Excepciones: Debería retornar 500 si Prisma falla al crear la reserva', async () => {
        mockRequest.body = { publicationId: 'cancha-1', date: '2026-06-20', startTime: '18:00', endTime: '19:00' };
        prismaMock.reservation.create.mockRejectedValue(new Error('Caída de BD'));

        await createReservation(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(500);
    });
});